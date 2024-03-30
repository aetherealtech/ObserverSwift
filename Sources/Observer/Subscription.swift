//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation

public protocol Subscription: Sendable {
    func cancel()
}

public struct AnySubscription: Subscription {
    init(erasing value: some Subscription) {
        self.value = value
    }
    
    public func cancel() {
        value.cancel()
    }
    
    private let value: any Subscription
}

public extension Subscription {
    func erase() -> AnySubscription {
        .init(erasing: self)
    }
}

public struct AutoSubscription: ~Copyable, Sendable {
    init(subscription: some Subscription) {
        cancel = { subscription.cancel() }
    }
    
    deinit {
        cancel()
    }
    
    private let cancel: @Sendable () -> Void
}

public final class SharedAutoSubscription: Hashable, Sendable {
    init(subscription: consuming AutoSubscription) {
        self.subscription = subscription
    }
    
    public static func == (lhs: SharedAutoSubscription, rhs: SharedAutoSubscription) -> Bool {
        lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self).hash(into: &hasher)
    }
    
    private let subscription: AutoSubscription
}

public extension Subscription {
    func autoCancel() -> AutoSubscription {
        .init(subscription: self)
    }
}

public extension AutoSubscription {
    consuming func share() -> SharedAutoSubscription {
        .init(subscription: self)
    }
}

public extension AutoSubscription {
    consuming func store(in collection: inout some RangeReplaceableCollection<AutoSubscription>) {
        collection.append(self)
    }
}

public extension SharedAutoSubscription {
    func store(in collection: inout Set<SharedAutoSubscription>) {
        collection.insert(self)
    }
}

public struct AggregateSubscription : Subscription, ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = any Subscription

    public init(arrayLiteral elements: any Subscription...) {
        self.subscriptions = .init(elements)
    }

    public init(_ subscriptions: some Sequence<some Subscription>) {
        self.subscriptions = .init(subscriptions.map { $0 as any Subscription })
    }
    
    public init(_ subscriptions: some Sequence<any Subscription>) {
        self.subscriptions = .init(subscriptions)
    }
    
    public func cancel() {
        subscriptions.forEach { subscription in subscription.cancel() }
    }

    private let subscriptions: [any Subscription]
}

public extension Sequence where Element: Subscription {
    var aggregated: AggregateSubscription {
        .init(self)
    }
}

public extension Sequence where Element == any Subscription {
    var aggregated: AggregateSubscription {
        .init(self)
    }
}
