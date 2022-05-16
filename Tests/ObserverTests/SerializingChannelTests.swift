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
        let double: Double
        let child: Child
    }

    func testPublish() throws {

        let underlyingChannel = SimpleChannel<Data>()

        let channel = JSONChannel<TestValue>(
            underlyingChannel: underlyingChannel
        )

        var receivedValue1: TestValue?
        var receivedValue2: TestValue?

        let subscription1 = channel.subscribe { value in receivedValue1 = value }
        let subscription2 = channel.subscribe { value in receivedValue2 = value }

        let testValue = TestValue(
            string: "Test",
            int: 5,
            double: 8.7,
            child: TestValue.Child(
                string: "Moire",
                array: ["1", "2", "3"]
            )
        )

        channel.publish(testValue)

        XCTAssertEqual(receivedValue1, testValue)
        XCTAssertEqual(receivedValue2, testValue)

        withExtendedLifetime(subscription1) {  }
        withExtendedLifetime(subscription2) {  }
    }

    func testPublishUnderlying() throws {

        let underlyingChannel = SimpleChannel<Data>()

        let channel = JSONChannel<TestValue>(
            underlyingChannel: underlyingChannel
        )

        var receivedValue1: TestValue?
        var receivedValue2: TestValue?

        let subscription1 = channel.subscribe { value in receivedValue1 = value }
        let subscription2 = channel.subscribe { value in receivedValue2 = value }

        let testValue = TestValue(
            string: "Test",
            int: 5,
            double: 8.7,
            child: TestValue.Child(
                string: "Moire",
                array: ["1", "2", "3"]
            )
        )

        let testEncoded = try! JSONEncoder().encode(testValue)

        underlyingChannel.publish(testEncoded)

        XCTAssertEqual(receivedValue1, testValue)
        XCTAssertEqual(receivedValue2, testValue)

        withExtendedLifetime(subscription1) {  }
        withExtendedLifetime(subscription2) {  }
    }

    class MockErrorHandler
    {
        var invocations: [Error] = []

        func invoke(error: Error) {

            invocations.append(error)
        }
    }

    func testPublishFail() throws {

        let underlyingChannel = SimpleChannel<Data>()

        let errorHandler = MockErrorHandler()

        let channel = JSONChannel<TestValue>(
            underlyingChannel: underlyingChannel,
            encodingErrorHandler: errorHandler.invoke
        )

        let testInvalidValue = TestValue(
            string: "Test",
            int: 5,
            double: .infinity,
            child: TestValue.Child(
                string: "Moire",
                array: ["1", "2", "3"]
            )
        )

        channel.publish(testInvalidValue)

        guard errorHandler.invocations.count == 1 else {
            XCTFail("Error handler not invoked")
            return
        }

        let invocation = errorHandler.invocations[0]

        XCTAssertTrue(invocation is EncodingError)
    }

    func testSubscribeFail() throws {

        let underlyingChannel = SimpleChannel<Data>()

        let errorHandler = MockErrorHandler()

        let channel = JSONChannel<TestValue>(
            underlyingChannel: underlyingChannel,
            decodingErrorHandler: errorHandler.invoke
        )

        let testInvalidEncoded =
            """
            {
                "string": "Test",
                "int": "thisIsAString",
                "double" 8.5
            }
            """

        var receivedValue: TestValue? = nil

        let subscription = channel.subscribe { value in

            receivedValue = value
        }

        underlyingChannel.publish(testInvalidEncoded.data(using: .utf8)!)

        XCTAssertNil(receivedValue)

        guard errorHandler.invocations.count == 1 else {
            XCTFail("Error handler not invoked")
            return
        }

        let invocation = errorHandler.invocations[0]

        XCTAssertTrue(invocation is DecodingError)

        withExtendedLifetime(subscription) {  }
    }
}
