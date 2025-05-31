-- ===================================================================
-- SAMPLE DATA FOR TESTING
-- ===================================================================
-- Run this after the complete setup to add test data
-- WARNING: This will add test data to your database
-- ===================================================================

-- Create test homeowner user (use Supabase Auth to create the auth user first)
-- Email: client@test.ro, Password: test123
-- After creating in Supabase Auth, update the user profile:
/*
UPDATE public.users 
SET 
  first_name = 'Maria',
  last_name = 'Ionescu',
  phone = '0722123456',
  role = 'homeowner'
WHERE email = 'client@test.ro';
*/

-- Insert test home for the user
/*
INSERT INTO public.homes (user_id, name, county, city, street, number, apartment, postal_code, description, total_area, is_primary)
VALUES (
  (SELECT id FROM public.users WHERE email = 'client@test.ro'),
  'Apartament Principal',
  'București',
  'București Sector 2',
  'Strada Mihai Eminescu',
  '42',
  'Ap. 15',
  '020079',
  'Apartament 3 camere, etaj 4',
  85.5,
  true
);
*/

-- Insert test firms
INSERT INTO public.firms (name, tax_id, address, city, county, phone, email, website, description) VALUES
('Mobila Bucuresti SRL', 'RO12345678', 'Str. Industriilor 25', 'București', 'București', '021-312-4567', 'contact@mobilabucuresti.ro', 'www.mobilabucuresti.ro', 'Producător de mobilă la comandă din 1995'),
('Transilvania Wood SA', 'RO87654321', 'Bd. Eroilor 150', 'Cluj-Napoca', 'Cluj', '0264-123-456', 'office@transilvaniawood.ro', 'www.transilvaniawood.ro', 'Mobilier premium din lemn masiv'),
('Elegant Furniture SRL', 'RO11223344', 'Str. Depozitelor 8', 'Timișoara', 'Timiș', '0256-789-012', 'info@elegantfurniture.ro', null, 'Design modern și contemporan');

-- Get firm IDs for reference
-- SELECT id, name FROM public.firms;

-- Insert firm CEOs (password for all: 'test123')
-- Password hash: $2a$10$ZYqwRz5Atq0qMr3Yxlwc2OJ5ziIa9Kzqv3hU5XhEFK5QHGNHh9Ay2
INSERT INTO public.firm_users (firm_id, email, password_hash, first_name, last_name, phone, role) VALUES
((SELECT id FROM public.firms WHERE tax_id = 'RO12345678'), 'ceo@mobilabucuresti.ro', '$2a$10$ZYqwRz5Atq0qMr3Yxlwc2OJ5ziIa9Kzqv3hU5XhEFK5QHGNHh9Ay2', 'Alexandru', 'Popescu', '0721-111-111', 'ceo'),
((SELECT id FROM public.firms WHERE tax_id = 'RO87654321'), 'director@transilvaniawood.ro', '$2a$10$ZYqwRz5Atq0qMr3Yxlwc2OJ5ziIa9Kzqv3hU5XhEFK5QHGNHh9Ay2', 'Ioan', 'Mureșan', '0722-222-222', 'ceo'),
((SELECT id FROM public.firms WHERE tax_id = 'RO11223344'), 'manager@elegantfurniture.ro', '$2a$10$ZYqwRz5Atq0qMr3Yxlwc2OJ5ziIa9Kzqv3hU5XhEFK5QHGNHh9Ay2', 'Elena', 'Dumitrescu', '0723-333-333', 'ceo');

-- Insert firm employees
INSERT INTO public.firm_users (firm_id, email, password_hash, first_name, last_name, phone, role) VALUES
((SELECT id FROM public.firms WHERE tax_id = 'RO12345678'), 'angajat1@mobilabucuresti.ro', '$2a$10$ZYqwRz5Atq0qMr3Yxlwc2OJ5ziIa9Kzqv3hU5XhEFK5QHGNHh9Ay2', 'Mihai', 'Ionescu', '0731-111-111', 'employee'),
((SELECT id FROM public.firms WHERE tax_id = 'RO12345678'), 'angajat2@mobilabucuresti.ro', '$2a$10$ZYqwRz5Atq0qMr3Yxlwc2OJ5ziIa9Kzqv3hU5XhEFK5QHGNHh9Ay2', 'Ana', 'Georgescu', '0732-222-222', 'employee'),
((SELECT id FROM public.firms WHERE tax_id = 'RO87654321'), 'vanzari@transilvaniawood.ro', '$2a$10$ZYqwRz5Atq0qMr3Yxlwc2OJ5ziIa9Kzqv3hU5XhEFK5QHGNHh9Ay2', 'Vasile', 'Pop', '0733-333-333', 'employee');

-- Insert firm settings
INSERT INTO public.firm_settings (firm_id, assignment_mode, max_active_rfqs, auto_assign_enabled, notification_email) VALUES
((SELECT id FROM public.firms WHERE tax_id = 'RO12345678'), 'ceo_only', 20, false, 'notificari@mobilabucuresti.ro'),
((SELECT id FROM public.firms WHERE tax_id = 'RO87654321'), 'free_assignment', 15, true, 'alerts@transilvaniawood.ro'),
((SELECT id FROM public.firms WHERE tax_id = 'RO11223344'), 'ceo_only', 10, false, null);

-- Insert sample RFQs (requires existing users - create them first via Supabase Auth)
/*
-- Sample RFQ 1 - Kitchen furniture
INSERT INTO public.rfqs (user_id, home_id, title, description, status, budget_min, budget_max, deadline, is_urgent, published_at, expires_at)
VALUES (
  (SELECT id FROM public.users WHERE email = 'client@test.ro'),
  (SELECT id FROM public.homes WHERE user_id = (SELECT id FROM public.users WHERE email = 'client@test.ro') LIMIT 1),
  'Mobilier bucătărie completă - Apartament 3 camere',
  'Caut producător pentru mobilier de bucătărie complet, inclusiv corpuri suspendate și inferioare, blat, și eventual electrocasnice încorporate. Bucătăria are formă în L, aproximativ 3m x 2.5m.',
  'active',
  15000,
  25000,
  CURRENT_DATE + INTERVAL '45 days',
  false,
  NOW(),
  NOW() + INTERVAL '30 days'
);

-- Add categories to RFQ
INSERT INTO public.rfq_categories (rfq_id, category_id, quantity, room_name, specific_requirements)
VALUES (
  (SELECT id FROM public.rfqs WHERE title LIKE 'Mobilier bucătărie%' LIMIT 1),
  (SELECT id FROM public.categories WHERE name = 'kitchen'),
  1,
  'Bucătărie principală',
  'Prefer culori deschise, poate alb sau bej. Blat rezistent la căldură și zgârieturi.'
);

-- Sample RFQ 2 - Bedroom furniture (urgent)
INSERT INTO public.rfqs (user_id, home_id, title, description, status, budget_min, budget_max, deadline, is_urgent, published_at, expires_at)
VALUES (
  (SELECT id FROM public.users WHERE email = 'client@test.ro'),
  (SELECT id FROM public.homes WHERE user_id = (SELECT id FROM public.users WHERE email = 'client@test.ro') LIMIT 1),
  'URGENT - Mobilier dormitor matrimonial',
  'Am nevoie urgentă de mobilier pentru dormitor: pat matrimonial cu saltea, 2 noptiere, dulap cu uși glisante (min. 2.5m lățime), comodă. Termenul este foarte strâns!',
  'active',
  8000,
  12000,
  CURRENT_DATE + INTERVAL '14 days',
  true,
  NOW(),
  NOW() + INTERVAL '7 days'
);

-- Add categories to RFQ
INSERT INTO public.rfq_categories (rfq_id, category_id, quantity, room_name, specific_requirements)
VALUES (
  (SELECT id FROM public.rfqs WHERE title LIKE '%URGENT%dormitor%' LIMIT 1),
  (SELECT id FROM public.categories WHERE name = 'bedroom'),
  1,
  'Dormitor matrimonial',
  'Stil modern minimalist. Culoare wenge sau nuc. Dulap cu oglinzi pe uși.'
);

-- Sample RFQ 3 - Living room
INSERT INTO public.rfqs (user_id, home_id, title, description, status, budget_min, budget_max, deadline, is_urgent, published_at, expires_at)
VALUES (
  (SELECT id FROM public.users WHERE email = 'client@test.ro'),
  (SELECT id FROM public.homes WHERE user_id = (SELECT id FROM public.users WHERE email = 'client@test.ro') LIMIT 1),
  'Mobilier living - Canapea extensibilă și bibliotecă',
  'Doresc o canapea extensibilă de calitate (3 locuri) și o bibliotecă/unitate TV modernă. Living open-space, aproximativ 35mp.',
  'active',
  10000,
  18000,
  CURRENT_DATE + INTERVAL '60 days',
  false,
  NOW(),
  NOW() + INTERVAL '30 days'
);

-- Add categories to RFQ
INSERT INTO public.rfq_categories (rfq_id, category_id, quantity, room_name, specific_requirements)
VALUES (
  (SELECT id FROM public.rfqs WHERE title LIKE '%living%' LIMIT 1),
  (SELECT id FROM public.categories WHERE name = 'living'),
  1,
  'Living open-space',
  'Canapea cu tapițerie ușor de întreținut (poate piele ecologică). Bibliotecă cu multe spații de depozitare.'
);
*/

-- View test data summary
SELECT 'Test Data Summary' as info;
SELECT 'Firms' as entity, COUNT(*) as count FROM public.firms
UNION ALL
SELECT 'Firm Users' as entity, COUNT(*) as count FROM public.firm_users
UNION ALL
SELECT 'Categories' as entity, COUNT(*) as count FROM public.categories
UNION ALL
SELECT 'Active RFQs' as entity, COUNT(*) as count FROM public.rfqs WHERE status = 'active';

-- Test credentials summary
SELECT '=== TEST CREDENTIALS ===' as info;
SELECT 'Firm Portal Users:' as info;
SELECT email, 'test123' as password, f.name as firm_name, fu.role 
FROM public.firm_users fu
JOIN public.firms f ON f.id = fu.firm_id
ORDER BY f.name, fu.role DESC; 