---
title: DOM里的attribute和property
date: 2017-12-06 13:53:53
tags:
    - javascript
    - HTML
    - vue
categories:
    - 前端编程
---

在偶然间使用vue里的v-bind指令，发现v-bind竟然还有一个prop的修饰符。喵喵喵？:sunglasses:一下子我的好奇心就来，vue的中文文档翻译为**被用于绑定 DOM 属性 (property)**。什么叫做DOM属性？然后这篇文章就来了...

还是先讲讲使用这个修饰符我遇到的坑吧，首先，我试了试在v-bind上绑定`visibility`特性(**<span style='color:blue'>请注意我目前的措辞</span>**),大概代码如下：
```html
    <div :visibility.prop="false">看的到我嘛？</div>
```
但是结果并不是div标签被隐藏掉，而是什么事情都不发生。What's the fuck?:flushed:不死心的我又尝试去掉了prop修饰符，结果虽然有了效果，但是也不是div被隐藏，而是div标签上多了一个自定义属性，在浏览器里像这样：
```html
    <div visibility="false">看的到我嘛？</div>
```
坑爹啊...vue api文档里不是说可以改变DOM自带的属性嘛？其实vue里v-bind有点坑，但是之所以不生效，是因为我之前没有理解DOM里attribute和property的问题。:sob:

<span style='color:red'>ok，现在进入show time时间>>>>>>>>>>>>>>>>>>>>>>>>>>>>>></span>

# 什么叫做DOM的属性
`属性`这个名称其实是对英文翻译的误解，因为在DOM里是有两个单词来解释的，一个是`attribute`,一个是`property`，这两个单词其实都有属性的意思，但是又各有不同。所以在我查了很多博客和segmentfault社区之后发现，目前最好的翻译应该是`attribute`--->**特性**，`property`--->**属性**。
那*attribute*和*property*到底又分别是代表什么呢？

## 1. attribute是开发者自行添加的特性，property是标签自带的属性
什么意思呢？也就是说，attribute是开发者自行在html标签里添加的，不是DOM节点自带的，而property是只要你创建了这个html标签，就存在，举个例子：
```html
    <div id="box" value="2333" data-sex="male">我是一个div</div>
```
我们通过javascript获取DOM的方式获取DOM节点(有NodeList和HTMLCollection两种)，最好通过`document.getElementsByTagName`或`document.getElementsByClassName`来获取，因为打印的是一个集合，否则用其余方法获取的打印出来是一个标签节点
![](/print1.png)

`id`和`data-sex`都是div这个节点自带的，我们可以在这个节点对象属性里看到，这些就叫做这个节点对象的`property`。而value是我们自行添加，并不是标签原本就有，属于自定义特性，我们可以在这个节点对象的`attributes`属性里看到。
但是有一个很有意思的地方，就是虽然`id`和`data-sex`是节点对象的`property`，然而我们依然可以在`attributes`找到，说明`attributes`里存放的是我们在html标签写的所有(包括自带和自定义)。

## 2. attribute和property其实定义没有明确的界限
vue里关于v-bind绑定DOM属性解释的链接是[stackoverflow上的答案](https://stackoverflow.com/questions/6003819/what-is-the-difference-between-properties-and-attributes-in-html#)，这也是我查到的最全面也是最正确的解释。

`property`是每个html被创建时就存在的属性，就算我们不在标签里写上id，DOM节点对象里也存在id属性，而且`property`对于不同的html标签所对应的属性也不相同。比如：input有value和type属性，div就没有。a有href属性，div就没有。img有src属性(<span style="color:blue">这里有v-bind设计的坑</span>)，div就没有，button有disabled，别的就没有。但是都会有共有的一些属性，比如：accessKey，textContent，title,hidden...

`attribute`是开发者自行添加在html标签上的，可以是节点对象原本就有的，也可以是自定义的特性。只要在html标签上写了，我们就可以在节点对象的`attributes`属性里找到。

## 3. attribute和property读写存在区别
对于`property`，我们可以直接通过对象的属性这种方式来读写，比如：
```javascript
    const box = document.querySelector('#box')
    console.log(box.id) // 打印出出 box
    console.log(box.dataset.sex) // 打印出 male
    box.id = 'alan'
    console.log(box.id) // 打印出出 alan
```
对于`attribute`，我们只能通过DOM给定的方法`getAttribute()`和`setAttribute()`来读写，当然，也可以通过DOM节点对象的`attributes`属性获取，两者是等价的,获取class时，DOM节点的className和通过`getAttribute('class')`也是等价的。请注意：这两种方法也适用于读写`property`，但是它们存在细微的差别。
`getAttribute()`获取到的值永远是`string`类型，我们可以试一下：
```javascript
    consloe.log(typeof box.getAttribute('draggable')) // 打印出string，但是我们从上图可以看出'draggable'明明是boolean类型
```
`setAttribute()`在设置`attribute`特性时，**参数必须是字符串**，但是在设置`property`时可以是任何类型，这里发现了一个有趣的现象，当我在设置**draggable**时，除了false(Boolean)和'false'(String)可以让**draggable**为false外，其余设置的值都为true。所以我大胆猜测，DOM节点对于`property`有着严格的限制，对值的类型应该做了转换。

## 4. attribute和property写入有时同步，有时不同步
回到上面改变**id**的例子上，我们通过写入`property`改变了id属性，发现，页面里的html也发生了的变化，并且在此之后获取的`attribute`也同步发生了改变
```html
    <div id="alan" value="2333" data-sex="male"></div>
```
```javascript
    const box = document.querySelector('#box')
    box.id = 'alan'
    console.log(box.id) // 打印出出 alan
    console.log(box.getAttribute('id')) // 打印出出 alan
```
我在stackoverflow上发现，除了input里的value属性不会导致属性和特性同步外，其余的都会同步。当然大家最好还是自己测一测:wink:
> 在使用javascript的过程中，强烈建议大家通过setAttribute()来设置属性和特性，但是对于读取，还是得分开获取，因为getAttribute()只会获取到string，或者说，会强制把值改为string

# vue的v-bind里对DOM的属性和特性有什么区别
现在回到文章开头的那个问题，prop这个修饰符意义到底在哪里。结合前面讲的所有知识，大概就能知道prop只适用于改变`property`。因为在vue的v-bind指令里，默认是给组件或者html标签添加`attribute`。很明显visibility不是`property`，而是`attribute`，如果想要使用prop来让标签隐藏，我们可以改为
```html
    <div :hidden.prop="false">看的到我嘛？</div>
```
这样div就会被隐藏了，因为hidden是DOM节点对象的**属性**

 > <span style="color:red">不得不讲的v-bind的api设计坑的地方:</span>

v-bind在英文文档里明明写着是**绑定一个DOM特性或者组件的props**，但是我在使用的时候，发现img标签可以直接`:src`，What's the fuck?:flushed:，你特喵的不是专门出了个prop修饰符来专门绑定DOM property嘛，那为什么src就直接绑定了，还有title，id等等都可以在不使用prop修饰符的情况下直接绑定成功...这就为难我胖虎了:roll_eyes: 我只好理解为：**vue允许v-bind可以直接绑定常用的DOM property，对于不常用的，或者说一般不会写在html的property只能用prop修饰符来搞定了...23333神坑**

> 写在最后，我用textContent属性直接就实现了v-text的功能，innerHTML直接就实现了v-html的功能:stuck_out_tongue_closed_eyes:。最后的最后，我好像发现了vue通过props让父组件传值给子组件的原理。`害怕.jpg`:grin:,至于思路，我就不讲啦，哈哈哈，其实就是这篇文章里讲到的。