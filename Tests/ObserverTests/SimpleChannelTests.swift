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

final class SimpleChannelTests: XCTestCase {
    final class TestValue {}

    func testPublish() throws {
        let channel = SimpleChannel<TestValue>()

        @Synchronized
        var receivedValue1: TestValue?
        
        @Synchronized
        var receivedValue2: TestValue?

        _ = channel.subscribe { [_receivedValue1] value in _receivedValue1.wrappedValue = value }
        _ = channel.subscribe { [_receivedValue2] value in _receivedValue2.wrappedValue = value }

        let testValue = TestValue()

        channel.publish(testValue)

        try assertIdentical(receivedValue1, testValue)
        try assertIdentical(receivedValue2, testValue)
    }

    func testUnsubscribe() throws {
        let channel = SimpleChannel<TestValue>()
        
        @Synchronized
        var receivedValue1: TestValue?
        
        @Synchronized
        var receivedValue2: TestValue?

        _ = channel.subscribe { [_receivedValue1] value in _receivedValue1.wrappedValue = value }
        let subscription = channel.subscribe { [_receivedValue2] value in _receivedValue2.wrappedValue = value }

        let testValue = TestValue()
        
        subscription.cancel()

        channel.publish(testValue)

        try assertIdentical(receivedValue1, testValue)
        try assertNil(receivedValue2)
    }
}
