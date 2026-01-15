import SwiftUI

struct AddContactView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddContactViewModel()

    // Optional: callback when contact is saved
    var onSave: (() -> Void)?

    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Full Name *", text: $viewModel.fullName)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("Job Title", text: $viewModel.title)
                        .textContentType(.jobTitle)
                }

                // Company Section
                Section("Company") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Company Name", text: $viewModel.companyName)
                            .textContentType(.organizationName)
                            .onChange(of: viewModel.companyName) { _, _ in
                                viewModel.clearCompanySelection()
                                Task {
                                    await viewModel.searchCompanies()
                                }
                            }

                        if viewModel.isSearchingCompanies {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Company suggestions
                        if !viewModel.companySuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.companySuggestions) { company in
                                    Button {
                                        viewModel.selectCompany(company)
                                    } label: {
                                        HStack {
                                            Image(systemName: "building.2")
                                                .foregroundColor(.blue)
                                            Text(company.name)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if viewModel.selectedCompany?.id == company.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    Divider()
                                }
                            }
                            .padding(.top, 4)
                        }

                        if viewModel.selectedCompany != nil {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Company selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
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

                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                        TextField("Website", text: $viewModel.website)
                            .textContentType(.URL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "location")
                            .foregroundColor(.gray)
                            .frame(width: 24)
                            .padding(.top, 8)
                        TextField("Address", text: $viewModel.address, axis: .vertical)
                            .textContentType(.fullStreetAddress)
                            .lineLimit(2...4)
                    }
                }

                // Notes Section
                Section("Notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 80)
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
            .navigationTitle("Add Contact")
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
                            await viewModel.saveContact()
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .fontWeight(.semibold)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                }
            }
            .onChange(of: viewModel.didSaveSuccessfully) { _, success in
                if success {
                    onSave?()
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        AddContactView()
    }
}
#endif
