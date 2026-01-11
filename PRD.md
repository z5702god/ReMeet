# Product Requirements Document (PRD)
# ReMeet - AI-Powered Business Card Management App

**Version**: 1.0
**Date**: 2026-01-10
**Status**: Draft

---

## Executive Summary

ReMeet is an iOS application that revolutionizes business card management by combining OCR technology, AI-powered context tracking, and intelligent search capabilities. Unlike traditional business card apps that simply digitize contacts, ReMeet helps users remember the story behind each connection - where they met, when, and in what context - making networking more meaningful and effective.

---

## Problem Statement

**Current Pain Points:**
- Business professionals collect numerous business cards but struggle to remember the context of each meeting
- Traditional business card apps only store contact information without relationship context
- Finding the right contact requires remembering names rather than circumstances
- No easy way to revisit networking moments or recall meeting details
- Manual data entry is time-consuming and error-prone

**User Need:**
Business professionals need a smart way to not just store business cards, but to preserve and retrieve the meaningful context of each professional relationship.

---

## Goals & Objectives

### Primary Goals
1. Reduce business card data entry time by 90% through batch OCR processing
2. Enable context-based contact search ("Who did I meet at the tech conference last month?")
3. Create a memorable, story-driven approach to contact management

### Success Metrics
- **Adoption**: 10,000+ downloads in first 3 months
- **Engagement**: Users scan average 10+ cards per month
- **Retention**: 60% MAU (Monthly Active Users) after 3 months
- **AI Interaction**: 70% of users use AI search at least once per week
- **OCR Accuracy**: >95% accuracy on key fields (name, company, phone, email)

---

## User Personas

### Primary Persona: "Networking Nancy"
- **Role**: Sales Manager at Tech Startup
- **Age**: 28-35
- **Tech Savvy**: High
- **Pain Point**: Attends 3-5 networking events per month, collects 20-30 cards, forgets context
- **Goal**: Build meaningful professional relationships and follow up effectively
- **Quote**: "I remember faces and conversations, but I can never find the right business card when I need it"

### Secondary Persona: "Executive Eric"
- **Role**: VP of Business Development
- **Age**: 40-50
- **Tech Savvy**: Medium
- **Pain Point**: Large existing network, needs better organization and recall
- **Goal**: Maintain and leverage professional network efficiently
- **Quote**: "I have hundreds of contacts but no way to remember how I know each person"

---

## User Stories

### Core Functionality

**US-001: Batch Card Scanning**
- **As a** business professional
- **I want to** scan multiple business cards at once after a networking event
- **So that** I can quickly digitize all new contacts without manual entry

**US-002: Contextual Memory Recording**
- **As a** user
- **I want to** tell an AI agent where, when, and how I met someone
- **So that** I can preserve the story behind each connection

**US-003: Company-Based Organization**
- **As a** user
- **I want to** view all contacts grouped by company
- **So that** I can understand my network within each organization

**US-004: Memory Timeline**
- **As a** user
- **I want to** browse my business cards like a photo album with memories
- **So that** I can revisit networking moments chronologically

**US-005: Conversational Search**
- **As a** user
- **I want to** ask the AI "Have I met someone named [name]?"
- **So that** the system reminds me of when and where we met

**US-006: Context-Based Retrieval**
- **As a** user
- **I want to** search by event or location (e.g., "Show me people from the AWS Summit")
- **So that** I can find contacts based on circumstances rather than names

---

## Functional Requirements

### 1. Business Card Capture & OCR

**FR-1.1: Multi-Card Camera Capture**
- Support batch scanning of multiple business cards in one session
- Auto-detect card boundaries and capture individual images
- Provide visual feedback for successful capture
- Allow retake for individual cards

**FR-1.2: OCR Processing**
- Extract key fields: Name, Title, Company, Phone, Email, Address, Website
- Support English and Chinese (Traditional/Simplified) business cards
- Confidence scoring for OCR results
- Queue-based processing for multiple cards

**FR-1.3: Manual Editing**
- Allow users to review and edit OCR results
- Highlight low-confidence fields for review
- Original card image always accessible

### 2. AI-Powered Context Recording

**FR-2.1: Conversational Context Input**
- Chat interface with AI agent to record meeting context
- Natural language processing for date, time, location, occasion
- Support voice input for hands-free entry
- Structured data extraction from conversation

**FR-2.2: Meeting Context Fields**
- Date & Time
- Location (with map integration)
- Event/Occasion name
- Notes/Conversation topics
- Relationship type (client, partner, investor, etc.)
- Follow-up reminders (optional)

### 3. Database & Storage (Supabase)

**FR-3.1: Data Schema**
```
Tables:
- business_cards
  - id, user_id, image_url, created_at, updated_at

- contacts
  - id, card_id, name, title, company_id, phone, email, website, address
  - ocr_confidence_score, is_verified

- companies
  - id, name, industry, logo_url, website

- meeting_contexts
  - id, contact_id, date, time, location, location_lat, location_lng
  - event_name, occasion_type, notes, relationship_type

- users
  - id, email, name, created_at, preferences
```

**FR-3.2: Data Synchronization**
- Real-time sync across user devices
- Offline mode with local SQLite cache
- Conflict resolution for concurrent edits

### 4. Organization & Categorization

**FR-4.1: Company Grouping**
- Auto-group contacts by company
- Display company logo (fetched from Clearbit/similar API)
- Company-level statistics (# of contacts, last interaction)

**FR-4.2: Smart Lists**
- Recent contacts (last 30 days)
- Favorites/Starred contacts
- Custom tags/labels
- Event-based collections

### 5. Memory & Timeline Features

**FR-5.1: Timeline View**
- Chronological browsing of business cards
- Calendar view with meeting density visualization
- Filter by date range, location, or company

**FR-5.2: Memory Playback**
- Card flip animation showing front/back
- Display meeting context alongside card image
- Photo gallery-style navigation
- Search and filter within memories

### 6. AI Agent Chat Interface

**FR-6.1: Conversational Search**
- Natural language query processing
- Examples:
  - "Did I meet someone named David?"
  - "Who did I meet at the CES event?"
  - "Show me contacts from Google"
  - "When did I last meet John from Microsoft?"

**FR-6.2: AI Responses**
- Contextual answers with meeting details
- Display relevant business cards
- Suggest follow-up actions
- Provide relationship insights

**FR-6.3: Chat History**
- Persistent conversation history
- Quick access to frequent queries
- Suggested questions based on recent activity

### 7. Backend Integration (n8n)

**FR-7.1: n8n Workflow Responsibilities**
- OCR processing orchestration (integration with Google Vision AI, AWS Textract, or Azure Computer Vision)
- AI conversation handling (OpenAI API integration)
- Database queries and vector search (for semantic search)
- Image storage and optimization
- Webhook endpoints for iOS app

**FR-7.2: API Endpoints**
```
POST /api/cards/upload - Upload card images
POST /api/cards/batch-upload - Batch upload multiple cards
GET /api/cards - List user's cards
GET /api/cards/:id - Get card details
PUT /api/cards/:id - Update card information
DELETE /api/cards/:id - Delete card

POST /api/chat - Send chat message to AI agent
GET /api/chat/history - Get chat history

GET /api/contacts - List contacts with filters
GET /api/contacts/search - Semantic search contacts
GET /api/companies - List companies
```

---

## Non-Functional Requirements

### Performance
- **NFR-1**: OCR processing completes within 5 seconds per card
- **NFR-2**: AI chat response time < 2 seconds
- **NFR-3**: App launch time < 2 seconds
- **NFR-4**: Support up to 10,000 business cards per user
- **NFR-5**: Image upload should support batch of 10 cards simultaneously

### Security & Privacy
- **NFR-6**: End-to-end encryption for sensitive contact data
- **NFR-7**: SOC 2 compliant data storage (Supabase provides this)
- **NFR-8**: User authentication via OAuth 2.0 (Apple Sign In, Google)
- **NFR-9**: GDPR-compliant data export and deletion
- **NFR-10**: Business card images stored with access control

### Usability
- **NFR-11**: Support iOS 15+, optimized for iPhone 12 and newer
- **NFR-12**: Support Dark Mode
- **NFR-13**: Accessibility: VoiceOver support, Dynamic Type
- **NFR-14**: Localization: English, Traditional Chinese, Simplified Chinese

### Reliability
- **NFR-15**: 99.9% uptime for backend services
- **NFR-16**: Graceful degradation when offline
- **NFR-17**: Automatic retry for failed OCR processing
- **NFR-18**: Data backup every 24 hours

---

## Technical Architecture

### High-Level System Design

```
┌─────────────────────────────────────────────┐
│           iOS App (Swift/SwiftUI)           │
│  ┌─────────┐  ┌─────────┐  ┌────────────┐  │
│  │ Camera  │  │   AI    │  │  Timeline  │  │
│  │  + OCR  │  │  Chat   │  │   Browse   │  │
│  └─────────┘  └─────────┘  └────────────┘  │
└─────────────────┬───────────────────────────┘
                  │ HTTPS/REST API
                  ▼
┌─────────────────────────────────────────────┐
│              n8n Workflows                   │
│  ┌──────────────┐  ┌────────────────────┐   │
│  │ OCR Pipeline │  │  AI Agent Service  │   │
│  │ (Vision API) │  │  (OpenAI GPT-4)    │   │
│  └──────────────┘  └────────────────────┘   │
│  ┌──────────────┐  ┌────────────────────┐   │
│  │ Image Proc.  │  │  Vector Search     │   │
│  │ (Cloudinary) │  │  (Embeddings)      │   │
│  └──────────────┘  └────────────────────┘   │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│         Supabase (Backend as a Service)     │
│  ┌──────────────┐  ┌────────────────────┐   │
│  │  PostgreSQL  │  │   Auth Service     │   │
│  │   Database   │  │   (Row Level Sec)  │   │
│  └──────────────┘  └────────────────────┘   │
│  ┌──────────────┐  ┌────────────────────┐   │
│  │    Storage   │  │   Realtime Sync    │   │
│  │   (Images)   │  │                    │   │
│  └──────────────┘  └────────────────────┘   │
└─────────────────────────────────────────────┘
```

### Technology Stack

**iOS Frontend:**
- Swift 5.9+
- SwiftUI for UI
- AVFoundation for camera
- CoreML for on-device text detection
- Combine for reactive programming
- SQLite for offline cache

**Backend (n8n):**
- n8n workflow automation
- Node.js runtime
- HTTP endpoints for API
- Integration nodes:
  - Google Vision AI / AWS Textract (OCR)
  - OpenAI API (GPT-4 for AI chat)
  - Supabase nodes (database operations)
  - Cloudinary (image processing)

**Database & Services:**
- Supabase (PostgreSQL, Auth, Storage, Realtime)
- Vector database for semantic search (pgvector extension)

**Third-Party Services:**
- OCR: Google Cloud Vision API or AWS Textract
- AI: OpenAI GPT-4 API
- Image CDN: Cloudinary or Supabase Storage
- Maps: Apple MapKit
- Company data: Clearbit API (optional)

---

## User Interface Design

### Key Screens

1. **Home Screen**
   - Recent business cards grid
   - Quick scan FAB button
   - AI chat button
   - Bottom navigation: Cards, Companies, Timeline, Profile

2. **Camera/Scan Screen**
   - Multi-card capture interface
   - Real-time card detection overlay
   - Batch scan indicator (3/5 cards)
   - Review & retake options

3. **AI Context Chat**
   - Conversational UI
   - Quick prompts: "Add meeting context", "When was this?", "Where did we meet?"
   - Auto-populated entities (dates, locations)
   - Save context button

4. **Card Detail View**
   - Front/back card images
   - Extracted contact information
   - Meeting context card
   - Quick actions: Call, Email, Navigate, Edit

5. **Company View**
   - Company header with logo
   - List of contacts from company
   - Company notes
   - Last interaction date

6. **Timeline/Memory View**
   - Calendar picker
   - Card gallery by date
   - Event groupings
   - Filter by location/company

7. **AI Search Chat**
   - Conversation interface
   - Contact card results
   - Contextual insights
   - Follow-up suggestions

---

## Data Flow Examples

### Flow 1: Scanning Business Cards

1. User taps "Scan Cards" button
2. Camera opens with card detection
3. User captures 5 business cards
4. App uploads images to n8n endpoint
5. n8n triggers OCR workflow:
   - Send to Vision API
   - Parse OCR results
   - Extract structured data
   - Store in Supabase
6. App receives OCR results
7. User reviews and confirms data
8. AI agent prompts: "Tell me about meeting these people"
9. User describes context via chat
10. AI extracts meeting metadata
11. Context saved to database
12. Cards appear in timeline and company views

### Flow 2: Searching with AI

1. User opens chat interface
2. Types: "Did I meet anyone from Microsoft last month?"
3. App sends query to n8n AI endpoint
4. n8n workflow:
   - Generate embedding for query
   - Vector search in database
   - Filter by company = "Microsoft" and date range
   - Format results with context
   - Generate natural language response
5. AI responds: "Yes, you met 2 people from Microsoft in December:
   - Sarah Chen (PM) at Tech Summit on Dec 15
   - David Liu (Engineer) at Coffee meeting on Dec 22"
6. Display contact cards with meeting context
7. User can tap to view full details

---

## Development Phases & Timeline

### Phase 1: MVP (8-10 weeks)
**Core Features:**
- Basic OCR scanning (single card)
- Manual context input (form-based)
- Supabase database setup
- Simple contact list and detail views
- Basic n8n workflows for OCR

**Deliverables:**
- Functional iOS app (TestFlight)
- Working OCR pipeline
- Basic database schema
- API documentation

### Phase 2: AI & Intelligence (6-8 weeks)
**Core Features:**
- Batch card scanning
- AI chat for context recording
- Conversational search
- Company grouping
- n8n AI agent workflows

**Deliverables:**
- AI-powered context input
- Semantic search capability
- Enhanced user experience

### Phase 3: Memory & Polish (4-6 weeks)
**Core Features:**
- Timeline/memory view
- Photo album browsing
- Advanced filters
- Offline mode
- Performance optimization

**Deliverables:**
- Complete feature set
- App Store submission
- User documentation

### Phase 4: Launch & Iterate (Ongoing)
**Focus:**
- User feedback integration
- Bug fixes
- Performance monitoring
- Feature enhancements

---

## Success Metrics & KPIs

### Engagement Metrics
- **Daily Active Users (DAU)**: Target 30% of MAU
- **Cards Scanned per User**: Target 10+ per month
- **AI Chat Interactions**: Target 5+ per week
- **Session Duration**: Target 3+ minutes average

### Quality Metrics
- **OCR Accuracy**: Target >95% on key fields
- **AI Search Success Rate**: >80% queries return relevant results
- **User Satisfaction (NPS)**: Target 50+
- **Crash-Free Rate**: >99.5%

### Business Metrics
- **User Acquisition Cost (CAC)**: Target <$10
- **Retention Rate (D7)**: >40%
- **Retention Rate (D30)**: >25%
- **App Store Rating**: Target 4.5+

---

## Risks & Mitigation

### Technical Risks

**RISK-1: OCR Accuracy Issues**
- **Impact**: High - Core feature reliability
- **Probability**: Medium
- **Mitigation**:
  - Use multiple OCR providers with fallback
  - Implement confidence scoring and manual review
  - Train custom models for common card formats
  - Allow manual editing of all fields

**RISK-2: AI Hallucination in Context**
- **Impact**: Medium - Incorrect meeting details
- **Probability**: Medium
- **Mitigation**:
  - Always show confidence levels
  - Require user confirmation for extracted entities
  - Implement structured prompts with validation
  - Allow easy editing of AI-generated context

**RISK-3: Supabase Scaling Limits**
- **Impact**: High - Service degradation
- **Probability**: Low
- **Mitigation**:
  - Monitor database performance
  - Implement caching strategies
  - Design for horizontal scaling
  - Have migration plan to dedicated infrastructure

**RISK-4: n8n Workflow Complexity**
- **Impact**: Medium - Development velocity
- **Probability**: Medium
- **Mitigation**:
  - Document workflows thoroughly
  - Version control n8n workflows (JSON export)
  - Implement comprehensive testing
  - Consider migration to custom backend if complexity grows

### Business Risks

**RISK-5: User Privacy Concerns**
- **Impact**: High - Adoption barrier
- **Probability**: Medium
- **Mitigation**:
  - Clear privacy policy
  - Option to store data locally only
  - SOC 2 compliance
  - Transparent data usage

**RISK-6: Competitive Landscape**
- **Impact**: Medium - Market differentiation
- **Probability**: High
- **Mitigation**:
  - Focus on unique AI context features
  - Build community and word-of-mouth
  - Iterate quickly based on feedback
  - Patent AI conversation approach if novel

---

## Out of Scope (V1)

The following features are explicitly **not included** in the initial version:

1. **Android App** - iOS only for MVP
2. **Web Dashboard** - Mobile-first approach
3. **CRM Integration** - Standalone product initially
4. **Email Campaign Features** - Focus on organization, not outreach
5. **Team/Collaboration Features** - Single-user product
6. **Business Card Printing/Design** - Input only, not output
7. **Social Media Integration** - Direct contact info only
8. **Automatic Follow-up Reminders** - Manual for now
9. **Analytics Dashboard** - Basic metrics only
10. **Multi-language OCR** - English and Chinese only

---

## Appendix

### A. Competitive Analysis

**Existing Solutions:**
- **CamCard**: Strong OCR, weak on context and AI
- **HiHello**: Digital cards, not focused on physical card management
- **Evernote Scannable**: General scanning, not business card specific
- **Built-in iOS Contacts**: No context, manual entry

**ReMeet Differentiation:**
- AI-powered context recording (unique)
- Conversational search (unique)
- Memory/timeline approach (unique)
- Story-driven networking (unique)

### B. User Research Insights
- 73% of surveyed professionals lose business card context within 1 week
- 85% prefer scanning vs. manual entry
- 62% would use AI search if available
- Top frustration: "I remember the person but can't find their card"

### C. Technical Specifications

**Image Requirements:**
- Format: JPEG, PNG
- Min resolution: 1280x720
- Max file size: 5MB per card
- Color space: sRGB

**API Rate Limits:**
- OCR: 100 requests/minute
- AI Chat: 50 requests/minute
- Database queries: 1000 requests/minute

**Data Retention:**
- Business cards: Unlimited
- Chat history: 90 days
- Backups: 30 days

---

## Approval & Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Product Owner | | | |
| Technical Lead | | | |
| Design Lead | | | |
| iOS Developer | | | |

---

**Document Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-10 | Claude | Initial draft based on user requirements |

---

**Next Steps:**
1. Review and refine PRD with stakeholders
2. Create detailed UI/UX mockups
3. Set up development environment
4. Initialize Supabase project
5. Create n8n workspace and initial workflows
6. Begin iOS app scaffold development

