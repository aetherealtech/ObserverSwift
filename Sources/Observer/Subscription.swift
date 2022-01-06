//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation

open class Subscription : Hashable {

    public init() {

    }

    public static func ==(lhs: Subscription, rhs: Subscription) -> Bool {

        lhs === rhs
    }

    public func hash(into hasher: inout Hasher) {

        ObjectIdentifier(self).hash(into: &hasher)
    }
}

extension Subscription {

    public func store(in set: inout Set<Subscription>) {

        set.insert(self)
    }

    public func remove(from set: inout Set<Subscription>) {

        set.remove(self)
    }
}

final public class AggregateSubscription : Subscription, ExpressibleByArrayLiteral {

    public typealias ArrayLiteralElement = Subscription

    public init(arrayLiteral elements: Subscription...) {

        self.subscriptions = Set<Subscription>(elements)
    }

    public init<Subscriptions: Sequence>(_ subscriptions: Subscriptions) where Subscriptions.Element : Subscription {

        self.subscriptions = Set<Subscription>(subscriptions.map { value in value as Subscription })
    }

    private let subscriptions: Set<Subscription>
}