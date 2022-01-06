//
//  SerializingChannelTests.swift
//  ObserverTests
//
//  Created by Daniel Coleman on 11/18/21.
//

import XCTest

@testable import Observer

class SerializingChannelTests: XCTestCase {

    struct TestEvent : Codable, Equatable {

        struct Child : Codable, Equatable {

            let string: String
            let array: [String]
        }

        let string: String
        let int: Int
        let child: Child
    }

    func testPublish() throws {

        let underlyingChannel: AnyTypedChannel<Data> = SimpleChannel().asTypedChannel()

        let channel = SimpleJSONChannel(
            underlyingChannel: underlyingChannel
        )

        var receivedEvent1: TestEvent?
        var receivedEvent2: TestEvent?

        let subscription1 = channel.subscribe { event in receivedEvent1 = event }
        let subscription2 = channel.subscribe { event in receivedEvent2 = event }

        let testEvent = TestEvent(
            string: "Test",
            int: 5,
            child: TestEvent.Child(
                string: "Moire",
                array: ["1", "2", "3"]
            )
        )

        channel.publish(testEvent)

        XCTAssertEqual(receivedEvent1, testEvent)
        XCTAssertEqual(receivedEvent2, testEvent)
    }
}
