import Foundation

/// Supabase configuration
///
/// Configuration is loaded from Info.plist which reads from Config.xcconfig
/// Setup: Copy Config.xcconfig.example to Config.xcconfig and add your API keys
enum SupabaseConfig {

    // MARK: - Configuration Errors

    enum ConfigError: LocalizedError {
        case missingSupabaseURL
        case missingSupabaseKey
        case invalidURL(String)

        var errorDescription: String? {
            switch self {
            case .missingSupabaseURL:
                return "SUPABASE_URL not configured. Please check Config.xcconfig"
            case .missingSupabaseKey:
                return "SUPABASE_ANON_KEY not configured. Please check Config.xcconfig"
            case .invalidURL(let url):
                return "Invalid URL format: \(url)"
            }
        }
    }

    // MARK: - Configuration

    /// Supabase project URL - loaded from Config.xcconfig via Info.plist
    static var supabaseURL: URL {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !urlString.isEmpty,
              !urlString.contains("$("),
              let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL not configured. Please check Config.xcconfig and Xcode configuration.")
        }
        return url
    }

    /// Supabase anon (public) API key - loaded from Config.xcconfig via Info.plist
    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty,
              !key.contains("$(") else {
            fatalError("SUPABASE_ANON_KEY not configured. Please check Config.xcconfig and Xcode configuration.")
        }
        return key
    }

    // MARK: - Storage Configuration

    /// Business cards storage bucket name
    static let businessCardsBucket = "business-cards"

    /// User avatars storage bucket name
    static let avatarsBucket = "avatars"

    // MARK: - n8n API Configuration

    /// n8n Chat API endpoint
    /// Loaded from Info.plist → N8N_CHAT_API_URL
    static var n8nChatAPIURL: URL {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "N8N_CHAT_API_URL") as? String,
              !urlString.isEmpty,
              let url = URL(string: urlString) else {
            // n8n is optional - return a placeholder that will fail gracefully
            return URL(string: "https://n8n-not-configured.local")!
        }
        return url
    }

    // NOTE: Google Cloud Vision API Key has been moved to server-side
    // The OCR functionality now uses the ocr-scan Edge Function
    // This prevents API key exposure in the app binary
}
