//
//  Created by Daniel Coleman on 1/6/22.
//

import Foundation
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SimpleSerializingPubChannel<Value: Encodable, Encoder: TopLevelEncoder> : SerializingPubChannel {

    init<UnderlyingChannel: TypedPubChannel>(
        underlyingChannel: UnderlyingChannel,
        encoder: Encoder
    ) where UnderlyingChannel.Value == Encoder.Output {

        self.underlyingChannel = underlyingChannel.erase()
        self.encoder = encoder
    }

    func tryPublish(_ value: Value) throws {

        let encoded = try encoder.encode(value)

        underlyingChannel.publish(encoded)
    }

    private let underlyingChannel: AnyTypedPubChannel<Encoder.Output>
    private let encoder: Encoder
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SimpleSerializingSubChannel<Value: Decodable, Decoder: TopLevelDecoder> : SerializingSubChannel {

    init<UnderlyingChannel: TypedChannel>(
        underlyingChannel: UnderlyingChannel,
        decoder: Decoder
    ) where UnderlyingChannel.Value == Decoder.Input {

        self.underlyingChannel = underlyingChannel.erase()
        self.decoder = decoder

        let valueChannel = self.valueChannel
        let errorChannel = self.errorChannel

        self.underlyingSubscription = underlyingChannel.subscribe { encoded in

            do {

                let value = try decoder.decode(Value.self, from: encoded)
                valueChannel.publish(value)
            }
            catch(let error) {

                errorChannel.publish(error)
                return
            }
        }
    }

    private func receive(_ encoded: Decoder.Input) {

        do {

            let value = try decoder.decode(Value.self, from: encoded)
            valueChannel.publish(value)
        }
        catch(let error) {

            errorChannel.publish(error)
            return
        }
    }

    func subscribe(
        onValue: @escaping (Value) -> (),
        onError: @escaping (Error) -> ()
    ) -> Subscription {

        let valueSubscription = valueChannel.subscribe(onValue)
        let errorSubscription = errorChannel.subscribe(onError)

        return AggregateSubscription([
            valueSubscription,
            errorSubscription
        ])
    }

    func subscribe(_ handler: @escaping (Value) -> Void) -> Subscription {

        valueChannel.subscribe(handler)
    }

    private let underlyingChannel: AnyTypedSubChannel<Decoder.Input>
    private let decoder: Decoder

    private let valueChannel: AnyTypedChannel<Value> = SimpleChannel().asTypedChannel()
    private let errorChannel: AnyTypedChannel<Error> = SimpleChannel().asTypedChannel()

    private let underlyingSubscription: Subscription
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
class SimpleSerializingChannel<Value: Codable, Encoder: TopLevelEncoder, Decoder: TopLevelDecoder> : SerializingChannel where Decoder.Input == Encoder.Output {

    init<UnderlyingChannel: TypedChannel>(
        underlyingChannel: UnderlyingChannel,
        decoder: Decoder,
        encoder: Encoder
    ) where UnderlyingChannel.Value == Decoder.Input {

        self.pubChannel = SimpleSerializingPubChannel(
            underlyingChannel: underlyingChannel,
            encoder: encoder
        ).erase()

        self.subChannel = SimpleSerializingSubChannel(
            underlyingChannel: underlyingChannel,
            decoder: decoder
        ).erase()
    }

    func tryPublish(_ value: Value) throws {

        try pubChannel.tryPublish(value)
    }

    func subscribe(
        onValue: @escaping (Value) -> (),
        onError: @escaping (Error) -> ()
    ) -> Subscription {

        subChannel.subscribe(
            onValue: onValue,
            onError: onError
        )
    }

    private let pubChannel: AnySerializingPubChannel<Value>
    private let subChannel: AnySerializingSubChannel<Value>
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
typealias SimpleJSONChannel<Value: Codable> = SimpleSerializingChannel<Value, JSONEncoder, JSONDecoder>

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension SimpleSerializingChannel where Decoder == JSONDecoder, Encoder == JSONEncoder {

    convenience init<UnderlyingChannel: TypedChannel>(
        underlyingChannel: UnderlyingChannel
    ) where UnderlyingChannel.Value == Decoder.Input {

        self.init(
            underlyingChannel: underlyingChannel,
            decoder: JSONDecoder(),
            encoder: JSONEncoder()
        )
    }
}
