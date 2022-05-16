//
//  Created by Daniel Coleman on 1/6/22.
//

import Foundation
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SerializingPubChannel<Value: Encodable, Encoder: TopLevelEncoder> : PubChannel {

    init<UnderlyingChannel: PubChannel>(
        underlyingChannel: UnderlyingChannel,
        encoder: Encoder,
        encodingErrorHandler: ((Error) -> Void)? = nil
    ) where UnderlyingChannel.Value == Encoder.Output {

        self.underlyingChannel = underlyingChannel.erase()
        self.encoder = encoder
        self.encodingErrorHandler = encodingErrorHandler
    }

    func publish(_ value: Value) {

        do {

            let encoded = try encoder.encode(value)

            underlyingChannel.publish(encoded)

        } catch(let error) {

            encodingErrorHandler?(error)
        }
    }

    private let underlyingChannel: AnyPubChannel<Encoder.Output>
    private let encoder: Encoder
    private let encodingErrorHandler: ((Error) -> Void)?
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SerializingSubChannel<Value: Decodable, Decoder: TopLevelDecoder> : SubChannel {

    init<UnderlyingChannel: Channel>(
        underlyingChannel: UnderlyingChannel,
        decoder: Decoder,
        decodingErrorHandler: ((Error) -> Void)? = nil
    ) where UnderlyingChannel.Value == Decoder.Input {

        self.underlyingChannel = underlyingChannel.erase()
        self.decoder = decoder
        self.decodingErrorHandler = decodingErrorHandler

        let outputChannel = self.outputChannel

        underlyingSubscription = underlyingChannel.subscribe { encoded in

            do {

                let value = try decoder.decode(Value.self, from: encoded)
                outputChannel.publish(value)
            }
            catch(let error) {

                decodingErrorHandler?(error)
            }
        }
    }

    func subscribe(_ handler: @escaping (Value) -> Void) -> Subscription {

        outputChannel.subscribe(handler)
    }

    private let underlyingChannel: AnySubChannel<Decoder.Input>
    private let decoder: Decoder
    private let decodingErrorHandler: ((Error) -> Void)?

    private let outputChannel = SimpleChannel<Value>()

    private let underlyingSubscription: Subscription
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SerializingChannel<Value: Codable, Encoder: TopLevelEncoder, Decoder: TopLevelDecoder> : Channel where Decoder.Input == Encoder.Output {

    init<UnderlyingChannel: Channel>(
        underlyingChannel: UnderlyingChannel,
        decoder: Decoder,
        encoder: Encoder,
        decodingErrorHandler: ((Error) -> Void)? = nil,
        encodingErrorHandler: ((Error) -> Void)? = nil
    ) where UnderlyingChannel.Value == Decoder.Input {

        pubChannel = SerializingPubChannel(
            underlyingChannel: underlyingChannel,
            encoder: encoder,
            encodingErrorHandler: encodingErrorHandler
        )

        subChannel = SerializingSubChannel(
            underlyingChannel: underlyingChannel,
            decoder: decoder,
            decodingErrorHandler: decodingErrorHandler
        )
    }

    convenience init<UnderlyingChannel: Channel>(
        underlyingChannel: UnderlyingChannel,
        decoder: Decoder,
        encoder: Encoder,
        errorHandler: ((Error) -> Void)? = nil
    ) where UnderlyingChannel.Value == Decoder.Input {

        self.init(
            underlyingChannel: underlyingChannel,
            decoder: decoder,
            encoder: encoder,
            decodingErrorHandler: errorHandler,
            encodingErrorHandler: errorHandler
        )
    }

    func publish(_ value: Value) {

        pubChannel.publish(value)
    }

    func subscribe(_ handler: @escaping (Value) -> ()) -> Subscription {

        subChannel.subscribe(handler)
    }

    let pubChannel: SerializingPubChannel<Value, Encoder>
    let subChannel: SerializingSubChannel<Value, Decoder>
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
typealias JSONChannel<Value: Codable> = SerializingChannel<Value, JSONEncoder, JSONDecoder>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SerializingChannel where Decoder == JSONDecoder, Encoder == JSONEncoder {

    convenience init<UnderlyingChannel: Channel>(
        underlyingChannel: UnderlyingChannel,
        decodingErrorHandler: ((Error) -> Void)? = nil,
        encodingErrorHandler: ((Error) -> Void)? = nil
    ) where UnderlyingChannel.Value == Decoder.Input {

        self.init(
            underlyingChannel: underlyingChannel,
            decoder: JSONDecoder(),
            encoder: JSONEncoder(),
            decodingErrorHandler: decodingErrorHandler,
            encodingErrorHandler: encodingErrorHandler
        )
    }

    convenience init<UnderlyingChannel: Channel>(
        underlyingChannel: UnderlyingChannel,
        errorHandler: ((Error) -> Void)? = nil
    ) where UnderlyingChannel.Value == Decoder.Input {

        self.init(
            underlyingChannel: underlyingChannel,
            decoder: JSONDecoder(),
            encoder: JSONEncoder(),
            errorHandler: errorHandler
        )
    }
}
