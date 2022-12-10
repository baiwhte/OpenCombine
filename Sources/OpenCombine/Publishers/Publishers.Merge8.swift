//
//  File.swift
//  
//
//  Created by baiwhte on 2022/12/8.
//

extension Publisher {
    /// Combines elements from this publisher with those from seven other publishers, delivering an interleaved sequence of elements.
    ///
    /// Use merge(with:_:_:_:_:_:_:) when you want to receive a new element whenever any of the upstream publishers emits an element.
    /// To receive tuples of the most-recent value from all the upstream publishers whenever any of them emit a value, use combineLatest(_:_:_:).
    /// To combine elements from multiple upstream publishers, use zip(_:_:_:).
    ///
    /// In this example, as merge(with:_:_:_:_:_:_:) receives input from the upstream publishers, it republishes the interleaved elements to the downstream:
    ///
    ///     let pubA = PassthroughSubject<Int, Never>()
    ///     let pubB = PassthroughSubject<Int, Never>()
    ///     let pubC = PassthroughSubject<Int, Never>()
    ///     let pubD = PassthroughSubject<Int, Never>()
    ///     let pubE = PassthroughSubject<Int, Never>()
    ///     let pubF = PassthroughSubject<Int, Never>()
    ///     let pubG = PassthroughSubject<Int, Never>()
    ///     let pubH = PassthroughSubject<Int, Never>()
    ///
    ///     cancellable = pubA
    ///         .merge(with: pubB, pubC, pubD, pubE, pubF, pubG, pubH)
    ///         .sink { print("\($0)", terminator: " " ) }
    ///
    ///     pubA.send(1)
    ///     pubB.send(40)
    ///     pubC.send(90)
    ///     pubD.send(-1)
    ///     pubE.send(33)
    ///     pubF.send(44)
    ///     pubG.send(54)
    ///     pubH.send(1000)
    ///
    ///     pubA.send(2)
    ///     pubB.send(50)
    ///     pubC.send(100)
    ///     pubD.send(-2)
    ///     pubE.send(33)
    ///     pubF.send(33)
    ///     pubG.send(54)
    ///     pubH.send(1001)
    ///
    ///     //Prints: "1 40 90 -1 33 44 54 1000 2 50 100 -2 33 33 54 1001"
    ///
    /// The merged publisher continues to emit elements until all upstream publishers finish. If an upstream publisher produces an error,
    /// the merged publisher fails with that error.
    ///
    ///
    /// - Parameters:
    ///   - b: A second publisher.
    ///   - c: A third publisher.
    ///   - d: A fourth publisher.
    ///   - e: A fifth publisher.
    ///   - f: A sixth publisher.
    ///   - g: A seventh publisher.
    ///   - h: An eighth publisher.
    /// - Returns: A publisher that emits an event when any upstream publisher emits an event.
    public func merge<B, C, D, E, F, G, H>(
        with b: B,
        _ c: C,
        _ d: D,
        _ e: E,
        _ f: F,
        _ g: G,
        _ h: H
    ) -> Publishers.Merge8<Self, B, C, D, E, F, G, H>
    where B : Publisher, C : Publisher, D : Publisher, E : Publisher, F : Publisher, G : Publisher, H : Publisher,
            Self.Failure == B.Failure, Self.Output == B.Output, B.Failure == C.Failure, B.Output == C.Output,
            C.Failure == D.Failure, C.Output == D.Output, D.Failure == E.Failure, D.Output == E.Output,
            E.Failure == F.Failure, E.Output == F.Output, F.Failure == G.Failure, F.Output == G.Output,
            G.Failure == H.Failure, G.Output == H.Output {
        .init(self, b, c, d, e, f, g, h)
    }

}

extension Publishers {
    public struct Merge8<A, B, C, D, E, F, G, H> where A : Publisher, B : Publisher, C : Publisher, D : Publisher,
                                                       E : Publisher, F : Publisher, G : Publisher, H : Publisher,
                                                       A.Failure == B.Failure, A.Output == B.Output, B.Failure == C.Failure,
                                                       B.Output == C.Output, C.Failure == D.Failure, C.Output == D.Output,
                                                       D.Failure == E.Failure, D.Output == E.Output, E.Failure == F.Failure,
                                                       E.Output == F.Output, F.Failure == G.Failure, F.Output == G.Output,
                                                       G.Failure == H.Failure, G.Output == H.Output {
        
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
        
        /// A fourth publisher to merge.
        public let d: D
        
        /// A fifth publisher to merge.
        public let e: E
        
        /// A sixth publisher to merge.
        public let f: F
        
        /// A seventh publisher to merge.
        public let g: G
        
        /// An eighth publisher to merge.
        public let h: H
        
        let pubisher: AnyPublisher<A.Output, A.Failure>
        
        /// Creates a publisher created by applying the merge function to two upstream publishers.
        /// - Parameters:
        ///   - a: A publisher to merge
        ///   - b: A second publisher to merge.
        ///   - c: A third publisher to merge.
        ///   - d: A fourth publisher to merge.
        ///   - e: A fifth publisher to merge.
        ///   - f: A sixth publisher to merge.
        ///   - g: A seventh publisher to merge.
        ///   - h: An eighth publisher to merge.
        init(
            _ a: A,
            _ b: B,
            _ c: C,
            _ d: D,
            _ e: E,
            _ f: F,
            _ g: G,
            _ h: H
        ) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
            self.g = g
            self.h = h
            
            pubisher = Publishers.Sequence(sequence: [a.eraseToAnyPublisher(),
                                                      b.eraseToAnyPublisher(),
                                                      c.eraseToAnyPublisher(),
                                                      d.eraseToAnyPublisher(),
                                                      e.eraseToAnyPublisher(),
                                                      f.eraseToAnyPublisher(),
                                                      g.eraseToAnyPublisher(),
                                                      h.eraseToAnyPublisher()])
            .flatMap { $0 }
            .eraseToAnyPublisher()
        }
    }
}

extension Publishers.Merge8: Publisher {
    public func receive<S>(subscriber: S) where S : Subscriber, H.Failure == S.Failure, H.Output == S.Input {
        pubisher.receive(subscriber: subscriber)
    }
}

extension Publishers.Merge8: Equatable where A : Equatable, B : Equatable, C : Equatable, D : Equatable, E : Equatable, F : Equatable, G : Equatable, H : Equatable {
    /// Available when A conforms to Publisher, A conforms to Equatable, B conforms to Publisher, B conforms to Equatable, A.Failure is B.Failure, and A.Output is B.Output.
    public static func == (lhs: Publishers.Merge8<A, B, C, D, E, F, G, H>, rhs: Publishers.Merge8<A, B, C, D, E, F, G, H>) -> Bool {
        rhs.a == lhs.a && lhs.b == rhs.b && lhs.c == rhs.c && lhs.d == rhs.d && lhs.e == rhs.e && lhs.f == rhs.f && lhs.g == rhs.g && lhs.h == rhs.h
    }
}
