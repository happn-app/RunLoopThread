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

import Foundation
#if canImport(os)
	import os.log
#endif



/**
A class that can be used to launch a background thread with a runloop.

- Note: Inherits from NSObject to be able to call perform selector on thread.
- Important: This class is _not_ thread-safe! */
public final class RunLoopThread : NSObject {
	
	public enum State {
		
		/** The long lived thread is inited, but the internal thread has not been
		started. */
		case initialized
		/** The long lived thread started the internal thread. The long lived
		thread is live! */
		case running(Thread)
		/** The long lived thread has been told to stop, but the run loop did not
		go to the next run yet. */
		case stopping(Thread)
		/** The long lived thread is stopped. It is now useless. */
		case stopped
		
		internal var isStopping: Bool {
			switch self {
			case .stopping:                        return true
			case .initialized, .running, .stopped: return false
			}
		}
		
		internal var thread: Thread? {
			switch self {
			case .initialized, .stopped:            return nil
			case .running(let t), .stopping(let t): return t
			}
		}
		
	}
	
	public let name: String
	
	public var state: State
	
	public var isCurrentThread: Bool {
		guard let thread = state.thread else {return false}
		return Thread.current === thread
	}
	
	/* TODO: Make it dynamic! (May not be useful… must be thought through.) */
	public let runLoopModes = [RunLoop.Mode.default]
	
	public var threadPriority: Double {
		didSet {state.thread?.threadPriority = threadPriority}
	}
	
	init(name n: String = "Unnamed RunLoopThread", startThread start: Bool = false) {
		name = n
		state = .initialized
		threadPriority = 0.5

		super.init()
		
		if start {startThread()}
	}
	
	deinit {
		#if canImport(os)
		if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
			RunLoopThreadConfig.oslog.flatMap{ os_log("Deallocing RunLoop Thread “%{public}@”", log: $0, type: .debug, name) }}
		#endif
		assert(state.thread == nil, "Deinitialization of a RunLoopThread whose state is \(state).")
	}
	
	/**
	The thread is neither started nor stopped automatically. When using a
	`RunLoopThread`, you **have to** explicitly call the start and stop thread
	methods.
	The run-loop of the underlying thread will run in the default mode.
	
	You *cannot* relaunch a new thread after stopThread has been called (an
	exception is thrown if it is done). */
	public func startThread() {
		guard case .initialized = state else {
			return NSException(name: NSExceptionName(rawValue: "Long Lived Thread Already Used"), reason: "Cannot start more than once a long lived thread (faulty long lived thread name: “\(name)”)", userInfo: nil).raise()
		}
		
		let thread = Thread(target: self, selector: #selector(startThreadInternal), object: nil)
		thread.threadPriority = threadPriority
		thread.name = name
		
		state = .running(thread)
		thread.start()
	}
	
	/**
	The thread is neither started nor stopped automatically. When using a
	`RunLoopThread`, you **have to** explicitly call the start and stop thread
	methods.
	The run-loop of the underlying thread will run in the default mode.
	
	You *cannot* relaunch a new thread after stopThread has been called (an
	exception is thrown if it is done). */
	public func stopThread() {
		guard let thread = state.thread, !thread.isCancelled else {
			return
		}
		
		#if canImport(os)
		if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
			RunLoopThreadConfig.oslog.flatMap{ os_log("Stopping Long Lived Thread “%@”", log: $0, type: .debug, name) }}
		#endif
		
		thread.cancel()
		state = .stopping(thread)
		/* Waking the RunLoop to do the next loop. The thread is cancelled, which
		 * will lead to cancelling the run loop too (see startThreadInternal). */
		perform(#selector(nop), on: thread, with: nil, waitUntilDone: false)
	}
	
	/** Execute the block at the next free run-loop entry synchronously. */
	public func sync(_ block: @escaping () -> Void) {
		execute(block, waitForCompletion: true)
	}
	
	/** Execute the block at the next free run-loop entry asynchronously. */
	public func async(_ block: @escaping () -> Void) {
		execute(block, waitForCompletion: false)
	}
	
	public func execute(_ block: @escaping () -> Void, waitForCompletion: Bool) {
		guard case .running(let thread) = state else {
			return NSException(name: NSExceptionName(rawValue: "Thread Is Not Running"), reason: "Trying to execute a block on non-running long lived thread “\(name)”.", userInfo: nil).raise()
		}
		perform(#selector(executeInternal(_:)), on: thread, with: BlockWrapper(block), waitUntilDone: waitForCompletion)
	}
	
	@objc
	private class BlockWrapper : NSObject {
		
		let block: () -> Void
		init(_ b: @escaping () -> Void) {
			block = b
		}
		
	}
	
	@objc
	private func startThreadInternal() {
		guard let thread = state.thread else {
			//log
			return
		}
		
		let rl = RunLoop.current
		rl.add(Port(), forMode: .default) /* Ensures the run loop won't stop when nothing is running on it. */
		
		var ok = true
		while ok {
			autoreleasepool{
//				HCLogT(@"RunLoop: New loop for Long Lived Thread <%@>.", self.name);
				ok = (!thread.isCancelled && rl.run(mode: .default, before: .distantFuture))
			}
		}
//		HCLogD(@"No more run for RunLoops for long lived thread <%@>: thread is stopped.", self.name);
		
		assert(state.isStopping, "INTERNAL ERROR: Invalid state \(state) when ending internal thread for RunLoopThread \(name).")
		state = .stopped
	}
	
	@objc
	private func executeInternal(_ blockWrapper: BlockWrapper) {
		blockWrapper.block()
	}
	
	@objc
	private func nop() {
		#if canImport(os)
		if #available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
			RunLoopThreadConfig.oslog.flatMap{ os_log("Noping Long Lived Thread “%@”!", log: $0, type: .debug, name) }}
		#endif
	}
	
}
