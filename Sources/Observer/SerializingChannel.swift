//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation
import Combine

public protocol SerializingPubChannel : TypedPubChannel where Value: Encodable {

    func tryPublish(_ value: Value) throws
}

extension SerializingPubChannel {

    public func publish(_ value: Value) {

        try? tryPublish(value)
    }
}

public class AnySerializingPubChannel<Value: Encodable> : AnyTypedPubChannel<Value>, SerializingPubChannel {

    init<Channel: SerializingPubChannel>(erasing channel: Channel) where Channel.Value == Value {

        self.tryPublishImp = channel.tryPublish

        super.init(publishImp: channel.publish)
    }

    public func tryPublish(_ value: Value) throws {

        try tryPublishImp(value)
    }

    private let tryPublishImp: (_ value: Value) throws -> Void
}

extension SerializingPubChannel {

    func erase() -> AnySerializingPubChannel<Value> {

        AnySerializingPubChannel(erasing: self)
    }
}

protocol SerializingSubChannel : TypedSubChannel where Value: Decodable {

    func subscribe(
        onValue: @escaping (Value) -> Void,
        onError: @escaping (Error) -> Void
    ) -> Subscription
}

extension SerializingSubChannel {

    func subscribe(_ handler: @escaping (Value) -> Void) -> Subscription {

        subscribe(
            onValue: handler,
            onError: { _ in }
        )
    }
}

public class AnySerializingSubChannel<Value: Decodable> : AnyTypedSubChannel<Value>, SerializingSubChannel {

    init<Channel: SerializingSubChannel>(erasing channel: Channel) where Channel.Value == Value {

        self.subscribeImp = channel.subscribe

        super.init(subscribeImp: channel.subscribe)
    }

    public func subscribe(
        onValue: @escaping (Value) -> Void,
        onError: @escaping (Error) -> Void
    ) -> Subscription {

        subscribeImp(
            onValue,
            onError
        )
    }

    private let subscribeImp: (
        @escaping (Value) -> Void,
        @escaping (Error) -> Void
    ) -> Subscription
}

extension SerializingSubChannel {

    func erase() -> AnySerializingSubChannel<Value> {

        AnySerializingSubChannel(erasing: self)
    }
}

typealias SerializingChannel = SerializingPubChannel & SerializingSubChannel

extension SerializingSubChannel where Self: SerializingPubChannel {


}

public class AnySerializingChannel<Value: Codable> : AnyTypedChannel<Value>, SerializingChannel {

    init<Channel: SerializingChannel>(erasing channel: Channel) where Channel.Value == Value {

        self.pubChannel = channel.erase()
        self.subChannel = channel.erase()

        super.init(
            pubChannel: pubChannel,
            subChannel: subChannel
        )
    }

    public func tryPublish(_ value: Value) throws {

        try pubChannel.tryPublish(value)
    }

    public func subscribe(
        onValue: @escaping (Value) -> Void,
        onError: @escaping (Error) -> Void
    ) -> Subscription {

        subChannel.subscribe(
            onValue: onValue,
            onError: onError
        )
    }

    private let pubChannel: AnySerializingPubChannel<Value>
    private let subChannel: AnySerializingSubChannel<Value>
}
