//
//  SimpleChannelTests.swift
//  ObserverTests
//
//  Created by Daniel Coleman on 11/18/21.
//

import Assertions
import Synchronization
import XCTest

@testable import Observer

final class NotificationCenterTests: XCTestCase {
    private let testNotificationName = Notification.Name(rawValue: "SomeNotification")

    func testPublish() throws {
        let channel = NotificationCenter.default
            .channel(for: testNotificationName)

        @Synchronized
        var receivedNotification: Notification? = nil

        NotificationCenter.default
            .addObserver(
                forName: testNotificationName,
                object: nil,
                queue: nil
            ) { [_receivedNotification] notification in
                _receivedNotification.wrappedValue = notification
            }

        let testData: NotificationCenterChannel.Value = ("someValue", ["someKey": 58])

        channel.publish(testData)

        try assertEqual(receivedNotification!.object as! String, testData.object as! String)
        try assertEqual(receivedNotification!.userInfo as! [String: Int], testData.userInfo as! [String: Int])
    }

    func testSubscribe() throws {
        let channel = NotificationCenter.default
            .channel(for: testNotificationName)

        @Synchronized
        var receivedData: NotificationCenterChannel.Value?

        _ = channel.subscribe { [_receivedData] object, userInfo in
            _receivedData.wrappedValue = (object, userInfo)
        }

        let testData: NotificationCenterChannel.Value = ("someValue", ["someKey": 58])

        NotificationCenter.default.post(
            name: testNotificationName,
            object: testData.object,
            userInfo: testData.userInfo
        )

        try assertEqual(receivedData!.object as! String, testData.object as! String)
        try assertEqual(receivedData!.userInfo as! [String: Int], testData.userInfo as! [String: Int])
    }

    func testUnsubscribe() throws {
        let channel = NotificationCenter.default
            .channel(for: testNotificationName)

        @Synchronized
        var receivedData: NotificationCenterChannel.Value?

        let subscription = channel.subscribe { [_receivedData] object, userInfo in
            _receivedData.wrappedValue = (object, userInfo)
        }

        let testData: NotificationCenterChannel.Value = ("someValue", ["someKey": 58])

        subscription.cancel()

        NotificationCenter.default.post(name: testNotificationName, object: testData.object, userInfo: testData.userInfo)

        try assertNil(receivedData)
    }
}
