#' @export
map_clusterLoadProfile <- function(loadProfile,
                                   initialK,
                                   threshold,
                                   numCenters) {
  loadProfileSplited <- split(loadProfile, loadProfile$classification) %>%
    map(select_, .dots = c("-classification", "-id", "-date"))

  kmeansResult <- map(
    .x = loadProfileSplited,
    .f = clusterLoadProfile,
    initialK = initialK,
    threshold = threshold,
    numCenters = numCenters
  )

  return(kmeansResult)
}

#' @export
getMappingTbl <- function(loadProfile, kmeansResult) {
  loadProfile$cluster <- kmeansResult$cluster
  return(loadProfile %>%
           select(id, date, cluster))
}

#' @export
getDf_mappingTbl <- function(loadProfile, kmeansResult) {
  loadProfileSplited <- split(loadProfile, loadProfile$classification)

  nameOrder <- names(kmeansResult)
  loadProfileSplited <- loadProfileSplited[nameOrder]
  kmeansResult <- kmeansResult[nameOrder]

  df_mappingTbl <- map2_df(.x = loadProfileSplited,
                           .y = kmeansResult,
                           .f = function(loadProfile, kmeansResult) {
                             loadProfile$cluster <- kmeansResult$cluster
                             loadProfile %<>% select(id, date, classification, cluster)
                             return(loadProfile)
                           })

  return(df_mappingTbl)
}

#' @export
getDf_centers <- function(kmeansResult) {
  df_centers <- map2_df(.x = names(kmeansResult),
                        .y = kmeansResult,
                        function(classification, kmeansResult) {
                          kmeansResult$centers %<>%
                            as.data.frame() %>%
                            mutate(classification = classification,
                                   cluster = 1:nrow(.),
                                   size = kmeansResult$size)
                          return(kmeansResult$centers)
                        })
  return(df_centers)
}

#' @export
clusterLoadProfile <- function(loadProfile,
                               initialK,
                               threshold,
                               numCenters) {
  initialResult <- kmeansSatisfiedThreshold(loadProfile,
                                            initialK = initialK,
                                            threshold = threshold)

  reducedCenter <-
    reduceCluster(initialResult, targetSize = numCenters)

  reducedResult <- kmeans(loadProfile,
                          reducedCenter)
  return(reducedResult)
}

kmeansSatisfiedThreshold <- function(loadProfile, initialK, threshold) {
  kmeansResult <- kmeans(loadProfile, centers = initialK)
  thetaDf <- getMeanSquareError(kmeansResult = kmeansResult,
                                loadProfile = loadProfile)

  while (any(thetaDf$mse > threshold)) {
    print(nrow(thetaDf))
    newCenter <- getNewCenter(loadProfile,
                              kmeansResult,
                              thetaDf,
                              threshold)
    kmeansResult <- kmeans(loadProfile, centers = newCenter)
    thetaDf <- getMeanSquareError(kmeansResult = kmeansResult,
                                  loadProfile = loadProfile)
  }
  return(kmeansResult)

}

reduceCluster <- function(kmeansResult, targetSize) {
  centers <- kmeansResult$centers %>% as.data.frame()
  numCluster <- nrow(centers)
  while (numCluster > targetSize) {
    distance <- dist(centers) %>% as.matrix()
    distance <- ifelse(distance == 0, NA, distance)
    closetClusters <-
      which(distance == min(distance, na.rm = TRUE), arr.ind = TRUE)[1, ] %>% unname()
    closetClustersCenter <-
      centers[rownames(centers) %in% closetClusters, ] %>%
      mutate(cluster = rownames(.) %>% as.numeric(),
             size = kmeansResult$size[cluster])

    newCenter <- apply(closetClustersCenter, 2, function(x) {
      return((
        x[1] * closetClustersCenter$size[1] + x[2] * closetClustersCenter$size[2]
      ) /
        (sum(closetClustersCenter$size)))
    }) %>% t() %>% as.data.frame() %>% select(-cluster, -size)

    centers %<>% subset(rownames(centers) %nin% closetClusters)
    centers %<>% bind_rows(newCenter)
    numCluster <- nrow(centers)
  }
  return(centers)
}

#' @export
attachCluster <- function(to, kmeansResult) {
  mappingTbl <- getMappingTbl(loadProfile = to,
                              kmeansResult = kmeansResult)
  mappingTbl %<>% as.data.table() %>% setkeyv(c("id", "date"))

  if (all(c("id", "dateTime") %in% colnames(to))) {
    to %<>% attachDate(keep_dateTime = TRUE)
  }

  to %<>% as.data.table() %>% setkeyv(c("id", "date"))
  to %<>% left_join(mappingTbl, by = c("id", "date"))

  return(to)
}

getCenterIthClusterSplitedIntoTwo <- function(ithCluster,
                                              loadProfile,
                                              kmeansResult) {
  ithLoadProfile <- loadProfile %>%
    mutate(cluster = kmeansResult$cluster) %>%
    filter(cluster == ithCluster) %>%
    select(-cluster)
  return(as.data.frame(kmeans(ithLoadProfile, centers = 2)$centers))
}

getNewCenter <- function(loadProfile,
                         kmeansResult,
                         thetaDf,
                         threshold) {
  thetaDf$cnt <- table(kmeansResult$cluster)
  clusterSatisfyingThreshold <- thetaDf[thetaDf$mse <= threshold | thetaDf$cnt <= 2,]$cluster
  clusterNotSatisfyingThreshold <- thetaDf[thetaDf$mse > threshold & thetaDf$cnt > 2,]$cluster

  centerSatisfyingThreshold <- kmeansResult$centers %>% as.data.frame() %>%
    filter(row.names(.) %in% clusterSatisfyingThreshold)

  newCenterSplitedIntoTwo <- map_df(
    clusterNotSatisfyingThreshold,
    ~getCenterIthClusterSplitedIntoTwo(
      ithCluster = .x,
      loadProfile = loadProfile,
      kmeansResult = kmeansResult
    )
  )
  return(bind_rows(centerSatisfyingThreshold, newCenterSplitedIntoTwo))
}
