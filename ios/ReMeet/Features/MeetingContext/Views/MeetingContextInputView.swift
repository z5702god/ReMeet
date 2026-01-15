import SwiftUI

/// View for inputting meeting context after scanning a business card
struct MeetingContextInputView: View {

    @Bindable var contactViewModel: AddContactViewModel
    let imageUrl: String?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MeetingContextViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                Form {
                    // When did you meet?
                    Section("When did you meet?") {
                        DatePicker(
                            "Date",
                            selection: $viewModel.meetingDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }

                    // Where did you meet?
                    Section("Where did you meet?") {
                        TextField("Location Name", text: $viewModel.locationName)
                            .textContentType(.location)

                        TextField("Address (optional)", text: $viewModel.locationAddress)
                            .textContentType(.fullStreetAddress)
                    }

                    // Event/Occasion
                    Section("What was the occasion?") {
                        TextField("Event Name (optional)", text: $viewModel.eventName)

                        Picker("Occasion Type", selection: $viewModel.occasionType) {
                            ForEach(OccasionType.allCases) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                    }

                    // Relationship
                    Section("Relationship") {
                        Picker("Relationship Type", selection: $viewModel.relationshipType) {
                            ForEach(RelationshipType.allCases) { type in
                                Text(type.displayName)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    // Notes
                    Section("Notes") {
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 80)

                        Text("What did you talk about? Any key takeaways?")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    // Follow-up
                    Section("Follow-up") {
                        Toggle("Needs Follow-up", isOn: $viewModel.followUpRequired)
                            .tint(AppColors.accentPurple)

                        if viewModel.followUpRequired {
                            DatePicker(
                                "Follow-up Date",
                                selection: $viewModel.followUpDate,
                                displayedComponents: .date
                            )
                        }
                    }

                    // Skip option
                    Section {
                        Button {
                            Task {
                                await saveWithoutContext()
                            }
                        } label: {
                            HStack {
                                Text("Skip & Save Contact Only")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(AppColors.textSecondary)
                        }
                    }

                    // Error Display
                    if let error = viewModel.errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(AppColors.accentRed)
                                .font(AppTypography.caption)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Meeting Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveWithContext()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.accentPurple)
                    .disabled(viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding(AppSpacing.lg)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppCornerRadius.medium)
                }
            }
        }
    }

    // MARK: - Save Methods

    private func saveWithContext() async {
        viewModel.isLoading = true
        viewModel.errorMessage = nil

        do {
            // First save contact
            let contact = try await saveContact()
            print("saveContact completed, contactId: \(contact.id)")

            // Then save meeting context
            do {
                _ = try await viewModel.saveMeetingContext(forContactId: contact.id)
                print("saveMeetingContext succeeded")
            } catch {
                print("saveMeetingContext failed: \(error)")
                throw error
            }

            viewModel.isLoading = false
            onSave()
            dismiss()

        } catch {
            print("saveWithContext overall error: \(error)")
            viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
            viewModel.isLoading = false
        }
    }

    private func saveWithoutContext() async {
        viewModel.isLoading = true
        viewModel.errorMessage = nil

        do {
            // Only save contact
            _ = try await saveContact()

            viewModel.isLoading = false
            onSave()
            dismiss()

        } catch {
            viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
            viewModel.isLoading = false
        }
    }

    private func saveContact() async throws -> Contact {
        let supabase = SupabaseManager.shared

        // Handle company
        var companyId: UUID?
        let trimmedCompanyName = contactViewModel.companyName.trimmingCharacters(in: .whitespaces)

        if let selected = contactViewModel.selectedCompany {
            companyId = selected.id
        } else if !trimmedCompanyName.isEmpty {
            let company = try await supabase.findOrCreateCompany(name: trimmedCompanyName)
            companyId = company.id
        }

        // Get current user
        guard let userId = supabase.currentUser?.id else {
            throw NSError(domain: "MeetingContext", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        // Create business card record if we have an image
        var cardId: UUID?
        if let url = imageUrl {
            let card = BusinessCard(
                id: UUID(),
                userId: userId,
                imageUrl: url,
                imageFrontUrl: url,
                imageBackUrl: nil,
                ocrStatus: .pending,
                ocrRawData: nil,
                ocrProcessedAt: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            do {
                let savedCard = try await supabase.createBusinessCard(card)
                cardId = savedCard.id
                print("createBusinessCard succeeded")
            } catch {
                print("createBusinessCard failed: \(error)")
                throw error
            }
        }

        // Create contact
        let contact = Contact(
            id: UUID(),
            userId: userId,
            cardId: cardId,
            companyId: companyId,
            fullName: contactViewModel.fullName.trimmingCharacters(in: .whitespaces),
            title: contactViewModel.title.isEmpty ? nil : contactViewModel.title.trimmingCharacters(in: .whitespaces),
            department: nil,
            phone: contactViewModel.phone.isEmpty ? nil : contactViewModel.phone.trimmingCharacters(in: .whitespaces),
            email: contactViewModel.email.isEmpty ? nil : contactViewModel.email.trimmingCharacters(in: .whitespaces).lowercased(),
            website: contactViewModel.website.isEmpty ? nil : contactViewModel.website.trimmingCharacters(in: .whitespaces),
            address: contactViewModel.address.isEmpty ? nil : contactViewModel.address.trimmingCharacters(in: .whitespaces),
            linkedinUrl: nil,
            twitterUrl: nil,
            ocrConfidenceScore: nil,
            isVerified: true,
            isFavorite: false,
            tags: nil,
            notes: contactViewModel.notes.isEmpty ? nil : contactViewModel.notes.trimmingCharacters(in: .whitespaces),
            createdAt: Date(),
            updatedAt: Date(),
            lastContactedAt: nil,
            company: nil
        )

        do {
            let savedContact = try await supabase.createContact(contact)
            print("createContact succeeded")
            return savedContact
        } catch {
            print("createContact failed: \(error)")
            throw error
        }
    }
}

// MARK: - Standalone Meeting Context View

struct MeetingContextView: View {

    let contactId: UUID
    let onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = MeetingContextViewModel()

    init(contactId: UUID, onSave: (() -> Void)? = nil) {
        self.contactId = contactId
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                Form {
                    // When did you meet?
                    Section("When did you meet?") {
                        DatePicker(
                            "Date",
                            selection: $viewModel.meetingDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }

                    // Where did you meet?
                    Section("Where did you meet?") {
                        TextField("Location Name", text: $viewModel.locationName)
                            .textContentType(.location)

                        TextField("Address (optional)", text: $viewModel.locationAddress)
                            .textContentType(.fullStreetAddress)
                    }

                    // Event/Occasion
                    Section("What was the occasion?") {
                        TextField("Event Name (optional)", text: $viewModel.eventName)

                        Picker("Occasion Type", selection: $viewModel.occasionType) {
                            ForEach(OccasionType.allCases) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                    }

                    // Relationship
                    Section("Relationship") {
                        Picker("Relationship Type", selection: $viewModel.relationshipType) {
                            ForEach(RelationshipType.allCases) { type in
                                Text(type.displayName)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    // Notes
                    Section("Notes") {
                        TextEditor(text: $viewModel.notes)
                            .frame(minHeight: 80)
                    }

                    // Follow-up
                    Section("Follow-up") {
                        Toggle("Needs Follow-up", isOn: $viewModel.followUpRequired)
                            .tint(AppColors.accentPurple)

                        if viewModel.followUpRequired {
                            DatePicker(
                                "Follow-up Date",
                                selection: $viewModel.followUpDate,
                                displayedComponents: .date
                            )
                        }
                    }

                    // Error Display
                    if let error = viewModel.errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(AppColors.accentRed)
                                .font(AppTypography.caption)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Meeting Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await save()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.accentPurple)
                    .disabled(viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding(AppSpacing.lg)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppCornerRadius.medium)
                }
            }
        }
    }

    private func save() async {
        viewModel.isLoading = true
        viewModel.errorMessage = nil

        do {
            _ = try await viewModel.saveMeetingContext(forContactId: contactId)
            viewModel.isLoading = false
            onSave?()
            dismiss()
        } catch {
            viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
            viewModel.isLoading = false
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MeetingContextInputView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MeetingContextInputView(
                contactViewModel: AddContactViewModel(),
                imageUrl: nil,
                onSave: {}
            )
            .preferredColorScheme(.light)

            MeetingContextInputView(
                contactViewModel: AddContactViewModel(),
                imageUrl: nil,
                onSave: {}
            )
            .preferredColorScheme(.dark)
        }
    }
}
#endif
