import Foundation

/// Supabase configuration
///
/// ⚠️ IMPORTANT: Do not commit actual API keys to version control
/// Use environment variables or xcconfig files instead
enum SupabaseConfig {

    // MARK: - Configuration

    /// Supabase project URL
    /// Get this from: Supabase Dashboard → Settings → API
    static var supabaseURL: URL {
        // Method 1: From Info.plist (recommended for production)
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           let url = URL(string: urlString) {
            return url
        }

        // Method 2: Hardcoded (for development only)
        // ⚠️ Replace with your actual Supabase URL
        guard let url = URL(string: "https://your-project-ref.supabase.co") else {
            fatalError("Invalid Supabase URL")
        }
        return url
    }

    /// Supabase anon (public) API key
    /// Get this from: Supabase Dashboard → Settings → API
    static var supabaseAnonKey: String {
        // Method 1: From Info.plist (recommended for production)
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            return key
        }

        // Method 2: Hardcoded (for development only)
        // ⚠️ Replace with your actual anon key
        return "your-anon-key-here"
    }

    // MARK: - Storage Configuration

    /// Business cards storage bucket name
    static let businessCardsBucket = "business-cards"

    /// User avatars storage bucket name
    static let avatarsBucket = "avatars"
}

// MARK: - Setup Instructions

/*

 ## Setup Instructions

 ### Option 1: Using Info.plist (Recommended)

 1. Open Info.plist
 2. Add the following keys:

    <key>SUPABASE_URL</key>
    <string>https://your-project-ref.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>your-anon-key-here</string>

 3. Make sure Info.plist is in .gitignore if you commit the keys

 ### Option 2: Using xcconfig file (Most Secure)

 1. Create a new file: Config.xcconfig
 2. Add to .gitignore
 3. Add content:

    SUPABASE_URL = https:/$()/your-project-ref.supabase.co
    SUPABASE_ANON_KEY = your-anon-key-here

 4. In Xcode project settings, set Config.xcconfig as the configuration file
 5. Access in code via environment or Info.plist

 ### Getting Your Supabase Credentials

 1. Go to https://app.supabase.com
 2. Select your "Re:Meet" project
 3. Click Settings → API
 4. Copy:
    - Project URL
    - API Key (anon, public)

 */
