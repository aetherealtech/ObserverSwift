//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation

protocol Subscriber: AnyObject {

    func receive<ReceivedEvent>(_ event: ReceivedEvent)
}

class TypeMatchingSubscriber<Event> : Subscriber {

    init(handler: @escaping (Event) -> Void) {

        self.handler = handler
    }

    func receive<ReceivedEvent>(_ event: ReceivedEvent) {

        guard let matchingEvent = event as? Event else {
            return
        }

        handler(matchingEvent)
    }

    private let handler: (Event) -> Void
}
