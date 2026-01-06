import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SOBAT HR - Admin Dashboard",
  description: "Smart Operations & Business Administrative Tool - Human Resources Information System",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
