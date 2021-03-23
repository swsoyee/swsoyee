---
title: 命令行批量修复所有文件中的坏链接
date: '2021-03-23'
slug: fix-url-in-all-files-by-cmd
categories: [中文]
tags: [linux]
summary: '昨晚临睡时打开博客瞅了一眼，结果发现所有图片的加载不出来了。怀疑是不是所有图片都被图床给删了，赶紧去看了一眼，发现只是所有图片的地址都被从 `https://s3` 迁移到了 `https://z3` 而已。还好只是虚惊一场，不过因此博客也不能不修复所有的图片链接了。'
---

昨晚临睡时打开博客瞅了一眼，结果发现所有图片的加载不出来了。怀疑是不是所有图片都被图床给删了，赶紧去看了一眼，发现只是所有图片的地址都被从 `https://s3` 迁移到了 `https://z3` 而已。还好只是虚惊一场，不过因此博客也不能不修复所有的图片链接了。

虽然现在所有文章的图片也不算多，就算手动修复也完全搞得过来。不过这也太不 Geek 了，而且万一以后还有别的变更不是还得重复手动修复工作？那还不如直接命令号来修复更具有可拓展性，也能以不变应万变。

最后得出的命令虽然很简单，但还是在调研试错上花了半个小时以上：

```bash
find -E . -iregex '.*\.(md|Rmd|yaml|html)' | xargs sed -i '' 's#https://s3#https://z3#g'
```

看了一下最终试错得出的历史：

```bash
# 列出该文件下的所有文件
find $PWD | xargs ls -ld

# 只显示文件路径，精简显示
find $PWD | xargs ls -d

# 尝试直接用 sed 替换所有路径（失败：sed 的正则表达式错误，无法识别）
find $PWD | xargs ls -d | xargs sed -i 's/https:\/\/s3/https:\/\/z3/g'

# 其实 sed 的分隔符并不一定是要用 / 的，路径这种随便换别的符号就好，如 #（失败）
find $PWD | xargs ls -d | xargs sed -i 's#https://s3#https://z3#g'

# 先用一个单文件看看 sed 的命令到底对不对
#（失败：Mac 的 sed 命令问题参考 https://blog.csdn.net/fdipzone/article/details/51253955）
sed -i 's#https://s3#https://z3#g' config.yaml

# 根据搜到的答案，加入空白符作为备份后成功
sed -i '' 's#https://s3#https://z3#g' config.yaml

# 再次尝试（失败：列文件名的时候有文件夹名）
find $PWD | xargs ls -d | xargs sed -i '' 's#https://s3#https://z3#g'

# 只列文件，不包括文件夹名
find $PWD -type f

# 再次尝试（失败：似乎是因为系统字符的问题）
# https://stackoverflow.com/questions/19242275/re-error-illegal-byte-sequence-on-mac-os-x
find $PWD -type f | xargs ls -d | xargs sed -i '' 's#https://s3#https://z3#g'

# 因为含有网址的只会是文章和设定类的文件，那就先做一轮筛选
find -E . -iregex '.*\.(md|Rmd|yaml|html)'

# OK，搞定！
find -E . -iregex '.*\.(md|Rmd|yaml|html)' | xargs sed -i '' 's#https://s3#https://z3#g'
```

嗯，算是一次不错的复习 `find`、`xargs`、`sed` 命令的经历吧，毕竟有 6 年没正经用命令来做这种操作了。
