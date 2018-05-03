plotDailyConsumptionDistribution <- function(usageHourly, log = TRUE) {
  usageDaily <- convertPowerUsageHourlyToDaily(usageHourly)
  usageDaily$usage <- usageDaily$usage / 1000000
  if (log) {
    usageDaily %<>% mutate(usage = log(1 + usage))
  }
  densityPlot <- ggplot(usageDaily, aes(x = usage)) +
    geom_density() + facet_wrap(~classification)

  if (log) {
    densityPlot <- densityPlot +
      ggtitle("log(1+daily consumption) distribution") +
      xlab("log(1+daily consumption)") + theme_bw()
  } else {
    densityPlot <- densityPlot +
      ggtitle("daily consumption distribution") +
      xlab("Daily consumption (kWh)") + theme_bw()
  }
  return(densityPlot)
}

plotCenters <- function(df_centers) {
  plotDf <- df_centers  %>%
    melt(id.vars = c("classification", "cluster", "size")) %>%
    rename(hour = variable, normalizedLoad = value)

  linePlot <- ggplot(plotDf, aes(x = hour, y = normalizedLoad, group = cluster, color = classification)) +
    geom_point() +
    geom_line() +
    facet_wrap(~cluster) +
    facet_wrap(~classification) +
    theme(axis.text.x = element_blank(),
          axis.ticks.x = element_blank()) +
    theme_bw()


}

plotCenters <- function(kmeansResult) {
  plotDf <- as.data.frame(kmeansResult$center) %>%
    mutate(cluster = 1:nrow(kmeansResult$centers)) %>%
    melt(id.vars = "cluster") %>%
    rename(hour = variable, normalizedLoad = value)

  linePlot <- ggplot(plotDf, aes(x = hour, y = normalizedLoad, group = cluster)) +
    geom_point() +
    geom_line() +
    facet_wrap(~cluster) +
    theme(axis.text.x = element_blank(),
          axis.ticks.x = element_blank())
  return(linePlot)
}

plotHeatMap <- function(loadProfile, kmeansResult, cols = as.character(0:23)) {
  loadProfileWithCluster <-
    attachCluster(loadProfile = loadProfile,
                  kmeansResult = kmeansResult) %>%
    mutate(idx = rownames(.))

  idVars <- colnames(loadProfileWithCluster)[which(colnames(loadProfileWithCluster) %nin% cols)]
  plotDf <- loadProfileWithCluster %>%
    melt(id.vars = idVars) %>%
    rename(hour = variable, normalizedLoad = value)

  heatMapPlot <- ggplot(plotDf, aes(x = hour, y = idx)) +
    geom_tile(aes(fill = normalizedLoad)) +
    scale_fill_gradient(low = "yellow", high = "red") +
    facet_wrap(~cluster, scales = "free", nrow = 2) +
    theme(axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank())

  return(heatMapPlot)
}