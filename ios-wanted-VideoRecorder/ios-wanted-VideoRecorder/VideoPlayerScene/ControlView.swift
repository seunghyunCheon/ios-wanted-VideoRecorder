//
//  ControllView.swift
//  ios-wanted-VideoRecorder
//
//  Created by brody on 2023/06/21.
//

import UIKit

final class ControlView: UIView {
    private let backwardButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(
            pointSize: 30,
            weight: .bold,
            scale: .default
        )
        button.setImage(
            UIImage(systemName: "backward.fill", withConfiguration: config),
            for: .normal
        )
        button.tintColor = .white
        
        return button
    }()
    
    private let playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(
            pointSize: 30,
            weight: .bold,
            scale: .default
        )
        button.setImage(
            UIImage(systemName: "play.fill", withConfiguration: config),
            for: .normal
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private let forwardButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(
            pointSize: 30,
            weight: .bold,
            scale: .default
        )
        button.setImage(
            UIImage(systemName: "forward.fill", withConfiguration: config),
            for: .normal
        )
        
        button.tintColor = .white
        
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayout() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.backgroundColor = .black.withAlphaComponent(0.5)
        stackView.layer.cornerRadius = 10
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        
        stackView.addArrangedSubview(backwardButton)
        stackView.addArrangedSubview(playButton)
        stackView.addArrangedSubview(forwardButton)
    }
}
