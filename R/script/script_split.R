usageHourly %<>%
  mutate(classification = case_when(
    weekdays(dateTime) %in% c("Saturday", "Sunday") ~ "weekend",
    weekdays(dateTime) %nin% c("Saturday", "Sunday") ~ "weekday"
  ))

usageHourly %<>% split(usageHourly$classification)

normalized <- map(usageHourly,
                  normalizeUsageHourly)

loadProfile <- map(normalized,
                   transformDfForKmeans)

kmeansResult <- map(loadProfile %>% map(select, c(-id, -date, -classification)),
                    clusterLoadProfile,
                    initialK = 50,
                    threshold = 0.2,
                    numCenters = 10)
