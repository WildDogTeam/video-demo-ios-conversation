//
//  InviteViewController.swift
//  WilddogVideo
//
//  Created by Zheng Li on 8/29/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

import UIKit
import WilddogSync
import WilddogAuth
import WilddogVideo

class InviteViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    let wilddog: Wilddog = Wilddog(url: "https://<#AppID#>.wilddogio.com")
    let wilddogAuth = WDGAuth.auth(appID: "<#AppID#>")!
    var wilddogVideoClient: WDGVideoClient?

    var onlineUsers = [String]()
    var myUserID: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

        setupOnlineUserMonitoring()
        setupWilddogVideoClient()
    }
}

// MARK: - Step 1 ~ Initialize WDGVideoClient ~
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

// MARK: - UITableViewDataSource
extension InviteViewController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return onlineUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath)
        cell.textLabel?.text = onlineUsers[indexPath.row]
        return cell
    }
}

// MARK: - UITableViewDelegate
extension InviteViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if let
            targetUserID = tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.text,
            selfUserID = self.myUserID,
            wilddogVideoClient = self.wilddogVideoClient
            where targetUserID != selfUserID {

            inviteUser(targetUserID, wilddogVideoClient: wilddogVideoClient)
        }
    }
}

// MARK: - Step 2 ~ Process Invitation ~
extension InviteViewController {
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
}

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

// MARK: - Online User Monitor
extension InviteViewController {
    private func setupOnlineUserMonitoring() {
        wilddog.childByAppendingPath("users").observeEventType(.Value) { [weak self] (snapshot: WDataSnapshot) in
            guard let strongSelf = self else { return }

            strongSelf.onlineUsers = snapshot.children.allObjects.flatMap {
                return $0 as? WDataSnapshot
            }.map {
                return $0.key
            }.filter { [weak self] in
                guard let strongSelf = self else { return false }

                return $0 != strongSelf.myUserID
            }

            strongSelf.tableView.reloadData()
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appWillEnterForegroundNotification(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)
    }

    func appWillEnterForegroundNotification(notification: NSNotification) {
        guard let uid = self.myUserID else { return }

        self.wilddog.childByAppendingPath("users").childByAppendingPath(uid).setValue(true)
        self.wilddog.childByAppendingPath("users").childByAppendingPath(uid).onDisconnectRemoveValue()
    }
}

// MARK: - Enter Conversation Room
extension InviteViewController {
    private func presentRoomWithConversation(conversation: WDGVideoConversation) {
        guard let
            roomNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("RoomNavigationController") as? UINavigationController,
            roomViewController = roomNavigationController.viewControllers.first as? RoomViewController else {
            return
        }

        roomViewController.wilddogVideoConversation = conversation
        self.presentViewController(roomNavigationController, animated: true, completion: nil)
    }
}
