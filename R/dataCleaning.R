#' @export
normalizeUsageHourly <- function(usageHourly) {
  normalizedUsageHourly <- usageHourly %>%
    attachDate(keep_dateTime = TRUE) %>%
    group_by(id, date) %>%
    mutate(usageDaily = sum(usage)) %>%
    ungroup() %>%
    mutate(usage = usage / usageDaily) %>%
    select(-date, -usageDaily) %>%
    as.data.table()
  return(normalizedUsageHourly)
}

#' @export
transformDfForKmeans <- function(normalizedUsageHourly) {
  loadProfile <- normalizedUsageHourly %>%
    attachDate(keep_dateTime = TRUE) %>%
    attachHour(keep_dateTime = FALSE)

  if ("classification" %in% colnames(normalizedUsageHourly)) {
    loadProfile %<>%
      dcast(id + date + classification ~ hour,
            value.var = "usage")
  } else {
    loadProfile %<>%
      dcast(id + date ~ hour,
            value.var = "usage")
  }
  loadProfile %<>% na.omit()
  return(loadProfile)
}
