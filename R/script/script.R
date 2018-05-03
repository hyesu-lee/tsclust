usageHourly_normalized <- usageHourly %>% normalizeUsageHourly()

loadProfile <- usageHourly_normalized %>% transformDfForKmeans()

kmeansResult <- clusterLoadProfile(
  loadProfile = loadProfile %>% select(-id, -date),
  initialK = 50,
  threshold = 0.2,
  numCenters = 10
)

getMeanSquareError(kmeansResult, loadProfile %>% select(-id, -date))


loadProfile %<>% attachCluster(kmeansResult = kmeansResult)

usageHourlyWithCluster <- attachCluster(loadProfile = loadProfile,
                                        kmeansResult = kmeansResult,
                                        to = usageHourly)

usageDaily <- convertPowerUsageHourlyToDaily(usageHourly)
usageDailyWithCluster <- attachCluster(loadProfile = loadProfile,
                                       kmeansResult = kmeansResult,
                                       to = usageDaily)

entropy <- calcEntropy(usageDailyWithCluster = usageDailyWithCluster)
distribution <- getDistributionByCluster(df_cluster = usageHourlyWithCluster)
