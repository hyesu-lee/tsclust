'%nin%' <- Negate('%in%')

convertPowerUsageHourlyToDaily <- function(df_dateTime) {
  usageDaily <- df_dateTime %>%
    attachDate() %>%
    group_by(id, date) %>%
    filter(n() == 24) %>%
    mutate(usage = sum(usage)) %>%
    distinct(.keep_all = TRUE)
  return(usageDaily)
}

attachDate <- function(df_dateTime, keep_dateTime = FALSE) {
  df_dateTime$date <- as.IDate(df_dateTime$dateTime, tz = "Asia/Seoul") %>%
    convertHumanDate2KST()
  if (!keep_dateTime) {
    df_dateTime %<>% select(-dateTime)
  }
  return(df_dateTime)
}

attachHour <- function(df_dateTime, keep_dateTime = FALSE) {
  df_dateTime$hour <- hour(df_dateTime$dateTime)
  if (!keep_dateTime) {
    df_dateTime %<>% select(-dateTime)
  }
  return(df_dateTime)
}