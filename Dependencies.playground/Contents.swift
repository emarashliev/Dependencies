import Foundation

protocol Service1: Sendable {
    func doSomething()
}
//
protocol Service2: Sendable {
    func doSomething()
}

// Example 1
struct MyService1: Service1 {
    func doSomething() {
        print("Doing something... 1")
    }
}

struct MyServiceKey: DependencyKey {
    static let currentValue: Service1 =  MyService1()
}

extension DependencyValues {
    var myService: Service1 {
        get { self[MyServiceKey.self] }
        set { self[MyServiceKey.self] = newValue }
    }
}

// Example 2
struct MyService2: Service2 {
    func doSomething() {
        print("Doing something... 2")
    }
}

extension MyService2: DependencyKey {
    static let currentValue: Service2 = Self()
}

// Actual usage
struct ContentView {
    @Dependency(\.myService) var myService
    @Dependency(MyService2.self) var myService2

    func performAction() {
        myService.doSomething()
        myService2.doSomething()
    }
}

let contentView = ContentView()
contentView.performAction()

// Mock dependencies
struct MockedMyService1: Service1 {
    func doSomething() {
        print("Something mocked... 1")
    }
}

struct MockedMyService2: Service2 {
    func doSomething() {
        print("Something mocked... 2")
    }
}

let contentViewWhichMockedDependencies = withDependencies {
    $0.myService = MockedMyService1()
    $0[MyService2.self] = MockedMyService2()
} operation: {
    ContentView()
}

contentViewWhichMockedDependencies.performAction()

