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
    
    var errorDescription: String? {
        switch self {
        case .failedToPlay:
            return "비디오 실행 및 정지에 실패했습니다."
        }
    }
}

final class VideoPlayerViewModel {
    var player: AVPlayer
    private var cancellables = Set<AnyCancellable>()
    var isVideoPlaying: Bool = false
    @Published var error: Error?
    
    struct Input {
        let playVideoButtonTappedEvent: AnyPublisher<Void, Never>
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
        
        
        return Output(isVideoPlaying: isVideoPlayingPublisher)
    }
}
