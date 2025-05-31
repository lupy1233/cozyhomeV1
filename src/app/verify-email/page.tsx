"use client";

import { useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Mail, CheckCircle, AlertCircle, RefreshCw } from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";

function VerifyEmailForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const email = searchParams.get("email") || "";
  const { signUp } = useAuth();

  const [isResending, setIsResending] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleResendEmail = async () => {
    if (!email) {
      setError(
        "Nu am putut găsi adresa de email. Te rugăm să te înregistrezi din nou."
      );
      return;
    }

    setIsResending(true);
    setError("");
    setSuccess("");

    try {
      // Trigger a new signup to resend confirmation email
      const { error: resendError } = await signUp(email, "temp_password", {
        first_name: "Resend",
        last_name: "Email",
      });

      if (
        resendError &&
        !resendError.message.includes("User already registered")
      ) {
        setError(
          "Nu am putut retrimite email-ul. Te rugăm să încerci din nou."
        );
      } else {
        setSuccess(
          "Email-ul de confirmare a fost retrimis! Verifică inbox-ul."
        );
      }
    } catch (err) {
      setError("A apărut o eroare. Te rugăm să încerci din nou.");
    } finally {
      setIsResending(false);
    }
  };

  return (
    <main className="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        {/* Header */}
        <div className="text-center">
          <Link href="/" className="text-2xl font-bold text-primary">
            Cozy Home
          </Link>
          <Mail className="mx-auto mt-6 h-16 w-16 text-primary" />
          <h2 className="mt-6 text-3xl font-bold text-gray-900 dark:text-white">
            Verifică-ți email-ul
          </h2>
          <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
            {email ? (
              <>
                Am trimis un link de confirmare la{" "}
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
        {success && (
          <Alert className="border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-950">
            <CheckCircle className="h-4 w-4 text-green-600" />
            <AlertDescription className="text-green-800 dark:text-green-200">
              {success}
            </AlertDescription>
          </Alert>
        )}

        {/* Instructions */}
        <div className="bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
          <h3 className="text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">
            Următorii pași:
          </h3>
          <ol className="text-sm text-blue-800 dark:text-blue-200 space-y-1 list-decimal list-inside">
            <li>Verifică inbox-ul pentru email-ul de la Cozy Home</li>
            <li>Dă click pe linkul de confirmare din email</li>
            <li>Vei fi redirecționat pentru a te autentifica</li>
          </ol>
        </div>

        {/* Actions */}
        <div className="space-y-4">
          {/* Resend Email */}
          {email && (
            <div className="text-center">
              <Button
                variant="outline"
                onClick={handleResendEmail}
                disabled={isResending}
                className="w-full"
              >
                {isResending ? (
                  <>
                    <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                    Se retrimite...
                  </>
                ) : (
                  <>
                    <Mail className="mr-2 h-4 w-4" />
                    Retrimite email-ul de confirmare
                  </>
                )}
              </Button>
            </div>
          )}

          {/* Change Email */}
          <div className="text-center">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Email greșit?{" "}
              <Link
                href="/register"
                className="font-medium text-primary hover:text-primary/80"
              >
                Înregistrează-te din nou
              </Link>
            </p>
          </div>

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
            <li>• Folosește butonul "Retrimite" dacă nu ajunge</li>
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
