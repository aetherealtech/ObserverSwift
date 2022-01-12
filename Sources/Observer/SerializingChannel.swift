//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation
import Combine

public protocol SerializingPubChannel {

    func publish<Value: Encodable>(_ value: Value)
}

public protocol SerializingSubChannel {

    func subscribe<Value: Decodable>(_ handler: @escaping (Value) -> Void) -> Subscription
}

public typealias SerializingChannel = SerializingPubChannel & SerializingSubChannel
