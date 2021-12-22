/*
Copyright 2020-2021 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import Foundation
#if canImport(os)
import os.log
#endif



public final class RunLoopThread : Thread {
	
	public let runLoopMode: RunLoop.Mode
	
	public init(name n: String? = nil, runLoopMode m: RunLoop.Mode = .default) {
		runLoopMode = m
		
		super.init()
		
		name = n
	}
	
	public override func main() {
		let rl = RunLoop.current
		rl.add(Port(), forMode: .default) /* Ensures the run loop won't stop when nothing is running on it. */
		
		var ok = true
		while ok {
			autoreleasepool{
#if canImport(os)
				if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
					RunLoopThreadConfig.oslog.flatMap{ os_log("New RunLoop run for RunLoopThread “%{public}@”", log: $0, type: .debug, String(describing: name)) }}
#endif
				ok = (!isCancelled && rl.run(mode: .default, before: .distantFuture))
			}
		}
#if canImport(os)
		if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
			RunLoopThreadConfig.oslog.flatMap{ os_log("No more RunLoop runs for RunLoopThread “%{public}@”", log: $0, type: .debug, String(describing: name)) }}
#endif
	}
	
	public override func cancel() {
		super.cancel()
		triggerNextRunLoopRun()
	}
	
	public func triggerNextRunLoopRun() {
		async{}
	}
	
	public func sync<T>(_ block: @escaping () -> T) -> T {
		let wrapper = BlockWrapper(block)
		perform(#selector(RunLoopThread.internalRunBlock(_:)), on: self, with: wrapper, waitUntilDone: true)
		return wrapper.res! as! T
	}
	
	public func async(_ block: @escaping () -> Void) {
		perform(#selector(RunLoopThread.internalRunBlock(_:)), on: self, with: BlockWrapper(block), waitUntilDone: false)
	}
	
	/** Do not make assumptions on the context on which the handler will be called. */
	public func async<T>(_ block: @escaping () -> T, handler: @escaping (_ res: T) -> Void) {
		perform(#selector(RunLoopThread.internalRunBlock(_:)), on: self, with: BlockWrapper({ handler(block()) }), waitUntilDone: false)
	}
	
	@objc private func internalRunBlock(_ blockWrapper: BlockWrapper) {
		blockWrapper.res = blockWrapper.block()
	}
	
	private class BlockWrapper : NSObject {
		
		let block: () -> Any
		init(_ b: @escaping () -> Any) {
			block = b
		}
		
		var res: Any?
		
	}
	
}
