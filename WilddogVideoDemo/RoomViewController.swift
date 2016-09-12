//
//  ViewController.swift
//  WilddogVideoDemo
//
//  Created by Zheng Li on 8/17/16.
//  Copyright © 2016 WildDog. All rights reserved.
//

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
