# Firebase Crashlytics Setup Guide

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name it "ReMeet" (or your preferred name)
4. Disable Google Analytics (optional, can enable later)
5. Click "Create project"

## Step 2: Add iOS App

1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter Bundle ID: `com.yourcompany.ReMeet` (match your Xcode bundle ID)
3. Enter App nickname: "Re:Meet"
4. Download `GoogleService-Info.plist`
5. **Important**: Add this file to `.gitignore`:
   ```
   # Firebase
   GoogleService-Info.plist
   ```

## Step 3: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to File → Add Package Dependencies
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: Up to Next Major Version
4. Select these packages:
   - FirebaseCrashlytics
   - FirebaseAnalytics (optional)

## Step 4: Configure Firebase in App

Update `ReMeetApp.swift`:

```swift
import SwiftUI
import Firebase

@main
struct ReMeetApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SupabaseManager.shared)
        }
    }
}
```

## Step 5: Add Run Script for dSYM Upload

1. In Xcode, select your target
2. Go to Build Phases
3. Click "+" → "New Run Script Phase"
4. Add this script:

```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

5. Add Input Files:
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist
$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist
$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)
```

## Step 6: Test Crashlytics

Add a test crash button (remove before release):

```swift
Button("Test Crash") {
    fatalError("Test crash for Crashlytics")
}
```

1. Build and run the app
2. Trigger the crash
3. Relaunch the app (crash report is sent on next launch)
4. Check Firebase Console → Crashlytics

## Step 7: Add Custom Logging (Optional)

```swift
import FirebaseCrashlytics

// Log custom events
Crashlytics.crashlytics().log("User scanned business card")

// Set user identifier (anonymized)
Crashlytics.crashlytics().setUserID("user_\(userId.hashValue)")

// Record non-fatal errors
Crashlytics.crashlytics().record(error: error)
```

## Files to Add to .gitignore

```gitignore
# Firebase
GoogleService-Info.plist
firebase-debug.log
```

## Troubleshooting

### Crashes not appearing in Console
- Make sure you relaunched the app after the crash
- Wait a few minutes for processing
- Check that GoogleService-Info.plist is in the app bundle

### dSYM upload issues
- Ensure Build Settings → Debug Information Format = "DWARF with dSYM File"
- Check the Run Script output for errors
