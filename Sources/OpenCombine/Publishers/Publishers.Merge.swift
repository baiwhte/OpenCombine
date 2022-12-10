//
//  Publishers.Merge.swift
//  
//
//  Created by baiwhte on 2022/12/8.
//

extension Publisher {
    
    /// Combines elements from this publisher with those from other publishers, delivering an interleaved sequence of elements.
    ///
    /// Use merge(with:) when you want to receive a new element whenever any of the upstream publishers emits an element.
    /// To receive tuples of the most-recent value from all the upstream publishers whenever any of them emit a value, use combineLatest(_:_:_:).
    /// To combine elements from multiple upstream publishers, use zip(_:_:_:).
    ///
    /// In this example, as merge(with:_:) receives input from the upstream publishers, it republishes the interleaved elements to the downstream:
    ///
    ///     let pubA = PassthroughSubject<Int, Never>()
    ///     let pubB = PassthroughSubject<Int, Never>()
    ///
    ///     cancellable = pubA
    ///         .merge(with: pubB)
    ///         .sink { print("\($0)", terminator: " " ) }
    ///
    ///     pubA.send(1)
    ///     pubB.send(40)
    ///
    ///     pubA.send(2)
    ///     pubB.send(50)
    ///
    ///     //Prints: "1 40 2 50"
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error,
    /// the merged publisher fails with that error.
    ///
    /// - Parameters:
    ///   - other: A second publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<P>(with other: P) -> Publishers.Merge<Self, P> where P : Publisher, Self.Failure == P.Failure, Self.Output == P.Output {
        .init(self, other)
    }
}

extension Publishers.Merge {
    public func merge<Z, Y>(
        with z: Z,
        _ y: Y
    ) -> Publishers.Merge4<A, B, Z, Y> where Z : Publisher, Y : Publisher, B.Failure == Z.Failure, B.Output == Z.Output, Z.Failure == Y.Failure, Z.Output == Y.Output {
        Publishers.Merge4(a, b, z, y)
    }
    
    public func merge<Z, Y, X>(
        with z: Z,
        _ y: Y,
        _ x: X
    ) -> Publishers.Merge5<A, B, Z, Y, X>
    where Z : Publisher, Y : Publisher, X : Publisher, B.Failure == Z.Failure,
          B.Output == Z.Output, Z.Failure == Y.Failure, Z.Output == Y.Output,
          Y.Failure == X.Failure, Y.Output == X.Output
    {
        Publishers.Merge5(a, b, z, y, x)
    }
    
    public func merge<Z, Y, X, W>(
        with z: Z,
        _ y: Y,
        _ x: X,
        _ w: W
    ) -> Publishers.Merge6<A, B, Z, Y, X, W>
    where Z : Publisher, Y : Publisher, X : Publisher, W : Publisher,
          B.Failure == Z.Failure, B.Output == Z.Output, Z.Failure == Y.Failure,
          Z.Output == Y.Output, Y.Failure == X.Failure, Y.Output == X.Output,
          X.Failure == W.Failure, X.Output == W.Output
    {
        Publishers.Merge6(a, b, z, y, x, w)
    }
    
    public func merge<Z, Y, X, W, V>(
        with z: Z,
        _ y: Y,
        _ x: X,
        _ w: W,
        _ v: V
    ) -> Publishers.Merge7<A, B, Z, Y, X, W, V>
    where Z : Publisher, Y : Publisher, X : Publisher, W : Publisher, V : Publisher,
          B.Failure == Z.Failure, B.Output == Z.Output, Z.Failure == Y.Failure, Z.Output == Y.Output, Y.Failure == X.Failure, Y.Output == X.Output, X.Failure == W.Failure, X.Output == W.Output, W.Failure == V.Failure, W.Output == V.Output
    {
        Publishers.Merge7(a, b, z, y, x, w, v)
    }
    
    public func merge<Z, Y, X, W, V, U>(
        with z: Z,
        _ y: Y,
        _ x: X,
        _ w: W,
        _ v: V,
        _ u: U
    ) -> Publishers.Merge8<A, B, Z, Y, X, W, V, U> where Z : Publisher, Y : Publisher, X : Publisher, W : Publisher, V : Publisher, U : Publisher, B.Failure == Z.Failure, B.Output == Z.Output, Z.Failure == Y.Failure, Z.Output == Y.Output, Y.Failure == X.Failure, Y.Output == X.Output, X.Failure == W.Failure, X.Output == W.Output, W.Failure == V.Failure, W.Output == V.Output, V.Failure == U.Failure, V.Output == U.Output
    {
        Publishers.Merge8(a, b, z, y, x, w, v, u)
    }
}

extension Publishers {
    /// A publisher created by applying the merge function to two upstream publishers.
    public struct Merge<A, B> where A : Publisher, B : Publisher, A.Failure == B.Failure, A.Output == B.Output {
        
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
        
        let pubisher: AnyPublisher<A.Output, A.Failure>
        
        /// Creates a publisher created by applying the merge function to two upstream publishers.
        /// - Parameters:
        ///   - a: A publisher to merge
        ///   - b: A second publisher to merge.
        init(
            _ a: A,
            _ b: B
        ) {
            self.a = a
            self.b = b
            
            pubisher = Publishers.Sequence(sequence: [a.eraseToAnyPublisher(),
                                                      b.eraseToAnyPublisher()])
            .flatMap { $0 }
            .eraseToAnyPublisher()
        }
    }
}

extension Publishers.Merge: Publisher {
    public func receive<S>(subscriber: S) where S : Subscriber, B.Failure == S.Failure, B.Output == S.Input {
        pubisher.receive(subscriber: subscriber)
    }
}

extension Publishers.Merge: Equatable where A : Equatable, B : Equatable {
    /// Available when A conforms to Publisher, A conforms to Equatable, B conforms to Publisher, B conforms to Equatable, A.Failure is B.Failure, and A.Output is B.Output.
    public static func == (lhs: Publishers.Merge<A, B>, rhs: Publishers.Merge<A, B>) -> Bool {
        rhs.a == lhs.a && lhs.b == rhs.b
    }
}
