'use client';

import { useState, useCallback } from 'react';
import { ToastProvider, useToast } from '@/components/website/Toast';
import { Navbar } from '@/components/website/Navbar';
import { Hero } from '@/components/website/Hero';
import { Metrics } from '@/components/website/Metrics';
import { CostEstimator } from '@/components/website/CostEstimator';
import { Homeowners } from '@/components/website/Homeowners';
import { Contractors } from '@/components/website/Contractors';
import { PlatformFeatures } from '@/components/website/PlatformFeatures';
import { HowItWorks } from '@/components/website/HowItWorks';
import { AppShowcase } from '@/components/website/AppShowcase';
import { Testimonials } from '@/components/website/Testimonials';
import { Partners } from '@/components/website/Partners';
import { CTA } from '@/components/website/CTA';
import { Footer } from '@/components/website/Footer';
import { PolicyPage } from '@/components/website/Policies';

const sectionIds = ['hero', 'features', 'estimator', 'homeowners', 'contractors'];

const routeMessages: Record<string, string> = {
  login: 'Opening sign-in page...',
  download: 'Redirecting to Google Play Store...',
  contact: 'Opening contact page...',
  'register/homeowner': 'Starting homeowner registration...',
  'register/contractor': 'Starting contractor registration...',
  'register/supplier': 'Starting supplier registration...',
  'register/business': 'Starting business registration...',
  contractors: 'Opening contractor directory...',
  marketplace: 'Opening material marketplace...',
  chat: 'Opening chat...',
  news: 'Opening material market news...',
  vendors: 'Opening verified vendor directory...',
  audit: 'Opening audit logs...',
  invoices: 'Opening invoice manager...',
  dashboard: 'Opening provider dashboard...',
  verification: 'Opening verification page...',
  about: 'Opening about page...',
  'market-news': 'Opening market prices...',
  partner: 'Opening partner onboarding...',
  'b2b-network': 'Opening B2B supply network...',
};

const policyTitles: Record<string, string> = {
  'privacy-policy': 'Privacy Policy',
  terms: 'Terms of Service',
  'refund-policy': 'Refund & Cancellation Policy',
};

function WebsiteContent() {
  const { notify } = useToast();
  const [currentPage, setCurrentPage] = useState('home');

  const handleNavigate = useCallback(
    (target: string) => {
      // Handle policy pages
      if (['privacy-policy', 'terms', 'refund-policy'].includes(target)) {
        setCurrentPage(target);
        window.scrollTo({ top: 0, behavior: 'smooth' });
        return;
      }

      // Handle home navigation
      if (target === 'home') {
        setCurrentPage('home');
        window.scrollTo({ top: 0, behavior: 'smooth' });
        return;
      }

      // Handle scrolling to sections
      if (sectionIds.includes(target)) {
        if (currentPage !== 'home') {
          setCurrentPage('home');
          setTimeout(() => {
            const el = document.getElementById(target);
            if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
          }, 100);
          return;
        }

        const el = document.getElementById(target);
        if (el) {
          el.scrollIntoView({ behavior: 'smooth', block: 'start' });
          return;
        }
      }

      // Handle other links (toasts)
      const message = routeMessages[target] || `Navigating to ${target}...`;
      notify(message);
    },
    [currentPage, notify]
  );

  return (
    <div className="min-h-screen bg-white">
      <Navbar onNavigate={handleNavigate} />
      <main>
        {currentPage === 'home' ? (
          <>
            <Hero onNavigate={handleNavigate} />
            <Metrics />
            <CostEstimator onNavigate={handleNavigate} />
            <Homeowners onNavigate={handleNavigate} />
            <Contractors onNavigate={handleNavigate} />
            <PlatformFeatures onNavigate={handleNavigate} />
            <HowItWorks />
            <AppShowcase />
            <Testimonials onNavigate={handleNavigate} />
            <Partners />
            <CTA onNavigate={handleNavigate} />
          </>
        ) : (
          <PolicyPage
            title={policyTitles[currentPage] || 'Policy Document'}
            onBack={() => handleNavigate('home')}
          />
        )}
      </main>
      <Footer onNavigate={handleNavigate} />
    </div>
  );
}

export default function HomePage() {
  return (
    <ToastProvider>
      <WebsiteContent />
    </ToastProvider>
  );
}
