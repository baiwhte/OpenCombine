//
//  File.swift
//  
//
//  Created by baiwhte on 2022/12/9.
//

internal protocol SideSubscriber {
    /// The kind of values this subscriber receives.
    associatedtype Input
    
    /// The kind of errors this subscriber might receive.
    ///
    /// Use `Never` if this `Subscriber` cannot receive errors.
    associatedtype Failure: Error
    
    /// Tells the subscriber that it has successfully subscribed to the publisher and may
    /// request items.
    ///
    /// Use the received `Subscription` to request items from the publisher.
    /// - Parameter subscription: A subscription that represents the connection between
    ///   publisher and subscriber.
    /// - Parameter index: A `Upstream's` index
    func receive(subscription: Subscription, at index: Int)
    
    /// Tells the subscriber that the publisher has produced an element.
    ///
    /// - Parameter input: The published element.
    /// - Parameter index: A `Upstream's` index
    /// - Returns: A `Subscribers.Demand` instance indicating how many more elements
    ///   the subscriber expects to receive.
    func receive(_ input: Input, at index: Int) -> Subscribers.Demand
    
    /// Tells the subscriber that the publisher has completed publishing, either normally
    /// or with an error.
    ///
    /// - Parameter completion: A `Subscribers.Completion` case indicating whether
    ///   publishing completed normally or with an error.
    /// - Parameter index: A `Upstream's` index
    func receive(completion: Subscribers.Completion<Failure>, at index: Int)
}
