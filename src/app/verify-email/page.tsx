"use client";

import { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Mail, CheckCircle, AlertCircle, Clock } from "lucide-react";

function VerifyEmailForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const email = searchParams.get("email") || "";
  const token = searchParams.get("token") || "";

  const [verificationCode, setVerificationCode] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isResending, setIsResending] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [countdown, setCountdown] = useState(0);

  // Auto-verify if token is present in URL
  useEffect(() => {
    if (token) {
      verifyWithToken(token);
    }
  }, [token]);

  // Countdown timer for resend button
  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  const verifyWithToken = async (verificationToken: string) => {
    setIsLoading(true);
    setError("");

    try {
      // TODO: Implement actual token verification
      console.log("Verifying token:", verificationToken);

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 2000));

      // Simulate different scenarios
      if (verificationToken === "expired") {
        setError(
          "Linkul de verificare a expirat. Te rugăm să soliciți un nou cod."
        );
        return;
      }

      if (verificationToken === "invalid") {
        setError(
          "Linkul de verificare nu este valid. Te rugăm să verifici email-ul sau să soliciți un nou cod."
        );
        return;
      }

      // Success
      setSuccess(
        "Email-ul a fost verificat cu succes! Vei fi redirecționat în câteva secunde..."
      );
      setTimeout(() => {
        router.push("/login?verified=true");
      }, 3000);
    } catch (err) {
      setError(
        "A apărut o eroare la verificarea email-ului. Te rugăm să încerci din nou."
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleCodeSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!verificationCode.trim()) {
      setError("Te rugăm să introduci codul de verificare.");
      return;
    }

    setIsLoading(true);
    setError("");

    try {
      // TODO: Implement actual code verification
      console.log("Verifying code:", verificationCode, "for email:", email);

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1500));

      // Simulate different scenarios
      if (verificationCode === "123456") {
        setSuccess(
          "Email-ul a fost verificat cu succes! Vei fi redirecționat în câteva secunde..."
        );
        setTimeout(() => {
          router.push("/login?verified=true");
        }, 3000);
      } else {
        setError(
          "Codul de verificare nu este corect. Te rugăm să încerci din nou."
        );
      }
    } catch (err) {
      setError(
        "A apărut o eroare la verificarea codului. Te rugăm să încerci din nou."
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleResendCode = async () => {
    if (countdown > 0) return;

    setIsResending(true);
    setError("");
    setSuccess("");

    try {
      // TODO: Implement actual resend logic
      console.log("Resending verification code to:", email);

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1000));

      setSuccess(
        "Un nou cod de verificare a fost trimis la adresa ta de email."
      );
      setCountdown(60); // 60 seconds cooldown
    } catch (err) {
      setError("Nu am putut retrimite codul. Te rugăm să încerci din nou.");
    } finally {
      setIsResending(false);
    }
  };

  const handleChangeEmail = () => {
    router.push("/register");
  };

  if (success) {
    return (
      <main className="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-md w-full space-y-8">
          <div className="text-center">
            <CheckCircle className="mx-auto h-16 w-16 text-green-500" />
            <h2 className="mt-6 text-3xl font-bold text-gray-900 dark:text-white">
              Email verificat!
            </h2>
            <Alert className="mt-6 border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-950">
              <CheckCircle className="h-4 w-4 text-green-600" />
              <AlertDescription className="text-green-800 dark:text-green-200">
                {success}
              </AlertDescription>
            </Alert>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        {/* Header */}
        <div className="text-center">
          <Link href="/" className="text-2xl font-bold text-primary">
            Mobilier Personalizat
          </Link>
          <Mail className="mx-auto mt-6 h-16 w-16 text-primary" />
          <h2 className="mt-6 text-3xl font-bold text-gray-900 dark:text-white">
            Verifică-ți email-ul
          </h2>
          <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
            {email ? (
              <>
                Am trimis un cod de verificare la{" "}
                <span className="font-medium text-gray-900 dark:text-white">
                  {email}
                </span>
              </>
            ) : (
              "Te rugăm să verifici email-ul pentru a-ți activa contul"
            )}
          </p>
        </div>

        {/* Error Alert */}
        {error && (
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {/* Success Alert */}
        {success && !success.includes("verificat cu succes") && (
          <Alert className="border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-950">
            <CheckCircle className="h-4 w-4 text-green-600" />
            <AlertDescription className="text-green-800 dark:text-green-200">
              {success}
            </AlertDescription>
          </Alert>
        )}

        {/* Verification Form */}
        {!token && (
          <form className="mt-8 space-y-6" onSubmit={handleCodeSubmit}>
            <div>
              <Label htmlFor="verificationCode">Cod de verificare</Label>
              <Input
                id="verificationCode"
                name="verificationCode"
                type="text"
                required
                value={verificationCode}
                onChange={(e) => setVerificationCode(e.target.value)}
                className="mt-1 text-center text-lg tracking-widest"
                placeholder="123456"
                maxLength={6}
              />
              <p className="mt-1 text-xs text-gray-500">
                Introdu codul de 6 cifre din email
              </p>
            </div>

            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading ? "Se verifică..." : "Verifică email-ul"}
            </Button>
          </form>
        )}

        {/* Loading state for token verification */}
        {token && isLoading && (
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
            <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
              Se verifică email-ul...
            </p>
          </div>
        )}

        {/* Actions */}
        <div className="space-y-4">
          {/* Resend Code */}
          <div className="text-center">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Nu ai primit email-ul?{" "}
              <button
                type="button"
                onClick={handleResendCode}
                disabled={countdown > 0 || isResending}
                className="font-medium text-primary hover:text-primary/80 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isResending ? (
                  "Se retrimite..."
                ) : countdown > 0 ? (
                  <>
                    <Clock className="inline h-3 w-3 mr-1" />
                    Retrimite în {countdown}s
                  </>
                ) : (
                  "Retrimite codul"
                )}
              </button>
            </p>
          </div>

          {/* Change Email */}
          {email && (
            <div className="text-center">
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Email greșit?{" "}
                <button
                  type="button"
                  onClick={handleChangeEmail}
                  className="font-medium text-primary hover:text-primary/80"
                >
                  Schimbă adresa de email
                </button>
              </p>
            </div>
          )}

          {/* Back to Login */}
          <div className="text-center">
            <Link
              href="/login"
              className="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
            >
              ← Înapoi la autentificare
            </Link>
          </div>
        </div>

        {/* Help Text */}
        <div className="mt-8 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-2">
            Nu găsești email-ul?
          </h3>
          <ul className="text-xs text-gray-600 dark:text-gray-400 space-y-1">
            <li>• Verifică folderul de spam/junk</li>
            <li>• Verifică că adresa de email este corectă</li>
            <li>• Poate dura până la 5 minute să ajungă</li>
            <li>• Contactează suportul dacă problema persistă</li>
          </ul>
        </div>
      </div>
    </main>
  );
}

export default function VerifyEmailPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
            <p className="mt-2 text-gray-600">Se încarcă...</p>
          </div>
        </div>
      }
    >
      <VerifyEmailForm />
    </Suspense>
  );
}
