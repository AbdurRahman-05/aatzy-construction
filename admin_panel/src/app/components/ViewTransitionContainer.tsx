'use client';

import React from 'react';

interface ViewTransitionContainerProps {
  currentView: string;
  children: React.ReactNode;
}

export default function ViewTransitionContainer({
  currentView,
  children,
}: ViewTransitionContainerProps) {
  return (
    <div key={currentView} className="animate-view-enter w-full">
      {children}
    </div>
  );
}
