'use client';

import { useRef, type ReactNode } from 'react';

interface RippleButtonProps {
  children: ReactNode;
  onClick?: () => void;
  className?: string;
  variant?: 'primary' | 'secondary' | 'ghost';
  href?: string;
  type?: 'button' | 'submit';
  disabled?: boolean;
  ariaLabel?: string;
}

export function RippleButton({
  children,
  onClick,
  className = '',
  variant = 'primary',
  href,
  type = 'button',
  disabled = false,
  ariaLabel,
}: RippleButtonProps) {
  const buttonRef = useRef<HTMLButtonElement>(null);

  const createRipple = (e: React.MouseEvent) => {
    const button = buttonRef.current;
    if (!button) return;
    const circle = document.createElement('span');
    const diameter = Math.max(button.clientWidth, button.clientHeight);
    const rect = button.getBoundingClientRect();
    circle.style.width = `${diameter}px`;
    circle.style.height = `${diameter}px`;
    circle.style.left = `${e.clientX - rect.left - diameter / 2}px`;
    circle.style.top = `${e.clientY - rect.top - diameter / 2}px`;
    circle.classList.add('ripple');
    const existing = button.getElementsByClassName('ripple')[0];
    if (existing) existing.remove();
    button.appendChild(circle);
    setTimeout(() => circle.remove(), 600);
  };

  const handleClick = (e: React.MouseEvent) => {
    if (disabled) return;
    createRipple(e);
    onClick?.();
  };

  const base =
    'relative inline-flex items-center justify-center gap-2 rounded-full px-6 py-3 text-sm transition-all duration-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed';
  const variants = {
    primary: 'btn-primary',
    secondary: 'btn-secondary',
    ghost:
      'text-slate-700 hover:bg-slate-100 hover:text-blue-600 transition-colors font-semibold',
  };

  if (href) {
    return (
      <a
        href={href}
        target={href.startsWith('http') ? '_blank' : undefined}
        rel={href.startsWith('http') ? 'noopener noreferrer' : undefined}
        className={`${base} ${variants[variant]} ${className}`}
        aria-label={ariaLabel}
        onClick={(e) => createRipple(e)}
      >
        {children}
      </a>
    );
  }

  return (
    <button
      ref={buttonRef}
      type={type}
      onClick={handleClick}
      disabled={disabled}
      className={`${base} ${variants[variant]} ${className}`}
      aria-label={ariaLabel}
    >
      {children}
    </button>
  );
}
