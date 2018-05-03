# tsclust


## Overview
tsclust is a set of tools for clustering time-series energy data: you need to manipulate data, cluster load profile, and calculate MSE, entropy, etc.
* `normalizeUsageHourly()` normalize usage hourly by daily
* `transformDfForKmeans()` transform data frame to use kmeans function in stats package
* `clusterLoadProfile()` perform clustering algorithm
* `getMeanSquareError()` calculate MSE
* `getMappingTbl()` map cluster index to existing data
* `calcEntropy()` calculate entropy(how many clusters each id belongs to)


## Installation
`devtools::install_github("hyesu-lee/tsclust")`

## Usage
```
library(tsclust)

head(usageHourly)
##          id            dateTime  usage
## 1: abcdefgh 2017-05-01 00:00:00  28532
## 2: abcdefgh 2017-05-01 01:00:00  18428
## 3: abcdefgh 2017-05-01 02:00:00  17311
## 4: abcdefgh 2017-05-01 03:00:00  15110
## 5: abcdefgh 2017-05-01 04:00:00  14271
## 6: abcdefgh 2017-05-01 05:00:00  14706

normalized <- usageHourly %>% normalizeUsageHourly()
##          id            dateTime      usage
## 1: abcdefgh 2017-05-01 00:00:00 0.04876862
## 2: abcdefgh 2017-05-01 01:00:00 0.03223735
## 3: abcdefgh 2017-05-01 02:00:00 0.02962630
## 4: abcdefgh 2017-05-01 03:00:00 0.02583752
## 5: abcdefgh 2017-05-01 04:00:00 0.02422190
## 6: abcdefgh 2017-05-01 05:00:00 0.02462555


loadProfile <- normalized %>% transformDfForKmeans()
head(loadProfile, 2)
##          id       date          0          1          2          3
## 1: abcdefgh 2017-05-01 0.04876862 0.03223735 0.02962630 0.02583752
## 2: abcdefgh 2017-05-02 0.05218131 0.02329010 0.02201246 0.02226989
##             4          5          6          7          8          9
## 1: 0.02422190 0.02462555 0.02551375 0.02610639 0.02747036 0.02222794
## 2: 0.02104697 0.02195711 0.02075798 0.02062176 0.02697100 0.02412587
##            10         11         12         13         14         15
## 1: 0.02769206 0.02710991 0.02162927 0.01957248 0.01902355 0.01901013
## 2: 0.04929198 0.03825852 0.02976856 0.05208315 0.06647298 0.06854807
##            16         17         18         19         20         21
## 1: 0.01912718 0.01864194 0.02641588 0.09451927 0.11198642 0.11098823
## 2: 0.04005490 0.03344747 0.03629949 0.06403990 0.07356697 0.07041019
##            22         23
## 1: 0.10379798 0.09385002
## 2: 0.05441505 0.06810834


kmeansResult <- clusterLoadProfile(
  loadProfile = loadProfile %>% select(-id, -date),
  initialK = 50,
  threshold = 0.2,
  numCenters = 10
)


getMeanSquareError(kmeansResult = kmeansResult, 
                   loadProfile = loadProfile %>% select(-id, -date))
##    cluster        mse
## 1        1 0.15430347
## 2        2 0.13330370
## 3        3 0.15733124
## 4        4 0.10694762
## 5        5 0.15698871
## 6        6 0.14744894
## 7        7 0.12960738
## 8        8 0.13154827
## 9        9 0.07064577
## 10      10 0.18390186


mappingTbl <- getMappingTbl(loadProfile = loadProfile,
                                  kmeansResult = kmeansResult)
head(mappingTbl)
##         id       date cluster
## 1 abcdefgh 2017-05-01       1
## 2 abcdefgh 2017-05-02       9
## 3 abcdefgh 2017-05-03       9
## 4 abcdefgh 2017-05-04       6
## 5 abcdefgh 2017-05-05       4
## 6 abcdefgh 2017-05-06       6


loadProfileWithCluster <- attachCluster(to = loadProfile,
                                        kmeansResult = kmeansResult)
head(loadProfileWithCluster, 2)
##         id       date          0          1          2          3
## 1 abcdefgh 2017-05-01 0.04876862 0.03223735 0.02962630 0.02583752
## 2 abcdefgh 2017-05-02 0.05218131 0.02329010 0.02201246 0.02226989
##            4          5          6          7          8          9
## 1 0.02422190 0.02462555 0.02551375 0.02610639 0.02747036 0.02222794
## 2 0.02104697 0.02195711 0.02075798 0.02062176 0.02697100 0.02412587
##           10         11         12         13         14         15
## 1 0.02769206 0.02710991 0.02162927 0.01957248 0.01902355 0.01901013
## 2 0.04929198 0.03825852 0.02976856 0.05208315 0.06647298 0.06854807
##           16         17         18         19         20         21
## 1 0.01912718 0.01864194 0.02641588 0.09451927 0.11198642 0.11098823
## 2 0.04005490 0.03344747 0.03629949 0.06403990 0.07356697 0.07041019
##           22         23 cluster
## 1 0.10379798 0.09385002       1
## 2 0.05441505 0.06810834       9


entropy <- calcEntropy(usageHourly = usageHourly,
                       kmeansResult = kmeansResult)
head(entropy)
## # A tibble: 6 x 2
##         id entropy
##      <dbl>   <dbl>
## 1 abcdefgh    2.13
## 2 22cdefgh    2.11
## 3 333defgh    1.22
## 4 4444efgh    2.06
## 5 55555fgh    1.78
## 6 666666gh    1.97
```

## Application
If you need to cluster by specific column, use as follows:

```
usageHourly %<>%
  mutate(classification = case_when(
    weekdays(dateTime) %in% c("Saturday", "Sunday") ~ "weekend",
    weekdays(dateTime) %nin% c("Saturday", "Sunday") ~ "weekday"
  ))

head(usageHourly)
##         id            dateTime  usage classification
## 1 333defgh 2017-05-01 00:00:00   2833        weekday
## 2 333defgh 2017-05-01 01:00:00   1724        weekday
## 3 333defgh 2017-05-01 02:00:00   1715        weekday
## 4 333defgh 2017-05-01 03:00:00   1504        weekday
## 5 333defgh 2017-05-01 04:00:00   1307        weekday
## 6 333defgh 2017-05-01 05:00:00   1230        weekday

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
```



