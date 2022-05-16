//
//  SimpleChannelTests.swift
//  ObserverTests
//
//  Created by Daniel Coleman on 11/18/21.
//

import XCTest
@testable import Observer

class SimpleChannelTests: XCTestCase {

    class TestValue : Equatable {

        init(payload: String) {

            self.payload = payload
        }

        let payload: String

        static func ==(lhs: SimpleChannelTests.TestValue, rhs: SimpleChannelTests.TestValue) -> Bool {

            lhs.equals(rhs)
        }

        func equals(_ other: TestValue) -> Bool {

            payload == other.payload
        }
    }

    func testPublish() throws {

        let channel = SimpleChannel<TestValue>()

        var receivedValue1: TestValue?
        var receivedValue2: TestValue?

        let subscription1 = channel.subscribe { value in receivedValue1 = value }
        let subscription2 = channel.subscribe { value in receivedValue2 = value }

        let testValue = TestValue(payload: "SomePayload")

        channel.publish(testValue)

        XCTAssertEqual(receivedValue1, testValue)
        XCTAssertEqual(receivedValue2, testValue)

        withExtendedLifetime(subscription1) {  }
        withExtendedLifetime(subscription2) {  }
    }

    func testUnsubscribe() throws {

        let channel = SimpleChannel<TestValue>()

        var receivedValue1: TestValue?
        var receivedValue2: TestValue?

        let subscription1 = channel.subscribe { value in receivedValue1 = value }
        var subscription2: Subscription? = channel.subscribe { value in receivedValue2 = value }

        let testValue = TestValue(payload: "SomePayload")

        withExtendedLifetime(subscription1) {  }
        withExtendedLifetime(subscription2) {  }
        subscription2 = nil

        channel.publish(testValue)

        XCTAssertEqual(receivedValue1, testValue)
        XCTAssertNil(receivedValue2)
    }
}
