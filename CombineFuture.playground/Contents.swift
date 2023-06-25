import UIKit
import Combine

func generateAsyncRandomNumberFromFuture() -> Future <Int, Never> {
    return Future() { promise in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let number = Int.random(in: 1...10)
            promise(Result.success(number))
        }
    }
}

let cancellable = generateAsyncRandomNumberFromFuture()
    .sink { number in print("Got random number \(number).") }
