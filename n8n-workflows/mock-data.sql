-- ReMeet Mock Data for Testing AI Chat
-- User ID: d0617310-7540-4025-94c2-9691c572b6a3

-- =============================================
-- 1. Insert Companies
-- =============================================

INSERT INTO companies (id, name, industry, website, description, created_at, updated_at) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Google', 'Technology', 'https://google.com', 'Search and cloud company', NOW(), NOW()),
  ('22222222-2222-2222-2222-222222222222', 'Anthropic', 'AI Research', 'https://anthropic.com', 'AI safety company', NOW(), NOW()),
  ('33333333-3333-3333-3333-333333333333', 'TSMC', 'Semiconductor', 'https://tsmc.com', 'Taiwan Semiconductor Manufacturing', NOW(), NOW()),
  ('44444444-4444-4444-4444-444444444444', 'Appier', 'AI/AdTech', 'https://appier.com', 'AI-powered marketing platform', NOW(), NOW()),
  ('55555555-5555-5555-5555-555555555555', 'PChome', 'E-commerce', 'https://pchome.com.tw', 'Taiwan e-commerce platform', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- 2. Insert Contacts
-- =============================================

INSERT INTO contacts (id, user_id, company_id, full_name, title, department, phone, email, is_verified, is_favorite, tags, notes, created_at, updated_at) VALUES
  -- Google contacts
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'd0617310-7540-4025-94c2-9691c572b6a3', '11111111-1111-1111-1111-111111111111',
   'David Chen', 'Senior Product Manager', 'Product', '+1-650-123-4567', 'david.chen@google.com',
   true, true, ARRAY['tech', 'PM'], 'Met at Google I/O', NOW() - INTERVAL '5 days', NOW()),

  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'd0617310-7540-4025-94c2-9691c572b6a3', '11111111-1111-1111-1111-111111111111',
   'Sarah Wang', 'Software Engineer', 'Engineering', '+1-650-234-5678', 'sarah.wang@google.com',
   true, false, ARRAY['tech', 'engineer'], 'Interested in AI projects', NOW() - INTERVAL '10 days', NOW()),

  -- Anthropic contacts
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'd0617310-7540-4025-94c2-9691c572b6a3', '22222222-2222-2222-2222-222222222222',
   'Michael Liu', 'Research Scientist', 'Research', '+1-415-345-6789', 'michael.liu@anthropic.com',
   true, true, ARRAY['AI', 'research'], 'Claude team member', NOW() - INTERVAL '3 days', NOW()),

  -- TSMC contacts
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'd0617310-7540-4025-94c2-9691c572b6a3', '33333333-3333-3333-3333-333333333333',
   '張志明', 'Director', 'Business Development', '+886-3-567-8901', 'zhiming.zhang@tsmc.com',
   true, false, ARRAY['semiconductor', 'BD'], '台積電業務開發主管', NOW() - INTERVAL '15 days', NOW()),

  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'd0617310-7540-4025-94c2-9691c572b6a3', '33333333-3333-3333-3333-333333333333',
   '林美玲', 'Senior Engineer', 'R&D', '+886-3-678-9012', 'meiling.lin@tsmc.com',
   true, false, ARRAY['semiconductor', 'engineer'], '製程研發專家', NOW() - INTERVAL '20 days', NOW()),

  -- Appier contacts
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', 'd0617310-7540-4025-94c2-9691c572b6a3', '44444444-4444-4444-4444-444444444444',
   '王小華', 'VP of Engineering', 'Engineering', '+886-2-789-0123', 'xiaohua.wang@appier.com',
   true, true, ARRAY['AI', 'startup'], 'Appier 工程副總', NOW() - INTERVAL '7 days', NOW()),

  -- PChome contacts
  ('10000001-aaaa-bbbb-cccc-dddddddddddd', 'd0617310-7540-4025-94c2-9691c572b6a3', '55555555-5555-5555-5555-555555555555',
   '陳大文', 'Product Director', 'Product', '+886-2-890-1234', 'dawen.chen@pchome.com.tw',
   true, false, ARRAY['ecommerce', 'product'], 'PChome 產品總監', NOW() - INTERVAL '25 days', NOW()),

  -- Independent consultant (no company)
  ('20000002-aaaa-bbbb-cccc-dddddddddddd', 'd0617310-7540-4025-94c2-9691c572b6a3', NULL,
   'Alex Johnson', 'Independent Consultant', NULL, '+1-510-901-2345', 'alex.j@gmail.com',
   true, false, ARRAY['consultant', 'freelance'], 'Startup advisor', NOW() - INTERVAL '2 days', NOW())

ON CONFLICT (id) DO NOTHING;

-- =============================================
-- 3. Insert Meeting Contexts
-- =============================================

INSERT INTO meeting_contexts (id, user_id, contact_id, meeting_date, location_name, location_address, event_name, occasion_type, relationship_type, conversation_topics, notes, follow_up_required, follow_up_date, follow_up_notes, created_at, updated_at) VALUES
  -- David Chen - met at Tech Summit in Taipei
  ('a1000001-1111-1111-1111-111111111111', 'd0617310-7540-4025-94c2-9691c572b6a3', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   '2026-01-08', 'Taipei International Convention Center', '台北市信義區信義路五段1號',
   'Tech Summit 2026', 'conference', 'potential_partner',
   ARRAY['AI products', 'Google Cloud', 'Partnership opportunities'],
   'Discussed potential collaboration on AI features. Very interested in our app.',
   true, '2026-01-20', 'Send product demo and partnership proposal',
   NOW() - INTERVAL '5 days', NOW()),

  -- Sarah Wang - met at Google office
  ('a2000002-2222-2222-2222-222222222222', 'd0617310-7540-4025-94c2-9691c572b6a3', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
   '2026-01-03', 'Google Taipei Office', '台北市信義區松仁路100號',
   'Office Visit', 'business_meeting', 'technical_contact',
   ARRAY['Mobile development', 'Firebase', 'ML Kit'],
   'Technical discussion about integrating Google ML Kit for OCR.',
   false, NULL, NULL,
   NOW() - INTERVAL '10 days', NOW()),

  -- Michael Liu - met at AI conference in San Francisco
  ('a3000003-3333-3333-3333-333333333333', 'd0617310-7540-4025-94c2-9691c572b6a3', 'cccccccc-cccc-cccc-cccc-cccccccccccc',
   '2026-01-10', 'Moscone Center', 'San Francisco, CA',
   'AI Summit SF', 'conference', 'industry_expert',
   ARRAY['Claude API', 'AI safety', 'LLM applications'],
   'Great insights on using Claude for business applications. Offered to help with AI integration.',
   true, '2026-01-25', 'Schedule follow-up call about Claude API integration',
   NOW() - INTERVAL '3 days', NOW()),

  -- 張志明 - met at TSMC event
  ('a4000004-4444-4444-4444-444444444444', 'd0617310-7540-4025-94c2-9691c572b6a3', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
   '2025-12-28', '新竹科學園區', '新竹市東區力行路1號',
   'TSMC Tech Day', 'conference', 'potential_client',
   ARRAY['半導體產業', '數位轉型', 'CRM需求'],
   '對我們的名片管理解決方案有興趣，希望能為TSMC客戶關係管理提供幫助。',
   true, '2026-01-18', '準備企業版proposal給TSMC',
   NOW() - INTERVAL '15 days', NOW()),

  -- 林美玲 - also met at TSMC
  ('a5000005-5555-5555-5555-555555555555', 'd0617310-7540-4025-94c2-9691c572b6a3', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
   '2025-12-28', '新竹科學園區', '新竹市東區力行路1號',
   'TSMC Tech Day', 'conference', 'technical_contact',
   ARRAY['製程技術', 'R&D collaboration'],
   '張志明的同事，負責技術評估。',
   false, NULL, NULL,
   NOW() - INTERVAL '15 days', NOW()),

  -- 王小華 - met at startup event
  ('a6000006-6666-6666-6666-666666666666', 'd0617310-7540-4025-94c2-9691c572b6a3', 'ffffffff-ffff-ffff-ffff-ffffffffffff',
   '2026-01-06', 'AppWorks', '台北市松山區民生東路三段',
   'Startup Mixer', 'networking', 'industry_peer',
   ARRAY['AI startup', 'Growth strategies', 'Engineering culture'],
   'Appier的工程副總，分享了很多 AI startup 經驗。',
   true, '2026-01-22', '約喝咖啡深聊技術團隊建設',
   NOW() - INTERVAL '7 days', NOW()),

  -- 陳大文 - met at e-commerce conference
  ('a7000007-7777-7777-7777-777777777777', 'd0617310-7540-4025-94c2-9691c572b6a3', '10000001-aaaa-bbbb-cccc-dddddddddddd',
   '2025-12-18', '台北世貿中心', '台北市信義區信義路五段5號',
   'E-commerce Expo 2025', 'conference', 'potential_client',
   ARRAY['電商趨勢', '客戶管理', 'B2B solutions'],
   'PChome產品總監，對企業版名片管理很有興趣。',
   false, NULL, NULL,
   NOW() - INTERVAL '25 days', NOW()),

  -- Alex Johnson - met at coffee chat
  ('a8000008-8888-8888-8888-888888888888', 'd0617310-7540-4025-94c2-9691c572b6a3', '20000002-aaaa-bbbb-cccc-dddddddddddd',
   '2026-01-11', 'Starbucks Reserve', 'San Francisco, CA',
   'Coffee Chat', 'networking', 'advisor',
   ARRAY['Startup advice', 'Fundraising', 'Product strategy'],
   'Experienced startup advisor. Offered to make introductions to VCs.',
   true, '2026-01-30', 'Send pitch deck for feedback',
   NOW() - INTERVAL '2 days', NOW())

ON CONFLICT (id) DO NOTHING;

-- =============================================
-- Verification Query
-- =============================================

-- Run this to verify data was inserted:
-- SELECT c.full_name, c.title, co.name as company, mc.event_name, mc.location_name, mc.meeting_date
-- FROM contacts c
-- LEFT JOIN companies co ON c.company_id = co.id
-- LEFT JOIN meeting_contexts mc ON c.id = mc.contact_id
-- WHERE c.user_id = 'd0617310-7540-4025-94c2-9691c572b6a3'
-- ORDER BY mc.meeting_date DESC;
