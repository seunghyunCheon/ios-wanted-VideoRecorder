//
//  VideoListViewController.swift
//  ios-wanted-VideoRecorder
//
//  Created by brody on 2023/06/07.
//
import UIKit
import Combine
import AVKit

final class VideoListViewController: UIViewController {
    private enum Section: Hashable {
        case videos
    }
    
    private lazy var videoCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewListLayout())
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
    }()
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, VideoEntity.ID>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, VideoEntity.ID>
    private let videoListViewModel: VideoListViewModel
    private let videoRepository: VideoRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: DataSource?
    private let dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }()
    
    init(videoListViewModel: VideoListViewModel, videoRepository: VideoRepositoryProtocol) {
        self.videoListViewModel = videoListViewModel
        self.videoRepository = videoRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureRootView()
        configureNavigationBar()
        configureLayout()
        configureDataSource()
        bind()
    }
    
    private func configureRootView() {
        view.backgroundColor = .white
        view.addSubview(videoCollectionView)
    }
    
    private func configureNavigationBar() {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold, scale: .default)
        let leftButton = UIButton()
        leftButton.tintColor = .black
        leftButton.setImage(
            UIImage(systemName: "list.triangle", withConfiguration: config),
            for: .normal
        )
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
        titleLabel.text = "Video List"
        
        let stackView = UIStackView(arrangedSubviews: [leftButton, titleLabel])
        stackView.spacing = 5
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: stackView)
        
        let rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "video.fill.badge.plus", withConfiguration: config),
            style: .plain,
            target: self,
            action: #selector(presentRecordingScene)
        )
        rightBarButtonItem.tintColor = .systemBlue
        
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    private func configureLayout() {
        self.videoCollectionView.delegate = self
        let safe = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            videoCollectionView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            videoCollectionView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            videoCollectionView.topAnchor.constraint(equalTo: safe.topAnchor),
            videoCollectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ])
    }
    
    private func configureDataSource() {
        dataSource = DataSource(collectionView: videoCollectionView, cellProvider: cellProvider)
    }
    
    private func cellProvider(_ collectionView: UICollectionView, indexPath: IndexPath, identifier: VideoEntity.ID) -> UICollectionViewCell? {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoCell.identifier,
            for: indexPath
        ) as? VideoCell
        
        cell?.accessories = [
            .disclosureIndicator()
        ]
        
        let video = self.videoListViewModel.videoEntitiesPublisher.value[indexPath.row]
        
        cell?.provide(video, dateFormatter)
        
        return cell
    }
    
    private func collectionViewListLayout() -> UICollectionViewLayout {
        var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfiguration.backgroundColor = .clear
        listConfiguration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            guard let self else {
                return UISwipeActionsConfiguration()
            }
            
            let actionHandler: UIContextualAction.Handler = { [weak self] action, view, completion in
                guard let video = self?.videoListViewModel.videoEntity(at: indexPath.row) else {
                    return
                }
                
                 self?.videoListViewModel.delete(videoID: video.id)
                completion(true)
            }
            
            let action = UIContextualAction(
                style: .destructive,
                title: "Delete",
                handler: actionHandler
            )
            
            return UISwipeActionsConfiguration(actions: [action])
        }
        
        return UICollectionViewCompositionalLayout.list(using: listConfiguration)
    }
    
    private func bind() {
        let input = VideoListViewModel.Input(viewDidLoadEvent: Just(()))
        videoListViewModel.transform(from: input)
        
        videoListViewModel.videoEntitiesPublisher
            .sink { videoEntities in
                self.applySnapshot(videoEntities: videoEntities)
            }
            .store(in: &cancellables)
    }
    
    private func applySnapshot(videoEntities: [VideoEntity]) {
        let videoIDList = videoEntities.map { $0.id }
        
        var snapshot = Snapshot()
        snapshot.appendSections([.videos])
        snapshot.appendItems(videoIDList)
        dataSource?.apply(snapshot)
    }
    
    @objc func presentRecordingScene() {
        let recordManager = RecordManager()
        let videoGenerator = VideoGenerator()
        let createUseCase = CreateVideoUseCase(videoRepository: videoRepository)
        let viewModel = RecordingViewModel(
            recordManager: recordManager,
            videoGenerator: videoGenerator,
            createVideoUseCase: createUseCase
        )
        let recordingViewController = RecordingVideoViewController(recordingViewModel: viewModel)
        recordingViewController.modalPresentationStyle = .fullScreen
        
        self.present(recordingViewController, animated: true)
    }
}

extension VideoListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let video = videoListViewModel.videoEntity(at: indexPath.row)
        
        let videoPlayerViewController = VideoPlayerViewController(url: video.videoURL)
        self.navigationController?.pushViewController(videoPlayerViewController, animated: true)
//        print(video.videoURL)
//        let player = AVPlayer(url: video.videoURL)
//        let vcPlayer = AVPlayerViewController()
//        vcPlayer.player = player
//        self.present(vcPlayer, animated: true)
    }
}
