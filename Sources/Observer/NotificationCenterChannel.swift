//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation

extension NotificationCenter : Channel {

    public func publish<Value>(_ value: Value) {

        self.post(name: Self.notificationName, object: value)
    }

    public func subscribe<Value>(_ handler: @escaping (Value) -> Void) -> Subscription {

        let subscriber = self.addObserver(forName: Self.notificationName, object: nil, queue: .main) { notification in

            guard let value = notification.object as? Value else { return }

            handler(value)
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
