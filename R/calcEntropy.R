calcEntropy_ <- function(usageDailyWithCluster) {
  result <- map_df(.x = unique(usageDailyWithCluster$classification),
                   .f = function(c, usageDailyWithCluster) {
                     usageDailyWithCluster %<>% filter(classification == c)
                     result <- table(usageDailyWithCluster$id, usageDailyWithCluster$cluster) %>%
                       as.data.frame() %>%
                       rename(id = Var1, cluster = Var2) %>%
                       group_by(id) %>%
                       mutate(relativeFreq = Freq / sum(Freq)) %>%
                       summarise(entropy = -1 * sum(relativeFreq * log(relativeFreq), na.rm = TRUE)) %>%
                       mutate(classification = c)
                     return(result)
                   },
                   usageDailyWithCluster = usageDailyWithCluster)
  result$id %<>% as.character() %>% as.numeric()
  return(result)
}

calcEntropy <- function(usageHourly, kmeansResult) {
  usageDailyWithCluster <-
    convertPowerUsageHourlyToDaily(usageHourly) %>%
    attachCluster(kmeansResult)

  result <- table(usageDailyWithCluster$id, usageDailyWithCluster$cluster) %>%
    as.data.frame() %>%
    rename(id = Var1, cluster = Var2) %>%
    group_by(id) %>%
    mutate(relativeFreq = Freq / sum(Freq)) %>%
    summarise(entropy = -1 * sum(relativeFreq * log(relativeFreq), na.rm = TRUE))

  result$id %<>% as.character() %>% as.numeric()
  return(result)
}
