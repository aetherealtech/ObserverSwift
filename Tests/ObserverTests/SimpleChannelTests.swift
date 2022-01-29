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

    class TestDerivedValue : TestValue {

        init(
            payload: String,
            extra: String
        ) {

            self.extra = extra

            super.init(payload: payload)
        }

        let extra: String

        override func equals(_ other: TestValue) -> Bool {

            guard let otherDerived = other as? TestDerivedValue else { return false }

            return super.equals(otherDerived) &&
                extra == otherDerived.extra
        }
    }

    class TestOtherValue : Equatable {

        init(payload: String) {

            self.payload = payload
        }

        let payload: String

        static func ==(lhs: SimpleChannelTests.TestOtherValue, rhs: SimpleChannelTests.TestOtherValue) -> Bool {

            lhs.payload == rhs.payload
        }
    }

    func testPublish() throws {

        let channel = SimpleChannel()

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

        let channel = SimpleChannel()

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

    func testPublishUnrelated() throws {

        let channel = SimpleChannel()

        var receivedValue1: TestValue?
        var receivedValue2: TestOtherValue?

        let subscription1 = channel.subscribe { value in receivedValue1 = value }
        let subscription2 = channel.subscribe { value in receivedValue2 = value }

        let testValue = TestValue(payload: "SomePayload")

        channel.publish(testValue)

        XCTAssertEqual(receivedValue1, testValue)
        XCTAssertNil(receivedValue2)

        withExtendedLifetime(subscription1) {  }
        withExtendedLifetime(subscription2) {  }
    }

    func testPublishDerived() throws {

        let channel = SimpleChannel()

        var receivedValue1: TestValue?
        var receivedValue2: TestDerivedValue?

        let subscription1 = channel.subscribe { value in receivedValue1 = value }
        let subscription2 = channel.subscribe { value in receivedValue2 = value }

        let testValue = TestDerivedValue(payload: "SomePayload", extra: "SomeExtra")

        channel.publish(testValue)

        XCTAssertEqual(receivedValue1, testValue)
        XCTAssertEqual(receivedValue2, testValue)

        withExtendedLifetime(subscription1) {  }
        withExtendedLifetime(subscription2) {  }
    }

    func testPublishBase() throws {

        let channel = SimpleChannel()

        var receivedValue1: TestValue?
        var receivedValue2: TestDerivedValue?

        let subscription1 = channel.subscribe { value in receivedValue1 = value }
        let subscription2 = channel.subscribe { value in receivedValue2 = value }

        let testValue = TestValue(payload: "SomePayload")

        channel.publish(testValue)

        XCTAssertEqual(receivedValue1, testValue)
        XCTAssertNil(receivedValue2)

        withExtendedLifetime(subscription1) {  }
        withExtendedLifetime(subscription2) {  }
    }
}
