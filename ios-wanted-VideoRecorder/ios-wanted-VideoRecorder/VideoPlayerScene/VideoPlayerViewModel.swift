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
    case failedToTimerError
    
    var errorDescription: String? {
        switch self {
        case .failedToPlay:
            return "비디오 실행 및 정지에 실패했습니다."
        case .failedToForward:
            return "비디오 앞으로 이동에 실패했습니다."
        case .failedToDurationError:
            return "비디오 시간 로드에 실패했습니다."
        case .failedToTimerError:
            return "비디오 타이머동작에 실패했습니다."
        }
    }
}

final class VideoPlayerViewModel {
    var player: AVPlayer
    var isVideoPlaying: Bool = false
    @Published var error: Error?
    @Published var duration: String?
    @Published var sliderValue: Float = 0.0
    @Published var currentTime: String = "00:00"
    private var cancellables = Set<AnyCancellable>()
    
    struct Input {
        let playVideoButtonTappedEvent: AnyPublisher<Void, Never>
        let forwardButtonTappedEvent: AnyPublisher<Void, Never>
        let backwardButtonTappedEvent: AnyPublisher<Void, Never>
        let sliderValueChangedEvent: AnyPublisher<Float, Never>
    }
    
    struct Output {
        let isVideoPlaying = PassthroughSubject<Bool, Never>()
    }
    
    init(url: URL) {
        player = AVPlayer(url: url)
        addDurationObserver()
        addTimeObserver()
    }
    
    func makeAVPlayerLayer(frame: CGRect) -> AVPlayerLayer {
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = frame
        
        return playerLayer
    }
    
    func transform(input: Input) -> Output {
        let output = Output()
        
        input.playVideoButtonTappedEvent
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self else {
                    return Fail(error: VideoPlayerViewModelError.failedToPlay).eraseToAnyPublisher()
                }
                return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.error = error
                }
            }, receiveValue: {
                self.changeVideoState()
                output.isVideoPlaying.send(self.isVideoPlaying)
            })
            .store(in: &cancellables)
        
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
        
        bindSliderPauseEvent(to: output.isVideoPlaying)
        
        return output
    }
    
    private func changeVideoState() {
          if self.isVideoPlaying {
              player.pause()
          } else {
              player.play()
          }
          self.isVideoPlaying.toggle()
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
    
    private func addTimeObserver() {
        guard let videoItem = player.currentItem else {
            error = VideoPlayerViewModelError.failedToTimerError
            return
        }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        _ = player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            guard let self else { return }
            
            let totalDuration = Float(CMTimeGetSeconds(videoItem.duration))
            self.sliderValue = Float(videoItem.currentTime().seconds) / totalDuration
            self.currentTime = self.getTimeString(from: videoItem.currentTime())
        })
    }
    
    private func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        print("totalSeconds: \(totalSeconds), CMTime: \(time)")
        
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        return timeString
    }
    
    private func forwardButtonTapped() throws {
        guard let duration = player.currentItem?.duration else {
            throw VideoPlayerViewModelError.failedToForward
        }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 2.0
        
        if newTime < (CMTimeGetSeconds(duration)) {
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
    
    private func bindSliderPauseEvent(to isVideoPlaying: PassthroughSubject<Bool, Never>) {
        player.publisher(for: \.timeControlStatus)
            .sink { status in
                switch status {
                case .playing:
                    isVideoPlaying.send(true)
                default:
                    isVideoPlaying.send(false)
                }
            }
            .store(in: &cancellables)
    }
    
    private func sliderValueChanged(value: Float) {
        guard let item = player.currentItem else { return }
        let totalDuration = item.duration.seconds
        let targetTime = CMTimeMake(value: Int64(Double(value)*1000*totalDuration), timescale: 1000)
        currentTime = getTimeString(from: targetTime)
        player.seek(to: targetTime)
    }
}

