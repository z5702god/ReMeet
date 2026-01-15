# Changelog

All notable changes to Re:Meet will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-15

### Added
- Initial release of Re:Meet
- Business card scanning with Google Cloud Vision OCR
- Contact management (create, read, update, delete)
- Meeting context notes for each contact
- Company organization and grouping
- Search functionality across contacts
- Favorites system
- Timeline view of meetings
- AI-powered chat assistant (via n8n)
- Dark Mode support
- User authentication (email/password)
- Password reset functionality
- Delete account functionality
- Privacy policy (in-app and web)

### Security
- API keys stored in Config.xcconfig (not in source code)
- RFC 5322 email validation
- Password complexity requirements (8+ chars, uppercase, lowercase, number)
- HTTPS for all API communications

---

## Template for Future Releases

## [Unreleased]

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Features that will be removed in future versions

### Removed
- Features that were removed

### Fixed
- Bug fixes

### Security
- Security improvements
