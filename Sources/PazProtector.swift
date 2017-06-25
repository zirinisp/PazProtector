//
//  PazProtector.swift
//  PazHelperSwift
//
//  Created by Pantelis Zirinis on 14/05/2015.
//  Copyright (c) 2015 paz-labs. All rights reserved.
//

import Foundation
#if os(Linux)
    import Dispatch
#endif

public class PazReadWriteLock {
    public private (set) lazy var queue: DispatchQueue = DispatchQueue(label: self.lockName, attributes: .concurrent)
    
    public init(lockName: String) {
        self.lockName = lockName
    }
    
    public convenience init(randomLockName: String) {
        let lockName = PazReadWriteLock.RandomLockName(randomLockName)
        self.init(lockName: lockName)
    }
    
    public class func RandomLockName(_ prefix: String) -> String {
        let random = Int(arc4random_uniform(10000))
        return "\(prefix).\(random)"
    }
    
    public private (set) var lockName: String
    
    public func withReadLock(_ closure: @escaping () -> Void) {
        self.queue.sync {
            closure()
        }
    }
    
    public func withWriteLock(_ closure: @escaping () -> Void) {
        self.queue.async(flags: DispatchWorkItemFlags.barrier) {
            closure()
        }
    }
}

/*
 * A convenience class to wrap a locked object. All access to the object must go through
 * blocks passed to this object.
 */
public class PazProtector<T> {
    private let lock : PazReadWriteLock
    private var item: T
    
    public init(name: String, item: T) {
        self.lock = PazReadWriteLock(lockName: name)
        self.item = item
    }
    
    public convenience init(item: T) {
        self.init(name: PazReadWriteLock.RandomLockName("PazProtector"), item: item)
    }
    
    public func withReadLock(_ block: @escaping (T) -> Void) {
        lock.withReadLock() { [weak self] in
            guard let strongSelf = self else {
                return
            }
            block(strongSelf.item)
        }
    }
    
    public func withWriteLock(_ block: @escaping (inout T) -> Void) {
        lock.withWriteLock() { [weak self] in
            guard let strongSelf = self else {
                return
            }
            block(&strongSelf.item)
        }
    }
}

public class PazProtectedDictionary<S: Hashable, T>: PazProtector<Dictionary<S, T>> {
    public init(lockName: String) {
        let item = Dictionary<S, T>()
        super.init(name: lockName, item: item)
    }
    
    /// Takes the randomLockName and add a random suffix
    public convenience init(randomLockName: String) {
        let lockName = PazReadWriteLock.RandomLockName(randomLockName)
        self.init(lockName: lockName)
    }
    
    public subscript(key: S) -> T? {
        get {
            var result: T?
            self.withReadLock { (dictionary) in
                result = dictionary[key]
            }
            return result
            
        }
        set(object) {
            self.withWriteLock { (dictionary) in
                dictionary[key] = object
            }
        }
    }
    
    /// Deletes all object of the dictionary
    public func reset() {
        self.withWriteLock { (dictionary) in
            dictionary = Dictionary<S, T>()
        }
    }
    
    /// Rerplaces current dictionary
    public func setDictionary(_ newDictinoary: Dictionary<S, T>) {
        self.withWriteLock { (dictionary) in
            dictionary = newDictinoary
        }
    }
}


public class PazProtectedArray<Element>: PazProtector<Array<Element>> {
    
    public init(lockName: String) {
        let item = Array<Element>()
        super.init(name: lockName, item: item)
    }
    
    public convenience init(randomLockName: String) {
        let lockName = PazReadWriteLock.RandomLockName(randomLockName)
        self.init(lockName: lockName)
    }
    
    public var copiedItem: Array<Element>? {
        var result: Array<Element>?
        self.withReadLock { (array) in
            result = array
        }
        return result
    }
    
    public subscript(index: Int) -> Element? {
        get {
            var result: Element?
            self.withReadLock { (array) in
                result = array[index]
            }
            return result
            
        }
        set(object) {
            self.withWriteLock { (array) in
                if let letObject = object {
                    array[index] = letObject
                } else {
                    array.remove(at: index)
                }
            }
        }
    }
    
    public func append(_ item: Element) {
        self.withWriteLock { (array) in
            array.append(item)
        }
    }
    
    public var count: Int {
        var result: Int = 0
        self.withReadLock { (array) in
            result = array.count
        }
        return result
    }
    
    public var last: Element? {
        var result: Element?
        self.withReadLock({ (array) in
            result = array.last
        })
        return result
    }
    
    /// Deletes all object of the dictionary
    public func reset() {
        self.withWriteLock { (array) in
            array = Array<Element>()
        }
    }
    
    /// Rerplaces current dictionary
    public func setArray(_ newArray: Array<Element>) {
        self.withWriteLock { (array) in
            array = newArray
        }
    }
}


public class PazProtectedSet<T: Hashable>: PazProtector<Set<T>>, Collection {
    
    public init(lockName: String) {
        let item = Set<T>()
        super.init(name: lockName, item: item)
    }
    
    public convenience init(randomLockName: String) {
        let lockName = PazReadWriteLock.RandomLockName(randomLockName)
        self.init(lockName: lockName)
    }
    
    public var copiedItem: Set<T>? {
        var result: Set<T>?
        self.withReadLock { (set) in
            result = Set<T>(set)
        }
        return result
    }
    
    /// Insert a member into the set.
    public func insert(_ member: T) {
        self.withWriteLock { (set) in
            set.insert(member)
        }
    }
    
    /// Remove the member from the set and return it if it was present.
    public func remove(_ member: T) -> T? {
        var itemToReturn: T?
        self.withWriteLock { (set) in
            itemToReturn = set.remove(member)
        }
        return itemToReturn
    }
    
    /// Remove the member referenced by the given index.
    public func removeAtIndex(_ index: SetIndex<T>) {
        self.withWriteLock { (set) in
            set.remove(at: index)
        }
    }
    
    /// Erase all the elements.  If `keepCapacity` is `true`, `capacity`
    /// will not decrease.
    public func removeAll(keepCapacity: Bool) {
        self.withWriteLock { (set) in
            set.removeAll(keepingCapacity: keepCapacity)
        }
    }
    
    /// Remove a member from the set and return it. Requires: `count > 0`.
    public func removeFirst() -> T {
        var itemToReturn: T?
        self.withWriteLock { (set) in
            itemToReturn = set.removeFirst()
        }
        return itemToReturn!
    }
    
    public var count: Int {
        var count = 0
        self.withReadLock { (set) in
            count = set.count
        }
        return count
    }
    
    public subscript (position: SetIndex<T>) -> T {
        get {
            var result: T?
            self.withReadLock { (set) in
                result = set[position]
            }
            return result!
        }
    }
    
    /// Returns `true` iff the `Interval` contains `x`
    public func contains(x: T) -> Bool {
        var result = false
        self.withReadLock { (set) in
            result = set.contains(x)
        }
        return result
    }
    
    /// Deletes all object of the dictionary
    public func reset() {
        self.withWriteLock { (set) in
            set = Set<T>()
        }
    }
    
    /// Rerplaces current dictionary
    public func setNewSet(_ newSet: Set<T>) {
        self.withWriteLock { (set) in
            set = newSet
        }
    }
    /* Swift 3.0 Removed
     public func generate() -> SetGenerator<T> {
     var result: SetGenerator<T>?
     self.queue.sync { [weak self] in
     result = self.item.generate()
     }
     return result!
     
     }*/
    
    /// The position of the first element in a non-empty set.
    ///
    /// This is identical to `endIndex` in an empty set.
    ///
    /// Complexity: amortized O(1) if `self` does not wrap a bridged
    /// `NSSet`, O(N) otherwise.
    public var startIndex: SetIndex<T> {
        var result: SetIndex<T>?
        self.withReadLock { (set) in
            result = set.startIndex
        }
        return result!
        
    }
    
    /// The collection's "past the end" position.
    ///
    /// `endIndex` is not a valid argument to `subscript`, and is always
    /// reachable from `startIndex` by zero or more applications of
    /// `successor()`.
    ///
    /// Complexity: amortized O(1) if `self` does not wrap a bridged
    /// `NSSet`, O(N) otherwise.
    public var endIndex: SetIndex<T> {
        var result: SetIndex<T>?
        self.withReadLock { (set) in
            result = set.endIndex
        }
        return result!
    }
    
    public func index(after i: SetIndex<T>) -> SetIndex<T> {
        var result: SetIndex<T>?
        self.withReadLock { (set) in
            result = set.index(after: i)
        }
        return result!
    }
}




