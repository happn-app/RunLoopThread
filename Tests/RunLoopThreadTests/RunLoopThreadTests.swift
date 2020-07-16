/*
Copyright 2020 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import XCTest
@testable import RunLoopThread



final class RunLoopThreadTests: XCTestCase {
	
	func testAsyncUsage() {
		let t = RunLoopThread(name: "com.happn.runloop-thread.test-async-usage")
		let witness = Witness()
		
		let witnessExpectation = XCTKVOExpectation(keyPath: #keyPath(Witness.value), object: witness)
		let exitExpectation = XCTNSNotificationExpectation(name: .NSThreadWillExit, object: t)
		
		t.start()
		t.async{
			witness.value = 1
			t.cancel()
		}
		
		let r = XCTWaiter().wait(for: [witnessExpectation, exitExpectation], timeout: 1)
		XCTAssertEqual(r, .completed)
		XCTAssertEqual(witness.value, 1)
	}
	
	func testSyncUsage() {
		let t = RunLoopThread(name: "com.happn.runloop-thread.test-sync-usage")
		let witness = Witness()
		
		let exitExpectation = XCTNSNotificationExpectation(name: .NSThreadWillExit, object: t)
		
		t.start()
		t.sync{ witness.value = 1 }
		t.cancel()
		
		let r = XCTWaiter().wait(for: [exitExpectation], timeout: 1)
		XCTAssertEqual(r, .completed)
		XCTAssertEqual(witness.value, 1)
	}
	
	func testNoExit() {
		let t = RunLoopThread(name: "com.happn.runloop-thread.test-no-exit")
		t.start()
		
		Thread.sleep(forTimeInterval: 0.5)
		XCTAssertTrue(t.isExecuting)
		XCTAssertFalse(t.isFinished)
		
		t.cancel()
		let exitExpectation = XCTNSNotificationExpectation(name: .NSThreadWillExit, object: t)
		let r = XCTWaiter().wait(for: [exitExpectation], timeout: 1)
		XCTAssertEqual(r, .completed)
	}
	
	@objc
	private class Witness : NSObject {
		@objc dynamic var value: NSNumber = 0
	}
	
}
