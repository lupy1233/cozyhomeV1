-- ===================================================================
-- DATABASE SETUP VERIFICATION SCRIPT
-- ===================================================================
-- Run this after the complete setup to verify everything is working
-- ===================================================================

-- Check installed extensions
SELECT 
  'Extensions' as check_type,
  string_agg(extname, ', ') as installed
FROM pg_extension 
WHERE extname IN ('uuid-ossp');

-- Check custom types
SELECT 
  'Custom Types' as check_type,
  string_agg(typname, ', ') as created_types
FROM pg_type 
WHERE typname IN ('user_role', 'account_status', 'rfq_status', 'offer_status', 
                  'message_status', 'firm_user_role', 'assignment_mode', 'assignment_status')
AND typtype = 'e';

-- Check main system tables
SELECT 
  'Main Tables' as check_type,
  string_agg(table_name, ', ') as tables
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'homes', 'categories', 'rfqs', 'rfq_categories', 
                   'rfq_answers', 'files', 'offers', 'messages', 'notifications');

-- Check firm system tables
SELECT 
  'Firm Tables' as check_type,
  string_agg(table_name, ', ') as tables
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('firms', 'firm_users', 'firm_settings', 'rfq_assignments', 'firm_sessions');

-- Check functions
SELECT 
  'Functions' as check_type,
  string_agg(routine_name, ', ') as functions
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('update_updated_at_column', 'validate_manufacturer_offer', 
                     'handle_new_user', 'update_user_last_login', 'get_filtered_rfqs');

-- Check triggers
SELECT 
  'Triggers' as check_type,
  string_agg(trigger_name, ', ') as triggers
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND trigger_name LIKE '%updated_at%' OR trigger_name LIKE '%manufacturer%' 
OR trigger_name LIKE '%user%';

-- Check indexes
SELECT 
  'Indexes' as check_type,
  COUNT(*)::text as index_count
FROM pg_indexes 
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%';

-- Check RLS status
SELECT 
  'RLS Enabled Tables' as check_type,
  string_agg(tablename, ', ') as tables
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true;

-- Check policies count
SELECT 
  'Security Policies' as check_type,
  COUNT(*)::text as policy_count
FROM pg_policies 
WHERE schemaname = 'public';

-- Check categories
SELECT 
  'Categories' as check_type,
  COUNT(*)::text || ' categories' as count
FROM public.categories;

-- Summary
SELECT 
  '=== SETUP SUMMARY ===' as check_type,
  'If all checks above show data, the setup is complete!' as status; 