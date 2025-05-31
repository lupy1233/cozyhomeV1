import { createClient } from "@supabase/supabase-js";

const supabaseUrl =
  process.env.NEXT_PUBLIC_SUPABASE_URL ||
  "https://qwjowtodjikqrtljzwnl.supabase.co";
const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3am93dG9kamlrcXJ0bGp6d25sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1MzEwMDQsImV4cCI6MjA2NDEwNzAwNH0.qkLVppg-ayo39DWeyq6UTmZOtx7lge36MxrQ-H0a_j8";

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
});

// For server-side operations (API routes)
export const supabaseAdmin = createClient(
  supabaseUrl,
  process.env.SUPABASE_SERVICE_ROLE_KEY ||
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3am93dG9kamlrcXJ0bGp6d25sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODUzMTAwNCwiZXhwIjoyMDY0MTA3MDA0fQ.PkL8IAdDIStBiISmax5mn1sBIttiaHD48ZXvFhArCUU",
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);
