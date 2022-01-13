//
//  Created by Daniel Coleman on 1/6/22.
//

import Foundation

public protocol TypedPubChannel {

    associatedtype Value

    func publish(_ value: Value)
}

public class AnyTypedPubChannel<Value> : TypedPubChannel {
    
    convenience init<Channel: TypedPubChannel>(channel: Channel) where Channel.Value == Value {
        
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

extension TypedPubChannel {
    
    public func erase() -> AnyTypedPubChannel<Value> {
        
        return AnyTypedPubChannel(channel: self)
    }
}

extension TypedPubChannel where Value == Void {
    
    public func publish() {
        
        self.publish(())
    }
}

public protocol TypedSubChannel {

    associatedtype Value

    func subscribe(_ handler: @escaping (Value) -> Void) -> Subscription
}

public class AnyTypedSubChannel<Value> : TypedSubChannel {
    
    convenience init<Channel: TypedSubChannel>(channel: Channel) where Channel.Value == Value {
        
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

extension TypedSubChannel {
    
    public func erase() -> AnyTypedSubChannel<Value> {
        
        return AnyTypedSubChannel(channel: self)
    }
}

extension TypedSubChannel where Value == Void {
    
    public func subscribe(_ handler: @escaping () -> Void) -> Subscription {
        
        self.subscribe { _ in handler() }
    }
}

public typealias TypedChannel = TypedPubChannel & TypedSubChannel

public class AnyTypedChannel<Value> : TypedChannel {
    
    convenience init<Channel: TypedChannel>(channel: Channel) where Channel.Value == Value {
        
        self.init(
            pubChannel: channel.erase(),
            subChannel: channel.erase()
        )
    }
    
    init(
        pubChannel: AnyTypedPubChannel<Value>,
        subChannel: AnyTypedSubChannel<Value>
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
    
    private let pubChannel: AnyTypedPubChannel<Value>
    private let subChannel: AnyTypedSubChannel<Value>
}

extension TypedPubChannel where Self: TypedSubChannel {
    
    public func erase() -> AnyTypedChannel<Value> {
        
        return AnyTypedChannel(channel: self)
    }
}

extension PubChannel {
    
    public func asTypedChannel<Value>() -> AnyTypedPubChannel<Value> {
        
        AnyTypedPubChannel<Value> { value in
            
            self.publish(value)
        }
    }
}

extension SubChannel {
    
    public func asTypedChannel<Value>() -> AnyTypedSubChannel<Value> {
        
        AnyTypedSubChannel<Value> { handler in
            
            self.subscribe(handler)
        }
    }
}

extension SubChannel where Self: PubChannel {
    
    public func asTypedChannel<Value>() -> AnyTypedChannel<Value> {
        
        AnyTypedChannel<Value>(
            pubChannel: self.asTypedChannel(),
            subChannel: self.asTypedChannel()
        )
    }
}
