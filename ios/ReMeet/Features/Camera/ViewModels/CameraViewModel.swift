import SwiftUI
import AVFoundation
import Photos

/// ViewModel for camera functionality
@MainActor
class CameraViewModel: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var capturedImage: UIImage?
    @Published var isShowingPreview = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined

    // MARK: - Camera Session

    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Initialization

    override init() {
        super.init()
        checkPermissions()
    }

    // MARK: - Permissions

    func checkPermissions() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch permissionStatus {
        case .notDetermined:
            requestCameraPermission()
        case .authorized:
            setupCamera()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permissionStatus = granted ? .authorized : .denied
                if granted {
                    self?.setupCamera()
                }
            }
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Get back camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            errorMessage = "Camera not available"
            session.commitConfiguration()
            return
        }

        currentDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
            }

            session.commitConfiguration()

        } catch {
            errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            session.commitConfiguration()
        }
    }

    // MARK: - Session Control

    func startSession() {
        guard permissionStatus == .authorized else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Capture Photo

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Image Processing

    func retakePhoto() {
        capturedImage = nil
        isShowingPreview = false
        startSession()
    }

    func usePhoto() async -> (imageUrl: String, imageData: Data)? {
        guard let image = capturedImage else { return nil }

        isUploading = true
        uploadProgress = 0
        errorMessage = nil

        // Compress image
        guard let imageData = compressImage(image) else {
            errorMessage = "Failed to process image"
            isUploading = false
            return nil
        }

        // Generate filename
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "card_\(timestamp).jpg"

        do {
            uploadProgress = 0.5

            let imageUrl = try await supabase.uploadBusinessCard(
                image: imageData,
                fileName: fileName
            )

            uploadProgress = 1.0
            isUploading = false

            return (imageUrl, imageData)

        } catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
            isUploading = false
            return nil
        }
    }

    private func compressImage(_ image: UIImage) -> Data? {
        // Resize if needed
        let maxSize: CGFloat = 2048
        var processedImage = image

        if image.size.width > maxSize || image.size.height > maxSize {
            let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(
                width: image.size.width * ratio,
                height: image.size.height * ratio
            )

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            processedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }

        // Compress to JPEG
        return processedImage.jpegData(compressionQuality: 0.8)
    }

    // MARK: - Flash Control

    func toggleFlash() {
        guard let device = currentDevice, device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            device.unlockForConfiguration()
        } catch {
            print("Flash toggle error: \(error)")
        }
    }

    var isFlashOn: Bool {
        currentDevice?.torchMode == .on
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewModel: AVCapturePhotoCaptureDelegate {

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                self.errorMessage = "Photo capture error: \(error.localizedDescription)"
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                self.errorMessage = "Failed to process photo"
                return
            }

            // Fix orientation
            let fixedImage = fixImageOrientation(image)
            self.capturedImage = fixedImage
            self.isShowingPreview = true
            self.stopSession()
        }
    }

    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }
}
