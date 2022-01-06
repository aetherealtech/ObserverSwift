//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation
import Combine

public protocol SerializingPubChannel {

    func publish<Event: Encodable>(_ event: Event)
}

public protocol SerializingSubChannel {

    func subscribe<Event: Decodable>(_ handler: @escaping (Event) -> Void) -> Subscription
}

public typealias SerializingChannel = SerializingPubChannel & SerializingSubChannel
