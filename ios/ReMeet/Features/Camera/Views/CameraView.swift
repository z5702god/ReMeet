import SwiftUI
import AVFoundation

struct CameraView: View {

    @StateObject private var viewModel = CameraViewModel()
    @State private var showAddContact = false
    @State private var capturedImageUrl: String?
    @State private var capturedImageData: Data?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.permissionStatus == .authorized {
                    if viewModel.isShowingPreview, let image = viewModel.capturedImage {
                        // Preview captured image
                        previewView(image: image)
                    } else {
                        // Camera view
                        cameraView
                    }
                } else if viewModel.permissionStatus == .denied || viewModel.permissionStatus == .restricted {
                    permissionDeniedView
                } else {
                    // Loading / requesting permission
                    ProgressView("Requesting camera access...")
                }
            }
            .navigationTitle("Scan Card")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.startSession()
            }
            .onDisappear {
                viewModel.stopSession()
            }
            .sheet(isPresented: $showAddContact) {
                AddContactWithImageView(
                    imageUrl: capturedImageUrl,
                    imageData: capturedImageData
                ) {
                    // Reset after saving
                    viewModel.retakePhoto()
                    capturedImageUrl = nil
                    capturedImageData = nil
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                CameraPreviewView(session: viewModel.session)
                    .ignoresSafeArea()

                // Card frame overlay
                VStack {
                    Spacer()

                    // Card frame guide
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(
                            width: geometry.size.width * 0.85,
                            height: geometry.size.width * 0.85 * 0.6 // Standard card ratio
                        )
                        .overlay(
                            Text("Align business card within frame")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                                .offset(y: -60)
                        )

                    Spacer()

                    // Controls
                    HStack(spacing: 60) {
                        // Flash button
                        Button {
                            viewModel.toggleFlash()
                        } label: {
                            Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }

                        // Capture button
                        Button {
                            viewModel.capturePhoto()
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 70, height: 70)

                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            }
                        }

                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 50, height: 50)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Preview View

    private func previewView(image: UIImage) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()

                if viewModel.isUploading {
                    // Upload progress
                    VStack(spacing: 12) {
                        ProgressView(value: viewModel.uploadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 200)

                        Text("Uploading...")
                            .foregroundColor(.white)
                    }
                    .padding()
                } else {
                    // Action buttons
                    HStack(spacing: 40) {
                        // Retake
                        Button {
                            viewModel.retakePhoto()
                        } label: {
                            VStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                Text("Retake")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding()
                        }

                        // Use Photo
                        Button {
                            Task {
                                if let result = await viewModel.usePhoto() {
                                    capturedImageUrl = result.imageUrl
                                    capturedImageData = result.imageData
                                    showAddContact = true
                                }
                            }
                        } label: {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text("Use Photo")
                                    .font(.caption)
                            }
                            .foregroundColor(.green)
                            .padding()
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Please enable camera access in Settings to scan business cards.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
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

// MARK: - Add Contact With Image View

struct AddContactWithImageView: View {

    let imageUrl: String?
    let imageData: Data?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddContactViewModel()
    @State private var showMeetingContext = false

    var body: some View {
        NavigationView {
            Form {
                // Business card image preview
                if let data = imageData, let uiImage = UIImage(data: data) {
                    Section {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
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
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        TextField("Phone", text: $viewModel.phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }

                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
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
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
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
                    .disabled(!viewModel.isFormValid)
                    .fontWeight(.semibold)
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
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
#endif
