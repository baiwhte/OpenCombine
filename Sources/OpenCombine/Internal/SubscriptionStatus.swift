//
//  File.swift
//  
//
//  Created by baiwhte on 2022/11/24.
//

import Foundation

internal enum SubscriptionStatus {
    case awaiting
    case subscribed(Subscription)
    case pendingTerminal(Subscription)
    case terminal
}

extension SubscriptionStatus {
    internal var isAwaiting: Bool {
        switch self {
            case .awaiting:
                return true
            default:
                return false
        }
    }
    
    internal var subscription: Subscription? {
        switch self {
            case .awaiting, .terminal:
                return nil
            case let .subscribed(subscription), let .pendingTerminal(subscription):
                return subscription
        }
    }
}

extension SubscriptionStatus {
    /// Determines whether `self` can be transitioned to the provided `SubscriptionStatus`.
    ///
    /// If YES, set `self` to `status`.
    internal mutating func canTransitionTo(_ status: SubscriptionStatus) -> Bool {
        switch (self, status) {
            case (.awaiting, _):
                self = status
                return true
            case (_, .awaiting), (.terminal, _), (.pendingTerminal, .subscribed):
                return false
            case (.subscribed, .pendingTerminal):
                self = status
                return true
            case (.subscribed, .subscribed), (.pendingTerminal, .pendingTerminal):
                return false
            case (_, .terminal):
                self = .terminal
                return true
        }
    }
}
