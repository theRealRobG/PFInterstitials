//
//  MainThreadAccessConvenience.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation

func ensureMainThreadSync<T>(_ block: () -> T) -> T {
    if Thread.isMainThread {
        return block()
    } else {
        return DispatchQueue.main.sync { block() }
    }
}

func ensureMainThreadAsync<T>(_ block: @escaping () -> T, completion: ((T) -> Void)? = nil) {
    if Thread.isMainThread {
        completion?(block())
    } else {
        DispatchQueue.main.async { completion?(block()) }
    }
}
