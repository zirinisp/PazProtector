//
//  PazHelperSwiftTests.swift
//  PazHelperSwiftTests
//
//  Created by Pantelis Zirinis on 22/06/2017.
//  Copyright © 2017 paz-labs. All rights reserved.
//

import XCTest
import Foundation
import PazHelperSwift

class PazHelperSwiftTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    let runs = 5
    let iterations = 2000
    
    func testPazProtectedArray() {
        for run in  0...50 {
            // This is an example of a functional test case.
            // Use XCTAssert and related functions to verify your tests produce the correct results.
            for x in 0...runs {
                let tidalExpectation = self.expectation(description: "\(run):protector\(x)")
                DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                    // Thread-safe array
                    let protectedArray = PazProtectedArray<Int>(randomLockName: "array\(x)")
                    var i = self.iterations
                    
                    DispatchQueue.concurrentPerform(iterations: self.iterations) { index in
                        let last = protectedArray.last ?? 0
                        protectedArray.append(last + 1)
                        i -= 1
                        // Final loop
                        guard i <= 0 else { return }
                        //print("a: \(x): \(protectedArray.count) \(protectedArray.last ?? 0)")
                        XCTAssert(protectedArray.count == self.iterations)
                        tidalExpectation.fulfill()
                    }
                    
                }
            }
            waitForExpectations(timeout: 5) { (error) in
                if let _ = error {
                    XCTFail("Timeout")
                }
            }
        }
    }
    

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
