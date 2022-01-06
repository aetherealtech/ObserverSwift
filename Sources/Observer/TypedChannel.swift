//
//  Created by Daniel Coleman on 1/6/22.
//

import Foundation

public protocol TypedPubChannel {

    associatedtype Event

    func publish(_ payload: Event)
}

public class AnyTypedPubChannel<Event> : TypedPubChannel {
    
    convenience init<Channel: TypedPubChannel>(channel: Channel) where Channel.Event == Event {
        
        self.init(publishImp: channel.publish)
    }
    
    init(publishImp: @escaping (Event) -> Void) {
        
        self.publishImp = publishImp
    }
    
    public func publish(_ payload: Event) {
        
        publishImp(payload)
    }
    
    private let publishImp: (Event) -> Void
}

extension TypedPubChannel {
    
    public func erase() -> AnyTypedPubChannel<Event> {
        
        return AnyTypedPubChannel(channel: self)
    }
}

public protocol TypedSubChannel {

    associatedtype Event

    func subscribe(_ handler: @escaping (Event) -> Void) -> Subscription
}

public class AnyTypedSubChannel<Event> : TypedSubChannel {
    
    convenience init<Channel: TypedSubChannel>(channel: Channel) where Channel.Event == Event {
        
        self.init(subscribeImp: channel.subscribe)
    }
    
    init(subscribeImp: @escaping (@escaping (Event) -> Void) -> Subscription) {
        
        self.subscribeImp = subscribeImp
    }
    
    public func subscribe(_ handler: @escaping (Event) -> Void) -> Subscription {
        
        return subscribeImp(handler)
    }
    
    private let subscribeImp: (@escaping (Event) -> Void) -> Subscription
}

extension TypedSubChannel {
    
    public func erase() -> AnyTypedSubChannel<Event> {
        
        return AnyTypedSubChannel(channel: self)
    }
}

public typealias TypedChannel = TypedPubChannel & TypedSubChannel

public class AnyTypedChannel<Event> : TypedChannel {
    
    convenience init<Channel: TypedChannel>(channel: Channel) where Channel.Event == Event {
        
        self.init(
            pubChannel: channel.erase(),
            subChannel: channel.erase()
        )
    }
    
    init(
        pubChannel: AnyTypedPubChannel<Event>,
        subChannel: AnyTypedSubChannel<Event>
    ) {
        
        self.pubChannel = pubChannel
        self.subChannel = subChannel
    }
    
    public func publish(_ payload: Event) {
        
        pubChannel.publish(payload)
    }
    
    public func subscribe(_ handler: @escaping (Event) -> Void) -> Subscription {
        
        return subChannel.subscribe(handler)
    }
    
    private let pubChannel: AnyTypedPubChannel<Event>
    private let subChannel: AnyTypedSubChannel<Event>
}

extension TypedPubChannel where Self: TypedSubChannel {
    
    public func erase() -> AnyTypedChannel<Event> {
        
        return AnyTypedChannel(channel: self)
    }
}

extension PubChannel {
    
    public func asTypedChannel<Event>() -> AnyTypedPubChannel<Event> {
        
        return AnyTypedPubChannel<Event> { event in
            
            self.publish(event)
        }
    }
}

extension SubChannel {
    
    public func asTypedChannel<Event>() -> AnyTypedSubChannel<Event> {
        
        return AnyTypedSubChannel<Event> { handler in
            
            return self.subscribe(handler)
        }
    }
}

extension SubChannel where Self: PubChannel {
    
    public func asTypedChannel<Event>() -> AnyTypedChannel<Event> {
        
        return AnyTypedChannel<Event>(
            pubChannel: self.asTypedChannel(),
            subChannel: self.asTypedChannel()
        )
    }
}
