 //
//  Created by Daniel Coleman on 3/21/24.
//

import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension PublisherChannel: PubChannel where Publisher: Subject {
    public func publish(_ value: Publisher.Output) {
        publisher.send(value)
    }
}
