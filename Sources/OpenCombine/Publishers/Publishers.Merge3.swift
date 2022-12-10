//
//  File.swift
//  
//
//  Created by baiwhte on 2022/12/8.
//

extension Publisher {
    
    /// Combines elements from this publisher with those from two other publishers, delivering an interleaved sequence of elements.
    ///
    /// Use merge(with:_:) when you want to receive a new element whenever any of the upstream publishers emits an element.
    /// To receive tuples of the most-recent value from all the upstream publishers whenever any of them emit a value, use combineLatest(_:_:_:).
    /// To combine elements from multiple upstream publishers, use zip(_:_:_:).
    ///
    /// In this example, as merge(with:_:) receives input from the upstream publishers, it republishes the interleaved elements to the downstream:
    ///
    ///     let pubA = PassthroughSubject<Int, Never>()
    ///     let pubB = PassthroughSubject<Int, Never>()
    ///     let pubC = PassthroughSubject<Int, Never>()
    ///
    ///     cancellable = pubA
    ///         .merge(with: pubB, pubC)
    ///         .sink { print("\($0)", terminator: " " ) }
    ///
    ///     pubA.send(1)
    ///     pubB.send(40)
    ///     pubC.send(90)
    ///
    ///     pubA.send(2)
    ///     pubB.send(50)
    ///     pubC.send(100)
    ///
    ///     //Prints: "1 40 90 2 50 100"
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error,
    /// the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<B, C>(
        with b: B,
        _ c: C
    ) -> Publishers.Merge3<Self, B, C>
    where B : Publisher, C : Publisher,
          Self.Failure == B.Failure, Self.Output == B.Output, B.Failure == C.Failure,
          B.Output == C.Output
    {
        .init(self, b, c)
    }
}

extension Publishers.Merge3 {
    public func merge<Z, Y>(
        with z: Z,
        _ y: Y
    ) -> Publishers.Merge5<A, B, C, Z, Y> where Z : Publisher, Y : Publisher, C.Failure == Z.Failure, C.Output == Z.Output, Z.Failure == Y.Failure, Z.Output == Y.Output {
        Publishers.Merge5(a, b, c, z, y)
    }
    
    public func merge<Z, Y, X>(
        with z: Z,
        _ y: Y,
        _ x: X
    ) -> Publishers.Merge6<A, B, C, Z, Y, X>
    where Z : Publisher, Y : Publisher, X : Publisher, C.Failure == Z.Failure,
          C.Output == Z.Output, Z.Failure == Y.Failure, Z.Output == Y.Output,
            Y.Failure == X.Failure, Y.Output == X.Output
    {
        Publishers.Merge6(a, b, c, z, y, x)
    }
    
    public func merge<Z, Y, X, W>(
        with z: Z,
        _ y: Y,
        _ x: X,
        _ w: W
    ) -> Publishers.Merge7<A, B, C, Z, Y, X, W>
    where Z : Publisher, Y : Publisher, X : Publisher, W : Publisher,
            C.Failure == Z.Failure, C.Output == Z.Output, Z.Failure == Y.Failure,
            Z.Output == Y.Output, Y.Failure == X.Failure, Y.Output == X.Output,
            X.Failure == W.Failure, X.Output == W.Output
    {
        Publishers.Merge7(a, b, c, z, y, x, w)
    }
    
    public func merge<Z, Y, X, W, V>(
        with z: Z,
        _ y: Y,
        _ x: X,
        _ w: W,
        _ v: V
    ) -> Publishers.Merge8<A, B, C, Z, Y, X, W, V>
    where Z : Publisher, Y : Publisher, X : Publisher, W : Publisher, V : Publisher,
            C.Failure == Z.Failure, C.Output == Z.Output, Z.Failure == Y.Failure, Z.Output == Y.Output, Y.Failure == X.Failure, Y.Output == X.Output, X.Failure == W.Failure, X.Output == W.Output, W.Failure == V.Failure, W.Output == V.Output
    {
        Publishers.Merge8(a, b, c, z, y, x, w, v)
    }

}

extension Publishers {
    /// A publisher created by applying the merge function to three upstream publishers.
    public struct Merge3<A, B, C> where A : Publisher, B : Publisher, C : Publisher, A.Failure == B.Failure, A.Output == B.Output, B.Failure == C.Failure, B.Output == C.Output {
        
        /// The kind of values published by this publisher.
        ///
        /// This publisher uses its upstream publishers’ common output type.
        public typealias Output = A.Output
        
        /// The kind of errors this publisher might publish.
        ///
        /// This publisher uses its upstream publishers’ common failure type.
        public typealias Failure = A.Failure
        
        /// A publisher to merge
        public let a: A
        
        /// A second publisher to merge.
        public let b: B
        
        /// A third publisher to merge.
        public let c: C
        
        let pubisher: AnyPublisher<A.Output, A.Failure>
        
        /// Creates a publisher created by applying the merge function to two upstream publishers.
        /// - Parameters:
        ///   - a: A publisher to merge
        ///   - b: A second publisher to merge.
        ///   - c: A third publisher to merge.
        init(
            _ a: A,
            _ b: B,
            _ c: C
        ) {
            self.a = a
            self.b = b
            self.c = c
            
            pubisher = Publishers.Sequence(sequence: [a.eraseToAnyPublisher(),
                                                      b.eraseToAnyPublisher(),
                                                      c.eraseToAnyPublisher()])
            .flatMap { $0 }
            .eraseToAnyPublisher()
        }
    }
}

extension Publishers.Merge3: Publisher {
    public func receive<S>(subscriber: S) where S : Subscriber, C.Failure == S.Failure, C.Output == S.Input {
        pubisher.receive(subscriber: subscriber)
    }
}

extension Publishers.Merge3: Equatable where A : Equatable, B : Equatable, C : Equatable {
    /// Available when A conforms to Publisher, A conforms to Equatable, B conforms to Publisher, B conforms to Equatable, A.Failure is B.Failure, and A.Output is B.Output.
    public static func == (lhs: Publishers.Merge3<A, B, C>, rhs: Publishers.Merge3<A, B, C>) -> Bool {
        rhs.a == lhs.a && lhs.b == rhs.b && lhs.c == rhs.c
    }
}
