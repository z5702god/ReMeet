# Re:Meet iOS App - 專案設定指南

完整的 iOS 專案建立和 Supabase 整合步驟。

---

## 📋 目錄

1. [建立 Xcode 專案](#1-建立-xcode-專案)
2. [安裝 Supabase Swift SDK](#2-安裝-supabase-swift-sdk)
3. [專案架構](#3-專案架構)
4. [設定 Supabase](#4-設定-supabase)
5. [下一步](#5-下一步)

---

## 1. 建立 Xcode 專案

### 步驟 1.1: 建立新專案

1. 開啟 **Xcode**
2. 選擇 **File** → **New** → **Project**
3. 選擇 **iOS** → **App**
4. 填入專案資訊：
   ```
   Product Name: ReMeet
   Team: [你的開發團隊]
   Organization Identifier: com.yourcompany
   Bundle Identifier: com.yourcompany.ReMeet
   Interface: SwiftUI
   Language: Swift
   Storage: None (我們會用 Supabase)
   ```
5. 選擇儲存位置，點擊 **Create**

### 步驟 1.2: 設定最低版本

1. 在專案設定中，將 **Deployment Target** 設為 **iOS 15.0**
2. 這樣可以使用最新的 SwiftUI 功能同時保持兼容性

---

## 2. 安裝 Supabase Swift SDK

### 方法 1: 使用 Swift Package Manager（推薦）

1. 在 Xcode 中，選擇 **File** → **Add Package Dependencies**
2. 在搜尋欄輸入：
   ```
   https://github.com/supabase-community/supabase-swift
   ```
3. 點擊 **Add Package**
4. 選擇以下套件（全選）：
   - ✅ Auth
   - ✅ Functions
   - ✅ PostgREST
   - ✅ Realtime
   - ✅ Storage
   - ✅ Supabase
5. 點擊 **Add Package**

### 驗證安裝

在任何 Swift 檔案頂部嘗試 import：
```swift
import Supabase
```

如果沒有錯誤，表示安裝成功！

---

## 3. 專案架構

建議的專案資料夾結構：

```
ReMeet/
├── App/
│   ├── ReMeetApp.swift          # App entry point
│   └── ContentView.swift        # Root view
│
├── Core/
│   ├── Config/
│   │   └── SupabaseConfig.swift # Supabase 設定
│   ├── Network/
│   │   └── SupabaseClient.swift # Supabase 客戶端
│   └── Models/
│       ├── User.swift
│       ├── Contact.swift
│       ├── BusinessCard.swift
│       ├── Company.swift
│       └── MeetingContext.swift
│
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   ├── RegisterView.swift
│   │   │   └── ForgotPasswordView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   │
│   ├── Home/
│   │   ├── Views/
│   │   │   └── HomeView.swift
│   │   └── ViewModels/
│   │       └── HomeViewModel.swift
│   │
│   ├── Camera/
│   │   ├── Views/
│   │   │   ├── CameraView.swift
│   │   │   └── CardReviewView.swift
│   │   └── ViewModels/
│   │       └── CameraViewModel.swift
│   │
│   ├── Contacts/
│   │   ├── Views/
│   │   │   ├── ContactsListView.swift
│   │   │   └── ContactDetailView.swift
│   │   └── ViewModels/
│   │       └── ContactsViewModel.swift
│   │
│   ├── Companies/
│   │   ├── Views/
│   │   │   ├── CompaniesListView.swift
│   │   │   └── CompanyDetailView.swift
│   │   └── ViewModels/
│   │       └── CompaniesViewModel.swift
│   │
│   ├── Timeline/
│   │   ├── Views/
│   │   │   └── TimelineView.swift
│   │   └── ViewModels/
│   │       └── TimelineViewModel.swift
│   │
│   └── Chat/
│       ├── Views/
│       │   └── ChatView.swift
│       └── ViewModels/
│           └── ChatViewModel.swift
│
├── Shared/
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── CustomButton.swift
│   └── Extensions/
│       ├── View+Extensions.swift
│       └── Color+Extensions.swift
│
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```

---

## 4. 設定 Supabase

### 步驟 4.1: 取得 Supabase 金鑰

1. 登入 [Supabase Dashboard](https://app.supabase.com)
2. 選擇 **Re:Meet** 專案
3. 點擊 **Settings** → **API**
4. 複製以下資訊：
   - **Project URL**: `https://xxxxx.supabase.co`
   - **API Key (anon, public)**: `eyJhbGci...`

### 步驟 4.2: 建立設定檔

參考專案中的 `SupabaseConfig.swift` 和 `SupabaseClient.swift` 檔案。

⚠️ **重要**：不要把 API keys 直接寫在程式碼中！

建議使用以下方法之一：

**方法 1: 使用 xcconfig 檔案（推薦）**

1. 建立 `Config.xcconfig` 檔案
2. 加入 `.gitignore`
3. 在 Xcode project settings 中引用

**方法 2: 使用 Info.plist**

1. 在 Info.plist 添加：
   ```xml
   <key>SUPABASE_URL</key>
   <string>https://xxxxx.supabase.co</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>your-anon-key-here</string>
   ```

2. 在程式碼中讀取：
   ```swift
   guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
         let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
       fatalError("Missing Supabase configuration")
   }
   ```

---

## 5. 下一步

完成以上設定後：

### 立即可做
- [x] Xcode 專案建立完成
- [x] Supabase SDK 安裝完成
- [x] 專案架構規劃完成
- [ ] 實作 Supabase 客戶端
- [ ] 實作登入/註冊功能
- [ ] 實作相機拍照功能

### 接下來
1. 查看 `SupabaseClient.swift` - 設定 Supabase 連線
2. 查看 `AuthViewModel.swift` - 實作認證邏輯
3. 查看 `LoginView.swift` - 實作登入 UI
4. 測試登入功能

---

## 📚 相關資源

- [Supabase Swift SDK 文件](https://github.com/supabase-community/supabase-swift)
- [SwiftUI 教學](https://developer.apple.com/tutorials/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

---

**建立日期**: 2026-01-10
**專案**: Re:Meet iOS App
