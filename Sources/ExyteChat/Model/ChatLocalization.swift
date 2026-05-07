//
//  ChatLocalization.swift
//  Chat
//
//  Created by Aman Kumar on 18/12/24.
//

import Foundation

public struct ChatLocalization: Hashable {
    public var inputPlaceholder: String
    public var signatureText: String
    public var cancelButtonText: String
    public var recentToggleText: String
    public var waitingForNetwork: String
    public var recordingText: String
    public var replyToText: String
    public var checkFileSizeButtonText: String
    public var downloadFileButtonText: String
    public var openFileButtonText: String
    public var checkingSizeText: String
    public var downloadingText: String

    public init(inputPlaceholder: String, signatureText: String, cancelButtonText: String, recentToggleText: String, waitingForNetwork: String, recordingText: String, replyToText: String, checkFileSizeButtonText: String, downloadFileButtonText: String, openFileButtonText: String, checkingSizeText: String, downloadingText: String) {
        self.inputPlaceholder = inputPlaceholder
        self.signatureText = signatureText
        self.cancelButtonText = cancelButtonText
        self.recentToggleText = recentToggleText
        self.waitingForNetwork = waitingForNetwork
        self.recordingText = recordingText
        self.replyToText = replyToText
        self.checkFileSizeButtonText = checkFileSizeButtonText
        self.downloadFileButtonText = downloadFileButtonText
        self.openFileButtonText = openFileButtonText
        self.checkingSizeText = checkingSizeText
        self.downloadingText = downloadingText
    }

   public static var defaultLocalization: ChatLocalization {
        ChatLocalization(
            inputPlaceholder: String(localized: "Type a message..."),
            signatureText: String(localized: "Add signature..."),
            cancelButtonText: String(localized: "Cancel"),
            recentToggleText: String(localized: "Recents"),
            waitingForNetwork: String(localized: "Waiting for network"),
            recordingText: String(localized: "Recording..."),
            replyToText: String(localized: "Reply to"),
            checkFileSizeButtonText: String(localized: "Check File Size"),
            downloadFileButtonText: String(localized: "Download File"),
            openFileButtonText: String(localized: "Open File"),
            checkingSizeText: String(localized: "Checking the size"),
            downloadingText: String(localized: "Downloading")
        )
    }
}
