plotDf <- loadProfileWithCluster %>%
  filter(id == 10012027) %>%
  filter(classification == "겨울") %>%
  melt(id.vars = c("classification", "cluster", "date", "id")) %>%
  rename(hour = variable, normalizedLoad = value)

(linePlot <- ggplot(plotDf, aes(x = hour, y = normalizedLoad, group = date, color = as.factor(cluster))) +
  geom_point() +
  geom_line() +
  facet_wrap(~date) +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank()) +
  theme_bw())
