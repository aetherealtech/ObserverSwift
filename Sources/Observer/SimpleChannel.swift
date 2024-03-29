//
// Created by Daniel Coleman on 11/18/21.
//

import Foundation
import Synchronization

public struct SimpleChannel<Value> : Channel {
    public struct Subscription: Observer.Subscription {
        fileprivate init(
            subscribers: Synchronized<Set<Subscriber>>,
            subscriber: Subscriber
        ) {
            self.subscriber = subscriber
            
            _subscribers = subscribers
        }

        public func cancel() {
            _subscribers.wrappedValue.remove(subscriber)
        }

        private let subscriber: Subscriber
        
        private var _subscribers: Synchronized<Set<Subscriber>>
    }

    public init() {}

    public func subscribe(_ handler: @escaping @Sendable (Value) -> Void) -> Subscription {
        let subscriber = Subscriber(handler: handler)

        _subscribers.wrappedValue.insert(subscriber)

        return .init(
            subscribers: _subscribers,
            subscriber: subscriber
        )
    }

    public func publish(_ value: Value) {
        _subscribers
            .wrappedValue
            .forEach { subscriber in subscriber.receive(value) }
    }

    fileprivate final class Subscriber: Hashable, Sendable {
        init(handler: @escaping @Sendable (Value) -> Void) {
            self.handler = handler
        }

        func receive(_ value: Value) {
            handler(value)
        }

        static func ==(lhs: Subscriber, rhs: Subscriber) -> Bool {
            lhs === rhs
        }

        func hash(into hasher: inout Hasher) {
            ObjectIdentifier(self).hash(into: &hasher)
        }
        
        private let handler: @Sendable (Value) -> Void
    }

    private let _subscribers = Synchronized<Set<Subscriber>>(wrappedValue: [])
}
