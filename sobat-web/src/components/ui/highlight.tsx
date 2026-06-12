'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

const HighlightContext = React.createContext<{
  hoveredId: string | null;
  setHoveredId: (id: string | null) => void;
} | null>(null);

export function Highlight({ 
  children, 
  containerClassName,
}: any) {
  const [hoveredId, setHoveredId] = React.useState<string | null>(null);

  return (
    <HighlightContext.Provider value={{ hoveredId, setHoveredId }}>
      <div 
        className={cn("relative", containerClassName)}
        onMouseLeave={() => setHoveredId(null)}
      >
        {children}
      </div>
    </HighlightContext.Provider>
  );
}

export function HighlightItem({ children, activeClassName }: any) {
  const ctx = React.useContext(HighlightContext);
  const id = React.useId();
  
  if (!ctx) return <>{children}</>;
  const { hoveredId, setHoveredId } = ctx;

  const child = React.isValidElement(children) ? children : null;
  if (!child) return <>{children}</>;

  const isActive = child.props["data-active"] === true || child.props["data-active"] === "true";
  const isHovered = hoveredId === id;
  const isHighlighted = isHovered || (isActive && hoveredId === null);

  return (
    <div 
      className="peer/menu-button relative w-full"
      onMouseEnter={() => setHoveredId(id)}
    >
      {isHighlighted && (
        <motion.div
          layoutId="sidebar-highlight"
          className={cn("absolute inset-0 z-0 pointer-events-none", activeClassName)}
          initial={false}
          transition={{ type: "spring", bounce: 0.2, duration: 0.5 }}
        />
      )}
      {React.cloneElement(child, {
        "data-highlight": "true",
        className: cn(
          child.props.className, 
          "relative z-10 transition-colors duration-300",
          isHighlighted 
            ? "text-sidebar-accent-foreground data-[active=true]:text-sidebar-accent-foreground" 
            : "text-sidebar-foreground data-[active=true]:text-sidebar-foreground",
          "bg-transparent hover:bg-transparent data-[active=true]:bg-transparent"
        )
      } as any)}
    </div>
  );
}
