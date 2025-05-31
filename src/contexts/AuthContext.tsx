"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { User, Session, AuthError } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabase";

// Define user roles and types
export type UserRole = "homeowner" | "architect" | "manufacturer" | "admin";
export type AccountStatus = "active" | "inactive" | "pending" | "suspended";

export interface UserProfile {
  id: string;
  email: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  role: UserRole;
  status: AccountStatus;
  company_name?: string;
  company_description?: string;
  company_website?: string;
  company_address?: string;
  company_phone?: string;
  tax_id?: string;
  is_verified: boolean;
  avatar_url?: string;
  created_at: string;
  updated_at: string;
  last_login?: string;
  manufacturer_parent_id?: string;
}

interface AuthContextType {
  user: User | null;
  userProfile: UserProfile | null;
  session: Session | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  signUp: (
    email: string,
    password: string,
    userData: Partial<UserProfile>
  ) => Promise<{ error: AuthError | null }>;
  signIn: (
    email: string,
    password: string
  ) => Promise<{ error: AuthError | null }>;
  signOut: () => Promise<{ error: AuthError | null }>;
  updateProfile: (
    updates: Partial<UserProfile>
  ) => Promise<{ error: Error | null }>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const isAuthenticated = !!user && !!userProfile;

  // Fetch user profile from database
  const fetchUserProfile = async (
    userId: string
  ): Promise<UserProfile | null> => {
    try {
      console.log("Fetching profile for user:", userId);

      const { data, error } = await supabase
        .from("users")
        .select("*")
        .eq("id", userId)
        .single();

      if (error) {
        console.error("Error fetching user profile:", error);

        // If user doesn't exist in users table, this might be expected for new signups
        if (error.code === "PGRST116") {
          console.log(
            "User profile not found in database - this might be a new user"
          );
          return null;
        }

        return null;
      }

      console.log("Profile fetched successfully:", data);
      return data as UserProfile;
    } catch (error) {
      console.error("Unexpected error fetching user profile:", error);
      return null;
    }
  };

  // Refresh user profile
  const refreshProfile = async () => {
    if (user) {
      const profile = await fetchUserProfile(user.id);
      setUserProfile(profile);
    }
  };

  // Sign up function
  const signUp = async (
    email: string,
    password: string,
    userData: Partial<UserProfile>
  ) => {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            first_name: userData.first_name,
            last_name: userData.last_name,
            phone: userData.phone,
            role: userData.role || "homeowner",
            company_name: userData.company_name,
          },
        },
      });

      if (error) {
        return { error };
      }

      // If user is created successfully, the trigger will handle profile creation
      return { error: null };
    } catch (error) {
      return { error: error as AuthError };
    }
  };

  // Sign in function
  const signIn = async (email: string, password: string) => {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        return { error };
      }

      return { error: null };
    } catch (error) {
      return { error: error as AuthError };
    }
  };

  // Sign out function
  const signOut = async () => {
    try {
      const { error } = await supabase.auth.signOut();

      if (!error) {
        setUser(null);
        setUserProfile(null);
        setSession(null);
      }

      return { error };
    } catch (error) {
      return { error: error as AuthError };
    }
  };

  // Update profile function
  const updateProfile = async (updates: Partial<UserProfile>) => {
    if (!user) {
      return { error: new Error("No user logged in") };
    }

    try {
      const { error } = await supabase
        .from("users")
        .update(updates)
        .eq("id", user.id);

      if (error) {
        return { error: new Error(error.message) };
      }

      // Refresh profile after update
      await refreshProfile();
      return { error: null };
    } catch (error) {
      return { error: error as Error };
    }
  };

  // Initialize auth state
  useEffect(() => {
    let mounted = true;

    // Get initial session
    const initializeAuth = async () => {
      try {
        const {
          data: { session },
          error,
        } = await supabase.auth.getSession();

        if (error) {
          console.error("Error getting session:", error);
          setIsLoading(false);
          return;
        }

        if (session?.user && mounted) {
          console.log("Initial session found:", session.user.email);
          setUser(session.user);
          setSession(session);

          // Fetch user profile
          const profile = await fetchUserProfile(session.user.id);
          if (mounted) {
            setUserProfile(profile);
            console.log(
              "Initial profile loaded:",
              profile?.first_name || profile?.email
            );
          }
        }
      } catch (error) {
        console.error("Error initializing auth:", error);
      } finally {
        if (mounted) {
          setIsLoading(false);
        }
      }
    };

    initializeAuth();

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (!mounted) return;

      console.log("Auth state changed:", event, session?.user?.email);

      if (session?.user) {
        setUser(session.user);
        setSession(session);

        // Fetch user profile with retry logic
        try {
          const profile = await fetchUserProfile(session.user.id);
          if (mounted) {
            setUserProfile(profile);
            console.log(
              "Profile updated:",
              profile?.first_name || profile?.email
            );
          }
        } catch (error) {
          console.error("Error fetching profile after auth change:", error);
        }
      } else {
        console.log("No session, clearing auth state");
        setUser(null);
        setSession(null);
        setUserProfile(null);
      }

      if (mounted) {
        setIsLoading(false);
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const value: AuthContextType = {
    user,
    userProfile,
    session,
    isLoading,
    isAuthenticated,
    signUp,
    signIn,
    signOut,
    updateProfile,
    refreshProfile,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
