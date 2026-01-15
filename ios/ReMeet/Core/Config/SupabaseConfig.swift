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
        case missingGoogleVisionKey
        case invalidURL(String)

        var errorDescription: String? {
            switch self {
            case .missingSupabaseURL:
                return "SUPABASE_URL not configured. Please check Config.xcconfig"
            case .missingSupabaseKey:
                return "SUPABASE_ANON_KEY not configured. Please check Config.xcconfig"
            case .missingGoogleVisionKey:
                return "GOOGLE_CLOUD_VISION_API_KEY not configured. Please check Config.xcconfig"
            case .invalidURL(let url):
                return "Invalid URL format: \(url)"
            }
        }
    }

    // MARK: - Configuration

    /// Supabase project URL
    /// Loaded from Info.plist → SUPABASE_URL
    static var supabaseURL: URL {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !urlString.isEmpty else {
            fatalError(ConfigError.missingSupabaseURL.localizedDescription)
        }

        guard let url = URL(string: urlString) else {
            fatalError(ConfigError.invalidURL(urlString).localizedDescription)
        }

        return url
    }

    /// Supabase anon (public) API key
    /// Loaded from Info.plist → SUPABASE_ANON_KEY
    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.isEmpty else {
            fatalError(ConfigError.missingSupabaseKey.localizedDescription)
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

    // MARK: - Google Cloud Vision Configuration

    /// Google Cloud Vision API Key
    /// Loaded from Info.plist → GOOGLE_CLOUD_VISION_API_KEY
    static var googleCloudVisionAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLOUD_VISION_API_KEY") as? String,
              !key.isEmpty else {
            fatalError(ConfigError.missingGoogleVisionKey.localizedDescription)
        }
        return key
    }
}
