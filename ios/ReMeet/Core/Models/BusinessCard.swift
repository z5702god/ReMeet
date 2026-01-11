import Foundation

/// Business card model matching the public.business_cards table
struct BusinessCard: Codable, Identifiable {
    let id: UUID
    let userId: UUID

    // Image storage
    var imageUrl: String
    var imageFrontUrl: String?
    var imageBackUrl: String?

    // OCR metadata
    var ocrStatus: OCRStatus
    var ocrRawData: [String: Any]?
    var ocrProcessedAt: Date?

    // Timestamps
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case imageUrl = "image_url"
        case imageFrontUrl = "image_front_url"
        case imageBackUrl = "image_back_url"
        case ocrStatus = "ocr_status"
        case ocrRawData = "ocr_raw_data"
        case ocrProcessedAt = "ocr_processed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        imageFrontUrl = try container.decodeIfPresent(String.self, forKey: .imageFrontUrl)
        imageBackUrl = try container.decodeIfPresent(String.self, forKey: .imageBackUrl)
        ocrStatus = try container.decode(OCRStatus.self, forKey: .ocrStatus)
        ocrProcessedAt = try container.decodeIfPresent(Date.self, forKey: .ocrProcessedAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Decode JSON object
        if let rawData = try container.decodeIfPresent(Data.self, forKey: .ocrRawData) {
            ocrRawData = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any]
        }
    }
}

// MARK: - OCR Status

enum OCRStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

// MARK: - Sample Data

#if DEBUG
extension BusinessCard {
    static let sample = BusinessCard(
        id: UUID(),
        userId: UUID(),
        imageUrl: "https://example.com/card.jpg",
        imageFrontUrl: nil,
        imageBackUrl: nil,
        ocrStatus: .completed,
        ocrRawData: nil,
        ocrProcessedAt: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif
