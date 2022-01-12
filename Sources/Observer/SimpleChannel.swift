//
// Created by Daniel Coleman on 11/18/21.
//

import Foundation

public class SimpleChannel : Channel {

    public init() {

    }

    public func subscribe<Value>(_ handler: @escaping (Value) -> Void) -> Subscription {

        let subscriber = TypeMatchingSubscriber(handler: handler)

        subscribersQueue.async(flags: [DispatchWorkItemFlags.barrier]) {

            self.subscribers.append(subscriber)
        }

        return SimpleSubscription(
            channel: self,
            subscriber: subscriber
        )
    }

    public func publish<Value>(_ value: Value) {

        let subscribers: [Subscriber] = subscribersQueue.sync { self.subscribers }

        subscribers
            .forEach { subscriber in subscriber.receive(value) }
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

            channel.subscribersQueue.sync {

                channel.subscribers.removeAll(where: { subscriber in subscriber === self.subscriber})
            }
        }

        private weak var channel: SimpleChannel?
        private let subscriber: Subscriber
    }

    private var subscribers: [Subscriber] = []

    private let subscribersQueue = DispatchQueue(
        label: "com.devcraft.observer.simplechannel.subscriptionqueue",
        attributes: [.concurrent]
    )
}
