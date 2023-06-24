//
//  ControllView.swift
//  ios-wanted-VideoRecorder
//
//  Created by brody on 2023/06/21.
//

import UIKit

final class ControlView: UIView {
    let sliderView: UISlider = {
        let slider = UISlider()
        slider.tintColor = .systemGray
        
        return slider
    }()
    
    let sliderStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 5
        
        return stackView
    }()
    
    let currentTimerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.text = "00:00"
        label.textColor = .white
        
        return label
    }()
    
    let endTimerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.text = "00:00"
        label.textColor = .white
        
        return label
    }()
    
    let timerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        return stackView
    }()
    
    let backwardButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(
            pointSize: 20,
            weight: .bold,
            scale: .default
        )
        button.setImage(
            UIImage(systemName: "backward.fill", withConfiguration: config),
            for: .normal
        )
        button.tintColor = .white
        button.setContentHuggingPriority(.required, for: .horizontal)
        
        return button
    }()
    
    let playButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(
            pointSize: 20,
            weight: .bold,
            scale: .default
        )
        button.setImage(
            UIImage(systemName: "play.fill", withConfiguration: config),
            for: .normal
        )
        button.tintColor = .white
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    let forwardButton: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(
            pointSize: 20,
            weight: .bold,
            scale: .default
        )
        button.setImage(
            UIImage(systemName: "forward.fill", withConfiguration: config),
            for: .normal
        )
        
        button.tintColor = .white
        button.setContentHuggingPriority(.required, for: .horizontal)
        
        return button
    }()
    
    private let playerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        
        return stackView
    }()
    
    private let wholeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.backgroundColor = .black.withAlphaComponent(0.5)
        stackView.layer.cornerRadius = 10
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayout() {
        self.addSubview(wholeStackView)
        
        wholeStackView.addArrangedSubview(sliderView)
        wholeStackView.addArrangedSubview(timerStackView)
        wholeStackView.addArrangedSubview(playerStackView)
        
        timerStackView.addArrangedSubview(currentTimerLabel)
        timerStackView.addArrangedSubview(endTimerLabel)
        
        playerStackView.addArrangedSubview(backwardButton)
        playerStackView.addArrangedSubview(playButton)
        playerStackView.addArrangedSubview(forwardButton)

        NSLayoutConstraint.activate([
            wholeStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            wholeStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            wholeStackView.topAnchor.constraint(equalTo: self.topAnchor),
            wholeStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
}
