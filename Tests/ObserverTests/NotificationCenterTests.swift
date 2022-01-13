//
//  SimpleChannelTests.swift
//  ObserverTests
//
//  Created by Daniel Coleman on 11/18/21.
//

import XCTest
@testable import Observer

class NotificationCenterTests: XCTestCase {

    let testNotificationName = Notification.Name(rawValue: "SomeNotification")

    func testPublish() throws {

        let channel = NotificationCenter.default.channel(for: testNotificationName)

        var receivedNotification: Notification? = nil

        NotificationCenter.default.addObserver(forName: testNotificationName, object: nil, queue: nil) { notification in

            receivedNotification = notification
        }

        let testData: NotificationData = ("someValue", ["someKey": 58])

        channel.publish(testData)

        XCTAssertEqual(receivedNotification!.object as! String, testData.object as! String)
        XCTAssertEqual(receivedNotification!.userInfo as! [String: Int], testData.userInfo as! [String: Int])
    }

    func testSubscribe() throws {

        let channel = NotificationCenter.default.channel(for: testNotificationName)

        var receivedData: NotificationData?

        let subscription = channel.subscribe { object, userInfo in

            receivedData = (object, userInfo)
        }

        let testData: NotificationData = ("someValue", ["someKey": 58])

        NotificationCenter.default.post(name: testNotificationName, object: testData.object, userInfo: testData.userInfo)

        XCTAssertEqual(receivedData!.object as! String, testData.object as! String)
        XCTAssertEqual(receivedData!.userInfo as! [String: Int], testData.userInfo as! [String: Int])
    }

    func testUnsubscribe() throws {

        let channel = NotificationCenter.default.channel(for: testNotificationName)

        var receivedData: NotificationData?

        var subscription: Subscription? = channel.subscribe { object, userInfo in

            receivedData = (object, userInfo)
        }

        let testData: NotificationData = ("someValue", ["someKey": 58])

        subscription = nil

        NotificationCenter.default.post(name: testNotificationName, object: testData.object, userInfo: testData.userInfo)

        XCTAssertNil(receivedData)
    }
}