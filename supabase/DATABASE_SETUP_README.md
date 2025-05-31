# 🗄️ Database Setup Guide - Romanian Furniture RFQ Marketplace

## 📋 Overview

This database powers a dual-portal system for the Romanian furniture marketplace:

1. **Client Portal** - Where homeowners create RFQs (Request for Quotes) for furniture
2. **Firm Portal** - Where furniture companies and their employees access and respond to RFQs

## 🚀 Quick Start

### Prerequisites

- A Supabase project ([create one here](https://app.supabase.com))
- Environment variables configured in `.env.local`

### Setup Steps

1. **Run the Complete Setup**

   - Go to your Supabase Dashboard → SQL Editor
   - Open `01-complete-database-setup.sql`
   - Run the entire script
   - This will create all tables, functions, triggers, and policies

2. **Verify Installation**

   - Run `02-verify-setup.sql`
   - Check that all components are created successfully

3. **Configure Environment Variables**
   Create a `.env.local` file in the project root:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   ```

## 📊 Database Structure

### Main System Tables

| Table           | Description            | Key Fields                                                    |
| --------------- | ---------------------- | ------------------------------------------------------------- |
| `users`         | Extended auth users    | `role` (homeowner/architect/manufacturer), `company_*` fields |
| `homes`         | User properties        | Location details, `is_primary` flag                           |
| `categories`    | Furniture categories   | Bilingual names (RO/EN), icons                                |
| `rfqs`          | Quote requests         | Status, budget range, deadlines                               |
| `offers`        | Manufacturer responses | Pricing, delivery terms, status                               |
| `messages`      | Communication          | Threaded conversations                                        |
| `notifications` | System alerts          | Read/unread status                                            |

### Firm Portal Tables

| Table             | Description         | Key Fields                           |
| ----------------- | ------------------- | ------------------------------------ |
| `firms`           | Company profiles    | Tax ID (CUI), location, contact info |
| `firm_users`      | Company employees   | Role (CEO/employee), custom auth     |
| `firm_settings`   | Company preferences | Assignment mode, limits              |
| `rfq_assignments` | RFQ distribution    | Status tracking, response messages   |
| `firm_sessions`   | Auth sessions       | 8-hour expiry tokens                 |

### Custom Types

```sql
-- User roles in main system
user_role: 'homeowner', 'architect', 'manufacturer', 'admin'

-- RFQ lifecycle
rfq_status: 'draft', 'active', 'closed', 'expired', 'completed'

-- Firm portal roles
firm_user_role: 'ceo', 'employee'

-- Assignment modes
assignment_mode: 'ceo_only', 'free_assignment'
```

## 🔐 Security Model

### Row Level Security (RLS)

- All tables have RLS enabled
- Users can only access their own data
- Manufacturers can view active RFQs
- Firm portal uses custom session-based auth

### Authentication

- **Client Portal**: Supabase Auth (email/password)
- **Firm Portal**: Custom bcrypt authentication with session tokens

## 🛠️ Key Functions

### `get_filtered_rfqs()`

Filters RFQs for firm dashboard with support for:

- Category filtering
- Location filtering (city/county)
- Budget range
- Response time (urgent/7days/30days)

### `update_updated_at_column()`

Automatically updates `updated_at` timestamps on row changes

### `handle_new_user()`

Creates user profile when auth user is created

## 📁 File Structure

```
cozy-home/supabase/
├── 01-complete-database-setup.sql  # Main setup script
├── 02-verify-setup.sql            # Verification queries
├── 03-sample-data.sql            # Test data (optional)
└── DATABASE_SETUP_README.md      # This file
```

## 🧪 Testing the Setup

### Create Test Firm Account

```sql
-- Insert test firm
INSERT INTO firms (name, tax_id, address, city, county, phone, email)
VALUES ('Test Mobilier SRL', 'RO12345678', 'Str. Test 123', 'București', 'București', '0721234567', 'test@mobilier.ro');

-- Get the firm ID
SELECT id FROM firms WHERE tax_id = 'RO12345678';

-- Insert CEO user (password: 'test123')
INSERT INTO firm_users (firm_id, email, password_hash, first_name, last_name, role)
VALUES (
  'your-firm-id-here',
  'ceo@mobilier.ro',
  '$2a$10$ZYqwRz5Atq0qMr3Yxlwc2OJ5ziIa9Kzqv3hU5XhEFK5QHGNHh9Ay2',
  'Ion',
  'Popescu',
  'ceo'
);
```

### Verify Firm Portal Access

1. Navigate to `/firm/login`
2. Login with test credentials
3. Access dashboard at `/firm/dashboard`

## 🔧 Common Operations

### Add New Category

```sql
INSERT INTO categories (name, name_ro, description_ro, icon, sort_order)
VALUES ('custom', 'Personalizat', 'Mobilier la comandă', 'Palette', 10);
```

### Check Active RFQs

```sql
SELECT COUNT(*) as active_rfqs
FROM rfqs
WHERE status = 'active'
AND expires_at > NOW();
```

### View Firm Assignments

```sql
SELECT
  f.name as firm_name,
  r.title as rfq_title,
  ra.status,
  ra.assigned_at
FROM rfq_assignments ra
JOIN firms f ON f.id = ra.firm_id
JOIN rfqs r ON r.id = ra.rfq_id
ORDER BY ra.assigned_at DESC;
```

## 🐛 Troubleshooting

### "supabaseUrl is required" Error

- Ensure `.env.local` exists with all required variables
- Restart the development server after adding environment variables

### "Trigger already exists" Error

- Run the cleanup section at the beginning of `01-complete-database-setup.sql`
- This removes all existing objects before recreating them

### Authentication Issues

- Check that bcryptjs is installed: `npm install bcryptjs`
- Verify session cookies are being set correctly
- Check browser console for cookie domain issues

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL RLS Guide](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Next.js App Router](https://nextjs.org/docs/app)

## 🤝 Support

For issues or questions:

1. Check the verification script output
2. Review PostgreSQL logs in Supabase dashboard
3. Ensure all environment variables are set correctly

---

**Last Updated**: December 2024
**Database Version**: 1.0.0
