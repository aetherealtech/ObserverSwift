//
//  Created by Daniel Coleman on 1/6/22.
//

import Foundation

public protocol PubChannel {

    associatedtype Value

    func publish(_ value: Value)
}

public class AnyPubChannel<Value> : PubChannel {

    convenience init<Channel: PubChannel>(channel: Channel) where Channel.Value == Value {

        self.init(publishImp: channel.publish)
    }

    init(publishImp: @escaping (Value) -> Void) {
        
        self.publishImp = publishImp
    }
    
    public func publish(_ value: Value) {
        
        publishImp(value)
    }
    
    private let publishImp: (Value) -> Void
}

extension PubChannel {
    
    public func erase() -> AnyPubChannel<Value> {
        
        AnyPubChannel(channel: self)
    }
}

extension PubChannel where Value == Void {
    
    public func publish() {
        
        self.publish(())
    }
}

public protocol SubChannel {

    associatedtype Value

    func subscribe(_ handler: @escaping (Value) -> Void) -> Subscription
}

public class AnySubChannel<Value> : SubChannel {
    
    convenience init<Channel: SubChannel>(channel: Channel) where Channel.Value == Value {
        
        self.init(subscribeImp: channel.subscribe)
    }
    
    init(subscribeImp: @escaping (@escaping (Value) -> Void) -> Subscription) {
        
        self.subscribeImp = subscribeImp
    }
    
    public func subscribe(_ handler: @escaping (Value) -> Void) -> Subscription {
        
        return subscribeImp(handler)
    }
    
    private let subscribeImp: (@escaping (Value) -> Void) -> Subscription
}

extension SubChannel {
    
    public func erase() -> AnySubChannel<Value> {
        
        AnySubChannel(channel: self)
    }
}

extension SubChannel where Value == Void {
    
    public func subscribe(_ handler: @escaping () -> Void) -> Subscription {
        
        self.subscribe { _ in handler() }
    }
}

public typealias Channel = PubChannel & SubChannel

public class AnyChannel<Value> : Channel {
    
    convenience init<ChannelType: Channel>(channel: ChannelType) where ChannelType.Value == Value {
        
        self.init(
            pubChannel: channel.erase(),
            subChannel: channel.erase()
        )
    }
    
    init(
        pubChannel: AnyPubChannel<Value>,
        subChannel: AnySubChannel<Value>
    ) {
        
        self.pubChannel = pubChannel
        self.subChannel = subChannel
    }
    
    public func publish(_ value: Value) {
        
        pubChannel.publish(value)
    }
    
    public func subscribe(_ handler: @escaping (Value) -> Void) -> Subscription {
        
        return subChannel.subscribe(handler)
    }
    
    private let pubChannel: AnyPubChannel<Value>
    private let subChannel: AnySubChannel<Value>
}

extension PubChannel where Self: SubChannel {
    
    public func erase() -> AnyChannel<Value> {
        
        AnyChannel(channel: self)
    }
}
