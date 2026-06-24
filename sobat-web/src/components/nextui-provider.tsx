"use client";

import { NextUIProvider } from "@nextui-org/react";

export function NextUIProviderWrapper({ children }: { children: React.ReactNode }) {
  return (
    <NextUIProvider>
      {children}
    </NextUIProvider>
  );
}
