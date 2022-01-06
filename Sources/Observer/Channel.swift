//
// Created by Daniel Coleman on 11/18/21.
//

import Foundation

public protocol PubChannel : SerializingPubChannel {

    func publish<Event>(_ event: Event)
}

public protocol SubChannel : SerializingSubChannel {

    func subscribe<Event>(_ handler: @escaping (Event) -> Void) -> Subscription
}

public typealias Channel = PubChannel & SubChannel