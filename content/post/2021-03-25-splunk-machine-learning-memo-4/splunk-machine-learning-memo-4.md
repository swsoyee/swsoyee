---
title: 为 Splunk 用户准备的数据分析实践指南阅读笔记（第五章）
date: '2021-03-25'
slug: splunk-machine-learning-memo-4
categories: [中文]
tags: [machine-learning,splunk,memo]
thumbnailImage: 'https://z3.ax1x.com/2021/03/14/6B9oHx.jpg'
thumbnailImagePosition: right
summary: '第五章《生成特征量的预处理和方法》的阅读笔记。主要是讲解如何用 SPL 来进行数据预处理、特征量加工等。'
spl: true
---

第五章《生成特征量的预处理和方法》的阅读笔记。主要是讲解如何用 SPL 来进行数据预处理、特征量加工等。

### 5.1.1 对时间文本进行格式化

Splunk 没有一般编程语言的 `Date` 类型，除了在生成 Index 时候自带的 `_time`（本质是 UNIX 时间） 列外都是普通的文本类型。

下面这条命令展示如何将时间文本转换成 UNIX 时间。

```spl
index="tutorialdata_access"
| eval unixtime = strptime(req_time, "%d/%b/%Y:%H:%M:%S")
| table req_time unixtime
```

具体的时间格式化可参考官方文档：[Date and time format variables](https://docs.splunk.com/Documentation/Splunk/8.1.2/SearchReference/Commontimeformatvariables)。

### 5.1.2 将 UNIX 时间进行转换

在使用 `strptime` 转换成 UNIX 时间后，还可以用 `strftime` 重新转化为合适的文本时间。

```spl
index="tutorialdata_access"
| eval unixtime = strptime(req_time, "%d/%b/%Y:%H:%M:%S")
| eval full_date = strftime(unixtime, "%Y-%m-%d (%a) %H:%M:%S")
| table req_time full_date
```

### 5.1.3 时间的加减运算

```spl
index="tutorialdata_access"
| eval a_day_ago=relative_time(_time, "-1d")
| eval a_day_ago=strftime(a_day_ago, "%Y/%m/%d:%H:%M:%S")
| eval start_of_yest=relative_time(_time, "-1d@h")
| eval start_of_yest=strftime(start_of_yest, "%Y/%m/%d:%H:%M:%S")
| table _time a_day_ago start_of_yest
```

`-1d@h` 中的 `@h` 指的是只保留到天，把小时以后的具体时间都给舍去。

### 5.1.4 对时间进行分组

```spl
index="tutorialdata_access"
| eval unixtime=strptime(req_time, "%d/%b/%Y:%H:%M:%S")
| eval time_hour=strftime(unixtime, "%H")
| eval time_category=case(time_hour<=6 or time_hour>=21, "night", time_hour<=11, "morning", true(), "afternoon")
| table req_time time_hour time_category
```

如果在导入数据时，有将 `req_time` 进行正确的时间戳设置的话，Splunk 会自动生成一些系统列供使用。如此一来就能方便使用了。

```spl
index="tutorialdata_access"
| table req_time date_*
```

### 5.2.1 计算差值

可以使用 `streamstats` 来执行滑动窗口类的计算。

```spl
index="tutorialdata_access"
| reverse
| streamstats current=f global=f window=1 first(bytes) as pre_bytes by JSESSIONID
| eval diff_bytes=abs(bytes-pre_bytes) 
| table JSESSIONID req_time bytes pre_bytes diff_bytes
```

`current`：滑动窗口中包不包含本条记录。
`global`：窗口是基于所有数据还是 `by group` 。分组计算的时候需要设置为 `f`（False）。
`window`：窗口大小。如果是时间窗口的话需要使用 `time_window`。

### 5.2.2 对数据进行归一化

Min-Max 归一化：

$$x_{new} = \frac{x - x_{min}}{x_{max} - x_{min}}$$

但这种归一化容易受到异常值的影响，因此对于最大值最小值无法提前确定的情况的话最好先对异常值先做一些处理，或者用 5.2.3 的标准化方法。

```spl
index="tutorialdata_access"
| eventstats max(bytes) as bytes_max min(bytes) as bytes_min
| eval bytes_mms=(bytes-bytes_min)/(bytes_max-bytes_min)
| table bytes bytes_mms
```

`eventstats` 用来计算一些后续命令可能会用到的数值。

### 5.2.3 数值的标准化

例如对于个人资产这种分布偏得很厉害的数据来说，如果单纯使用归一化的话，范围会受到富人财富的影响，导致一般人的收入分布会被进行不必要的压缩。这个时候可以使用较为常见的 Z-Score 标准化：

$$x_{new} = \frac{x - \mu}{\sigma}$$

其中 $\mu$ 是样本数据的均值（mean）， $\sigma$ 是样本数据的标准差（STD）。

```spl
index="tutorialdata_access"
| table bytes
| fit StandardScaler bytes
```

### 5.2.4 数值的离散化（分组）

```spl
index="tutorialdata_access"
| bin bytes span=1000 as byte_bin
| table bytes byte_bin
```

### 5.2.5 计算移动平均

近 6 个小时的移动平均线计算示例：

```spl
index="tutorialdata_access"
| timechart span=1h count
| trendline sma6(count) as sma6_count
```

`trendline` 的使用方法

```spl
| trendline <trendtype><period>(field) as <new_field>
```

`trendtype`：`sma`（简易移动平均）、`ema`（指数移动平均）、`wma`（加权移动平均）。
不过有些时候 `trendline` 能用的地方有限，这个时候可以手动用 `streamstats` 来达成相同目的（后者可以算是前者的超集了）。

## 5.3 文本相关操作

- 截取：`substr(x, y, z)`，`x` 字符串，`y` 起始位置，`z` 长度。
- 连接：`.` 连接。和 `PHP` 一样。
- 删除前后缀：`ltrim(itemId, "EST-")` 从 `itemId` 中删除 `EST-`。后缀则是用 `rtrim`。前后缀都删的话用 `trim`。
- 大小写：`upper()`、`lower()`。
- 替换：`replace(req_time, "Feb", "02")`。
- 匹配：如果要进行文本分组的话可以用 `match`，如：
    ```spl
    index="tutorialdata_access"
    | eval useragent=lower(useragent)
    | eval os_category=case(match(useragent, "windows"), "WINDOWS", match(useragent, "mac os", "MAC", true(), "OTHER"))
    | table useragent os_category
    ```
- 提取：字符串提取可以用 `rex` 然后用正则表达式提取：
    ```spl
    index="tutorialdata_access"
    | eval useragent=lower(useragent)
    | rex field=useragent "windows nt (?<os_version>[\w.]+)"
    | rex field=useragent "mac os x (?<os_version>\w+)"
    | rex field=useragent "ipad; (u;)?cpu os (?<os_version>\w+) "
    | table useragent os_version
    ```
最后是 MLTK 独有的命令，用来进行 ONE-HOT 转换（简单来说就是把单列分类转换成 01 矩阵）：

```spl
index="tutorialdata_access"
| fillnull value=NULL action
| eval action_{action}=1
| fillnull value=0
| table action*
```

再来一个使用 TF-IDF + k-means 进行文本分类的例子：

```spl
index="tutorialdata_access"
| table useragent
| fit TFIDF useragent
| fit KMeans useragent k=10
| fields useragent cluster
```

## 5.4 IP 地址处理

直接看例子。IP 转换为地理位置（`iplocation`）：

```spl
index="tutorialdata_access"
| iplocation prefix="iplocation_" lang=ja allfields=t clientip
| table clientip iplocation_*
```

判定 IP 所属网络范围（`cidmatch`）：

```spl
index="tutorialdata_access"
| eval label=if(cidmatch("0.0.0.0/3"), clientip), "YES", "NO")
| table clientip label
```

## 5.5 数据汇总

每个商品的购买率：

```spl
index="tutorialdata_access"
| stats count as accessCount, count(eval(action="purchase")) as purchaseCount by itemId
| eval purchaseRate=round(purchaseCount/accessCount, 2)
```

每三个小时的营业额（用到了 `lookup` 去查找 master，因此有点像 SQL 的 JOIN）：

```spl
index="tutorialdata_access"
| lookup prices_manual productId OUTPUT price
| timechart span=3h sum(price) as sales
```

第二句命令意思是以 `productId` 为键，对表 `prices_manual` 进行参照，然后取出 `price` 列。

在搜索的时候也可以指定日期区间：

```spl
index="tutorialdata_access" earliest="08/01/2020:00:00:00" latest="08/02/2020:00:00:00"
| lookup prices_manual productId OUTPUT price
| timechart span=3h sum(price) as sales
```

对数据进行分块统计（transaction）：

```spl
index="tutorialdata_access" 
| transaction JSESSIONID endswith=eval(action=="purchase") mvlist=t
| rename eventcount as accessCount
| eval uniqueActionCount=mvcount(mvdedup(mvfilter(action!="NULL")))
| eval JSESSIONID=mvindex(JSESSIONID,0)
| table _time JSESSIONID action accessCount uniqueActionCount
```

简要说明一下几个比较难理解的点：

- 也正因为是汇总进行 transaction，因此需要首先对数据进行按时间进行升序排列。
- `endswith=eval(action=="purchase")` 就是选取所有 transaction 最后是以 purchase 为终止而进行分割的，也就是说如果用户最后没有购买，那么这些数据就不统计。
- `mvindex=t` 如果是 `null` 的情况下自动插入为 `NULL`。
- `eventcount` 为自动生成的列名。
- `mv*` 系列函数可以理解为是针对同一个 cell 中的内容是数组，因此需要 `multi values` 打头的函数进行处理。

## 5.6 其他类型的预处理

三种 **补缺失值** 的办法（定值、基于前后文和统计量）：

```spl
index="tutorialdata_access"
| reverse
| streamstats current=f global=f window=1 first(bytes) as pre_bytes by JSESSIONID
| eval diff_bytes=abs(bytes-pre_bytes)
| fillnull value="NULL" action
| reverse
| filldown diff_bytes
| eventstats count by JSESSIONID
| eval diff_bytes=if(count==1, null(), diff_bytes)
| eventstats mean(diff_bytes) as mean_diff_bytes
| eval diff_bytes=if(isnull(diff_bytes), mean_diff_bytes, diff_bytes)
| table _time JSESSIONID action count mean_diff_bytes diff_bytes
```

上述 SPL 需要注意的几点：

- `diff_bytes` 进过了几轮数据填充的操作，需要仔细阅读每一行结果。
- 因为不是需要最终结果，而是要保持一个结果到所有行中，因此用到的命令是 `eventstats` 而不是直接进行计算的 `stats`。
- 在 MLTK 中有 `fit Imputer` 自选方法进行快速填充，不需要自己手算。

数据 **采样** （设定随机种子，提取 10%）：

```spl
index="tutorialdata_access"
| sample ratio=0.1 seed=1234
```

但是这个 `sample` 只有安装了 MLTK 才能用，而且是搜索时（index 之后）才可使用。如果需要在 index 前的话，可以用自带的 `Event Sampling` 功能进行采样。

表格的 **拼合**（类似 SQL 的 `JOIN`）：

```spl
index="tutorialdata_access"
| lookup prices_manual productId OUTPUT product_name as productName
| table _time productId productName
```

**添加 ID**：

```spl
index="tutorialdata_access"
| eval num=1
| accum num as num
| eval id=printf("N%06d", num)
| table id _time
```

**降维（PCA）**：

```spl
index="tutorialdata_access"
| table bytes method
| fit StandardScaler bytes method
| fit PCA "SS_*" k=2
| fields bytes method "PC_*"
```

MLTK 的 PCA 只输出主成分得分，而特征量的权重和 PC 的贡献度等需要用多重回归分析自己算。
