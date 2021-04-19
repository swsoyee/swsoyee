---
title: Splunk 中计算每个 IP 的访问量与同期平均值的比较
date: '2021-04-19'
slug: calculate-current-request-than-average-in-splunk
categories: [中文]
tags: [splunk]
summary: '如何在 Splunk 中计算今天每个 IP 每小时的访问量和过去 7 天同一个时段的平均值来对比，如果有高于平均值的时候则发出警告。'
spl: true
---

## 1. 问题

今天碰到一个 Splunk 的需求，问：

> 如何在 Splunk 中计算今天每个 IP 每小时的访问量和过去 7 天同一个时段的平均值来对比，如果有高于平均值的时候则发出警告。

这个需求也不是特别难，“如果有高于平均值的时候则发出警告”这部分就不属于 SPL 本身的职责了，因此在这里跳过，仅仅谈谈如何用 SPL 来实现前半部分。  

## 2. 需求分析

首先先分解一下需要计算的字段：

> ……每个 IP ……的访问量……

需要判断该条 log 是否包含正确的 IP 信息，并且是属于访问（`request`）类型的 log；

> ……每小时的访问量……

需要对时间字段用 `bin _time span=1h` 或者 `eval _time=strftime(_time, "%H")` 截取成小时，再用 `stats count by _time` 进行统计。

> 今天……过去 7 天……

可以添加一个字段，搜索数据范围为8天前到 `now` 的区间，对数据进行分类标注便于计算统计。这样一来也可以避免用上子查询等更复杂的语句就可以实现该需求。

> ……同一个时段的平均值

在使用 `stats count by` 的时候合理选择 by 哪些字段即可。至于过去的 7 天平均值可以用 `avg()` 进行计算，不过也可以采用更为简单的分组求和后直接除以 7 即可。

## 3. 结果

```spl
index=access_log log="*request*" earliest=-8d latest=now                                  ```fiter log from 8 days ago to current```
| eval isvalidip = if(match(ip, "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"), "TRUE", "FALSE") ```only calculate validated ip address```
| where isvalidip="TRUE"
| eval hour=strftime(_time, "%H")                                                         ```converte time to hour```
| eval category=if((now() - _time) / 86400 <= 1, "today", "previous")                     ```distinguish log time period```
| stats count(eval(category="previous")) as average_request, count(eval(category="today")) as today_request by ip, hour
| eval average_request=average_request / 7                                                ```hourly average of the last 7 days```
| eval higher_today=if(today_request > average_request, "TRUE", null())
| table ip, hour, average_request, today_request, higher_today
```

可以得到类似下述格式的一个表格。之后只需要对 `higher_today` 进行只保留 `TRUE` 的过滤就可以设置相应警告了。配合一些定制化如修改阈值或者是根据数值对表格上色等食用更佳。

ip|hour|average_request|today_request|higher_today
:-----:|:-----:|:-----:|:-----:|:-----:
1.1.1.1|00|2|0| 
1.1.1.1|02|5|2| 
1.1.1.1|03|1|3|TRUE
1.1.1.1|04|3|2| 
1.1.1.2|02|6|6| 
1.1.1.3|03|5|1| 
1.1.1.3|04|2|4|TRUE
1.1.1.5|01|1|2|TRUE