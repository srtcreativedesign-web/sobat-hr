import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "@/components/auth-provider";

export const metadata: Metadata = {
  title: "SOBAT HR - Admin Dashboard",
  description: "Smart Operations & Business Administrative Tool - Human Resources Information System",
  icons: {
    icon: '/logo/logo.png',
  },
};

import SessionProvider from "@/components/SessionProvider";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        <AuthProvider>
          <SessionProvider>
            {children}
          </SessionProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
