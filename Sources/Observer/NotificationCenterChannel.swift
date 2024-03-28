//
// Created by Daniel Coleman on 11/20/21.
//

import Foundation
import Synchronization

public struct NotificationCenterChannel: Channel {
    public struct Subscription: Observer.Subscription {
        init(
            notificationCenter: NotificationCenter,
            subscriber: NSObjectProtocol
        ) {

            self.notificationCenter = notificationCenter
            self._subscriber = .init(wrappedValue: subscriber)
        }

        public func cancel() {
            notificationCenter?.removeObserver(_subscriber.wrappedValue)
        }

        private weak var notificationCenter: NotificationCenter?
        private let _subscriber: Synchronized<NSObjectProtocol>
    }
    
    public typealias Value = (object: Any?, userInfo: [AnyHashable : Any]?)

    init(
        notificationCenter: NotificationCenter,
        name: Notification.Name,
        queue: OperationQueue
    ) {

        self.notificationCenter = notificationCenter
        self.name = name
        self.queue = queue
    }

    public func publish(_ value: Value) {
        notificationCenter.post(
            name: name,
            object: value.object,
            userInfo: value.userInfo
        )
    }

    public func subscribe(_ handler: @escaping @Sendable (Value) -> Void) -> Subscription {
        let subscriber = notificationCenter.addObserver(
            forName: name,
            object: nil,
            queue: queue
        ) { notification in
            handler((
                notification.object,
                notification.userInfo
            ))
        }

        return .init(
            notificationCenter: notificationCenter,
            subscriber: subscriber
        )
    }

    public let notificationCenter: NotificationCenter
    public let name: Notification.Name
    public let queue: OperationQueue
}

public extension NotificationCenter {
    func channel(
        for name: Notification.Name,
        queue: OperationQueue = .main
    ) -> NotificationCenterChannel {
        .init(
            notificationCenter: self,
            name: name,
            queue: queue
        )
    }
}
