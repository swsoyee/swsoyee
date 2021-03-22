---
title: 为 Splunk 用户准备的数据分析实践指南阅读笔记（第四章）
date: '2021-03-20'
slug: splunk-machine-learning-memo-3
categories: [中文]
tags: [machine-learning,memo]
thumbnailImage: 'https://z3.ax1x.com/2021/03/14/6B9oHx.jpg'
thumbnailImagePosition: right
summary: '第四章《往 Splunk 导入数据的基本操作》的阅读笔记。主要是讲解如何往 Splunk 中导入数据和设置 SPL 使用环境的工作流程。'
---

第四章《往 Splunk 导入数据的基本操作》的阅读笔记。主要是讲解如何往 Splunk 中导入数据和设置 SPL 使用环境的工作流程。

### 4.1.1

准备工作大概有以下几个流程：

1. 创建 Index 和设置数据导入
2. 提取字段
3. 制作 master 信息的 Lookup
4. 搜索和数据加工
5. 数据评价和数据分析
6. 建模

第四章主要是利用测试数据来介绍前三步骤。测试数据可以从 Splunk 官网下载：[Download the tutorial data files](https://docs.splunk.com/Documentation/Splunk/8.0.4/SearchTutorial/Systemrequirements#Download_the_tutorial_data_files)。

首先看看 `tutorialdata.zip` 里的数据：

```bash
➜  tutorialdata du -a          
2096    ./www2/secure.log
7896    ./www2/access.log
9992    ./www2
2160    ./www3/secure.log
7904    ./www3/access.log
10064   ./www3
4024    ./vendor_sales/vendor_sales.log
4024    ./vendor_sales
2288    ./www1/secure.log
8328    ./www1/access.log
10616   ./www1
2184    ./mailsv/secure.log
2184    ./mailsv
36880   .
```

在这里我们使用 `www*/access.log` 来建立 Index。`access.log` 里的数据内容一览：

```
74.125.19.106 - - [11/Mar/2021:18:27:48] "GET /product.screen?productId=FS-SG-G03&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 3770 "http://www.buttercupgames.com/category.screen?categoryId=STRATEGY" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 667
74.125.19.106 - - [11/Mar/2021:18:27:50] "POST /cart.do?action=addtocart&itemId=EST-26&productId=FS-SG-G03&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 293 "http://www.buttercupgames.com/product.screen?productId=FS-SG-G03" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 100
74.125.19.106 - - [11/Mar/2021:18:27:50] "POST /cart.do?action=purchase&itemId=EST-26&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 2051 "http://www.buttercupgames.com/cart.do?action=addtocart&itemId=EST-26&categoryId=STRATEGY&productId=FS-SG-G03" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 871
74.125.19.106 - - [11/Mar/2021:18:27:51] "POST /cart/error.do?msg=CreditDoesNotMatch&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 2934 "http://www.buttercupgames.com/cart.do?action=purchase&itemId=EST-26" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 866
74.125.19.106 - - [11/Mar/2021:18:27:48] "GET /product.screen?productId=WC-SH-G04&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 1705 "http://www.buttercupgames.com/category.screen?categoryId=SHOOTER" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 160
74.125.19.106 - - [11/Mar/2021:18:27:50] "POST /cart.do?action=addtocart&itemId=EST-18&productId=WC-SH-G04&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 2537 "http://www.buttercupgames.com/product.screen?productId=WC-SH-G04" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 434
74.125.19.106 - - [11/Mar/2021:18:27:51] "POST /cart.do?action=purchase&itemId=EST-18&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 1152 "http://www.buttercupgames.com/cart.do?action=addtocart&itemId=EST-18&categoryId=SHOOTER&productId=WC-SH-G04" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 563
74.125.19.106 - - [11/Mar/2021:18:27:51] "POST /cart/success.do?JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 2071 "http://www.buttercupgames.com/cart.do?action=purchase&itemId=EST-18" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 144
74.125.19.106 - - [11/Mar/2021:18:27:50] "POST /oldlink?itemId=EST-12&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 200 2818 "http://www.buttercupgames.com/cart.do?action=addtocart&itemId=EST-12&productId=SC-MG-G10" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 504
74.125.19.106 - - [11/Mar/2021:18:27:50] "GET /oldlink?itemId=EST-12&JSESSIONID=SD10SL4FF4ADFF4976 HTTP 1.1" 400 1224 "http://www.buttercupgames.com/cart.do?action=view&itemId=EST-12" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5" 774
```

再来看看 `Prices.csv.zip` 里的数据（为了好看点，把 CSV 变成了表格形式）。用这个产品信息列表作为 master。

|productId |product_name                     |price|sale_price|Code|
|----------|---------------------------------|-----|----------|----|
|DB-SG-G01 |Mediocre Kingdoms                |24.99|19.99     |A   |
|DC-SG-G02 |Dream Crusher                    |39.99|24.99     |B   |
|FS-SG-G03 |Final Sequel                     |24.99|16.99     |C   |
|WC-SH-G04 |World of Cheese                  |24.99|19.99     |D   |
|WC-SH-T02 |World of Cheese Tee              |9.99 |6.99      |E   |
|PZ-SG-G05 |Puppies vs. Zombies              |4.99 |1.99      |F   |
|CU-PG-G06 |Curling 2014                     |19.99|16.99     |G   |
|MB-AG-G07 |Manganiello Bros.                |39.99|24.99     |H   |
|MB-AG-T01 |Manganiello Bros. Tee            |9.99 |6.99      |I   |
|FI-AG-G08 |Orvil the Wolverine              |39.99|24.99     |J   |
|BS-AG-G09 |Benign Space Debris              |24.99|19.99     |K   |
|SC-MG-G10 |SIM Cubicle                      |19.99|16.99     |L   |
|WC-SH-A01 |Holy Blade of Gouda              |5.99 |2.99      |M   |
|WC-SH-A02 |Fire Resistance Suit of Provolone|3.99 |1.99      |N   |
|SF-BVS-G01|Grand Theft Scooter              |26.99|21.99     |O   |
|SF-BVS-01 |Pony Run                         |49.99|41.99     |P   |

### 4.2.1 Source Type 和 Bucket

Source Type：数据类型种类，比如说所提供的示例数据就是 Apache HTTP Server 的 combined 形式的log，那么就可以选择内置的 `sourcetype=access_combined_wcookie` 这个类型进行导入。

Bucket：储存 Index 数据实体的文件。举例子就是一个 U 盘了。根据数据的新鲜程度可分为 Hot、Warm、Cold 和 Frozen 四种状态。Hot 可读可写，Warm 和 Cold 只可读，Frozen 就只是归档的数据了（可只保留原始 raw 数据，需要的时候再重新构建）。如果到达 Bucket 设定的文件大小或者时间间隔后，状态会自动迁移（Hot -> Warm -> Cold -> Frozen）。

数据的导入部分基本没什么特别要记录的要点，实际需要的时候再根据画面导航来导入就行。

### 4.3.1 列提取

列提取（Field Extraction）分两种，一种是在构建 Index 的时候提取，另一种是搜索时提取。Splunk 可以自动对记录中的一些类似 `action=addtocart` 等键值对进行自动提取，其他的类型就需要手动进行提取（其本质可看作写正则表达式对数据进行提取）。具体可以实操熟悉。

### 4.4.1 Lookup

Lookup 是 Splunk 内可以储存 CSV 等文件的一个简易数据库。可以和 Index 一样使用 SPL 进行搜索和更新，但是不能同 Index 一样适合储存大容量的数据，也没有自动删除等生存周期，因此一般储存一些固定的、不怎么需要更新的小容量 Master 信息。

文件的导入同样根据导航一步一步来就行了。最后可以用下列命令来测试 `file.csv` 这个 Master 文件的导入成功与否：

```spl
| inputlookup file.csv
```

### 4.5.1 常用命令

`where`、`eval`、`stats`。

关于 `where` 的一些小注意事项：
用法和 SQL 差不多，可以用函数（如 `| where method == "GET" AND isnotnull(action)` ），结果区别大小写，但是和 `search` 不一样的是不能在命令的最开头就使用。

`eval` 其实就是 assignment。可当成 JavaScript 的 `let`。

`makeresults`：表示搜索命令执行的时间，只是为了用来临时创建一些测试数据时候使用（不对 Index 中的内容进行搜索）。

```spl
| makeresults
| eval A = 15, B = 15
| append [| makeresults | eval A = 25, B = 15]
| eval C = if(A == 15 AND B == 15, "O", "X")
| table A B C
```

结果：

A   | B   | C
--- | --- | ---
15  | 15  | O
25  | 15  | X

除 `stats` 外，还有 `eventstats`、`steamstats` 等扩展命令。下面这个示例是每个 JSESSIONID 的购买事件数的命令：

```spl
index = "tutorialdata_access"
| stats count(eval(action == "purchase")) as count_purchase by JSESSIONID
```

### 4.5.5 子搜索

先来个例子，计算访问数最多3个的IP的购入物品数：

```spl
index="tutorialdata_access" action=purchase
[ search index=tutorialdata_access
  | top clientip limit=3
  | return 3 clientip
]
| stats count by productId
```

一些要点：在子搜索中的 `search` 不能省略。

```spl
| makeresults
| eval A = 1 + [ | makeresults | eval B = 1 | return $B]
| table A
```

输出结果：

|A  |
|---|
|2  |

在这里，如果子搜索前不加 `$` 的话，返回的就是 `B = 1` 这种键值对形式，而不是单纯返回 `B` 这个变量，因此会报错。

更多例子可参看官方文档[Use a subsearch](https://docs.splunk.com/Documentation/Splunk/8.1.2/SearchTutorial/Useasubsearch)。

### 4.6.1 数据模型高速化

在 Splunk 中有 data model 这个东西，其本质就和 SQL 中的临时表或者 View 感觉类似，通过对原始数据进行一些预处理变换，储存更便于使用能够高速搜索的表格。对于数据模型进行计算的命令一般是用 `tstats`（普通的是 `stats`） 。 

数据模型的生成根据导航来就行，下面是一个基于数据模型的统计命令例子：

```spl
| tstats count as count_purchase
          from datamodel="tutorialdata_dm"
         where ds.action="purchase"
            by ds.JSSESIONID
```

注意 `tstats` 前的 `｜` 不能省略。对于列名的指定时，需要采用 `操作对象的数据集名.列名` 的形式（有点像 SQL 的表的别名的用法）。

虽然数据模型能提高搜索或者汇总时候的速度，但同时会占用硬盘空间。这就是一个时间和空间的取舍问题了。