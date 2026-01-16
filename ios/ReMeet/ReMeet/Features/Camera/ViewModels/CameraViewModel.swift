import SwiftUI
import AVFoundation
import Photos

/// Captured card for batch scanning
struct CapturedCard: Identifiable {
    let id = UUID()
    let image: UIImage
    var imageData: Data?
    var imageUrl: String?
}

/// Observable state for camera
@Observable
@MainActor
final class CameraState {
    var capturedImage: UIImage?
    var isShowingPreview = false
    var isUploading = false
    var uploadProgress: Double = 0
    var errorMessage: String?
    var permissionStatus: AVAuthorizationStatus = .notDetermined

    // Batch scanning
    var capturedCards: [CapturedCard] = []
    var isBatchMode = true
    var selectedCardForPreview: CapturedCard?
}

/// ViewModel for camera functionality
@MainActor
final class CameraViewModel: NSObject, AVCapturePhotoCaptureDelegate {

    // MARK: - Observable State

    let state = CameraState()

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
        state.permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch state.permissionStatus {
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
            Task { @MainActor in
                self?.state.permissionStatus = granted ? .authorized : .denied
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
            state.errorMessage = "Camera not available"
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
                photoOutput.maxPhotoDimensions = device.activeFormat.supportedMaxPhotoDimensions.first ?? CMVideoDimensions(width: 4032, height: 3024)
            }

            session.commitConfiguration()

        } catch {
            state.errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            session.commitConfiguration()
        }
    }

    // MARK: - Session Control

    func startSession() {
        guard state.permissionStatus == .authorized else { return }

        let captureSession = session
        Task.detached {
            guard !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }

    func stopSession() {
        let captureSession = session
        Task.detached {
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }

    // MARK: - Capture Photo

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Image Processing

    func retakePhoto() {
        state.capturedImage = nil
        state.isShowingPreview = false
        startSession()
    }

    func usePhoto() async -> (imageUrl: String, imageData: Data)? {
        guard let image = state.capturedImage else { return nil }

        state.isUploading = true
        state.uploadProgress = 0
        state.errorMessage = nil

        // Compress image
        guard let imageData = compressImage(image) else {
            state.errorMessage = "Failed to process image"
            state.isUploading = false
            return nil
        }

        // Generate filename
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "card_\(timestamp).jpg"

        do {
            state.uploadProgress = 0.5

            let imageUrl = try await supabase.uploadBusinessCard(
                image: imageData,
                fileName: fileName
            )

            state.uploadProgress = 1.0
            state.isUploading = false

            return (imageUrl, imageData)

        } catch {
            state.errorMessage = "Upload failed: \(error.localizedDescription)"
            state.isUploading = false
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

    // MARK: - Batch Scanning

    /// Add current captured image to batch
    func addToBatch() {
        guard let image = state.capturedImage else { return }

        let imageData = compressImage(image)
        let card = CapturedCard(image: image, imageData: imageData, imageUrl: nil)
        state.capturedCards.append(card)

        // Reset for next capture
        state.capturedImage = nil
        state.isShowingPreview = false
        startSession()
    }

    /// Add image directly to batch (for simulator/photo picker)
    func addImageToBatch(_ image: UIImage) {
        let fixedImage = Self.fixImageOrientation(image)
        let imageData = compressImage(fixedImage)
        let card = CapturedCard(image: fixedImage, imageData: imageData, imageUrl: nil)
        state.capturedCards.append(card)
    }

    /// Remove card from batch
    func removeFromBatch(id: UUID) {
        state.capturedCards.removeAll { $0.id == id }
        state.selectedCardForPreview = nil
    }

    /// Clear all captured cards
    func clearBatch() {
        state.capturedCards.removeAll()
        state.selectedCardForPreview = nil
    }

    /// Get cards for batch editing
    func finishBatch() -> [CapturedCard] {
        let cards = state.capturedCards
        return cards
    }

    /// Upload all cards in batch
    func uploadBatchCards() async -> [CapturedCard] {
        var uploadedCards: [CapturedCard] = []

        for var card in state.capturedCards {
            guard let imageData = card.imageData else { continue }

            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "card_\(timestamp)_\(card.id.uuidString.prefix(8)).jpg"

            do {
                let imageUrl = try await supabase.uploadBusinessCard(
                    image: imageData,
                    fileName: fileName
                )
                card.imageUrl = imageUrl
                uploadedCards.append(card)
            } catch {
                print("Failed to upload card: \(error)")
                // Still add to list without URL
                uploadedCards.append(card)
            }
        }

        return uploadedCards
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            Task { @MainActor [weak self] in
                self?.state.errorMessage = "Photo capture error: \(error.localizedDescription)"
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor [weak self] in
                self?.state.errorMessage = "Failed to process photo"
            }
            return
        }

        // Fix orientation
        let fixedImage = Self.fixImageOrientation(image)

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            if self.state.isBatchMode {
                // Batch mode: add directly to list
                self.addImageToBatch(fixedImage)
            } else {
                // Single mode: show preview
                self.state.capturedImage = fixedImage
                self.state.isShowingPreview = true
                self.stopSession()
            }
        }
    }

    private static nonisolated func fixImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }
}
