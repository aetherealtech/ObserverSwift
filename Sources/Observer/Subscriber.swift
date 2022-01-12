//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation

protocol Subscriber: AnyObject {

    func receive<ReceivedValue>(_ value: ReceivedValue)
}

class TypeMatchingSubscriber<Value> : Subscriber {

    init(handler: @escaping (Value) -> Void) {

        self.handler = handler
    }

    func receive<ReceivedValue>(_ value: ReceivedValue) {

        guard let matchingValue = value as? Value else {
            return
        }

        handler(matchingValue)
    }

    private let handler: (Value) -> Void
}
