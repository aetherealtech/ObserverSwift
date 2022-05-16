//
// Created by Daniel Coleman on 11/18/21.
//

import Foundation
import CoreExtensions

public class SimpleChannel<Value> : Channel {

    public init() {

    }

    public func subscribe(_ handler: @escaping (Value) -> Void) -> Subscription {

        let subscriber = Subscriber(handler: handler)

        subscribers.exclusiveLock({ subscribers in _ = subscribers.insert(subscriber) })

        return SimpleSubscription(
            channel: self,
            subscriber: subscriber
        )
    }

    public func publish(_ value: Value) {

        let subscribers = subscribers.value

        subscribers
            .forEach { subscriber in subscriber.receive(value) }
    }

    class Subscriber : Equatable, Hashable {

        init(handler: @escaping (Value) -> Void) {

            self.handler = handler
        }

        func receive(_ value: Value) {

            handler(value)
        }

        static func ==(lhs: Subscriber, rhs: Subscriber) -> Bool {

            lhs === rhs
        }

        private let handler: (Value) -> Void

        func hash(into hasher: inout Hasher) {

            ObjectIdentifier(self).hash(into: &hasher)
        }
    }

    class SimpleSubscription : Subscription {

        init(
            channel: SimpleChannel,
            subscriber: Subscriber
        ) {

            self.channel = channel
            self.subscriber = subscriber
        }

        deinit {

            guard let channel = self.channel else { return }

            channel.subscribers.exclusiveLock({ subscribers in _ = subscribers.remove(subscriber) })
        }

        private weak var channel: SimpleChannel?
        private let subscriber: Subscriber
    }

    private var subscribers = Atomic<Set<Subscriber>>([])
}
