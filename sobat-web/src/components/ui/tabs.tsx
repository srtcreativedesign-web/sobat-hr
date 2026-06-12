"use client"

import * as React from "react"
import * as TabsPrimitive from "@radix-ui/react-tabs"
import { motion } from "framer-motion"
import Link from "next/link"

import { cn } from "@/lib/utils"

const Tabs = TabsPrimitive.Root

const TabsList = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.List>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.List>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.List
    ref={ref}
    className={cn(
      "inline-flex h-10 items-center justify-center rounded-md bg-muted p-1 text-muted-foreground",
      className
    )}
    {...props}
  />
))
TabsList.displayName = TabsPrimitive.List.displayName

const TabsTrigger = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Trigger>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Trigger>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.Trigger
    ref={ref}
    className={cn(
      "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-blue-100 data-[state=active]:text-blue-700 data-[state=active]:shadow-sm",
      className
    )}
    {...props}
  />
))
TabsTrigger.displayName = TabsPrimitive.Trigger.displayName

const TabsContent = React.forwardRef<
  React.ElementRef<typeof TabsPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof TabsPrimitive.Content>
>(({ className, ...props }, ref) => (
  <TabsPrimitive.Content
    ref={ref}
    className={cn(
      "mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
      className
    )}
    {...props}
  />
))
TabsContent.displayName = TabsPrimitive.Content.displayName

export function NavTabs({ tabs, activeValue }: { tabs: { label: string, href: string, value: string }[], activeValue: string }) {
  return (
    <div className="inline-flex h-11 items-center justify-center rounded-lg bg-gray-100 p-1 text-muted-foreground w-full">
       {tabs.map(tab => {
          const isActive = tab.value === activeValue;
          return (
             <Link 
               key={tab.value} 
               href={tab.href} 
               className={cn(
                 "relative flex-1 flex items-center justify-center whitespace-nowrap rounded-md px-3 py-2 text-sm transition-colors", 
                 isActive ? "text-blue-700 font-semibold" : "hover:text-gray-900 font-medium text-gray-500"
               )}
             >
                {isActive && (
                   <motion.div 
                     layoutId="nav-tabs" 
                     className="absolute inset-0 z-0 bg-blue-100 rounded-md shadow-sm pointer-events-none" 
                     initial={false}
                     transition={{ type: "spring", bounce: 0.2, duration: 0.5 }} 
                   />
                )}
                <span className="relative z-10">{tab.label}</span>
             </Link>
          )
       })}
    </div>
  )
}

export { Tabs, TabsList, TabsTrigger, TabsContent }
