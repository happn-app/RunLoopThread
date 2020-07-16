/*
 * RunLoopThreadTests.swift
 * RunLoopThread
 *
 * Created by François Lamboley on 15/07/2020.
 */

import XCTest
@testable import RunLoopThread



final class RunLoopThreadTests: XCTestCase {
	
	func testAsyncUsage() {
		let witness = Witness()
		let expectation = XCTKVOExpectation(keyPath: #keyPath(Witness.value), object: witness)
		
		let t = RunLoopThread(name: "com.happn.runloop-thread.test-basic-usage", startThread: false)
		t.startThread()
		t.async{
			witness.value = 1
		}
		XCTWaiter().wait(for: [expectation], timeout: 1)
	}
	
	@objc
	private class Witness : NSObject {
		@objc dynamic var value: NSNumber = 0
	}
	
}
