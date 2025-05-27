"use client";

import React, { createContext, useContext, useState, useEffect } from "react";

interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  accountType: "homeowner" | "architect";
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Auto-login for development - simulate checking stored auth
    setTimeout(() => {
      const testUser: User = {
        id: "1",
        email: "test@example.com",
        firstName: "Ion",
        lastName: "Popescu",
        accountType: "homeowner",
      };
      setUser(testUser);
      setIsLoading(false);
    }, 500);
  }, []);

  const login = async (email: string, password: string) => {
    setIsLoading(true);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));

    const testUser: User = {
      id: "1",
      email: email,
      firstName: "Ion",
      lastName: "Popescu",
      accountType: "homeowner",
    };
    setUser(testUser);
    setIsLoading(false);
  };

  const logout = () => {
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        login,
        logout,
        isLoading,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
