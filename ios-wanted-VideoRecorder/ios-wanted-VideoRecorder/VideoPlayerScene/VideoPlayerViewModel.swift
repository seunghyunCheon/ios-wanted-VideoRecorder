//
//  VideoPlayerViewModel.swift
//  ios-wanted-VideoRecorder
//
//  Created by brody on 2023/06/21.
//

import Foundation
import Combine
import AVFoundation

enum VideoPlayerViewModelError: LocalizedError {
    case failedToPlay
    case failedToForward
    case failedToDurationError
    
    var errorDescription: String? {
        switch self {
        case .failedToPlay:
            return "비디오 실행 및 정지에 실패했습니다."
        case .failedToForward:
            return "비디오 앞으로 이동에 실패했습니다."
        case .failedToDurationError:
            return "비디오 시간 로드에 실패했습니다."
        }
    }
}

final class VideoPlayerViewModel {
    var player: AVPlayer
    var isVideoPlaying: Bool = false
    @Published var error: Error?
    @Published var duration: String?
    private var cancellables = Set<AnyCancellable>()
    
    struct Input {
        let playVideoButtonTappedEvent: AnyPublisher<Void, Never>
        let forwardButtonTappedEvent: AnyPublisher<Void, Never>
        let backwardButtonTappedEvent: AnyPublisher<Void, Never>
        let sliderValueChangedEvent: AnyPublisher<Float, Never>
    }
    
    struct Output {
        let isVideoPlaying: AnyPublisher<Bool, Error>
    }
    
    init(url: URL) {
        player = AVPlayer(url: url)
        addDurationObserver()
    }
    
    func makeAVPlayerLayer(frame: CGRect) -> AVPlayerLayer {
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = frame
        
        return playerLayer
    }
    
    // 1. 자동으로 슬라이더가 변할 때
    // - status를 관찰해야 한다. 만약 변한다면 sliderValue를 이동시키도록 뷰컨에 발행해야 한다.
    // - 이때 발행할 때는 sliderValue의 값과 텍스트가 변경된 상태로 전달되어야 한다.
    // 2. 수동으로 변하게 할 때
    // - sliderValueChanged에서 값을 변하게하면서 뷰컨에 sliderValue를 전달.
    
    // 먼저 duration이 변경될 떄마다 duationLabel이 변경되도록해보자.
    // 뷰모델에서 addObserver를 하는 게 맞을까
    func transform(input: Input) -> Output {
        let isVideoPlayingPublisher = input.playVideoButtonTappedEvent
            .flatMap { [weak self] _ -> AnyPublisher<Bool, Error> in
                guard let self else {
                    return Fail(error: VideoPlayerViewModelError.failedToPlay).eraseToAnyPublisher()
                }
                if isVideoPlaying {
                    player.pause()
                } else {
                    player.play()
                }
                isVideoPlaying.toggle()
                return Just(isVideoPlaying).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        input.forwardButtonTappedEvent
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self else {
                    return Fail(error: VideoPlayerViewModelError.failedToForward).eraseToAnyPublisher()
                }
                do {
                    try forwardButtonTapped()
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                } catch {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .sink { completion in
                if case .failure(let error) = completion {
                    self.error = error
                }
            } receiveValue: { }
            .store(in: &cancellables)
        
        input.backwardButtonTappedEvent
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self else {
                    return Fail(error: VideoPlayerViewModelError.failedToForward).eraseToAnyPublisher()
                }
                do {
                    try backwardButtonTapped()
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                } catch {
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .sink { completion in
                if case .failure(let error) = completion {
                    self.error = error
                }
            } receiveValue: { }
            .store(in: &cancellables)
        
        input.sliderValueChangedEvent
            .sink { [weak self] value in
                self?.sliderValueChanged(value: value)
            }
            .store(in: &cancellables)
        
        return Output(isVideoPlaying: isVideoPlayingPublisher)
    }
    
    private func addDurationObserver() {
        guard let videoItem = player.currentItem else {
            error = VideoPlayerViewModelError.failedToDurationError
            return
        }
        
        videoItem.publisher(for: \.duration)
            .sink { [weak self] duration in
                guard duration.seconds > 0.0 else { return }
                self?.duration = self?.getTimeString(from: videoItem.duration)
            }
            .store(in: &cancellables)
    }
    
    private func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
            
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        return timeString
    }
    
    private func forwardButtonTapped() throws {
        guard let duration = player.currentItem?.duration else {
            throw VideoPlayerViewModelError.failedToForward
        }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 2.0
        
        if newTime < (CMTimeGetSeconds(duration) - 2.0) {
            let time: CMTime = CMTimeMake(value: Int64(Int(newTime*1000)), timescale: 1000)
            player.seek(to: time)
        }
    }
    
    private func backwardButtonTapped() throws {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 2.0
        
        if newTime < 0 {
            newTime = 0
        }
        let time = CMTimeMake(value: Int64(Int(newTime*1000)), timescale: 1000)
        player.seek(to: time)
    }
    
    private func sliderValueChanged(value: Float) {
        let seconds = Int64(value)
        let targetTime = CMTimeMake(value: seconds*1000, timescale: 1000)
        
        player.seek(to: targetTime)
    }
}

