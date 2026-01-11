# Re:Meet iOS App

這個資料夾包含 Re:Meet iOS app 的完整程式碼架構。

## 📁 專案結構

```
ios/ReMeet/
├── App/                          # App 入口點
│   ├── ReMeetApp.swift          # @main App struct
│   └── ContentView.swift        # Root view with auth routing
│
├── Core/                         # 核心功能
│   ├── Config/
│   │   └── SupabaseConfig.swift # Supabase 設定
│   ├── Network/
│   │   └── SupabaseClient.swift # Supabase 客戶端
│   └── Models/                  # 資料模型
│       ├── User.swift
│       ├── Contact.swift
│       ├── BusinessCard.swift
│       ├── Company.swift
│       └── MeetingContext.swift
│
├── Features/                     # 功能模組
│   ├── Authentication/          # 認證
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   ├── RegisterView.swift
│   │   │   └── ForgotPasswordView.swift
│   │   └── ViewModels/
│   │       └── AuthViewModel.swift
│   │
│   ├── Home/                    # 首頁（名片列表）
│   │   ├── Views/
│   │   │   └── HomeView.swift
│   │   └── ViewModels/
│   │       └── HomeViewModel.swift
│   │
│   ├── Contacts/                # 聯絡人詳情
│   │   └── Views/
│   │       └── ContactDetailView.swift
│   │
│   ├── Companies/               # 公司列表（占位）
│   │   └── Views/
│   │       └── CompaniesListView.swift
│   │
│   ├── Timeline/                # 時間軸（占位）
│   │   └── Views/
│   │       └── TimelineView.swift
│   │
│   ├── Chat/                    # AI 聊天（占位）
│   │   └── Views/
│   │       └── ChatView.swift
│   │
│   └── Camera/                  # 相機掃描（占位）
│       └── Views/
│           └── CameraView.swift
│
└── Shared/                      # 共用元件（待建立）
    ├── Components/
    └── Extensions/
```

## 🚀 快速開始

### 1. 在 Xcode 建立新專案

1. 開啟 Xcode
2. File → New → Project
3. 選擇 iOS → App
4. 填入資訊：
   - Product Name: `ReMeet`
   - Interface: `SwiftUI`
   - Language: `Swift`

### 2. 安裝 Supabase SDK

1. File → Add Package Dependencies
2. 輸入: `https://github.com/supabase-community/supabase-swift`
3. 選擇所有模組並安裝

### 3. 複製程式碼檔案

將 `ios/ReMeet/` 資料夾內的所有檔案複製到你的 Xcode 專案中。

**方式 1: 手動複製**
- 在 Xcode 中右鍵點擊專案
- New Group 建立對應的資料夾結構
- 將 .swift 檔案拖入對應位置

**方式 2: 直接匯入**
- 將整個 `ReMeet` 資料夾拖入 Xcode
- 選擇 "Create groups"
- 確認 "Copy items if needed" 有勾選

### 4. 設定 Supabase 憑證

**選項 A: 使用 Info.plist（推薦）**

1. 打開 `Info.plist`
2. 添加兩個 key：
   ```xml
   <key>SUPABASE_URL</key>
   <string>https://your-project-ref.supabase.co</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>your-anon-key-here</string>
   ```

3. 從 Supabase Dashboard 取得憑證：
   - 登入 https://app.supabase.com
   - 選擇 Re:Meet 專案
   - Settings → API
   - 複製 Project URL 和 anon key

**選項 B: 直接在程式碼中（僅開發測試用）**

修改 `Core/Config/SupabaseConfig.swift`：
```swift
static var supabaseURL: URL {
    return URL(string: "https://your-project-ref.supabase.co")!
}

static var supabaseAnonKey: String {
    return "your-anon-key-here"
}
```

⚠️ **注意**: 不要將實際的 API keys commit 到 git！

### 5. 設定 Info.plist 權限

在 Info.plist 添加相機權限（未來掃描名片需要）：

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan business cards</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to save business cards</string>
```

### 6. 執行專案

1. 選擇 iPhone 模擬器（建議 iPhone 14 或更新）
2. 點擊 Run (⌘R)
3. 應該會看到登入畫面

## 📱 目前功能狀態

### ✅ 已完成
- 完整的認證系統（登入、註冊、忘記密碼）
- Supabase 整合
- 主要導航結構（TabView）
- 聯絡人列表顯示
- 使用者個人資料
- 資料模型（所有 tables）

### 🚧 占位功能（需要實作）
- 相機掃描名片
- 公司列表
- 時間軸檢視
- AI 聊天介面
- OCR 處理
- 名片圖片上傳

## 🔧 下一步開發

### Phase 1: 基礎功能（MVP）
1. **相機功能**
   - 使用 `AVFoundation` 實作相機
   - 拍照並儲存到 Supabase Storage
   - 顯示拍攝的圖片

2. **手動輸入名片資訊**
   - 建立表單讓用戶輸入聯絡人資訊
   - 儲存到 Supabase

3. **聯絡人詳情完善**
   - 編輯功能
   - 刪除功能
   - 添加會面情境

### Phase 2: OCR 整合
1. 建立 n8n workflow
2. iOS app 上傳圖片後呼叫 n8n API
3. 顯示 OCR 結果並允許編輯

### Phase 3: AI 功能
1. 實作 AI 聊天介面
2. 整合情境記錄功能
3. 智能搜尋

## 📝 注意事項

1. **編譯錯誤處理**
   - 確保所有 import 正確
   - 如果有 "Cannot find SupabaseClient"，檢查是否正確安裝 SDK

2. **模擬器 vs 真機**
   - 相機功能需要在真機測試
   - 其他功能可以在模擬器開發

3. **資料庫連線**
   - 確保 Supabase 專案已正確設定
   - 檢查 RLS policies 是否啟用

## 🆘 常見問題

### Q: 編譯錯誤 "Cannot find type SupabaseClient"
A: 確保已安裝 Supabase Swift SDK，並在每個需要的檔案頂部加上 `import Supabase`

### Q: 登入後沒有反應
A: 檢查：
1. Supabase URL 和 Key 是否正確
2. 網路連線是否正常
3. Xcode console 的錯誤訊息

### Q: 如何測試認證功能？
A: 可以在 Supabase Dashboard 手動建立測試用戶，或直接使用註冊功能

## 📚 相關文件

- [iOS_PROJECT_SETUP.md](../iOS_PROJECT_SETUP.md) - 詳細設定指南
- [SUPABASE_SETUP.md](../SUPABASE_SETUP.md) - Supabase 設定
- [PRD.md](../PRD.md) - 產品需求文件

---

**版本**: 1.0 (MVP)
**最後更新**: 2026-01-10
**開發者**: Claude + 你
