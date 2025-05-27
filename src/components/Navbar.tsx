"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useTheme } from "next-themes";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import {
  Bell,
  Settings,
  LogOut,
  LayoutDashboard,
  Plus,
  Moon,
  Sun,
} from "lucide-react";

interface NavbarProps {
  unreadCount?: number;
}

export default function Navbar({ unreadCount = 0 }: NavbarProps) {
  const pathname = usePathname();
  const { theme, setTheme } = useTheme();
  const { isAuthenticated, logout, user } = useAuth();

  // Determine if we're on dashboard or authenticated pages
  const isDashboardPage = pathname === "/dashboard";
  const isAuthPage =
    pathname === "/login" ||
    pathname === "/register" ||
    pathname === "/verify-email" ||
    pathname === "/forgot-password" ||
    pathname === "/reset-password";
  const isHomePage = pathname === "/";

  // For non-authenticated users or auth pages, show the marketing navbar
  if (!isAuthenticated || isAuthPage) {
    return (
      <header className="bg-white dark:bg-gray-800 shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-4">
              <Link href="/" className="text-2xl font-bold text-primary">
                Cozy Home
              </Link>
              <nav className="hidden md:flex space-x-8">
                <Link
                  href="/categories"
                  className="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white"
                >
                  Categorii
                </Link>
                <Link
                  href="/how-it-works"
                  className="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white"
                >
                  Cum Funcționează
                </Link>
                <Link
                  href="/contact"
                  className="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white"
                >
                  Contact
                </Link>
              </nav>
            </div>

            <div className="flex items-center space-x-4">
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setTheme(theme === "light" ? "dark" : "light")}
              >
                <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
                <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
                <span className="sr-only">Toggle theme</span>
              </Button>
              {!isAuthPage && (
                <>
                  <Button variant="ghost" size="sm" asChild>
                    <Link href="/login">Autentificare</Link>
                  </Button>
                  <Button size="sm" asChild>
                    <Link href="/register">Începe o Cerere</Link>
                  </Button>
                </>
              )}
            </div>
          </div>
        </div>
      </header>
    );
  }

  // For authenticated users, show the app navbar
  return (
    <header className="bg-white dark:bg-gray-800 shadow-sm border-b">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center space-x-4">
            <Link href="/" className="text-2xl font-bold text-primary">
              Cozy Home
            </Link>
            <nav className="hidden md:flex space-x-8">
              {!isDashboardPage && (
                <Link
                  href="/dashboard"
                  className="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white flex items-center space-x-2"
                >
                  <LayoutDashboard className="h-4 w-4" />
                  <span>Dashboard</span>
                </Link>
              )}
              <Link
                href="/rfq/create"
                className="text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white flex items-center space-x-2"
              >
                <Plus className="h-4 w-4" />
                <span>Cerere Nouă</span>
              </Link>
            </nav>
          </div>

          <div className="flex items-center space-x-4">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setTheme(theme === "light" ? "dark" : "light")}
            >
              <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
              <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
              <span className="sr-only">Toggle theme</span>
            </Button>
            <Button variant="ghost" size="sm" className="relative">
              <Bell className="h-5 w-5" />
              {unreadCount > 0 && (
                <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                  {unreadCount}
                </span>
              )}
            </Button>
            <Button variant="ghost" size="sm">
              <Settings className="h-5 w-5" />
            </Button>
            <Button variant="ghost" size="sm" onClick={logout}>
              <LogOut className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </div>
    </header>
  );
}
