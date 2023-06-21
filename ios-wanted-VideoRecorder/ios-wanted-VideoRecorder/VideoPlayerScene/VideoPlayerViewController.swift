//
//  VideoPlayerViewController.swift
//  ios-wanted-VideoRecorder
//
//  Created by brody on 2023/06/21.
//

import UIKit
import AVFoundation

final class VideoPlayerViewController: UIViewController {

    private let videoView: UIView = {
        let view = UIView()
        
        return view
    }()
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    
    init(url: URL) {
        player = AVPlayer(url: url)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.frame
        
        view.layer.addSublayer(playerLayer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
}
