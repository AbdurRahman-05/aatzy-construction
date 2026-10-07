'use client';

import { useState, useCallback } from 'react';
import { ToastProvider, useToast } from '@/components/website/Toast';
import { Navbar } from '@/components/website/Navbar';
import { Hero } from '@/components/website/Hero';
import { CommodityTicker } from '@/components/website/CommodityTicker';
import { Metrics } from '@/components/website/Metrics';
import { CostEstimator } from '@/components/website/CostEstimator';
import { ServicesDirectory } from '@/components/website/ServicesDirectory';
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

const sectionIds = [
  'hero',
  'commodity-ticker',
  'estimator',
  'services-directory',
  'features',
  'how-it-works',
  'homeowners',
  'contractors',
  'download'
];

const routeMessages: Record<string, string> = {
  login: 'Opening sign-in page...',
  download: 'Redirecting to Connectzy Mobile App Download...',
  contact: 'Opening contact page...',
  'register/homeowner': 'Starting homeowner registration...',
  'register/contractor': 'Starting contractor registration...',
  'register/supplier': 'Starting supplier registration...',
  'register/business': 'Starting business registration...',
  contractors: 'Opening contractor directory...',
  marketplace: 'Opening B2B material marketplace...',
  chat: 'Opening milestone chat...',
  news: 'Opening live commodity news...',
  vendors: 'Opening 45+ trade services directory...',
  audit: 'Opening milestone photo auditing...',
  invoices: 'Opening quotation & GST invoicing...',
  dashboard: 'Opening provider dashboard...',
  verification: 'Opening credential verification...',
  about: 'Opening about Connectzy...',
  'market-news': 'Opening daily commodity ticker...',
  partner: 'Opening partner onboarding...',
  'b2b-network': 'Opening B2B wholesale network...',
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
      // Handle policy pages with dedicated URL paths (opens separately in a new tab)
      if (target === 'privacy-policy' || target === 'privacy') {
        window.open('/privacy-policy', '_blank');
        return;
      }
      if (target === 'terms' || target === 'terms-and-conditions' || target === 'terms-conditions') {
        window.open('/terms-and-conditions', '_blank');
        return;
      }
      if (target === 'refund-policy' || target === 'refund') {
        window.open('/refund-policy', '_blank');
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
            <CommodityTicker onNavigate={handleNavigate} />
            <Metrics />
            <CostEstimator onNavigate={handleNavigate} />
            <ServicesDirectory onNavigate={handleNavigate} />
            <PlatformFeatures onNavigate={handleNavigate} />
            <HowItWorks />
            <Homeowners onNavigate={handleNavigate} />
            <Contractors onNavigate={handleNavigate} />
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
