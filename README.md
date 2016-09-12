# Wilddog Video iOS 快速入门

## 快速入门下载地址

[快速入门 Demo](https://github.com/itolfh/wilddog-video-quickstart)

## 1. 创建应用

首先在控制面板中创建一个应用。更多创建应用的细节，请查看 [控制面板-创建应用](https://docs.wilddog.com/console/creat.html)。

创建好的应用（如下图）都有一个URL地址，这个地址是该应用的根节点位置。示例的应用地址为`https://yourapp.wilddogio.com`，其中`yourapp` 是该应用的 appId。

![](https://docs.wilddog.com/images/demoapp.png)

## 2. 引入 SDK

Wilddog Video SDK 基于 Auth SDK 和 Sync SDK 进行开发的，除了 Video SDK，还需要引入 [Wilddog Auth SDK](https://docs.wilddog.com/quickstart/auth/web.html) 以及 [Wilddog Sync SDK](https://docs.wilddog.com/quickstart/sync/web.html) 。

要将 Wilddog Video SDK 导入到你的工程中，请使用 [CocoaPods](https://cocoapods.org/)，如果您不了解 CocoaPods，请先访问 [CocoaPods getting started](https://guides.cocoapods.org/using/getting-started.html)。

成功安装Cocapods后，打开工程目录，新建一个 Podfile 文件

```shell
 $ cd your-project-directory

 $ pod init

 $ open -a Xcode Podfile # opens your Podfile in Xcode
```

然后在 Podfile 文件中添加以下语句

```ruby
 pod 'WilddogVideo'
```

最后安装 SDK

```shell
 $ pod install

 $ open your-project.xcworkspace
```

Cocoapods 会自动为您安装 Wilddog Video SDK 及其依赖的 Wilddog Auth SDK 和 Wilddog Sync SDK。

## 3. 初始化 WilddogVideoClient
使用 WilddogVideoClientClient 来创建和加入音视频会话。
出于安全，WilddogVideoClient 初始化前必须经过身份认证。这里采用匿名登录的方式，用户开发时可以选择邮箱密码、第三方或自定义认证方式。

### 3.1 在控制面板中打开匿名登录
![](https://docs.wilddog.com/images/openanonymous.png)

### 3.2 创建 WilddogVideoClient
WilddogVideoClient 初始化时需要 Wilddog 及 WDGUser 实例作为参数。
WilddogVideoClient 会自动在输入的 Wilddog 实例所在路径下建立 `Video` 子节点，所有的数据交换均在该子节点下进行。

```swift
extension InviteViewController {
    func setupWilddogVideoClient() {
        title = "Not Login"

        wilddogAuth.signInAnonymouslyWithCompletion { [weak self] (user, error) in
            guard let strongSelf = self else { return }
            guard let user = user where user.uid != "" else {
                print("请在控制台为您的AppID开启匿名登录功能，错误信息: \(error)")
                return
            }

            strongSelf.title = user.uid
            strongSelf.myUserID = user.uid
            strongSelf.wilddog.childByAppendingPath("users").childByAppendingPath(user.uid).setValue(true)
            strongSelf.wilddog.childByAppendingPath("users").childByAppendingPath(user.uid).onDisconnectRemoveValue()

            strongSelf.wilddogVideoClient = WDGVideoClient(wilddog: strongSelf.wilddog, user: user)
            strongSelf.wilddogVideoClient?.delegate = strongSelf
        }
    }
}
```

## 4. 邀请其他用户进行视频通话
接下来可以通过前一步创建的 wilddogVideoClient 邀请其他用户进行视频通话。

### 4.1 邀请者
邀请者可以通过 `WDGVideoClient` 的 `inviteUser` 方法，邀请其他用户进行视频会话。邀请发出后，可随时通过 `WDGOutgoingInvite` 的 `cancel` 方法撤销邀请。

```swift

func inviteUser(targetUserID: String, wilddogVideoClient: WDGVideoClient) {
    let alertController = UIAlertController(title: "邀请", message: "正在邀请\(targetUserID) 进行视频通话", preferredStyle: .Alert)

    let outgoingInvitation = wilddogVideoClient.inviteUser(targetUserID, conversationMode: .Basic) { [weak self] (conversation, error) in
        guard let strongSelf = self else { return }

        guard let conversation = conversation else {
            // Invitation Rejected
            strongSelf.dismissViewControllerAnimated(true) {
                let alertController = UIAlertController(title: "提示", message: "视频通话邀请被对方拒绝", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "好", style: .Cancel, handler: nil))
                strongSelf.presentViewController(alertController, animated: true, completion: nil)
            }
            return;
        }

        // Invitation Accepted
        strongSelf.dismissViewControllerAnimated(true) {
            strongSelf.presentRoomWithConversation(conversation)
        }
    }

    alertController.addAction(UIAlertAction(title: "取消邀请", style: .Destructive, handler: { (action) in
        outgoingInvitation.cancel()
    }))

    presentViewController(alertController, animated: true, completion: nil)
}

```

### 4.1 被邀请者
被邀请者通过实现 `WDGVideoClientDelegate` 响应邀请事件，可以通过 `WDGIncomingInvite` 的 `accept` 和 `reject` 方法接受或拒绝邀请。

```swift
// MARK: - WDGVideoClientDelegate
extension InviteViewController: WDGVideoClientDelegate {
    func wilddogVideoClient(videoClient: WDGVideoClient, didReceiveInvite invite: WDGVideoIncomingInvite) {
        processIncomingInvitation(invite)
    }

    func wilddogVideoClient(videoClient: WDGVideoClient, inviteDidCancel invite: WDGVideoIncomingInvite) {
        NSLog("Incoming Invite cancelled %@ ", invite)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
```

```swift
func processIncomingInvitation(invite: WDGVideoIncomingInvite) {
    let alertController = UIAlertController(title: invite.conversationID, message: "\(invite.fromUserID) 邀请你进行视频通话", preferredStyle: .Alert)

    alertController.addAction(UIAlertAction(title: "拒绝", style: .Destructive, handler: { (action) in
        invite.reject()
    }))

    alertController.addAction(UIAlertAction(title: "接受", style: .Default, handler: { [weak self] (action) in
        invite.acceptWithCompletionHandler({ [weak self] (conversation, error) in
            guard let strongSelf = self else { return }
            guard error == nil else {
                NSLog("%@", error!)
                return;
            }
            strongSelf.presentRoomWithConversation(conversation!)
            })
        }))

    presentViewController(alertController, animated: true, completion: nil)
}
```

## 5. 建立会话
被邀请者接受邀请后，双方均可通过 `WDGVideoConversation` 的 `localSteam` 方法获得本地视频流，并调用 `WDGVideoStream` 的 `attach` 方法将视频流渲染到 `WDGVideoView` 上。
同时双方通过实现 `WDGVideoConversationDelegate` 的 `conversation:didConnectParticipant:`方法获取代表视频通话对方的 `WDGVideoParticipant` 实例，并展示对方的视频流。

```swift
import UIKit
import WilddogVideo

class RoomViewController: UIViewController {
    @IBOutlet weak var localVideoView: WDGVideoView!
    @IBOutlet weak var remoteVideoView: WDGVideoView!

    var videoConversation: WDGVideoConversation?
    var localStream: WDGVideoLocalStream?
    var remoteStream: WDGVideoRemoteStream?

    var wilddogVideoConversation: WDGVideoConversation? {
        didSet {
            _ = self.view // Note: Force storyboard load view.
            guard let videoConversation = wilddogVideoConversation else {
                return;
            }

            videoConversation.delegate = self
            localStream = videoConversation.localStream
            videoConversation.localStream?.attach(localVideoView)
            if let remoteStream = videoConversation.participants.first?.stream {
                remoteStream.attach(remoteVideoView)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func dismiss(sender: AnyObject) {
        videoConversation?.disconnect()
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - WDGVideoConversationDelegate
extension RoomViewController: WDGVideoConversationDelegate {
    func conversation(conversation: WDGVideoConversation, didConnectParticipant participant: WDGVideoParticipant) {
        remoteStream = participant.stream
        remoteStream?.attach(remoteVideoView)
    }
}
```
