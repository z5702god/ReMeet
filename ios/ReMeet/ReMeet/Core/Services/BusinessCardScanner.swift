import Foundation
import UIKit
import Vision
import Supabase

/// Business card scanning service using Supabase Edge Function proxy
/// Handles OCR text recognition and intelligent field parsing
/// Security: Google API key is stored server-side, not in the app binary
class BusinessCardScanner {

    // MARK: - Singleton

    static let shared = BusinessCardScanner()

    private init() {}

    // MARK: - Configuration

    /// Supabase client for authentication
    private let supabase = SupabaseManager.shared

    // MARK: - OCR Result

    struct ScanResult {
        var fullName: String?
        var title: String?
        var company: String?
        var phone: String?
        var email: String?
        var website: String?
        var address: String?
        var rawText: String
        var croppedImage: UIImage?

        var isEmpty: Bool {
            return fullName == nil && title == nil && company == nil &&
                   phone == nil && email == nil && website == nil && address == nil
        }
    }

    // MARK: - Public Methods

    /// Scan a business card image and extract contact information
    func scanBusinessCard(image: UIImage) async throws -> ScanResult {
        // Step 1: Auto-crop the business card
        let croppedImage = await detectAndCropCard(from: image) ?? image

        // Step 2: Perform OCR using Supabase Edge Function (proxies Google Cloud Vision)
        let rawText = try await performOCR(on: croppedImage)

        // Step 3: Parse the text to extract fields
        var result = parseBusinessCardText(rawText)
        result.croppedImage = croppedImage
        result.rawText = rawText

        return result
    }

    // MARK: - Auto Crop using Vision Framework

    /// Detect and crop the business card from the image
    private func detectAndCropCard(from image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNRectangleObservation],
                      let card = results.first else {
                    continuation.resume(returning: nil)
                    return
                }

                // Crop the detected rectangle
                let croppedImage = self.cropImage(image, to: card)
                continuation.resume(returning: croppedImage)
            }

            // Configure for business card detection
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 0.9
            request.minimumSize = 0.1
            request.minimumConfidence = 0.5
            request.maximumObservations = 1

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    /// Crop image to the detected rectangle
    private func cropImage(_ image: UIImage, to observation: VNRectangleObservation) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

        // Convert normalized coordinates to image coordinates
        let topLeft = CGPoint(
            x: observation.topLeft.x * imageSize.width,
            y: (1 - observation.topLeft.y) * imageSize.height
        )
        let topRight = CGPoint(
            x: observation.topRight.x * imageSize.width,
            y: (1 - observation.topRight.y) * imageSize.height
        )
        let bottomLeft = CGPoint(
            x: observation.bottomLeft.x * imageSize.width,
            y: (1 - observation.bottomLeft.y) * imageSize.height
        )
        let bottomRight = CGPoint(
            x: observation.bottomRight.x * imageSize.width,
            y: (1 - observation.bottomRight.y) * imageSize.height
        )

        // Calculate bounding rect
        let minX = min(topLeft.x, bottomLeft.x)
        let maxX = max(topRight.x, bottomRight.x)
        let minY = min(topLeft.y, topRight.y)
        let maxY = max(bottomLeft.y, bottomRight.y)

        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

        // Add some padding
        let padding: CGFloat = 10
        let paddedRect = rect.insetBy(dx: -padding, dy: -padding)

        // Ensure rect is within bounds
        let clampedRect = paddedRect.intersection(CGRect(origin: .zero, size: imageSize))

        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else { return nil }

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - OCR via Supabase Edge Function

    /// Perform OCR using Supabase Edge Function (proxies Google Cloud Vision)
    /// Security: API key is stored server-side, never exposed in client code
    private func performOCR(on image: UIImage) async throws -> String {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ScanError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        // Get current session for authentication
        guard let session = try? await supabase.client.auth.session else {
            throw ScanError.authenticationRequired
        }

        // Build Edge Function URL
        let functionURL = SupabaseConfig.supabaseURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent("ocr-scan")

        // Build request
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let requestBody: [String: Any] = [
            "image": base64Image,
            "languageHints": ["zh-TW", "zh-CN", "en", "ja"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScanError.networkError
        }

        // Handle authentication errors
        if httpResponse.statusCode == 401 {
            throw ScanError.authenticationRequired
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorResponse["error"] as? String {
                throw ScanError.apiError(message)
            }
            throw ScanError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse response from Edge Function
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool,
              success,
              let text = json["text"] as? String else {
            return ""
        }

        return text
    }

    // MARK: - Text Parsing

    /// Parse OCR text to extract business card fields
    private func parseBusinessCardText(_ text: String) -> ScanResult {
        var result = ScanResult(rawText: text)

        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        for line in lines {
            // Email detection
            if result.email == nil, let email = extractEmail(from: line) {
                result.email = email
                continue
            }

            // Phone detection
            if result.phone == nil, let phone = extractPhone(from: line) {
                result.phone = phone
                continue
            }

            // Website detection
            if result.website == nil, let website = extractWebsite(from: line) {
                result.website = website
                continue
            }
        }

        // Try to identify name and company from remaining lines
        let remainingLines = lines.filter { line in
            !line.contains("@") &&
            !isPhoneNumber(line) &&
            !line.lowercased().contains("www.") &&
            !line.lowercased().contains("http")
        }

        // Heuristics for name and company
        if remainingLines.count >= 2 {
            // Usually name comes first, company second
            result.fullName = remainingLines[0]
            result.company = remainingLines[1]

            // Check if there's a title (often between name and company)
            if remainingLines.count >= 3 {
                // Look for common title patterns
                for i in 1..<remainingLines.count {
                    let line = remainingLines[i]
                    if isLikelyTitle(line) {
                        result.title = line
                        if i + 1 < remainingLines.count {
                            result.company = remainingLines[i + 1]
                        }
                        break
                    }
                }
            }
        } else if remainingLines.count == 1 {
            result.fullName = remainingLines[0]
        }

        return result
    }

    // MARK: - Field Extraction Helpers

    private func extractEmail(from text: String) -> String? {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        guard let regex = try? NSRegularExpression(pattern: emailPattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        return String(text[Range(match.range, in: text)!])
    }

    private func extractPhone(from text: String) -> String? {
        // Common phone patterns (international, Taiwan, etc.)
        let phonePatterns = [
            "\\+?\\d{1,4}[-.\\s]?\\(?\\d{1,4}\\)?[-.\\s]?\\d{1,4}[-.\\s]?\\d{1,9}",
            "\\(\\d{2,4}\\)[-.\\s]?\\d{3,4}[-.\\s]?\\d{3,4}",
            "\\d{4}[-.\\s]?\\d{3}[-.\\s]?\\d{3}",
            "0\\d{1,2}[-.\\s]?\\d{3,4}[-.\\s]?\\d{3,4}"
        ]

        for pattern in phonePatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                let phone = String(text[Range(match.range, in: text)!])
                // Verify it looks like a phone (has enough digits)
                let digits = phone.filter { $0.isNumber }
                if digits.count >= 8 {
                    return phone
                }
            }
        }
        return nil
    }

    private func extractWebsite(from text: String) -> String? {
        let patterns = [
            "https?://[\\w.-]+\\.[a-z]{2,}[/\\w.-]*",
            "www\\.[\\w.-]+\\.[a-z]{2,}[/\\w.-]*"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                return String(text[Range(match.range, in: text)!])
            }
        }
        return nil
    }

    private func isPhoneNumber(_ text: String) -> Bool {
        let digits = text.filter { $0.isNumber }
        return digits.count >= 8 && digits.count <= 15
    }

    private func isLikelyTitle(_ text: String) -> Bool {
        let titleKeywords = [
            "manager", "director", "engineer", "developer", "designer",
            "ceo", "cto", "cfo", "president", "vp", "vice president",
            "executive", "consultant", "analyst", "specialist",
            "經理", "總監", "工程師", "設計師", "總經理", "副總",
            "主任", "專員", "顧問", "分析師", "協理", "襄理"
        ]

        let lowercased = text.lowercased()
        return titleKeywords.contains { lowercased.contains($0) }
    }

    // MARK: - Errors

    enum ScanError: LocalizedError {
        case invalidImage
        case networkError
        case authenticationRequired
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid image format"
            case .networkError:
                return "Network error occurred"
            case .authenticationRequired:
                return "Please sign in to scan business cards"
            case .apiError(let message):
                return "Scan failed: \(message)"
            }
        }
    }
}
