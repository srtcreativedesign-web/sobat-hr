import type { Metadata } from "next";
import "./globals.css";
import { AuthProvider } from "@/components/auth-provider";
import { NextUIProviderWrapper } from "@/components/nextui-provider";

export const metadata: Metadata = {
  title: "SOBAT HR - Admin Dashboard",
  description: "Smart Operations & Business Administrative Tool - Human Resources Information System",
  icons: {
    icon: '/logo/favicon.png',
  },
};

import SessionProvider from "@/components/SessionProvider";
import { Geist } from "next/font/google";
import { cn } from "@/lib/utils";

const geist = Geist({subsets:['latin'],variable:'--font-sans'});


export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={cn("font-sans", geist.variable)}>
      <body className="antialiased">
        <AuthProvider>
          <SessionProvider>
            <NextUIProviderWrapper>
              {children}
            </NextUIProviderWrapper>
          </SessionProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
