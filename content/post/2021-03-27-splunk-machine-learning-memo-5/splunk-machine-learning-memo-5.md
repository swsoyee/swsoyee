---
title: 为 Splunk 用户准备的数据分析实践指南阅读笔记（第六章）
date: '2021-03-27'
slug: splunk-machine-learning-memo-5
categories: [中文]
tags: [machine-learning,memo]
thumbnailImage: 'https://z3.ax1x.com/2021/03/14/6B9oHx.jpg'
thumbnailImagePosition: right
summary: '第六章《使用 Splunk 进行特征量评价》的阅读笔记。讲述了在 Splunk 中如何使用各种分析可视化的图、Macro 或者命令计算评估数值来对特征量进行评估。'
---

## 6.2 进行特征量评价时候应该注意的点

首先就是最基本的性质，如正态性、线性、独立性等，还有回归分析确认方差。采用聚类的方法分析分離性・均質性（分离程度 / 均一性？）和时间序列数据的規則性（应该是平稳性？）。

在 Splunk 中，可以最简单的用直方图、箱线图和点图来进行简单的初步确认。

箱线图可以用来评估数据的正态性。但一般要求数据量到达 50 以上，最好是 100 以上才比较理想。

### 6.2.3 线性、独立性

在回归分析中，如果仅仅依靠相关系数进行判断的话，对于某些具有特殊分布的数据（如相关系数很高，几乎都分布在一条线上，但是如果可视化的话发现数据分布在线的两端。或者是甜甜圈型、X 型、或者是抛物线型），这种情况下仅靠相关系数而不结合图进行说明的话可能会导致对于模型的解释结果不正确。因此在分析相关的时候 **相关系数** 和 **图** 同样重要。

在考虑重视独立性的分析中，对于具有强关联的数据只采用一方、或者二者接不采用才比较合适。

### 6.2.4 正态性

中心极限定理：在适当的条件下，大量相互独立随机变量的均值经适当标准化后依分布收敛于正态分布。

标准正态分布：均值为 0，标准差为 1 的正态分布。

对于某些变量的直方图看起来不是正态分布的来说，只要进行合适变换也能转换为正态分布。如混合正态分布（[混合高斯分布](https://zhuanlan.zhihu.com/p/45793456)、[$\beta$ 分布](https://www.zhihu.com/question/30269898)），或者是峰值偏向某一边的对数正态分布（负二项分布、$\gamma$ 分布等）。

对于异常值的判断除了通过画图外、还可以用统计检验的手法来判别。

### 6.2.5 方差齐性

如果方差不齐可能会导致模型精度下降。对于不齐的时候，可以对变量采取对数变换或者是指数变换的方式来进行处理。

~~聚类的分離性・均質性和时间序列的規則性没啥特别需要记录的，跳过。~~

## 6.3 在 Splunk 中进行特征量评价

直方图

```spl
| inputlookup housing.csv
| `histogram(median_house_value, 300)`
```

箱线图

```spl
| inputlookup housing.csv
| table median_house_value
| `boxplot`
```

点图（这个没什么好说的，直接选择变量然后可视化时选择就行）。注意，Splunk 中默认最多可绘制 1000 个数值，要绘制更多的话要改写系统设定。

### 6.3.3 复数直方图和箱线图的制作

~~讲真，不如直接上 R 或者 Python 来搞舒服。~~
下面这个例子展示了对每个特征值进行 kmeans 分析后，通过直方图选择分离情况最好的特征值的过程。

```spl
| inputlookup track_day.csv
| where batteryVoltage>=15 OR engineCoolantTemperature<=50
| fit StandardScaler batteryVoltage engineCoolantTemperature engineSpeed
| table SS_*
| fit KMeans k=2 SS_*
| table cluster SS_* // 得到聚类结果表
| bin SS_batteryVoltage span=0.2 AS range
| chart count over range by cluster
| rename "0" as cluster_0
| rename "1" as cluster_1
| makecontinuous range
| fillnull value=0 cluster_0 cluster_1 // 得到用于绘图的数据
```

之后选择条形图看各个变量的分离程度即可。更换 `bin` 中的变量名就可以了。

箱线图如下：

```spl
| inputlookup app_usage.csv
| fit StandardScaler "CloudDrive", "Recruiting", "RemoteAccess", "Webmail" with_mean=true with_std=true
| fit KMeans k=3 "SS_CloudDrive" "SS_Recruting" "SS_RemoteAccess" "SS_Webmail"
| eval cluster="Cluster: " + cluster
| table cluster "SS_Webmail"
| xyseries "SS_Webmail" cluster "SS_Webmail"
| table Cluster*
| `boxplot`
```

### 6.3.4 绘制点图矩阵进行分析

注意每一个图上线只有 1000 个数据点，而且这个矩阵最多只能展示 5 组数据对。聚类的时候注意哪些特征值能使数据点分散得更好，而回归的时候注意自变量与因变量、自变量之间的线性关系来进行变量取舍。

### 6.3.5 主成分分析和多重回归分析的关系

~~Splunk 的 PCA 计算只能得到主成分分数（变换后的新特征值），但是贡献度等的话需要自己通过多重回归分析来计算。算了，以后真正实战一下加深印象吧。在 Splunk 里做也不是特别方便。~~

### 6.3.6 计算相关系数和相关系数矩阵

以相关系数的计算引出 Search Macro（本质就是自定义函数）的制作方式。先来看如何计算相关系数：

```spl
| inputlookup housing.csv
| eventstats mean(median_house_value) as mean_median_house_value, mean(crime_rate) as mean_crime_rate
| eval dev_median_house_value = median_house_value - mean_median_house_value, dev_crime_rate = crime_rate - mean_crime_rate
| eval x=dev_median_house_value * dev_crime_rate
| stats mean(x) as covariance, stdevp(median_house_value) as stdev_median_house_value, stdevp(crime_rate) as stdev_crime_rate
| eval median_house_value=round(covariance / (stdev_median_house_value * stdev_crime_rate), 2)
| eval field="crime_rate"
| fields field median_house_value
```

不可能每次都写这么一大堆，那么就来编写 Search Macro（`calc_correlation`）：

```spl
rename "$f1$" as f1, "$f2$" as f2
| eventstats mean(f1) as mean_f1, mean(f2) as mean_f2
| eval dev_f1 = f1 - mean_f1, dev_f2 = f2 - mean_f2,
| eval dev_f1xf2 = dev_f1 * dev_f2
| stats mean(dev_f1xf2) as covariance_f1xf2, stdevp(f1) as stdevp_f1, stdevp(f2) as stdevp_f2
| eval "$f1" = round(covariance_f1xf2 / (stdevp_f1 * stdevp_f2), 2)
| eval field="$f2$"
| fields field "$f1$"
```

注意首行是没有 `|` 的，因为实际在使用的时候前面会有 `|`，因此如果在 Macro 中的首行也定义了的话就会产生连续的两个 `|`，导致报错。

使用 Macro：

```spl
| inputlookup housing.csv
| `calc_correlation(median_house_value, crime_rate)`
```

相关系数矩阵的 Macro 定义（`correlation_matrix`）：

```spl
appendpipe [|`calc_correlation($f1$,$f2$,$f3$,$f4$,$f5$,$f6$,$f7$,$f8$,$f9$)`]
appendpipe [|`calc_correlation($f2$,$f3$,$f4$,$f5$,$f6$,$f7$,$f8$,$f9$,$f1$)`]
appendpipe [|`calc_correlation($f3$,$f4$,$f5$,$f6$,$f7$,$f8$,$f9$,$f1$,$f2$)`]
appendpipe [|`calc_correlation($f4$,$f5$,$f6$,$f7$,$f8$,$f9$,$f1$,$f2$,$f3$)`]
appendpipe [|`calc_correlation($f5$,$f6$,$f7$,$f8$,$f9$,$f1$,$f2$,$f3$,$f4$)`]
appendpipe [|`calc_correlation($f6$,$f7$,$f8$,$f9$,$f1$,$f2$,$f3$,$f4$,$f5$)`]
appendpipe [|`calc_correlation($f7$,$f8$,$f9$,$f1$,$f2$,$f3$,$f4$,$f5$,$f6$)`]
appendpipe [|`calc_correlation($f8$,$f9$,$f1$,$f2$,$f3$,$f4$,$f5$,$f6$,$f7$)`]
appendpipe [|`calc_correlation($f9$,$f1$,$f2$,$f3$,$f4$,$f5$,$f6$,$f7$,$f8$)`]
| where isnotnull(field) AND field!="0"
| table field corr_*
| sort + field
```

这个相关系数矩阵的计算只支持 9 个参数，并且如果不使用的时候需要传入 0，使其在计算过程中产生 `null`，最后在结果中被去除。

```spl
| inputlookup housing.csv
| `correlation_matrix(median_house_value, crime_rate, business_acres, nitric_oxide_concentration, avg_rooms_per_dwelling, 0, 0, 0, 0)`
```

~~如无必要，还真不如把数据集下载下来直接 R 或者 Python 编程来计算舒服。~~