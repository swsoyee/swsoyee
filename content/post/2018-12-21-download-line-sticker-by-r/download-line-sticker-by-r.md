---
title: R + bat一键批量下载LINE贴图的方法
date: '2018-12-21'
slug: download-line-sticker-by-r
output:
  blogdown::html_page:
    toc: true
categories: [中文]
tags: [r]
thumbnailImage: https://s1.ax1x.com/2018/12/22/FyZVOO.png
thumbnailImagePosition: right
summary: '出于练习用R对于网页素材的解析，并且写一些有意思并且实用的脚本，就尝试着结合Windows下的bat可执行文件捣鼓了这么一个东西。'
---

{{< alert warning >}}
如果是在国内访问的话请自带梯子（好像LINE商店无法在国内访问）。
{{< /alert >}}

## 1. 思路

当初本来想接着 R 中的 `{shiny}` 包直接做成一个 Web Application，但由于搞不好会摊上一些麻烦，因此作罢。而用 R 语言进行下载的话，首先用户必须要安装了 R 环境才可以使用，对于初学者来说即使看着脚本代码也不知道如何使用为好。因此结合 Windows 环境，大概下述准备工作是最方便的。

1. 在电脑里安装R环境；
2. 配置Rscript到环境变量上；
3. 用一个bat脚本解决双击直接下载问题。

至于使用方法的话：

1. 在名为 `sticker_id.txt` 的文件里复制粘贴上想要的贴图的ID；
2. 把 `sticker_id.txt` 、 `download.bat` 、 `sticker_download.R` 三个文件放在同一个文件夹下；
3. 双击 `download.bat` 即可下载贴图。

## 2. 环境配置

### 2.1 安装R语言环境

非常简单，直接到R的官网网站 https://www.r-project.org/ ，然后根据 **Getting Started** 中的说明完成配置即可。

### 2.2 修改环境变量

在 Windows 的 CMD 下可以运行 Rscript 程序直接运行自己编写的R脚本，如果是安装的时候没有改变安装路径的话一般在 `C:\Program Files\R\R-3.5.1\bin` 的下面。如果不设置环境变量的话，就需要写一长串路径指定到 `Rscript.exe` 的位置十分不便。

Windows10 的话可以通过到 **控制面板\所有控制面板项\系统页面** 中，然后点击左侧的 **高级系统设置** 弹出系统属性面板，然后点击 **高级** 标签后点击最下方的 **环境变量** 即可弹出环境变量面板。

接下来在下方的 系统变量 区域中找到名为Path的变量后点击编辑，在弹出的 **编辑环境变量** 的面板中点击 **新建** ，并且输入自己电脑中的R所安装的位置下的 `bin` 路径后点击 **确定** 即可（例如 `C:\Program Files\R\R-3.5.1\bin`）

完成上述步骤后基本就已经完成要做的准备工作了。

## 3. 准备代码

接下来分别往 `sticker_download.R` 中写入关键下载代码，然后往 `download.bat` 中写入脚本运行代码即可（现在想想，直接写 `bat` 脚本下载不就完了嘛搞这么多幺儿子干嘛😂~~不过我不会写bat~~）。

### 3.1 贴图下载R部分

由于使用到了 `{stringr}` 包，因此如果没有安装过的话下述代码会自动下载安装。将下面的代码保存到 `sticker_download.R` 里即可。

{{< alert info >}}
如果对于 R 不熟悉的用户的话可以直接复制下述代码到 txt 文档中然后修改后缀名为 `R` 即可。
{{< /alert >}}

```r
#### sticker_download.R ####

# Install and load package
if( !is.element("stringr", .packages(all.available = TRUE)) ) {
    install.packages("stringr")
}
library(stringr)

# Read ID and convert it to URL from txt file.
sticker_id <- readLines("sticker_id.txt", encoding = "UTF-8")
sticker_url <- paste0("https://store.line.me/stickershop/product/", sticker_id, "/ja")

for (x in 1:length(sticker_url)) {
  # Change the sticker url
  url <- sticker_url[x]
  # Fetch webpage source code
  page <- readLines(url, encoding = "UTF-8")
  
  # Extract sticker url
  prefix <-
    "https://stickershop.line-scdn.net/stickershop/v1/sticker/"
  suffix <- "/ANDROID/sticker.png"
  sticker <-
    str_extract_all(
      string = page,
      pattern = paste0(prefix, "\\d+", suffix),
      simplify = TRUE
    )
  sticker <- c(sticker[sticker[, 1] != "",])
  
  # Create directory
  dirName <- paste0("line_sticker_", sticker_id[x])
  dir.create(dirName)
  # Download all sticker into directory
  num <- 1
  for (i in sticker) {
    download.file(
      url = i,
      destfile = paste0(dirName, "//", num, ".gif"),
      mode = 'wb'
    )
    num <- num + 1
  }
}
```

### 3.2 可执行文件bat部分

新建一个 `txt` 文本文件然后写入下面一行代码，保存后修改文件名为 `download.bat` 即可。

```bash
Rscript sticker_download.R
```

### 3.3 下载贴图ID列表txt部分

{{< alert warning >}}
如果是在国内访问的话请自带梯子（好像LINE商店无法在国内访问）。
{{< /alert >}}

新建一个名为 `sticker_id.txt` 的文本文档，填入贴图的 ID 即可，每一行一个 ID 然后保存。 例如，要下载 `JOJO` 的贴图，我们可以在商店中找到下面3个贴图包。

**名称**|**地址**|**ID**
:-----:|:-----:|:-----:
ジョジョ 第3部 承太郎チーム|https://store.line.me/stickershop/product/3065/ja|3065
ジョジョ 第3部 Vol.2 バトル編|https://store.line.me/stickershop/product/4506/ja|4506
ジョジョ 第4部 杜王町へようこそ|https://store.line.me/stickershop/product/6784/ja|6784

然后把 ID 这一列保存到 `sticker_id.txt` 即可。

```
3065
4506
6784
```

{{< alert danger >}}
请不要一次性进行大量下载，需要多少写多少即可。
{{< /alert >}}

## 4. 运行

把 `sticker_id.txt` 、 `download.bat` 、`sticker_download.R` 三个文件放在同一个文件夹下，双击 `download.bat` 即可下载贴图。
