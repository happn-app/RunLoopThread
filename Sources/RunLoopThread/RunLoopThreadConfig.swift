/*
 * RunLoopThreadConfig.swift
 * RunLoopThread
 *
 * Created by François Lamboley on 15/07/2020.
 */

import Foundation
#if canImport(os)
import os.log
#endif



/**
The global configuration for RunLoopThread. */
public struct RunLoopThreadConfig {
	
	#if canImport(os)
	@available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *)
	public static var oslog: OSLog? = .default
	#endif
	
	/** This struct is simply a container for static configuration properties. */
	private init() {}
	
}
