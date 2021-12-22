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



/** The global configuration for RunLoopThread. */
public enum RunLoopThreadConfig {
	
#if canImport(os)
	@available(macOS 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *)
	public static var oslog: OSLog? = .default
#endif
	
}

typealias Conf = RunLoopThreadConfig
