//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation

extension NotificationCenter : Channel {

    public func publish<Event>(_ event: Event) {

        self.post(name: Self.notificationName, object: event)
    }

    public func subscribe<Event>(_ handler: @escaping (Event) -> Void) -> Subscription {

        let subscriber = self.addObserver(forName: Self.notificationName, object: nil, queue: .main) { notification in

            guard let event = notification.object as? Event else { return }

            handler(event)
        }
        
        return NotificationCenterSubscription(
            notificationCenter: self,
            subscriber: subscriber
        )
    }

    class NotificationCenterSubscription : Subscription {

        init(
            notificationCenter: NotificationCenter,
            subscriber: NSObjectProtocol
        ) {

            self.notificationCenter = notificationCenter
            self.subscriber = subscriber
        }

        deinit {

            guard let notificationCenter = self.notificationCenter else { return }

            notificationCenter.removeObserver(subscriber)
        }

        private weak var notificationCenter: NotificationCenter?
        private let subscriber: NSObjectProtocol
    }

    private static let notificationName = Notification.Name(rawValue: ObjectIdentifier(NotificationCenter.self).debugDescription)
}
