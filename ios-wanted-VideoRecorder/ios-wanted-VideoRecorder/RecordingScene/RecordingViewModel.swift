//
//  RecordingViewModel.swift
//  ios-wanted-VideoRecorder
//
//  Created by brody on 2023/06/09.
//

import AVFoundation
import Combine

final class RecordingViewModel: NSObject {
    private let recordManager: RecordManager
    let historyImagePublisher = PassthroughSubject<CGImage, Never>()
    private var isAccessDevice = false
    var cancellables = Set<AnyCancellable>()
    
    struct Input {
        let recordingButtonTappedEvent: AnyPublisher<Void, Never>
        let cameraSwitchButtonTappedEvent: AnyPublisher<Void, Never>
        let dismissButtonTappedEvent: AnyPublisher<Void, Never>
    }
    
    struct Output {
        let isRecording = PassthroughSubject<Bool?, Never>()
        let dismissTrigger = PassthroughSubject<Void, Never>()
    }
    
    init(recordManager: RecordManager) {
        self.recordManager = recordManager
    }
    
    func setupDevice() throws {
        let videoPermission = PermissionChecker.checkPermission(about: .video)
        let audioPermission = PermissionChecker.checkPermission(about: .audio)
        
        if videoPermission {
            isAccessDevice = true
            try recordManager.setupCamera()
        }
        
        if audioPermission {
            try recordManager.setupAudio(with: audioPermission)
        }
    }
    
    func makePreview(size: CGSize) -> AVCaptureVideoPreviewLayer {
        let preview = recordManager.makePreview(size: size)
        return preview
    }
    
    func startCaptureSession() {
        if isAccessDevice {
            recordManager.startCaptureSession()
        }
    }
    
    func transform(input: Input) -> Output {
        let output = Output()
        
        input.recordingButtonTappedEvent
            .sink { [weak self] in
                guard let self, isAccessDevice else { return }
                self.recordManager.processRecording(delegate: self)
                output.isRecording.send(self.recordManager.isRecording)
            }
            .store(in: &cancellables)
        
        input.cameraSwitchButtonTappedEvent
            .sink { [weak self] in
                guard let self, isAccessDevice else { return }
                self.recordManager.switchCamera()
            }
            .store(in: &cancellables)
        
        input.dismissButtonTappedEvent
            .sink {
                output.dismissTrigger.send(())
            }
            .store(in: &cancellables)
        
        return output
    }
}

extension RecordingViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        recordManager.generateThumbnail(videoURL: outputFileURL) { [weak self] cgImage in
            guard let self, let cgImage else { return }
            self.historyImagePublisher.send(cgImage)
        }
    }
}

// MARK: - 디바이스 권한 체커모델
fileprivate struct PermissionChecker {
    static func checkPermission(about device: AVMediaType) -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: device)
        var isAccessVideo = false
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: device) { granted in
                isAccessVideo = granted
            }
        case .authorized:
            return true
        default:
            return false
        }
        
        return isAccessVideo
    }
}
