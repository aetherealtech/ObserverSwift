//
//  SerializingChannelTests.swift
//  ObserverTests
//
//  Created by Daniel Coleman on 11/18/21.
//

import XCTest

@testable import Observer

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SerializingChannelTests: XCTestCase {

    struct TestValue : Codable, Equatable {

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

        var receivedValue1: TestValue?
        var receivedValue2: TestValue?

        let subscription1 = channel.subscribe { value in receivedValue1 = value }
        let subscription2 = channel.subscribe { value in receivedValue2 = value }

        let testValue = TestValue(
            string: "Test",
            int: 5,
            child: TestValue.Child(
                string: "Moire",
                array: ["1", "2", "3"]
            )
        )

        channel.publish(testValue)

        XCTAssertEqual(receivedValue1, testValue)
        XCTAssertEqual(receivedValue2, testValue)
    }
}
