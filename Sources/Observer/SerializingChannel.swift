//
//  Created by Daniel Coleman on 1/6/22.
//

import Foundation
import Combine
import Synchronization

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct SerializingPubChannel<
    Base: PubChannel,
    Value: Encodable,
    Encoder: TopLevelEncoder
>: PubChannel where Encoder.Output == Base.Value {
    public init(
        base: Base,
        encoder: Encoder,
        encodingErrorHandler: (@Sendable (Error) -> Void)? = nil
    ) {
        self.base = base
        self._encoder = .init(wrappedValue: encoder)
        self.encodingErrorHandler = encodingErrorHandler
    }

    public func publish(_ value: Value) {
        do {
            base.publish(try encoder.encode(value))
        } catch(let error) {
            encodingErrorHandler?(error)
        }
    }

    public let base: Base
    public var encoder: Encoder { _encoder.wrappedValue }
    
    private let _encoder: Synchronized<Encoder>
    private let encodingErrorHandler: (@Sendable (Error) -> Void)?
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension PubChannel {
    func encoded<
        Value: Encodable,
        Encoder: TopLevelEncoder
    >(
        to type: Value.Type = Value.self,
        encoder: Encoder,
        encodingErrorHandler: (@Sendable (Error) -> Void)? = nil
    ) -> SerializingPubChannel<Self, Value, Encoder> where Encoder.Output == Value {
        .init(
            base: self,
            encoder: encoder,
            encodingErrorHandler: encodingErrorHandler
        )
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct SerializingSubChannel<
    Base: SubChannel,
    Value: Decodable,
    Decoder: TopLevelDecoder
>: SubChannel where Decoder.Input == Base.Value {
    public init(
        base: Base,
        decoder: Decoder,
        decodingErrorHandler: (@Sendable (Error) -> Void)? = nil
    ) {
        self.base = base
        self._decoder = .init(wrappedValue: decoder)
        self.decodingErrorHandler = decodingErrorHandler

        let outputChannel = self.outputChannel

        underlyingSubscription = base.subscribe { [_decoder] encoded in
            do {
                let value = try _decoder.wrappedValue.decode(Value.self, from: encoded)
                outputChannel.publish(value)
            } catch {
                decodingErrorHandler?(error)
            }
        }
    }

    public func subscribe(_ handler: @escaping @Sendable (Value) -> Void) -> SimpleChannel<Value>.Subscription {
        outputChannel.subscribe(handler)
    }

    public let base: Base
    public var decoder: Decoder { _decoder.wrappedValue }
    
    private let _decoder: Synchronized<Decoder>
    private let decodingErrorHandler: (@Sendable (Error) -> Void)?
    private let outputChannel = SimpleChannel<Value>()
    private let underlyingSubscription: Base.Subscription
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension SubChannel {
    func decoded<
        Value: Encodable,
        Decoder: TopLevelDecoder
    >(
        to type: Value.Type = Value.self,
        decoder: Decoder,
        decodingErrorHandler: (@Sendable (Error) -> Void)? = nil
    ) -> SerializingSubChannel<Self, Value, Decoder> where Decoder.Input == Value {
        .init(
            base: self,
            decoder: decoder,
            decodingErrorHandler: decodingErrorHandler
        )
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct SerializingChannel<
    Base: Channel,
    Value: Codable,
    Encoder: TopLevelEncoder,
    Decoder: TopLevelDecoder
> : Channel where Decoder.Input == Encoder.Output, Encoder.Output == Base.Value {
    public init(
        base: Base,
        encoder: Encoder,
        decoder: Decoder,
        decodingErrorHandler: (@Sendable (Error) -> Void)? = nil,
        encodingErrorHandler: (@Sendable (Error) -> Void)? = nil
    ) {
        pubChannel = SerializingPubChannel(
            base: base,
            encoder: encoder,
            encodingErrorHandler: encodingErrorHandler
        )

        subChannel = SerializingSubChannel(
            base: base,
            decoder: decoder,
            decodingErrorHandler: decodingErrorHandler
        )
    }

    public init(
        base: Base,
        encoder: Encoder,
        decoder: Decoder,
        errorHandler: (@Sendable (Error) -> Void)? = nil
    ) {
        self.init(
            base: base,
            encoder: encoder,
            decoder: decoder,
            decodingErrorHandler: errorHandler,
            encodingErrorHandler: errorHandler
        )
    }

    public func publish(_ value: Value) {
        pubChannel.publish(value)
    }

    public func subscribe(_ handler: @escaping @Sendable (Value) -> ()) -> SerializingSubChannel<Base, Value, Decoder>.Subscription {
        subChannel.subscribe(handler)
    }
    
    public var base: Base { pubChannel.base }
    public var encoder: Encoder { pubChannel.encoder }
    public var decoder: Decoder { subChannel.decoder }

    private let pubChannel: SerializingPubChannel<Base, Value, Encoder>
    private let subChannel: SerializingSubChannel<Base, Value, Decoder>
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension PubChannel where Self: SubChannel {
    func coded<
        Value: Codable,
        Encoder: TopLevelEncoder,
        Decoder: TopLevelDecoder
    >(
        to type: Value.Type = Value.self,
        encoder: Encoder,
        decoder: Decoder,
        decodingErrorHandler: (@Sendable (Error) -> Void)? = nil,
        encodingErrorHandler: (@Sendable (Error) -> Void)? = nil
    ) -> SerializingChannel<Self, Value, Encoder, Decoder> where Decoder.Input == Value, Encoder.Output == Value {
        .init(
            base: self,
            encoder: encoder,
            decoder: decoder,
            decodingErrorHandler: decodingErrorHandler,
            encodingErrorHandler: encodingErrorHandler
        )
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
typealias JSONChannel<Base: ChannelOf<Data>, Value: Codable> = SerializingChannel<Base, Value, JSONEncoder, JSONDecoder>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension PubChannel where Self: SubChannel, Value == Data {
    func jsonCoded<
        Value: Codable
    >(
        to type: Value.Type = Value.self,
        decodingErrorHandler: (@Sendable (Error) -> Void)? = nil,
        encodingErrorHandler: (@Sendable (Error) -> Void)? = nil
    ) -> SerializingChannel<Self, Value, JSONEncoder, JSONDecoder> {
        .init(
            base: self,
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            decodingErrorHandler: decodingErrorHandler,
            encodingErrorHandler: encodingErrorHandler
        )
    }
    
    func jsonCoded<
        Value: Codable
    >(
        to type: Value.Type = Value.self,
        errorHandler: (@Sendable (Error) -> Void)? = nil
    ) -> SerializingChannel<Self, Value, JSONEncoder, JSONDecoder> {
        .init(
            base: self,
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            decodingErrorHandler: errorHandler,
            encodingErrorHandler: errorHandler
        )
    }
}
