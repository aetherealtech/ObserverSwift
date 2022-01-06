//
//  SimpleChannelTests.swift
//  ObserverTests
//
//  Created by Daniel Coleman on 11/18/21.
//

import XCTest
@testable import Observer

class SimpleChannelTests: XCTestCase {

    class TestEvent : Equatable {

        init(payload: String) {

            self.payload = payload
        }

        let payload: String

        static func ==(lhs: SimpleChannelTests.TestEvent, rhs: SimpleChannelTests.TestEvent) -> Bool {

            lhs.equals(rhs)
        }

        func equals(_ other: TestEvent) -> Bool {

            payload == other.payload
        }
    }

    class TestDerivedEvent : TestEvent {

        init(
            payload: String,
            extra: String
        ) {

            self.extra = extra

            super.init(payload: payload)
        }

        let extra: String

        override func equals(_ other: TestEvent) -> Bool {

            guard let otherDerived = other as? TestDerivedEvent else { return false }

            return super.equals(otherDerived) &&
                extra == otherDerived.extra
        }
    }

    class TestOtherEvent : Equatable {

        init(payload: String) {

            self.payload = payload
        }

        let payload: String

        static func ==(lhs: SimpleChannelTests.TestOtherEvent, rhs: SimpleChannelTests.TestOtherEvent) -> Bool {

            lhs.payload == rhs.payload
        }
    }

    func testPublish() throws {

        let channel = SimpleChannel()

        var receivedEvent1: TestEvent?
        var receivedEvent2: TestEvent?

        let subscription1 = channel.subscribe { event in receivedEvent1 = event }
        let subscription2 = channel.subscribe { event in receivedEvent2 = event }

        let testEvent = TestEvent(payload: "SomePayload")

        channel.publish(testEvent)

        XCTAssertEqual(receivedEvent1, testEvent)
        XCTAssertEqual(receivedEvent2, testEvent)
    }

    func testUnsubscribe() throws {

        let channel = SimpleChannel()

        var receivedEvent1: TestEvent?
        var receivedEvent2: TestEvent?

        let subscription1 = channel.subscribe { event in receivedEvent1 = event }
        var subscription2: Subscription? = channel.subscribe { event in receivedEvent2 = event }

        let testEvent = TestEvent(payload: "SomePayload")

        subscription2 = nil

        channel.publish(testEvent)

        XCTAssertEqual(receivedEvent1, testEvent)
        XCTAssertNil(receivedEvent2)
    }

    func testPublishUnrelated() throws {

        let channel = SimpleChannel()

        var receivedEvent1: TestEvent?
        var receivedEvent2: TestOtherEvent?

        let subscription1 = channel.subscribe { event in receivedEvent1 = event }
        let subscription2 = channel.subscribe { event in receivedEvent2 = event }

        let testEvent = TestEvent(payload: "SomePayload")

        channel.publish(testEvent)

        XCTAssertEqual(receivedEvent1, testEvent)
        XCTAssertNil(receivedEvent2)
    }

    func testPublishDerived() throws {

        let channel = SimpleChannel()

        var receivedEvent1: TestEvent?
        var receivedEvent2: TestDerivedEvent?

        let subscription1 = channel.subscribe { event in receivedEvent1 = event }
        let subscription2 = channel.subscribe { event in receivedEvent2 = event }

        let testEvent = TestDerivedEvent(payload: "SomePayload", extra: "SomeExtra")

        channel.publish(testEvent)

        XCTAssertEqual(receivedEvent1, testEvent)
        XCTAssertEqual(receivedEvent2, testEvent)
    }

    func testPublishBase() throws {

        let channel = SimpleChannel()

        var receivedEvent1: TestEvent?
        var receivedEvent2: TestDerivedEvent?

        let subscription1 = channel.subscribe { event in receivedEvent1 = event }
        let subscription2 = channel.subscribe { event in receivedEvent2 = event }

        let testEvent = TestEvent(payload: "SomePayload")

        channel.publish(testEvent)

        XCTAssertEqual(receivedEvent1, testEvent)
        XCTAssertNil(receivedEvent2)
    }
}
