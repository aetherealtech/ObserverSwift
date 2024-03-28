//
//  SerializingChannelTests.swift
//  ObserverTests
//
//  Created by Daniel Coleman on 11/18/21.
//

import Assertions
import Synchronization
import XCTest

@testable import Observer

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final class SerializingChannelTests: XCTestCase {
    struct TestValue: Codable, Equatable {
        struct Child: Codable, Equatable {
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

        let channel = underlyingChannel
            .jsonCoded(to: TestValue.self)

        @Synchronized
        var receivedValue1: TestValue?
        
        @Synchronized
        var receivedValue2: TestValue?

        _ = channel.subscribe { [_receivedValue1] value in _receivedValue1.wrappedValue = value }
        _ = channel.subscribe { [_receivedValue2] value in _receivedValue2.wrappedValue = value }

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

        try assertEqual(receivedValue1, testValue)
        try assertEqual(receivedValue2, testValue)
    }

    func testPublishUnderlying() throws {
        let underlyingChannel = SimpleChannel<Data>()

        let channel = underlyingChannel
            .jsonCoded(to: TestValue.self)

        @Synchronized
        var receivedValue1: TestValue?
        
        @Synchronized
        var receivedValue2: TestValue?

        _ = channel.subscribe { [_receivedValue1] value in _receivedValue1.wrappedValue = value }
        _ = channel.subscribe { [_receivedValue2] value in _receivedValue2.wrappedValue = value }

        let testValue = TestValue(
            string: "Test",
            int: 5,
            double: 8.7,
            child: TestValue.Child(
                string: "Moire",
                array: ["1", "2", "3"]
            )
        )

        let testEncoded = try! channel.encoder.encode(testValue)

        underlyingChannel.publish(testEncoded)

        try assertEqual(receivedValue1, testValue)
        try assertEqual(receivedValue2, testValue)
    }

    final class MockErrorHandler: Sendable {
        private let _invocations = Synchronized<[Error]>(wrappedValue: [])
        
        private(set) var invocations: [Error] {
            _read { yield _invocations.wrappedValue }
            _modify { yield &_invocations.wrappedValue }
        }
        
        func callAsFunction(error: Error) {
            invocations.append(error)
        }
    }

    func testPublishFail() throws {
        let underlyingChannel = SimpleChannel<Data>()

        let errorHandler = MockErrorHandler()
        
        let channel = underlyingChannel
            .jsonCoded(
                to: TestValue.self,
                errorHandler: { error in errorHandler(error: error) }
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

        try assertEqual(errorHandler.invocations.count, 1, "Error handler not invoked")

        let invocation = errorHandler.invocations[0]

        try assertTrue(invocation is EncodingError)
    }

    func testSubscribeFail() throws {
        let underlyingChannel = SimpleChannel<Data>()

        let errorHandler = MockErrorHandler()

        let channel = underlyingChannel
            .jsonCoded(
                to: TestValue.self,
                errorHandler: { error in errorHandler(error: error) }
            )

        let testInvalidEncoded =
            """
            {
                "string": "Test",
                "int": "thisIsAString",
                "double" 8.5
            }
            """

        @Synchronized
        var receivedValue: TestValue? = nil

        _ = channel.subscribe { [_receivedValue] value in
            _receivedValue.wrappedValue = value
        }

        underlyingChannel.publish(testInvalidEncoded.data(using: .utf8)!)

        try assertNil(receivedValue)

        try assertEqual(errorHandler.invocations.count, 1, "Error handler not invoked")

        let invocation = errorHandler.invocations[0]

        try assertTrue(invocation is DecodingError)
    }
}
