import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {

    @State private var viewModel = CameraViewModel()
    @State private var showBatchEdit = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showCardPreview = false

    // Check if running on simulator
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if isSimulator {
                    simulatorView
                } else if viewModel.state.permissionStatus == .authorized {
                    batchCameraView
                } else if viewModel.state.permissionStatus == .denied || viewModel.state.permissionStatus == .restricted {
                    permissionDeniedView
                } else {
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                        Text("Requesting camera access...")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Scan Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.state.capturedCards.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showBatchEdit = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.accentPurple)
                    }
                }
            }
            .onAppear {
                if !isSimulator {
                    viewModel.startSession()
                }
            }
            .onDisappear {
                if !isSimulator {
                    viewModel.stopSession()
                }
            }
            .fullScreenCover(isPresented: $showBatchEdit) {
                BatchEditView(
                    cards: viewModel.finishBatch(),
                    onComplete: {
                        viewModel.clearBatch()
                        showBatchEdit = false
                    }
                )
            }
            .sheet(isPresented: $showCardPreview) {
                if let card = viewModel.state.selectedCardForPreview {
                    CardPreviewSheet(
                        card: card,
                        onDelete: {
                            viewModel.removeFromBatch(id: card.id)
                            showCardPreview = false
                        },
                        onDismiss: {
                            showCardPreview = false
                        }
                    )
                }
            }
            .onChange(of: selectedPhotoItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            viewModel.addImageToBatch(image)
                        }
                    }
                    selectedPhotoItems = []
                }
            }
            .alert("Error", isPresented: .constant(viewModel.state.errorMessage != nil)) {
                Button("OK") {
                    viewModel.state.errorMessage = nil
                }
            } message: {
                Text(viewModel.state.errorMessage ?? "")
            }
        }
    }

    // MARK: - Simulator View

    private var simulatorView: some View {
        VStack(spacing: 0) {
            // Main area
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.textSecondary)

                Text("Camera not available in Simulator")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textSecondary)

                Text("Select photos to test batch scanning")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Choose Photos")
                    }
                    .font(AppTypography.headline)
                    .padding()
                    .background(AppColors.accentBlue)
                    .foregroundColor(.white)
                    .cornerRadius(AppCornerRadius.medium)
                }

                Spacer()
            }

            // Thumbnail strip
            if !viewModel.state.capturedCards.isEmpty {
                thumbnailStrip
                    .background(AppColors.cardBackground)
            }
        }
    }

    // MARK: - Batch Camera View

    private var batchCameraView: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Card frame guide
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(
                            width: geometry.size.width * 0.85,
                            height: geometry.size.width * 0.85 * 0.6
                        )
                        .overlay(
                            Text("Align business card within frame")
                                .font(AppTypography.caption)
                                .foregroundColor(.white)
                                .padding(AppSpacing.sm)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(AppCornerRadius.small)
                                .offset(y: -60)
                        )

                    Spacer()

                    // Thumbnail strip
                    if !viewModel.state.capturedCards.isEmpty {
                        thumbnailStrip
                            .background(Color.black.opacity(0.7))
                    }

                    // Controls
                    controlsBar
                        .background(Color.black.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Thumbnail Strip

    private var thumbnailStrip: some View {
        VStack(spacing: AppSpacing.sm) {
            // Count indicator
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(.white)
                Text("\(viewModel.state.capturedCards.count) card\(viewModel.state.capturedCards.count == 1 ? "" : "s") scanned")
                    .font(AppTypography.caption)
                    .foregroundColor(.white)
                Spacer()

                if viewModel.state.capturedCards.count > 1 {
                    Button("Clear All") {
                        HapticManager.shared.warning()
                        viewModel.clearBatch()
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.accentRed)
                    .accessibleButton(label: "Clear all scanned cards")
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)

            // Thumbnails
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(viewModel.state.capturedCards) { card in
                        CardThumbnail(card: card) {
                            viewModel.state.selectedCardForPreview = card
                            showCardPreview = true
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
            }
        }
    }

    // MARK: - Controls Bar

    private var controlsBar: some View {
        HStack(spacing: 40) {
            // Flash button with scale animation
            AnimatedButton(
                action: {
                    HapticManager.shared.lightImpact()
                    viewModel.toggleFlash()
                },
                label: {
                    Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(viewModel.isFlashOn ? AppColors.accentOrange.opacity(0.8) : Color.white.opacity(0.2))
                        .clipShape(Circle())
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isFlashOn)
                }
            )
            .accessibleButton(label: viewModel.isFlashOn ? "Turn flash off" : "Turn flash on")

            // Capture button with scale animation
            AnimatedButton(
                action: {
                    HapticManager.shared.heavyImpact()
                    viewModel.capturePhoto()
                },
                label: {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 60, height: 60)

                        // Badge for count with animation
                        if !viewModel.state.capturedCards.isEmpty {
                            Text("\(viewModel.state.capturedCards.count)")
                                .font(AppTypography.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(AppColors.accentBlue)
                                .clipShape(Circle())
                                .offset(x: 25, y: -25)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.state.capturedCards.count)
                }
            )
            .accessibleButton(label: "Capture business card photo")

            // Done button or placeholder
            if !viewModel.state.capturedCards.isEmpty {
                AnimatedButton(
                    action: {
                        HapticManager.shared.mediumImpact()
                        showBatchEdit = true
                    },
                    label: {
                        Text("Done")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 50)
                            .background(AppColors.accentBlue)
                            .cornerRadius(AppCornerRadius.medium)
                    }
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                Color.clear
                    .frame(width: 50, height: 50)
            }
        }
        .padding(.vertical, AppSpacing.lg)
        .animation(.easeInOut(duration: 0.2), value: viewModel.state.capturedCards.isEmpty)
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary)

            Text("Camera Access Required")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            Text("Please enable camera access in Settings to scan business cards.")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(AppTypography.headline)
                    .padding()
                    .background(AppColors.accentBlue)
                    .foregroundColor(.white)
                    .cornerRadius(AppCornerRadius.medium)
            }
            .padding(.top, AppSpacing.lg)
        }
    }
}

// MARK: - Card Thumbnail

struct CardThumbnail: View {

    let card: CapturedCard
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(uiImage: card.image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Card Preview Sheet

struct CardPreviewSheet: View {

    let card: CapturedCard
    let onDelete: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack {
                    Image(uiImage: card.image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(AppSpacing.md)

                    Spacer()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "trash")
                            Text("Remove this card")
                        }
                        .font(AppTypography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accentRed.opacity(0.1))
                        .foregroundColor(AppColors.accentRed)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .padding(AppSpacing.md)
                }
            }
            .navigationTitle("Card Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(AppColors.accentPurple)
                }
            }
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Add Contact With Image View (for batch edit)

struct AddContactWithImageView: View {

    let imageUrl: String?
    let imageData: Data?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddContactViewModel()
    @State private var showMeetingContext = false
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var croppedImage: UIImage?

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                Form {
                    // Business card image preview
                    if let image = displayImage {
                        Section {
                            HStack {
                                Spacer()
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(AppCornerRadius.small)
                                Spacer()
                            }
                        }
                    }

                    // OCR Status
                    if isScanning {
                        Section {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, AppSpacing.sm)
                                Text("Scanning business card...")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }

                    if let error = scanError {
                        Section {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(AppColors.accentOrange)
                                Text(error)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }

                    // Basic Info Section
                    Section("Contact Information") {
                        TextField("Full Name *", text: $viewModel.fullName)
                            .textContentType(.name)
                            .autocapitalization(.words)

                        TextField("Job Title", text: $viewModel.title)
                            .textContentType(.jobTitle)

                        TextField("Company", text: $viewModel.companyName)
                            .textContentType(.organizationName)
                    }

                    // Contact Details Section
                    Section("Contact Details") {
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 24)
                            TextField("Phone", text: $viewModel.phone)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                        }

                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(AppColors.textSecondary)
                                .frame(width: 24)
                            TextField("Email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    }

                    // Notes Section
                    Section("Notes") {
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 60)
                    }

                    // Error Display
                    if let error = viewModel.errorMessage {
                        Section {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.accentRed)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Next") {
                        showMeetingContext = true
                    }
                    .disabled(!viewModel.isFormValid || isScanning)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.accentPurple)
                }
            }
            .sheet(isPresented: $showMeetingContext) {
                MeetingContextInputView(
                    contactViewModel: viewModel,
                    imageUrl: imageUrl
                ) {
                    onSave()
                    dismiss()
                }
            }
            .task {
                await performOCR()
            }
        }
    }

    private var displayImage: UIImage? {
        if let croppedImage = croppedImage {
            return croppedImage
        }
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }

    private func performOCR() async {
        guard let data = imageData, let image = UIImage(data: data) else { return }

        isScanning = true
        scanError = nil

        do {
            let result = try await BusinessCardScanner.shared.scanBusinessCard(image: image)

            // Update form with OCR results
            await MainActor.run {
                if let name = result.fullName, !name.isEmpty {
                    viewModel.fullName = name
                }
                if let title = result.title, !title.isEmpty {
                    viewModel.title = title
                }
                if let company = result.company, !company.isEmpty {
                    viewModel.companyName = company
                }
                if let phone = result.phone, !phone.isEmpty {
                    viewModel.phone = phone
                }
                if let email = result.email, !email.isEmpty {
                    viewModel.email = email
                }
                if let croppedImg = result.croppedImage {
                    croppedImage = croppedImg
                }

                isScanning = false

                if result.isEmpty {
                    scanError = "Could not extract contact info. Please enter manually."
                }
            }
        } catch {
            await MainActor.run {
                isScanning = false
                scanError = "OCR failed: \(error.localizedDescription). Please enter manually."
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CameraView()
                .preferredColorScheme(.light)
            CameraView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
