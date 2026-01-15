import SwiftUI

/// View for editing multiple scanned business cards
struct BatchEditView: View {

    let cards: [CapturedCard]
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var completedCount = 0
    @State private var isUploading = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress header
                    progressHeader

                    Divider()
                        .background(AppColors.divider)

                    // Current card edit
                    if currentIndex < cards.count {
                        BatchCardEditView(
                            card: cards[currentIndex],
                            cardNumber: currentIndex + 1,
                            totalCards: cards.count,
                            onSave: {
                                moveToNext()
                            },
                            onSkip: {
                                moveToNext()
                            }
                        )
                        .id(cards[currentIndex].id) // Force view recreation when card changes
                    } else {
                        // All done
                        completionView
                    }
                }
            }
            .navigationTitle("Edit Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.divider)
                        .frame(height: 4)

                    Rectangle()
                        .fill(AppColors.accentBlue)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 4)

            // Progress text
            HStack {
                Text("Card \(min(currentIndex + 1, cards.count)) of \(cards.count)")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Text("\(completedCount) saved")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.accentGreen)
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .padding(.top, AppSpacing.sm)
    }

    private var progress: Double {
        guard cards.count > 0 else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.accentGreen)

            Text("All Done!")
                .font(AppTypography.title1)
                .foregroundColor(AppColors.textPrimary)

            Text("\(completedCount) contact\(completedCount == 1 ? "" : "s") saved successfully")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            Button {
                onComplete()
            } label: {
                Text("Finish")
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accentBlue)
                    .cornerRadius(AppCornerRadius.medium)
            }
            .padding(.horizontal, 40)
            .padding(.top, AppSpacing.lg)

            Spacer()
        }
    }

    // MARK: - Navigation

    private func moveToNext() {
        completedCount += 1
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentIndex < cards.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = cards.count // Show completion view
            }
        }
    }
}

// MARK: - Batch Card Edit View

struct BatchCardEditView: View {

    let card: CapturedCard
    let cardNumber: Int
    let totalCards: Int
    let onSave: () -> Void
    let onSkip: () -> Void

    @State private var viewModel = AddContactViewModel()
    @State private var showMeetingContext = false
    @State private var isScanning = false
    @State private var scanError: String?
    @State private var croppedImage: UIImage?
    @State private var imageUrl: String?
    @State private var shouldMoveToNext = false

    private let supabase = SupabaseManager.shared

    var body: some View {
        Form {
            // Card image
            Section {
                HStack {
                    Spacer()
                    Image(uiImage: displayImage ?? card.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .cornerRadius(AppCornerRadius.small)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)

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

            // Contact Information
            Section("Contact Information") {
                TextField("Full Name *", text: $viewModel.fullName)
                    .textContentType(.name)
                    .autocapitalization(.words)

                TextField("Job Title", text: $viewModel.title)
                    .textContentType(.jobTitle)

                TextField("Company", text: $viewModel.companyName)
                    .textContentType(.organizationName)
            }

            // Contact Details
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

            // Actions
            Section {
                Button {
                    showMeetingContext = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Save & Continue")
                            .font(AppTypography.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                        Spacer()
                    }
                    .foregroundColor(AppColors.accentPurple)
                }
                .disabled(!viewModel.isFormValid || isScanning)

                Button {
                    onSkip()
                } label: {
                    HStack {
                        Spacer()
                        Text("Skip this card")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .sheet(isPresented: $showMeetingContext, onDismiss: {
            // Only move to next after sheet is fully dismissed
            if shouldMoveToNext {
                shouldMoveToNext = false
                onSave()
            }
        }) {
            MeetingContextInputView(
                contactViewModel: viewModel,
                imageUrl: imageUrl
            ) {
                // Mark that we should move to next, then dismiss will trigger onSave
                shouldMoveToNext = true
            }
        }
        .task {
            await uploadAndScan()
        }
    }

    private var displayImage: UIImage? {
        croppedImage ?? nil
    }

    private func uploadAndScan() async {
        // First upload the image
        if let imageData = card.imageData {
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "card_\(timestamp)_\(card.id.uuidString.prefix(8)).jpg"

            do {
                imageUrl = try await supabase.uploadBusinessCard(
                    image: imageData,
                    fileName: fileName
                )
            } catch {
                print("Upload error: \(error)")
            }
        }

        // Then perform OCR
        await performOCR()
    }

    private func performOCR() async {
        isScanning = true
        scanError = nil

        do {
            let result = try await BusinessCardScanner.shared.scanBusinessCard(image: card.image)

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
                scanError = "OCR failed. Please enter manually."
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BatchEditView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BatchEditView(cards: [], onComplete: {})
                .preferredColorScheme(.light)
            BatchEditView(cards: [], onComplete: {})
                .preferredColorScheme(.dark)
        }
    }
}
#endif
