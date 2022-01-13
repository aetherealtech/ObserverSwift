//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation

typealias NotificationData = (object: Any?, userInfo: [AnyHashable : Any]?)

extension NotificationCenter {

    func channel(
        for name: Notification.Name,
        queue: OperationQueue = .main
    ) -> AnyTypedChannel<NotificationData> {

        NotificationCenterChannel(
            notificationCenter: self,
            name: name,
            queue: queue
        ).erase()
    }

    class NotificationCenterChannel: TypedChannel {

        typealias Value = NotificationData

        init(
            notificationCenter: NotificationCenter,
            name: Notification.Name,
            queue: OperationQueue
        ) {

            self.notificationCenter = notificationCenter
            self.name = name
            self.queue = queue
        }

        public func publish(_ value: NotificationData) {

            notificationCenter.post(name: name, object: value.object, userInfo: value.userInfo)
        }

        public func subscribe(_ handler: @escaping (NotificationData) -> Void) -> Subscription {

            let subscriber = notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: queue
            ) { notification in

                handler((notification.object, notification.userInfo))
            }

            return NotificationCenterSubscription(
                notificationCenter: notificationCenter,
                subscriber: subscriber
            )
        }

        private let notificationCenter: NotificationCenter
        private let name: Notification.Name
        private let queue: OperationQueue
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
}