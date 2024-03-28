//
//  Created by Daniel Coleman on 1/6/22.
//

import Foundation

public protocol PubChannel<Value>: Sendable {
    associatedtype Value

    func publish(_ value: Value)
}

public struct AnyPubChannel<Value>: PubChannel {
    init<Channel: PubChannel<Value>>(channel: Channel) {
        self.value = channel
    }
    
    public func publish(_ value: Value) {
        self.value.publish(value)
    }
    
    private let value: any PubChannel<Value>
}

extension PubChannel {
    public func erase() -> AnyPubChannel<Value> {
        .init(channel: self)
    }
}

extension PubChannel where Value == Void {
    public func publish() {
        self.publish(())
    }
}

public protocol SubChannel<Value>: Sendable {
    associatedtype Value
    associatedtype Subscription: Observer.Subscription

    func subscribe(_ handler: @escaping @Sendable (Value) -> Void) -> Subscription
}

public struct AnySubChannel<Value>: SubChannel {
    init<Channel: SubChannel<Value>>(channel: Channel) {
        self.value = channel
    }
    
    public func subscribe(_ handler: @escaping @Sendable (Value) -> Void) -> AnySubscription {
        value.subscribe(handler).erase()
    }
    
    private let value: any SubChannel<Value>
}

extension SubChannel {
    public func erase() -> AnySubChannel<Value> {
        .init(channel: self)
    }
}

extension SubChannel where Value == Void {
    public func subscribe(_ handler: @escaping @Sendable () -> Void) -> Subscription {
        self.subscribe { _ in handler() }
    }
}

public typealias Channel = PubChannel & SubChannel
public typealias ChannelOf<Value> = PubChannel<Value> & SubChannel<Value>

public struct AnyChannel<Value> : Channel {
    init<ChannelType: ChannelOf<Value>>(channel: ChannelType) {
        self.value = channel
    }

    public func publish(_ value: Value) {
        self.value.publish(value)
    }
    
    public func subscribe(_ handler: @escaping @Sendable (Value) -> Void) -> AnySubscription {
        self.value.subscribe(handler).erase()
    }
    
    private let value: any ChannelOf<Value>
}

extension PubChannel where Self: SubChannel {
    public func erase() -> AnyChannel<Value> {
        .init(channel: self)
    }
}
