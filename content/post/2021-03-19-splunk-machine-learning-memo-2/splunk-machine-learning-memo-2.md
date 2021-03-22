---
title: 为 Splunk 用户准备的数据分析实践指南阅读笔记（第三章）
date: '2021-03-19'
slug: splunk-machine-learning-memo-2
categories: [中文]
tags: [machine-learning,memo]
thumbnailImage: 'https://z3.ax1x.com/2021/03/14/6B9oHx.jpg'
thumbnailImagePosition: right
summary: '第三章《基于 Splunk / MLTK 的机器学习》的阅读笔记。主要是讲解一些常用的机器学习算法，和在 Splunk 中的一些相关 Demo。'
---

第三章《基于 Splunk / MLTK 的机器学习》的阅读笔记。主要是讲解一些常用的机器学习算法，和在 Splunk 中的一些相关 Demo。

### 3.1.1

虽然有像随机森林这种类似万金油的算法，不过一般还是根据目的使用相应的算法才是更为妥当的做法。
稍微简要的归纳汇总一下在 MLTK 中能够使用的各类算法：

---

有监督学习

回归
- 线性回归（包括多重线性回归）：销售额预测、供需预测、异常/故障检测
- Lasso回归、岭回归（在线性回归上添加L1或L2的正则化）：主要是为了提高线性回归的精度
- ElasticNet：同时具有 Lasso 回归加岭回归的优点的方法
- KernalRidge：让岭回归方法也能用在非线性数据上的方法

分类
- 逻辑回归（将线性回归的结果重新分布在 0 ～ 1 之间）：潜在客户预测（买或不买）、垃圾邮件
- 朴素贝叶斯：文本挖掘
- MLPClassifier：神经网络分类方法
- SVM

回归 / 分类
- 随机森林：万金油
- 决策树
- GradientBoosting
- SGD

时序列预测
- ARIMA：温度计、经济金融类时序列数据类预测
- StateSpaceForecast

---

无监督学习

聚类
- k-means / x-means：没有明确答案（分类标准）的数据的分类预测
- DBSCAN：异常值检测
- BIRCH
- SpectralClustering

异常检测（下列方法属于无监督？待调查）
- DensityFunction
- LocalOutlierFactor
- OneClassSVM

---

### 3.2.1 线性回归

最小二乘法：

$$y = ax+b$$

$y$：因变量，$x$：自变量，$a$：偏回归系数（对各变量的贡献度、权重）。

在 Splunk 的 MLTK 中，可以选择 `Show Case > Predict Fields > Predict Server Power Consumption` 的示例做初步认识。

### 3.2.2 Lasso 回归和岭回归

Lasso 回归：线性 + L1 正则化（可以用来特征选择，也就是降维）。
岭回归：线性 + L2 正则化（权重等比衰减，可以用来防止过拟合）。

同样可以在 MLTK 中变更 Algorithm 来体验。

### 3.2.3 逻辑回归

设 $p$ 为概率，那么 

$$odds = \frac{p}{1-p}$$

$odds$ 就是某个事件发生的概率和不发生的概率之比。

对 $odds$ 取对数再求反函数即为逻辑函数（又称标准sigmoid函数）：

$$log(\frac{p}{1-p})^{-1}={\frac {1}{1+e^{{-x}}}}$$

> 一般类型的Sigmoid函数：
> $${\frac {1}{1+e^{{-ax}}}}$$

因此逻辑回归就是：

$$\frac{1}{1+e^{-(\sum_{i=1}^n{a_ix_i}+b)}}$$

逻辑回归除了是把输出范围给定到 0 ～ 1 区间外，其他的性质和线性回归也基本相同。不过注意在使用时要对数据的线性的符合程度做一个衡量。

在 Splunk 的 MLTK 中，可以选择 `Show Case > Predict Fields > Predict Hard Drive Failure` 的示例做初步认识。

### 3.2.4 朴素贝叶斯

贝叶斯定理：事件 $A$ 发生后 事件 $B$ 发生的概率。比如有红球和白球的袋子里，在取出红球后，取出的是白球的概率。

$$P(B|A)=\frac{P(A|B) \times P(B)}{P(A)}$$

大概了解可参考知乎这篇文章：[带你理解朴素贝叶斯分类算法](https://zhuanlan.zhihu.com/p/26262151)。

优点就是算法简单、计算速度快。技术数据量大也不会造成处理时间大幅度增加。

MLTK 中可以使用**高斯（正规分布）朴素贝叶斯**和**伯努利（二项式）朴素贝叶斯**两种算法。

变量（$x$）是符合正规分布的，连续型的时候用高斯。如果是符合二项分布的时候（如变量是0、1、2等这种离散值）用伯努利。连续的时候也不是不能用伯努利，可以确定阈值进行连续转离散（分类）的操作，阈值本身就需要调参，操作起来还是比较复杂的。

在 Splunk 的 MLTK 中，可以选择 `Show Case > Predict Fields > Predict Hard Drive Failure` 的示例做测试，结果明显比逻辑回归要好。

> 书中关于为什么在这里选择使用伯努利来做演示而不是高斯的探讨这个例子也很好。其中一个原因是其中的一个离散（分组）变量的影响比其他连续的数值变量对结果的影响更大（因此适合伯努利）；另一个原因就是连续性变量除了一个外，基本不符合正规分布，因此高斯的方法不能很好的发挥实力。

### 3.2.5 随机森林

简单的说就是决策树 + 集成学习的算法。

#### （二分）决策树

确定阈值，使数据一分为二成为二组。到达成最终目的为止所凑成的一系列节点构造统合起来就是一棵决策树。

用于构造决策点的方法可以基于计算基尼系数或者熵值来判定。

由于是对每个变量进行决策点的构造，这种计算结果可以得出变量的权重，因此决策树也可以用来进行特征选择。此外，由于只要决定是如何进行二分就行了，因此不管是分类还是回归问题都可以使用。

可参考[决策树 – Decision tree](https://easyai.tech/ai-definition/decision-tree/)、[深入浅出决策树](https://zhuanlan.zhihu.com/p/59484953)加深理解。

#### 集成学习

从多个模型中得出的结果进行汇总计算，最后得出最终数值。分类问题就是少数服从多数，回归问题就可以用平均值。

Bagging：有放回抽样构建数据集，可并行处理进行独立模型构建，最终结果投票决定（简单）。
Boosting：按顺序进行模型训练进行线性组合（无法并行处理），根据错误率调整各个模型权重，最后得到最终模型。
Stacking：将通过学习得到的预测值作为新一轮的特征量积攒学习数据，然后再使用别的算法进行训练的过程。

可参考[集成学习（Ensemble Learning）](https://easyai.tech/ai-definition/ensemble-learning/)加深理解。

#### 随机森林的特点

优点：

1. 不容易过学习（过拟合）；
2. 分类、回归问题都能用，精度高的万金油；
3. 由于可以用来得到特征值的权重，因此也能用来做特征选择；
4. 能够广泛使用。

缺点是，由于要生成数量众多的弱学习期，处理时间较长。不过如果是 Bagging 的话可以考并行处理来解决这个问题。

在 Splunk 的 MLTK 中，可以选择 `Show Case > Predict Fields > Predict Categorical Filed Examples` 的示例做测试，结果显示各项指标都很好，证明随机森林的确是不错的。

### 3.2.6 ARIMA

书中关于这部分的解释说明较为笼统，一些关键词：自回归、移动平均、自相关图、偏自相关图等。推荐看[第 8 章 ARIMA 模型](https://otexts.com/fppcn/arima-cn.html)来做更好的理解。要不然只会运行个例子，但在实际中并不知道该如何去评价模型和做出模型选择。

在 Splunk 的 MLTK 中，可以选择 `Show Case > Forecast Time Series > Forecasting Examples > Forecast Exchange Rate TWI using ARIMA` 的示例做测试。

### 3.2.7 k-menas / x-means

距离：欧式、曼哈顿、切比雪夫、马哈拉诺比斯等等。

> 详解可看[OI - Wiki 距离](https://oi-wiki.org/geometry/distance/)了解更多。

k-means：需要预先设定所分成的组数。初始化重心的方法很多（假设随机），初始化后计算所有点距离重心的位置后，根据数据与各个重心的距离对每个数据进行分组，距离哪个重心近就归为哪个组。然后重新计算组内重心，循环到最后重心位置基本不变（收敛）后完成。

> 生动形象的例子：[5 分钟带你弄懂 k-means 聚类](https://blog.csdn.net/huangfei711/article/details/78480078)

x-means：k-means（k=2） + 决策树。一直增加分支到直到收敛为止，自动决定分类的组数。是否收敛则可以用 BIC（贝叶斯信息量） 来判定。关于 BIC（和AIC）可看[最优模型选择准则：AIC和BIC](https://www.biaodianfu.com/aic-bic.html#AIC)。如果树在分裂后 BIC 比分裂前还大那就可以结束了。

k-means：计算简单，处理时间短，组数可以事先定义好，其意义较容易得到解释。
x-means：可自动决定组数。

由于二者都是通过考虑距离的算法，如果数据分布是较为特殊的甜甜圈或者是新月型的话容易出现无意义的分组。或者是当存在异常值的时候容易被带歪，对噪音数据反应敏感。再者由于考虑的是距离，对于特征量是根据什么内容导致的相似也很难解释清楚。

在 Splunk 的 MLTK 中，可以选择 `Show Case > Cluster Events > Cluster Hard Drives by SMART Metrics` 的示例做测试。

### 3.2.8 DBSCAN

DBSCAN 其实和 k-means 也差不多，不过是将重心换成了密度中心来计算。重心的话基本就是适用于数据分布是圆或球型，但是对于甜甜圈或者新月状这种分布就不适合了。这个时候换成密度中心的话也就没问题了（就是 DBSCAN）。缺点就是计算开销大，处理时间要长了。

DBSCAN 和 x-means 一样不需要预先设定分类群组数，但是需要设定下面两个参数：

- EPS：从某点到自身同一个群组的探索距离。
- MinPts：判断为一个群组所需要的最少数据（点）。

更多内容可参考：[DBSCAN聚类算法——机器学习（理论+图解+python代码）](https://blog.csdn.net/huacha__/article/details/81094891)

在 Splunk 的 MLTK 中，可以选择 `Show Case > Cluster Events > Cluster Business Anomalies to Reduce Noise` 的示例做测试。

### 3.3.1 模型评价指标

利用 Splunk 的 [Macros 功能（类似自定义函数）](https://docs.splunk.com/Documentation/Splunk/8.1.2/Knowledge/Definesearchmacros)来快速计算一些常见指标：$R^2$、MAE、RMSE、混淆矩阵、Precision-Recall、Accuracy、F1、AUC等等。

内置（？）的有 `regressionstatistics`、`confusionmatrix`、`classificationstatistics`、`classificationreport`等，用 `score` 命令也可以。

```splunk
| score accuracy_score 正确列名 against 预测列名
```

$$Accuracy = \frac{TP + TN}{TP + FP + FN + TN}$$

精确率：判断为阳性中有多少是真的阳性（冤枉好人）
$$Precision = \frac{TP}{TP+FP}$$

召回率：真的阳性中判断了多少为阳性（漏了坏人）
$$Precision = \frac{TP}{TP+FN}$$

上述二者综合的$F1$指标。
$$F1 = 2 \times \frac{Precision \times Recall}{Precision + Recall}$$
