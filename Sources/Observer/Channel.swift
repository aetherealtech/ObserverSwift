//
// Created by Daniel Coleman on 11/18/21.
//

import Foundation

public protocol PubChannel : SerializingPubChannel {

    func publish<Value>(_ value: Value)
}

public protocol SubChannel : SerializingSubChannel {

    func subscribe<Value>(_ handler: @escaping (Value) -> Void) -> Subscription
}

public typealias Channel = PubChannel & SubChannel
