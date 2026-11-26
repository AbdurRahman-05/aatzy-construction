'use client';

import { useSyncExternalStore } from 'react';
import { createPortal } from 'react-dom';

const noopSubscribe = () => () => {};

/**
 * Renders overlays (side panels, dialogs, lightboxes) directly under the .admin-root element.
 * Keeps them full-screen even when an ancestor has a transform/animation (which would
 * otherwise trap `position: fixed`), while still inheriting the admin theme variables.
 */
export default function Portal({ children }: { children: React.ReactNode }) {
  const isClient = useSyncExternalStore(noopSubscribe, () => true, () => false);
  if (!isClient) return null;
  const target = document.querySelector('.admin-root') ?? document.body;
  return createPortal(children, target);
}
