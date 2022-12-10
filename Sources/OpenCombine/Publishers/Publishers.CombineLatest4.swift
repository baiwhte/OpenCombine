//
//  Publishers.combineLatest4.swift
//  
//
//  Created by baiwhte on 2022/12/8.
//

extension Publisher {
    /// Subscribes to three additional publishers and invokes a closure upon receiving output from any of the publishers.
    ///
    /// Use combineLatest(_:_:_:) when you want the downstream subscriber to receive a tuple of the most-recent element
    /// from multiple publishers when any of them emit a value. To combine elements from multiple publishers,
    /// use zip(_:_:_:) instead. To receive just the most-recent element from multiple publishers rather than tuples,
    /// use merge(with:_:_:).
    ///
    /// - Tip: The combined publisher doesn’t produce elements until each of its upstream publishers publishes at least one element.
    ///
    /// The combined publisher passes through any requests to all upstream publishers. However, it still obeys the
    /// demand-fulfilling rule of only sending the request amount downstream. If the demand isn’t unlimited, it drops
    /// values from upstream publishers. It implements this by using a buffer size of 1 for each upstream,
    /// and holds the most-recent value in each buffer.
    ///
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value, this publisher never finishes.
    ///
    /// In the example below, combineLatest(_:_:_:) receives input from any of the publishers, combines the latest value from each publisher into a tuple and publishes it:
    ///
    ///         let pub = PassthroughSubject<Int, Never>()
    ///         let pub2 = PassthroughSubject<Int, Never>()
    ///         let pub3 = PassthroughSubject<Int, Never>()
    ///         let pub4 = PassthroughSubject<Int, Never>()
    ///
    ///         cancellable = pub
    ///         .combineLatest(pub2, pub3, pub4)
    ///         .sink { print("Result: \($0).") }
    ///
    ///         pub.send(1)
    ///         pub.send(2)
    ///         pub2.send(2)
    ///         pub3.send(9)
    ///         pub4.send(1)
    ///
    ///         pub.send(3)
    ///         pub2.send(12)
    ///         pub.send(13)
    ///         pub3.send(19)
    ///
    ///         //
    ///         // Prints:
    ///         //  Result: (2, 2, 9, 1).
    ///         //  Result: (3, 2, 9, 1).
    ///         //  Result: (3, 12, 9, 1).
    ///         //  Result: (13, 12, 9, 1).
    ///         //  Result: (13, 12, 19, 1).
    ///
    /// If any individual publisher of the combined set terminates with a failure, this publisher also fails.
    public func combineLatest<P, Q, R>(
        _ publisher1: P,
        _ publisher2: Q,
        _ publisher3: R
    ) -> Publishers.CombineLatest4<Self, P, Q, R> where P : Publisher, Q : Publisher, R : Publisher, Self.Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure {
        .init(self, publisher1, publisher2, publisher3)
    }
    
    /// Subscribes to three additional publishers and invokes a closure upon receiving output from any of the publishers.
    ///
    /// Use combineLatest(_:_:_:_:) when you need to combine the current and 3 additional publishers and transform the values
    /// using a closure in which you specify the published elements, to publish a new element.
    ///
    /// - Tip: The combined publisher doesn’t produce elements until each of its upstream publishers publishes at least one element.
    ///
    /// The combined publisher passes through any requests to all upstream publishers. However, it still obeys the demand-fulfilling
    /// rule of only sending the request amount downstream. If the demand isn’t unlimited, it drops values from upstream publishers.
    /// It implements this by using a buffer size of 1 for each upstream, and holds the most-recent value in each buffer.
    ///
    /// All upstream publishers need to finish for this publisher to finish. If an upstream publisher never publishes a value,
    /// this publisher never finishes.
    /// 
    /// In the example below, as combineLatest(_:_:_:_:) receives the most-recent values published by four publishers, multiplies them together,
    /// and republishes the result:
    ///
    ///         let pub = PassthroughSubject<Int, Never>()
    ///         let pub2 = PassthroughSubject<Int, Never>()
    ///         let pub3 = PassthroughSubject<Int, Never>()
    ///         let pub4 = PassthroughSubject<Int, Never>()
    ///
    ///         cancellable = pub
    ///         .combineLatest(pub2, pub3, pub4) { firstValue, secondValue, thirdValue, fourthValue in
    ///             return firstValue * secondValue * thirdValue * fourthValue
    ///         }
    ///         .sink { print("Result: \($0).") }
    ///
    ///         pub.send(1)
    ///         pub.send(2)
    ///         pub2.send(2)
    ///         pub3.send(9)
    ///         pub4.send(1)
    ///
    ///         pub.send(3)
    ///         pub2.send(12)
    ///         pub.send(13)
    ///         pub3.send(19)
    ///
    ///         // Prints:
    ///         //  Result: 36.     // pub = 2,  pub2 = 2,   pub3 = 9,  pub4 = 1
    ///         //  Result: 54.     // pub = 3,  pub2 = 2,   pub3 = 9,  pub4 = 1
    ///         //  Result: 324.    // pub = 3,  pub2 = 12,  pub3 = 9,  pub4 = 1
    ///         //  Result: 1404.   // pub = 13, pub2 = 12,  pub3 = 9,  pub4 = 1
    ///         //  Result: 2964.   // pub = 13, pub2 = 12,  pub3 = 19, pub4 = 1
    public func combineLatest<P, Q, R, T>(
        _ publisher1: P,
        _ publisher2: Q,
        _ publisher3: R,
        _ transform: @escaping (Self.Output, P.Output, Q.Output, R.Output) -> T
    ) -> Publishers.Map<Publishers.CombineLatest4<Self, P, Q, R>, T> where P : Publisher, Q : Publisher, R : Publisher, Self.Failure == P.Failure, P.Failure == Q.Failure, Q.Failure == R.Failure {
        combineLatest(publisher1, publisher2, publisher3).map(transform)
    }

}

extension Publishers {
    /// A publisher that receives and combines the latest elements from four publishers.
    public struct CombineLatest4<A, B, C, D> where A : Publisher, B : Publisher, C : Publisher, D : Publisher, A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure {
        
        /// The kind of values published by this publisher.
        ///
        /// This publisher produces four-element tuples of the upstream publishers’ output types.
        public typealias Output = (A.Output, B.Output, C.Output, D.Output)
        
        /// The kind of errors this publisher might publish.
        ///
        /// Use `Never` if this `Publisher` does not publish errors.
        public typealias Failure = A.Failure
        
        public let a: A
        
        public let b: B
        
        public let c: C
        
        public let d: D
        
        init(
            _ a: A,
            _ b: B,
            _ c: C,
            _ d: D
        ) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
        }
    }
}

extension Publishers.CombineLatest4: Publisher {
    public func receive<S>(subscriber: S) where S : Subscriber, D.Failure == S.Failure, S.Input == (A.Output, B.Output, C.Output, D.Output) {
        a.combineLatest(b)
            .combineLatest(c)
            .combineLatest(d)
            .map {
                ($0.0.0, $0.0.1, $0.1, $1)
            }
            .receive(subscriber: subscriber)
    }
}

