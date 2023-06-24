//
//  UISlider+Combine.swift
//  ios-wanted-VideoRecorder
//
//  Created by brody on 2023/06/21.
//

import UIKit
import Combine

extension UISlider {
    var valuePublisher: AnyPublisher<Float, Never> {
        publisher(for: .valueChanged)
            .compactMap { self.value }
            .eraseToAnyPublisher()
    }
}
