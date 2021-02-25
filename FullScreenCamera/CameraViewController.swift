import AVFoundation
import UIKit
import SnapKit

class CameraViewController: UIViewController {
    private let cameraButton: UIButton = {
        let button = UIButton(frame: .zero)

        button.setBackgroundImage(UIImage(named: "camera_button"), for: .normal)
        button.addTarget(self, action: #selector(capture), for: .touchUpInside)

        return button
    }()
    private let flipButton: UIButton = {
        let button = UIButton(frame: .zero)

        button.setBackgroundImage(UIImage(named: "camera_flip"), for: .normal)
        button.addTarget(self, action: #selector(toggleCamera), for: .touchUpInside)

        return button
    }()

    // Camera
    let captureSession: AVCaptureSession
    let captureImageOutput: AVCapturePhotoOutput
    let cameraPreviewLayer: AVCaptureVideoPreviewLayer

    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    var currentScale: CGFloat = 1.0
    var maxZoomFactor: CGFloat {
        return currentDevice?.activeFormat.videoMaxZoomFactor ?? 5.0
    }

    // Gesture
    var zoomGestureRecognizer = UIPinchGestureRecognizer()

    // MARK: - Constructor
    init() {
        captureImageOutput = AVCapturePhotoOutput()
        captureSession = AVCaptureSession()
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lift Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .red

        setupView()
        setupCameraConfig()
        setupGestureConfig()
    }

    func setupCameraConfig() {
        func captureSessionConfig() {
            // 高解析度相片輸出
            captureSession.sessionPreset = AVCaptureSession.Preset.photo

            // 尋找可以用的捕捉裝置, 靜態圖片的裝置(.video)，這裡找尋廣角相機(.builtInWideAngleCamera)，位置不指定(.unspecified)
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                          mediaType: .video,
                                                                          position: .unspecified)

            for device in deviceDiscoverySession.devices {
                switch device.position {
                case .back:
                    backFacingCamera = device
                case .front:
                    frontFacingCamera = device
                default:
                    break
                }
            }

            currentDevice = backFacingCamera

            guard let currentDevice = currentDevice, let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
                print("🔴 CurrentDevice is not exist.")
                return
            }

            captureSession.addInput(captureDeviceInput)
            captureSession.addOutput(captureImageOutput)
        }

        func previewLayerConfig() {
            view.layer.addSublayer(cameraPreviewLayer)

            cameraPreviewLayer.videoGravity = .resizeAspectFill
            cameraPreviewLayer.frame = view.layer.frame

            // 關畢鏡像功能
            if let isMirroringSupported = cameraPreviewLayer.connection?.isVideoMirroringSupported, isMirroringSupported {
                cameraPreviewLayer.connection?.automaticallyAdjustsVideoMirroring = false
                cameraPreviewLayer.connection?.isVideoMirrored = false
            }

            view.bringSubviewToFront(cameraButton)
            view.bringSubviewToFront(flipButton)
        }

        captureSessionConfig()
        previewLayerConfig()

        captureSession.startRunning()
    }

    func setupGestureConfig() {
        zoomGestureRecognizer.addTarget(self, action: #selector(zoom))

        view.addGestureRecognizer(zoomGestureRecognizer)
    }

    // MARK: - Action
    @objc func capture(_ sender: UIButton) {
        // 輸出成JPEG
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])

        // 高解析度
        photoSettings.isHighResolutionPhotoEnabled = true
        // 閃光燈自動
        photoSettings.flashMode = .auto

        captureImageOutput.isHighResolutionCaptureEnabled = true
        captureImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    @objc func toggleCamera(_ sender: UISwipeGestureRecognizer) {
        captureSession.beginConfiguration()

        guard let newDevice = (currentDevice?.position == AVCaptureDevice.Position.back) ? frontFacingCamera : backFacingCamera else {
            print("🔴 NewDevice is not exist.")
            return
        }

        // 清除session中所有的input
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        let cameraInput: AVCaptureDeviceInput

        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice)
        } catch {
            print("🔴 \(error)")
            return
        }

        // 加入newDevice的input
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }

        // 變更currentDevice為newDevice
        currentDevice = newDevice

        // 重置scale
        currentScale = 1.0

        captureSession.commitConfiguration()
    }

    @objc func zoom(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            var newZoomFactor: CGFloat = currentScale * sender.scale

            // 限制上限與下限值
            newZoomFactor = min(maxZoomFactor, newZoomFactor)
            newZoomFactor = max(1.0, newZoomFactor)

            do {
                try currentDevice?.lockForConfiguration()

                currentDevice?.videoZoomFactor = newZoomFactor
                
                currentDevice?.unlockForConfiguration()
            } catch {
                print("🔴 \(error)")
            }
        }

        // 結束時，紀錄本次縮放的結果
        if sender.state == .ended {
            currentScale = currentScale * sender.scale
            currentScale = min(maxZoomFactor, currentScale)
            currentScale = max(1.0, currentScale)

            print("🟢 \(currentScale)")
        }
    }
}

extension CameraViewController {
    private func setupView() {
        func setupCameraButton() {
            let buttonWidth: CGFloat = 70

            self.view.addSubview(cameraButton)

            cameraButton.snp.makeConstraints { make in
                make.width.height.equalTo(buttonWidth)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-25)
                make.centerX.equalToSuperview()
            }
        }

        func setupFlipButton() {
            let buttonWidth: CGFloat = 35

            self.view.addSubview(flipButton)

            flipButton.snp.makeConstraints { make in
                make.width.height.equalTo(buttonWidth)
                make.centerY.equalTo(cameraButton.snp.centerY)
                make.right.equalToSuperview().offset(-20)
            }
        }

        setupCameraButton()
        setupFlipButton()
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            return
        }

        let stillImage = UIImage(data: imageData)

        let viewController = PhotoViewController(image: stillImage)
        viewController.modalPresentationStyle = .fullScreen

        self.present(viewController, animated: false, completion: nil)
    }
}
