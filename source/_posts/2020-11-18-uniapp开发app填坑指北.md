---
title: uniapp开发app填坑指北
comments: true
date: 2020-11-18 15:37:26
tags:
    - uniapp
categories:
    - 跨端编程
---

机缘巧合，曾经不看好uniapp开发的我，终于在前两个月使用uniapp重构我们的一款产品。期间踩了无数坑，甚至涉及到原生开发的一些问题，有卡了很久才解决的，也有到目前为止还未找到办法解决的。我们原本的产品采用hybrid开发，壳子非常轻量，几乎所有逻辑都由webview来展示，根据我自己实际体验感受来看，uniapp开发的app成品，在ios上不如我们之前的hybridapp，但是在安卓机器上速度提升比较明显。
> 为了下次开发uniapp给自己长点记性，专门写下一些在uniapp社区没有搜到的问题。

## 关于vue组件
uni对vue组件默认采用webview渲染，所以能够放心的移植原有的web端代码，我们原项目采用ts加vue-class-component开发，也是可以兼容的。
但是遇到一些特殊组件，譬如：video、audio等，uni会使用weex的原生video或audio来渲染。这个时候涉及到ui层级问题，此问题也很好解决，建议直接使用`cover-image`和`cover-view`。我们产品里有一个需要实现带弧形底边框的video，并且左上角带close的icon即是使用`cover-image`。
很多移动端视频播放为了考虑用户体验，均是`inline-play`模式，这个在web端会存在兼容问题，但uni可以很好的展示。但是在处理视频封面的问题时踩了第一个坑。

### video组件的poster属性只有nvue模式生效
因为最开始视频使用的远程服务器地址，poster封面展示不出来，会一直显示黑屏loading状态，最终通过`cover-image`覆盖一张图片在video上面解决。为了让poster体验更好，需要在video加载完视频资源时，立即隐藏poster，这里我们监听video的`timeupdate`事件，这里遇到了第二坑

### video组件的timeupdate事件在ios和android处理不一致
ios会在视频资源处理完成时立即触发timeupdate，然后封面消失的那一刻，视频自动播放，体验完美。然而，安卓的timeupdate触发后，视频居然还是loading状态的黑屏...
这个时候已经很无语了，关键还不知道安卓什么时候能完全加载好视频，为了体验着想，我在一启动app就预先下载好所有的video视频，然后写入存储中。这里使用的uni的两个api（`uni.downloadFile`和`uni.saveFile`）。为了避免每次都下载写入，做了一个优化处理，仅当线上服务器配置里的video地址和本地存储里的地址发生改变才触发。

### video播放在不同平台来回切前后台表现不一致
iOS平台，来回切前后台，video不会暂停，但是在安卓上，切回前台，会自动暂停，这个适合必须监听切回前台事件，重新拿到video的实例，手动调用`play()`。

## 关于nvue组件
nvue使用的是weex渲染，所以在性能上会有很大提升，尤其是长列表。nvue虽然也可以使用vue的语法，但不支持ts解析，其实是不支持ts的type语法。直接引入ts后缀文件，去除type的也是可以运行。nvue的样式只能使用css，建议直接去看weex的文档。这里有几个需要注意的点

### 安卓平台使用定位时，会出现裁剪，iOS不会
这个问题在weex的文档里有被提到过，目前无解，只能扩大你的父容器，因为安卓平台渲染时overflow永远是hidden。

### 动态改变css时，必须保证前后变化的css选择器属性一致
这个bug属实奇葩，我定位了至少一个小时，有一个组件view，正常情况的样式如下：
``` css
.follow {
    background-image: linear-gradient(to right, rgb(53, 164, 255), rgb(79, 121, 255));
}
```
另一个情况的样式如下：
``` css
.claimed {
    background-color: rgb(224, 224, 224);
}
```
按理说，`background-color`会覆盖`background-image`。奇葩的现象就是，claimed的样式会时不时失效，不是百分百。当把claimed样式写成这样就解决了：
``` css
.claimed {
    /* 必须要写成渐变色，不然在动态切换css class时候会出现bug，背景纯色不会生效！！ */
    background-image: linear-gradient(to right, rgb(224, 224, 224), rgb(225, 225, 225));
}
```

### nvue和vue使用的不是同一块内存空间
为什么这么说呢？项目中我实测，在`App.vue`里导入一个ts模块，然后改变其中变量，在一个nvue组件里同样导入该模块，发现变量并未发生改变！！
所以也能理解，为什么uni官方在文档里写到，nvue如果想和vue共享数据（其实是共享内存），必须使用`globalData`或者`vuex`。这里建议全程在nvue里使用vuex的`mapGetters`,`mapActions`等，因为在store里可以解析ts，并且操作的是同一块内存空间。

### nvue对vue语法支持有限
不能使用v-show，使用v-if，钩子函数不能看uni的生命周期，而是要去看weex的生命周期，不能拿到Vue.prototype上挂载的方法，老老实实用store吧。
遇到一个很奇怪的bug，web端，当在v-for时某个组件被多次使用，vue会复用这个组件实例，也就是说，虽然ui显示了两个，但是组件实例的逻辑都是复用的一个，然而在nvue里，不会复用，你for多少个，就是多少个vue实例。。。

## 关于uni的plus接口
目前遇到的不兼容问题比较少，有一个bug印象深刻。`plus.events`可以用来监听app的各种事件，我们需要频繁用到监听切入前后台事件。在ios平台上，直接使用`plus.globalEvent.addEventListener("resume", () => {});`没有任何问题，哪怕多次使用，增加多个事件监听器也不会出现问题。在安卓平台，同样的代码却只能给`resume`绑定一个监听器，属实奇葩。这里我只好自己写一个监听器队列拿来维护，而只在`App.vue`里使用一次`plus.globalEvent.addEventListener("resume", () => {});`，当触发了`resume`事件后，队列里的回调函数会依次触发，同时也可以手动解绑监听器。
另外，不同定制ui的安卓真的是极难兼容，`setInterval`在很多国产ui系统处理下，当切入后台30s左右就会停止。更无语的是`plus.globalEvent.addEventListener`在华为的emui下切入后台一段时间也会失效。。。目前没找到合适的解决方法，猜测定制ui对app后台处理实在太严格了。

# 总结
uniapp如果拿来开发跨端小程序，我觉得还是十分ok的。如果拿来开发app，建议只选择两种模式，一是纯vue组件，也就是纯webview渲染，二是纯nvue组件，纯weex渲染。因为vue混搭nvue会有很多不好解决的问题。同时uniapp开发的app在性能上其实也不太好，适合小型项目，我们项目里因为存在过多的活动组件，导致资源占用会比较多。由于我们的产品需要用到很多第三方功能，导致我们也不能脱离原生独立开发，这里发现uni也还是一个hybrid模式，只不过前端可以选择用什么来渲染ui罢了。