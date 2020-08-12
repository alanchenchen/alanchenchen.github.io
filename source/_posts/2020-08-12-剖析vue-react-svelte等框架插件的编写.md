---
title: 剖析vue/react/svelte等框架插件的编写
date: 2020-08-12 15:59:04
tags:
    - vue
    - react
categories:
    - 前端编程 
---
每一个web框架都支持组件，只有在vue框架中存在plugin这一说法。其实在react和svelte中也可以手动实现插件，我们接下来所说的插件主要是指<span style="color: blue">动态改变ui的插件</span>，类似于开源ui库中的dialog、modal、toast等。主要分析vue插件，react和svelte插件实现起来思路类似。

# vue插件
在vue的官方文档里，对plugin的解释为，可以随意自定义任何功能，绑定给`Vue`、`Vue.prototype`等。文档这里说的非常宽泛，我们这样理解，比如`VueRouter`，我们在使用router后，可以直接通过`Vue.protoytp.$router`使用导航，也可以直接从router包里导入组件来使用`RouterView`。以下只讨论插件编写逻辑，插件编写的api请参考vue文档，按照使用场景可以把插件分为以下几类：
* 纯逻辑插件，不涉及ui组件导出或者不涉及ui组件展示。例如：编写一个函数，编写一个全局filter，编写一个全局mixin等。
* 纯ui插件，这类插件其实就是纯组件，只不过在`Vue.use`时候，自动注册了全局组件而已，例如[我写的dialog插件](https://github.com/alanchenchen/vue2-dialog)。就是让开发者导入然后在template使用组件。
* ui加逻辑插件，这里我们不说上面两种的混合产物，而是讨论主流ui库的插件，例如toast。

## 怎样实现一个toast全局调用
如果只是编写纯逻辑插件，我们只需要编写好逻辑即可，因为既不需要展示ui（html展示），也不需要动态修改ui内容。如果只是编写纯ui插件，我们只需要写好组件即可，然后在插件暴露出去之前，全局注册组件。那么编写一个toast需要怎么实现？我们先来看下大多数toast使用方式。
```js
// main.js
import ui from "ui";
import Vue from "vue";
Vue.use(ui);
```
```js
// example.vue
// 弹出文本toast
this.$_Toast.show({
    text: "lucky chance！",
    duration: 3000
});
// 弹出带成功icon的toast
this.$_Toast.show({
    text: "lucky chance！",
    type: "success",
    duration: 3000
});
// 弹出loading状态的toast
this.$_Toast.show({
    text: "processing...",
    type: "loading",
});
setTimeout(() => {
    // 还得记得手动关闭
    this.$_Toast.hide();
}, 3000);
```
上面代码的使用方式明显是函数调用，但是却可以自定义弹出ui的内容，这是怎么实现的呢？我之前写的toast插件是纯组件调用，也就是在template里传参，这明显不符合函数调用。

### 脑洞一：很简单的可以想到一个实现方法，在插件里编写html不就行了嘛
```js
// 简单实现
const genDiv = () => {
    const toastDom = document.createElement("div");
    toastDom.contentText = text;
    // ...省略duration和loading逻辑
    document.body.appendChild(toastDom);
    return toastDom;
}
export default {
    install(Vue) {
        Vue.$_Toast = {
            _DOM: null,
            show({
                text = "",
                type = "text",
                duration = 2000
            } = {}) {
                if (this._DOM == null) {
                    this._DOM = genDiv();
                } else {
                    // 版本一，直接显示元素
                    this._DOM.style.display = "none";
                    // 版本二，插入elemtn节点
                    this._DOM = genDiv();
                }
            },
            hide() {
                // 版本一，直接隐藏元素
                this._DOM.style.display = "none";
                // 版本二，去除elemtn节点
                document.body.removeChild(this._DOM);
            }
        }
    }
}
```
优缺点分析：实现简单，不烧脑，轻松就能想到。但是后期维护简直灾难，这里只是非常简单的html结构，一旦结构复杂，比如想实现一个高度定制的dialog或者modal就直接gg。

### 脑洞二：编写ui采用vue组件，然后生成一个vue实例，来通过data动态修改内容
这里会有3个疑问
1. 怎么来将vue组件映射到真实的DOM展示并控制
2. 怎么实现脑洞一的动态显示隐藏效果，虽然可以很简单实现元素隐藏，但总觉得不完美
3. vue/react/svelte这类框架都不允许动态插入或删除节点，vue的方式只有template（render函数），react只有jsx，svelte只有template，怎么实现疑问2中的动态插入或删除内容节点
思路如下：
* 组件还是使用vue编写，就跟你写组件一样
* 在插件js里，导入这个组件，然后生成一个根实例，生成一个新的DOM，将根实例挂载DOM
这样就解决了以上疑问，并且解决了脑洞一的弊端
```js
// 插件简单代码
import Toast from "toast.vue";
import Vue from "vue";

export default {
    install(Vue) {
        const toastDom = document.createElement("div");
        toastDom.id = "toastRootInstance";
        const rootIns = new Vue({
            render: (h) => h(Toast),
        }).$mount("#toastRootInstance");
    }
}
```
详细代码见:
> 下列插件采用vue加ts的项目模版写法，不熟悉的请前去了解`vue-class-component`
* [dialog插件](https://github.com/alanchenchen/blogPractice/tree/master/Dialog)
* [toast插件](https://github.com/alanchenchen/blogPractice/tree/master/Toast)
写到这里，其实这篇文章就可以结束了，脑洞二里的方法到目前为止是我觉得最好的实现全局插件的方式，有如下优点：
1. 后期维护ui，可以直接修改组件，同时组件也可以导出在别的组件里组件调用
2. 动态增删DOM节点，不会让html平白显示一堆代码
3. 虽然我没看过element-ui，iview或者antd的源码，但是大家可以仔细去观察，当你使用过全局toast后，body上方一定会多出一个新的div结构，这个就是我们上面的思路，新建一个新的根实例来管理我们的组件

# react实现一个全局ui插件
大致思路和vue相似，唯一的区别在于，react的父子组件完全解藕，所有不存在`this.$_Toast`或 `Vue.prototype.$_Toast`这种调用方式。大家在使用antd的时候就会发现，插件跟组件导入一样，只不过插件是函数，组件按照jsx调用。

# svelte插件
svelte无法实现全局ui插件，因为它没有virtual DOM，只能通过template解析成真实DOM。但是svelte可以实现纯逻辑插件，类似于你写一个纯js。

# 总结
写插件的前提是要会写组件，为什么会出现全局ui插件这种东西？主要是因为类似toast、dialog这种调用频繁，并且也希望能直接在js里使用，看到这里，开源ui库离你应该不远了🙈🙈🙈🙈
