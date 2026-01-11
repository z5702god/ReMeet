import SwiftUI

struct ContactDetailView: View {

    let contact: Contact

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with avatar
                VStack(spacing: 16) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(contact.initials)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.white)
                        )

                    Text(contact.fullName)
                        .font(.title)
                        .fontWeight(.bold)

                    if let title = contact.titleWithCompany {
                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)

                // Contact information
                VStack(spacing: 16) {
                    if let phone = contact.phone {
                        ContactInfoRow(icon: "phone.fill", label: "Phone", value: phone, isLink: true)
                    }

                    if let email = contact.email {
                        ContactInfoRow(icon: "envelope.fill", label: "Email", value: email, isLink: true)
                    }

                    if let website = contact.website {
                        ContactInfoRow(icon: "globe", label: "Website", value: website, isLink: true)
                    }

                    if let address = contact.address {
                        ContactInfoRow(icon: "mappin.circle.fill", label: "Address", value: address)
                    }
                }
                .padding(.horizontal)

                // Notes
                if let notes = contact.notes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(notes)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // Tags
                if let tags = contact.tags, !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Contact Info Row

struct ContactInfoRow: View {

    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isLink {
                    Link(value, destination: linkURL)
                        .font(.body)
                } else {
                    Text(value)
                        .font(.body)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var linkURL: URL {
        if label == "Phone" {
            return URL(string: "tel:\(value.replacingOccurrences(of: " ", with: ""))")!
        } else if label == "Email" {
            return URL(string: "mailto:\(value)")!
        } else {
            return URL(string: value) ?? URL(string: "https://\(value)")!
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContactDetailView(contact: .sample)
        }
    }
}
#endif
