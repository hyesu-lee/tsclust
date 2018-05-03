plotTotalWithinssByK <- function(loadProfile) {
  totWithinssDf <- data.frame(
    k = seq(100, 1000, 100),
    totWithinss = sapply(seq(100, 1000, 100),
                         function(k){kmeans(loadProfile, centers = k)$tot.withinss})
  )
  ggplot(totWithinssDf, aes(x = k, y = totWithinss)) + geom_line() + geom_point() +
    geom_text(aes(label = round(totWithinss, 1)), size = 2, vjust = -1.5)
}

#' @export
getMeanSquareError <- function(kmeansResult, loadProfile) {
  fitted <- as.data.frame(fitted(kmeansResult))
  squareCenter <- as.data.frame(fitted(kmeansResult) * fitted(kmeansResult))

  squareCenter %<>% as.data.frame() %>%
    mutate(cluster = kmeansResult$cluster,
           rSum = rowSums(.)) %>%
    group_by(cluster) %>%
    summarize(right = sum(rSum))

  squareErr <- data.frame(
    cluster = 1:length(kmeansResult$size),
    left = kmeansResult$withinss
  )

  result <- left_join(squareErr, squareCenter, by = 'cluster') %>%
    mutate(mse = left / right) %>%
    select(cluster, mse)
  return(result)
}

#' @export
getDistributionByCluster <- function(df_cluster) {
  if (all(c("id", "dateTime") %in% colnames(df_cluster))) {
    df_cluster %<>% convertPowerUsageHourlyToDaily()
  }
  distribution <- df_cluster %>%
    group_by(cluster) %>%
    summarize(min = min(usage),
              quantile_1st = quantile(usage, 0.25),
              median = median(usage),
              mean = mean(usage),
              quantile_3rd = quantile(usage, 0.75),
              max = max(usage))
  return(distribution)
}
