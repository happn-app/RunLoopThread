// swift-tools-version:5.1
import PackageDescription



let package = Package(
	name: "RunLoopThread",
	products: [
		.library(name: "RunLoopThread", targets: ["RunLoopThread"])
	],
	targets: [
		.target(name: "RunLoopThread", dependencies: []),
		.testTarget(name: "RunLoopThreadTests", dependencies: ["RunLoopThread"])
	]
)
