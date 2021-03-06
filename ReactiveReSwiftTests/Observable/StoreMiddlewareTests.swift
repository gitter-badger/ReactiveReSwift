//
//  ObservableStoreMiddlewareTests.swift
//  ReactiveReSwift
//
//  Created by Charlotte Tortorella on 25/11/16.
//  Copyright © 2015 Benjamin Encz. All rights reserved.
//

import XCTest
import ReactiveReSwift

// swiftlint:disable function_body_length
class StoreMiddlewareTests: XCTestCase {

    /**
     it can decorate dispatch function
     */
    func testDecorateDispatch() {
        let store = Store(reducer: testValueStringReducer,
            stateType: TestStringAppState.self,
            observable: ObservableProperty(TestStringAppState()),
            middleware: Middleware(firstMiddleware, secondMiddleware))

        let subscriber = TestStoreSubscriber<TestStringAppState>()
        store.observable.subscribe(subscriber.subscription)

        let action = SetValueStringAction("OK")
        store.dispatch(action)

        XCTAssertEqual(store.observable.value.testValue, "OK First Middleware Second Middleware")
    }

    /**
     it can dispatch actions
     */
    func testCanDispatch() {
        let store = Store(reducer: testValueStringReducer,
            stateType: TestStringAppState.self,
            observable: ObservableProperty(TestStringAppState()),
            middleware: Middleware(firstMiddleware, secondMiddleware, dispatchingMiddleware))

        let subscriber = TestStoreSubscriber<TestStringAppState>()
        store.observable.subscribe(subscriber.subscription)

        let action = SetValueAction(10)
        store.dispatch(action)

        XCTAssertEqual(store.observable.value.testValue, "10 First Middleware Second Middleware")
    }

    /**
     it middleware can access the store's state
     */
    func testMiddlewareCanAccessState() {
        let property = ObservableProperty(TestStringAppState(testValue: "OK"))
        let store = Store(reducer: testValueStringReducer,
                                    stateType: TestStringAppState.self,
                                    observable: property,
                                    middleware: stateAccessingMiddleware)

        store.dispatch(SetValueStringAction("Action That Won't Go Through"))

        XCTAssertEqual(store.observable.value.testValue, "Not OK")
    }

    /**
     it middleware should not be executed if the previous middleware returned nil
     */
    func testMiddlewareSkipsReducersWhenPassedNil() {
        let filteringMiddleware = Middleware<TestStringAppState> { _, _, _ in nil }.map { _, _, action in XCTFail(); return action }

        let property = ObservableProperty(TestStringAppState(testValue: "OK"))
        let store = Store(reducer: testValueStringReducer,
                          stateType: TestStringAppState.self,
                          observable: property,
                          middleware: filteringMiddleware)

        store.dispatch(SetValueStringAction("Action That Won't Go Through"))
    }
}
