//
//  Created by Daniel Coleman on 3/21/24.
//

import Combine
import Synchronization

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct PublisherChannel<Publisher: Combine.Publisher>: SubChannel where Publisher.Failure == Never {
    public final class Subscription: Observer.Subscription, Subscriber {
        public typealias Input = Publisher.Output
        public typealias Failure = Never
        
        init(
            handler: @escaping @Sendable (Value) -> Void
        ) {
            self.handler = handler
        }
        
        public func receive(subscription: any Combine.Subscription) {
            _subscription.wrappedValue = subscription
            subscription.request(.unlimited)
        }
        
        public func receive(_ input: Input) -> Subscribers.Demand {
            handler(input)
            return .none
        }
        
        public func receive(completion: Subscribers.Completion<Never>) {}
        
        public func cancel() {
            _subscription.write { subscription in
                subscription?.cancel()
                subscription = nil
            }
        }
 
        private let handler: @Sendable (Input) -> Void
        private let _subscription = Synchronized<(any Combine.Subscription)?>(wrappedValue: nil)
    }
    
    public init(
        publisher: Publisher
    ) {
        self._publisher = .init(wrappedValue: publisher)
        
        let broadcaster = _broadcaster.wrappedValue
        
        _subscription = .init(
            wrappedValue: .init(broadcaster
                .multicast(subject: broadcaster)
                .connect()
            )
        )
    }

    public func subscribe(_ handler: @escaping @Sendable (Publisher.Output) -> Void) -> Subscription {
        let subscription = Subscription(handler: handler)
        _broadcaster.wrappedValue.receive(subscriber: subscription)
        return subscription
    }

    public var publisher: Publisher { _publisher.wrappedValue }
    
    private let _publisher: Synchronized<Publisher>
    private let _broadcaster = Synchronized<PassthroughSubject<Publisher.Output, Never>>(wrappedValue: .init())
    private let _subscription: Synchronized<AnyCancellable>
}
