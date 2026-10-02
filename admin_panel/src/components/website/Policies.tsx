'use client';

import { ArrowLeft } from 'lucide-react';

interface PolicyPageProps {
  title: string;
  onBack: () => void;
}

export function PolicyPage({ title, onBack }: PolicyPageProps) {
  return (
    <div className="min-h-screen bg-white pt-24 pb-12">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <button
          onClick={onBack}
          className="mb-8 flex items-center gap-2 text-sm font-semibold text-primary-500 transition-colors hover:text-accent"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to Home
        </button>
        
        <h1 className="mb-8 font-display text-3xl font-bold text-primary sm:text-4xl">
          {title}
        </h1>
        
        <div className="prose prose-lg text-primary-600">
          <p>
            Last updated: {new Date().toLocaleDateString()}
          </p>
          <p className="mt-6">
            This is the official policy document for <strong>{title}</strong> at Connectzy Construction Technologies.
          </p>
          
          <h2 className="mt-8 text-xl font-bold text-primary">1. Overview</h2>
          <p className="mt-4">
            Connectzy is committed to providing a transparent, secure, and dependable ecosystem for property owners, builders, contractors, and building material suppliers. This policy outlines our standards, practices, and guidelines.
          </p>
          
          <h2 className="mt-8 text-xl font-bold text-primary">2. User Data & Confidentiality</h2>
          <p className="mt-4">
            All user credentials, payment records, site inspection logs, and direct inquiries are stored with end-to-end security standards. We never sell or compromise proprietary trade details or personal identification documents.
          </p>

          <h2 className="mt-8 text-xl font-bold text-primary">3. Verified Providers & Service Standards</h2>
          <p className="mt-4">
            Contractors and suppliers registered on Connectzy undergo credential screening. Service milestones, photo verification, and digital invoicing are designed to ensure mutual accountability across all construction projects.
          </p>
        </div>
      </div>
    </div>
  );
}
