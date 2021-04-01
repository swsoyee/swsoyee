---
title: 更换并统一 blogdown 中的代码块主题
date: '2021-04-01'
slug: chang-highligh-theme-in-blogdown
categories: [中文]
tags: [blogdown,highlight]
summary: '偶然发现现在博客用的主题对原始文件是 Rmd 的文章和 md 中的文章代码块默认渲染出来的结果居然是不一样的，就稍微深入调查了一下原因。最终通过关闭 hugo 主题的 hightlight 高亮和设定 `{blogdown}` 全局设定（不完美）解决了问题。'
---

太长不看系列总结：

1. 在博客根目录下建立全局设定文件 `_output.yml` 并设定主题。
    ```yaml
    blogdown::html_page:
      toc: true
      highlight: "tango"
    ```
2. 博客包含代码的文章仅使用 Rmd 格式，并且关闭 hugo 主题中的 highlight 相关设定。
3. 重新渲染所有文章（为了使用新设定）。
    ```r
    blogdown::build_site(build_rmd = TRUE)
    ```
---

偶然发现现在博客用的主题对原始文件是 Rmd 的文章和 md 中的文章代码块默认渲染出来的结果居然是不一样的，就稍微深入调查了一下原因。

- 如果是 Rmd 的文章，那么首先会 knit 渲染 html 文件，然后再通过 hugo 对所生成的 html 文件进行打包成最后结果（参考：[在R中对分子结构进行3D可视化](https://swsoyee.vercel.app/2021/02/visualize-3d-molecular-structure-in-r/)）。
- 如果是 md 的文章，那么会通过 hugo 直接进行打包成最后结果（参考：[R + bat一键批量下载LINE贴图的方法](https://swsoyee.vercel.app/2018/12/download-line-sticker-by-r/)）。

由于 Rmd 中间加了一层又 knit 渲染了一次，因此如果这两者的 `highlight.js` 的设定不一样，就会导致即使是同一个博客，同样的 R 代码高亮，其结果也会不同。

如果不在 Rmd 文章的头部 yml 设定中明确指定使用的代码高亮主题的话，Rmd 转 html 渲染出来的代码块将会不包含一些高亮的标签，进而所使用的 hugo 主题也不能正确识别代码高亮，R 代码将会非常难看。

因此可以通过指定 Rmd 文章渲染时候所使用的代码块主题，在 Rmd 渲染 html 的时候插入自定义的高亮 CSS 模块，并且能够正确的对代码块插入高亮的标签。只要在每篇 Rmd 文章的头部设定插入下面代码即可。

```yaml
blogdown::html_page:
  toc: true
  highlight: "tango"
```

不过如果是 **每篇** 文章都这么做的话，一来非常繁琐，二来如果是哪天突然看腻了想更换主题的时候，更换起来就又非常麻烦了。对于这种问题，可以在 `{blogdown}` 项目的根目录下创建一个 `_output.yml` 的文件，里面同样插入上述代码，既可以完成 `{blogdown}` 的全局设定。

但设定只是设定而已， hugo 并不会识别 Rmd 的文章，而是在打包的时候识别 html 文章。因此还需要做的一步是在更换后，对所有 Rmd（或者根据自己需要）重新渲染成 html。

```r
blogdown::build_site(build_rmd = TRUE)
```

这个时候你就能获得已经被正确标记代码块高亮并且自带高亮主题的 html 文章了。  

不过其实这里还是存在一些问题的。  
如果 hugo 主题也支持 `highlight.js`，并且该主题设定的高亮主题和 `{blogdown}` 中的不一致，将会出现 2 次的代码块高亮渲染的现象发生。

一次为 hugo 主题的高亮，另一次为 html 文章中插入的样式高亮，后者会覆盖前者，在时间差的作用下会呈现高亮样式的跳动，用户体验不算好。可能的解决办法有关闭 hugo 主题的高亮，或者是二者使用同一个代码块高亮主题（但没有真正解决重复渲染的问题）。

也正因为二者主题的不一致，导致现在博客内的 md 文章 和 Rmd 文章的代码高亮不统一。然后继续调查了一下现在用的 [`hugo-tranquilpeak-theme`](https://github.com/kakawait/hugo-tranquilpeak-theme) 这个主题关于 `highligh.js` 的部分，发现作者把网站的样式（包括代码高亮）都打包在了同一个文件里（`hugo-tranquilpeak-theme/static/css/XX.min.css`）因此无论怎么引入 `highligh` 的外部文件，都会被默认的高亮样式给覆盖掉。  

- [yaml syntax highlighting problems when using code fences #186](https://github.com/kakawait/hugo-tranquilpeak-theme/issues/186)
- [Highlight.js improvements #320](https://github.com/kakawait/hugo-tranquilpeak-theme/issues/320)
- [Highlight style not taking effect #452](https://github.com/kakawait/hugo-tranquilpeak-theme/issues/452)

主题仓库里也有不少人反映了这个问题，不过看主题作者近几年的活动记录，似乎是没打算来解决这个问题了。

所以对于 md 文章的主题高亮问题只有下面这几种解决办法：

1. 更换主题（~~好累~~）；
2. 自己动手改掉被默认主题覆盖掉自定义主题的问题（花了一两个小时尝试过失败了，要修复的话可能比较花时间，而且感觉收益不是特别大）；
3. 不使用 md 格式的文章，包含代码的文章全部改成 Rmd 格式，并且关闭 hugo 主题的 `highlight.js` 功能（主题得到了统一，并且同时解决了重复渲染的问题）。

经过一番折腾最后还算得到了个比较好的解决办法了吧。对 hugo 主题的设定编写也有了个更深入的理解，以后自己在定制化或者编写新功能的时候也算是知道该如何下手了。

最后还差一步就是暂时还不知道 R markdown 中内置了多少高亮到底有多少主题，和如何使用自定义主题了。这个就下次再调查吧。
