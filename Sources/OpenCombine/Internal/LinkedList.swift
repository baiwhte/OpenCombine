//
//  File.swift
//  
//
//  Created by baiwhte on 2022/11/25.
//

import Foundation

internal struct LinkedList<Element> {
    final class Node {
        var prev: Node?
        var next: Node?
        
        var value: Element
        init(prev: Node? = nil, next: Node? = nil, value: Element) {
            self.prev = prev
            self.next = next
            self.value = value
        }
    }
    
    private var head: Node?
    private var tail: Node?
    
    var isEmpty: Bool {
        return self.head == nil
    }
    
    init() {
        head = nil
        tail = nil
    }
    
    mutating func append(_ value: Element) {
        append(Node(value: value))
    }
    
    mutating func append(_ node: Node) {
        guard tail != nil else {
            head = node
            tail = node
            return
        }
        
        tail?.next = node
        node.prev = tail
        
        tail = node
    }
    
    mutating func remove(_ toBeDeleted: Node) {
        if let prev = toBeDeleted.prev {
            prev.next = toBeDeleted.next
        } else {
            self.head = toBeDeleted.next
        }
        
        if let next = toBeDeleted.next {
            next.prev = toBeDeleted.prev
        } else {
            self.tail = toBeDeleted.prev
        }
        
        toBeDeleted.prev = nil
        toBeDeleted.next = nil
    }
    
    mutating func peek() -> Node? {
        guard let node = self.head else {
            return nil
        }
        
        remove(node)
        return node
    }
}

extension LinkedList {
    internal func forEach(_ body: (Element) -> Void) {
        var node = self.head
        while node != nil {
            body(node!.value)
            
            node = node?.next
        }
    }
}

extension LinkedList: HasDefaultValue {
    
}

//extension LinkedList : CustomStringConvertible {
//    var description: String {
//        return Array(self).description
//    }
//}
