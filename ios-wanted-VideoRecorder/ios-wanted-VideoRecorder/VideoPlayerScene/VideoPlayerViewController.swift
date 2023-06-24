//
//  VideoPlayerViewController.swift
//  ios-wanted-VideoRecorder
//
//  Created by brody on 2023/06/21.
//

import UIKit
import AVFoundation
import Combine

final class VideoPlayerViewController: UIViewController {

    var controllerView = ControlView()
    private var isVideoPlaying = false
    private let viewModel: VideoPlayerViewModel
    private var cancellables = Set<AnyCancellable>()
   
    init(url: URL, viewModel: VideoPlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        configureLayout()
        bindAction()
        bindState()
    }
    
    private func configureLayout() {
        view.backgroundColor = .white
        let playerLayer = viewModel.makeAVPlayerLayer(frame: view.frame)
        view.layer.addSublayer(playerLayer)
        
        controllerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controllerView)
        
        NSLayoutConstraint.activate([
            controllerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            controllerView.heightAnchor.constraint(
                equalTo: controllerView.widthAnchor,
                multiplier: 0.4
            ),
            controllerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
    }
    
    private func bindAction() {
        let input = VideoPlayerViewModel.Input(
            playVideoButtonTappedEvent: controllerView.playButton.buttonPublisher,
            forwardButtonTappedEvent: controllerView.forwardButton.buttonPublisher,
            backwardButtonTappedEvent: controllerView.backwardButton.buttonPublisher,
            sliderValueChangedEvent: controllerView.sliderView.valuePublisher
        )
        
        let output = viewModel.transform(input: input)
        
        output.isVideoPlaying
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print(error.localizedDescription)
                }
            }, receiveValue: { isVideoPlaying in
                self.changePlayButtonImage(isVideoPlaying)
            })
            .store(in: &cancellables)
    }
    
    private func bindState() {
        viewModel.$duration
            .sink { [weak self] duration in
                self?.controllerView.endTimerLabel.text = duration
            }
            .store(in: &cancellables)
    }
    
    private func changePlayButtonImage(_ isVideoPlaying: Bool) {
        let config = UIImage.SymbolConfiguration(
            pointSize: 30,
            weight: .bold,
            scale: .default
        )
        
        let imageName = isVideoPlaying ? "pause.fill" : "play.fill"
        
        self.controllerView.playButton.setImage(
            UIImage(systemName: imageName, withConfiguration: config), for: .normal
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
