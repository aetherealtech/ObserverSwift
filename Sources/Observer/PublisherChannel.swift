//
//  Created by Daniel Coleman on 3/21/24.
//

import Combine
import Synchronization

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct ThrowingPublisherChannel<Publisher: Combine.Publisher>: SubChannel {
    public final class Subscription: Observer.Subscription, Subscriber {
        public typealias Input = Publisher.Output
        public typealias Failure = Publisher.Failure
        
        init(
            handler: @escaping @Sendable (Result<Input, Failure>) -> Void
        ) {
            self.handler = handler
        }
        
        public func receive(subscription: any Combine.Subscription) {
            _subscription.wrappedValue = subscription
            subscription.request(.unlimited)
        }
        
        public func receive(_ input: Input) -> Subscribers.Demand {
            handler(.success(input))
            return .none
        }
        
        public func receive(completion: Subscribers.Completion<Failure>) {
            if case let .failure(error) = completion {
                handler(.failure(error))
            }
        }
        
        public func cancel() {
            _subscription.write { subscription in
                subscription?.cancel()
                subscription = nil
            }
        }
 
        private let handler: @Sendable (Result<Input, Failure>) -> Void
        private let _subscription = Synchronized<(any Combine.Subscription)?>(wrappedValue: nil)
    }
    
    public init(
        publisher: Publisher
    ) {
        self._publisher = .init(wrappedValue: publisher)
        
        let broadcaster = _broadcaster.wrappedValue
        
        _subscription = .init(
            wrappedValue: .init(publisher
                .multicast(subject: broadcaster)
                .connect()
            )
        )
    }

    public func subscribe(_ handler: @escaping @Sendable (Result<Publisher.Output, Publisher.Failure>) -> Void) -> Subscription {
        let subscription = Subscription(handler: handler)
        _broadcaster.wrappedValue.receive(subscriber: subscription)
        return subscription
    }

    public var publisher: Publisher { _publisher.wrappedValue }
    
    private let _publisher: Synchronized<Publisher>
    private let _broadcaster = Synchronized<PassthroughSubject<Publisher.Output, Publisher.Failure>>(wrappedValue: .init())
    private let _subscription: Synchronized<AnyCancellable>
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct PublisherChannel<Publisher: Combine.Publisher>: SubChannel where Publisher.Failure == Never {
    public init(
        publisher: Publisher
    ) {
        publisherChannel = .init(publisher: publisher)
    }

    public func subscribe(_ handler: @escaping @Sendable (Publisher.Output) -> Void) -> ThrowingPublisherChannel<Publisher>.Subscription {
        publisherChannel.subscribe { result in
            handler(try! result.get())
        }
    }

    public var publisher: Publisher { publisherChannel.publisher }
    
    private let publisherChannel: ThrowingPublisherChannel<Publisher>
}
