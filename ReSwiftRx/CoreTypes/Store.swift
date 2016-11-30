//
//  Store.swift
//  ReSwiftRx
//
//  Created by Charlotte Tortorella on 11/17/16.
//  Copyright © 2016 Benjamin Encz. All rights reserved.
//

import Foundation

/**
 This class is the default implementation of the `Store` protocol. You will use this
 store in most of your applications. You shouldn't need to implement your own store.
 You initialize the store with a reducer and an initial application state. If your app has multiple
 reducers you can combine them by initializng a `CombinedReducer` with all of your reducers as
 arguments.
 */

public class Store<ObservableProperty: ObservablePropertyType>: StoreType
                    where ObservableProperty.ValueType: StateType {

    public typealias StoreReader = Reader<ObservableProperty.ValueType>

    public var dispatchReader: Reader<ObservableProperty.ValueType>!

    private var reducer: AnyReducer

    public var observable: ObservableProperty!

    private var isDispatching = false

    private var disposeBag = SubscriptionReferenceBag()

    public required convenience init(reducer: AnyReducer,
                                     stateType: ObservableProperty.ValueType.Type,
                                     observable: ObservableProperty) {
        self.init(reducer: reducer,
                  stateType: stateType,
                  observable: observable,
                  middleware: Reader { $2 })
    }

    public required init(reducer: AnyReducer,
                         stateType: ObservableProperty.ValueType.Type,
                         observable: ObservableProperty,
                         middleware: StoreReader) {
        self.reducer = reducer
        self.observable = observable
        self.dispatchReader = middleware
    }

    private func defaultDispatch(action: Action) {
        guard !isDispatching else {
            raiseFatalError(
                "ReSwift:IllegalDispatchFromReducer - Reducers may not dispatch actions.")
        }

        isDispatching = true
        let newState = reducer._handleAction(action: action, state: observable.value)
        isDispatching = false

        observable.value = newState as! ObservableProperty.ValueType
    }

    @discardableResult
    public func dispatch(_ action: Action) {
        let mappedAction = dispatchReader.run(state: observable.value,
                                              dispatch: { self.dispatch($0) },
                                              argument: action)
        defaultDispatch(action: mappedAction)
    }

    public func dispatch<S: StreamType>(_ stream: S) where S.ValueType: Action {
        disposeBag += stream.subscribe { [unowned self] action in
            self.dispatch(action)
        }
    }
}
