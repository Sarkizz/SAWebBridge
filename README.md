# SAWebBridge

### 关于

SAWebBridge是基于WKWebView的UIDelegate协议方法

```swift
webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt: defaultText: initiatedByFrame: completionHandler
```

来实现的交互。
>为了实现同步数据交互，放弃了WKWebView自带的JS交互。不过JS注入仍然是使用常规方式。

### 使用
- ##### WebView
  - 自定义个`WKWebView`的子类，并且遵循`SAWebViewProtocol`协议，实现协议方法。
  - 创建自定义子类对象，并且设置`UIDelegate`和`NavigationDelegate`为`SAWebViewUIDelegateHandler`和`SAWebViewNavigationDelegateHandler`对象或其子类。
  - 自定义对不同类型事件的处理，处理完毕后一定要调用`result`回调函数来通知H5事件处理结果（可重复调用）
- ##### H5
  - 调用
  `window.jsbridge.init()`
  来初始化，如需在初始化后做配置，则可以在调用
  `init()`
  之前，先设置`jsbridge`的`onInited`函数。由于`onInited`函数是一个异步的回调，因此最好使用`Promise`。
  - 调用同步函数
  `const rs = $jssdk('sync.<#name#>', params)`
  来通知原生端处理同步事件，并且返回结果
  - 调用异步函数
  `$jssdk('async.<#name#>', params, p => {}).then().catch()`
  来通知原生端处理异步函数，并且返回结果。`p => {}`是进度回调。
- ##### 主应用
  - 主应用是App启动时候优先加载的H5，承载主要交互。推荐将主应用的`WebViewController`设置为单例。
  - `SAWebNotificationManager`初始化需要设置一个`main`，用于处理原生端对H5的通知逻辑和回调。推荐设置成主应用的web。
  - 主应用H5初始化完毕后可以调用
  `$register('event.<#name#>', (id, params) => {}`
  `$register('api.<#name#>', (id, params) => {}`
  来注册原生通知H5的事件。在回调用使用
  `$resolve(id, <#data#>)`
  `$reject(id, <#code: String#>, <#msg: String#>)`
  来返回处理结果。
  - `event`是原生主动通知H5的事件，`api`则是小程序通知主应用的接口。
- ##### 小程序
  - 非主应用的注入SDK的H5可以认为是小程序（无论页面来自本地还是服务器）
  - 小程序可以调用`$jssdk(sync/async.<#name#>)`实现跟原生的同步异步交互，操作同上。
  - 小程序可以调用
  `$jssdk('api.<#interface#>', params).then().catch()`
  来通知主应用处理事件。api接口必须主应用注册过，否则无效。

### LocalStorage
- 介绍
  >`webView`初始化的时候可以配置是否`hook`H5的LocalStorage存储。为了让主应用和各个小程序的存储不相互影响，推荐配置为true。
- SALocalStorageProtocol
  >遵循`SALocalStorageProtocol`协议的都可以成为存储器，默认提供一个使用`UserDefault`作为存储器的实现。
- 通过`SAWebViewProtocol`协议的`localStorageIdentifier()`方法，配置各个H5的存储id，用于区分各自的存储。

### 遗留问题
- 通知的注册只能是主应用处理，小程序无法作为主体使用。
- 目前无法自定义交互协议。
- 不知道为啥，pod提交成功了，但是目前还是搜不到。