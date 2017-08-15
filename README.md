# Wilddog Video iOS 快速入门

[完整文档](https://docs.wilddog.com/conversation/iOS/index.html)

---


<div class="env">
    <p class="env-title">环境准备</p>
    <ul>
        <li> Xcode 7.0 及以上版本 </li>
        <li> iOS 8.0 及以上版本 </li>
    </ul>
</div>


## 1. 创建应用

首先，在控制面板中创建应用。

![video_quickstart_create](https://raw.githubusercontent.com/WildDogTeam/video-demo-ios-conversation/master/images/video_quickstart_create.png)

## 2. 开启匿名登录

应用创建成功后，进入 管理应用-身份认证-登录方式，开启匿名登录。

![video_quickstart_openanonymous](https://raw.githubusercontent.com/WildDogTeam/video-demo-ios-conversation/master/images/openanonymous.png)

## 3. 开启实时视频通话

进入 管理应用-实时视频通话，开启视频通话功能。此处注意记下配置页面的 `VideoAppID`

![video_quickstart_openVideo](https://raw.githubusercontent.com/WildDogTeam/video-demo-ios-conversation/master/images/video_quickstart_openVideo.png)

## 4. 安装快速入门

使用 Cocoapods 管理快速入门包。进入工程目录，执行以下命令，自动下载依赖并更新到最新版。

```shell

 $ pod install

```

下载完毕后会自动创建 `WilddogVideoQuickStart.xcworkspace`，打开：

```shell

 $ open WilddogVideoQuickStart.xcworkspace

```

在 Xcode 中编译运行快速入门，把快速入门安装到 iPhone 中。


## 5. 运行快速入门

连接 iPhone，运行快速入门。

## 6. 登录快速入门

快速入门运行成功后，输入 `VideoAppID`。

![video_quickstart_ios_mainUI](https://raw.githubusercontent.com/WildDogTeam/video-demo-ios-conversation/master/images/video_quickstart_ios_login.png)

`VideoAppID` 为下图所示，然后点击匿名登录。

![video_quickstart_videoappid](https://raw.githubusercontent.com/WildDogTeam/video-demo-ios-conversation/master/images/video_quickstart_videoappid.png)

登录成功后，页面会显示本地视频画面、你的 Wilddog ID 和用户列表按钮。

![video_quickstart_ios_mainUI](https://raw.githubusercontent.com/WildDogTeam/video-demo-ios-conversation/master/images/video_quickstart_ios_mainUI.png)

## 7. 邀请他人加入

在其他 iPhone 上使用同一 `VideoAppID` 匿名登录，然后点击用户列表按钮，点击邀请按钮邀请对方加入视频通话。

![video_quickstart_ios_userList](https://raw.githubusercontent.com/WildDogTeam/video-demo-ios-conversation/master/images/video_quickstart_ios_userList.png)

## 8. 接受邀请

被邀请人收到邀请提示后，点击确认加入，视频通话建立。

![video_quickstart_ios_conversation](https://raw.githubusercontent.com/WildDogTeam/video-demo-ios-conversation/master/images/video_quickstart_ios_conversation.jpg)


更多详细功能请见 [完整指南](https://docs.wilddog.com/conversation/iOS/guide/0-concepts.html) 和 [API 文档](https://docs.wilddog.com/conversation/iOS/api/WDGVideo.html)。
