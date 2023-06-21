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
    
    var errorDescription: String? {
        switch self {
        case .failedToPlay:
            return "비디오 실행 및 정지에 실패했습니다."
        case .failedToForward:
            return "비디오 앞으로 이동에 실패했습니다."
        }
    }
}

final class VideoPlayerViewModel {
    var player: AVPlayer
    var isVideoPlaying: Bool = false
    @Published var error: Error?
    private var cancellables = Set<AnyCancellable>()
    
    struct Input {
        let playVideoButtonTappedEvent: AnyPublisher<Void, Never>
        let forwardButtonTappedEvent: AnyPublisher<Void, Never>
        let backwardButtonTappedEvent: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let isVideoPlaying: AnyPublisher<Bool, Error>
    }
    
    init(url: URL) {
        player = AVPlayer(url: url)
    }
    
    func makeAVPlayerLayer(frame: CGRect) -> AVPlayerLayer {
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = frame
        
        return playerLayer
    }
    
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
        
        return Output(isVideoPlaying: isVideoPlayingPublisher)
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
}
