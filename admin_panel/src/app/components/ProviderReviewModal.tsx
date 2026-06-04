'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface Provider {
  id: string;
  businessName: string;
  ownerName: string;
  email: string;
  phone: string;
  category: string;
  experience: number;
  bio?: string | null;
  address?: string | null;
  aadharCard?: string | null;
  panCard?: string | null;
  profileCompletion: number;
  createdAt: any;
}

export default function ProviderReviewModal({ provider }: { provider: Provider }) {
  const [isOpen, setIsOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleAction = async (action: 'approve' | 'reject') => {
    setLoading(true);
    try {
      const endpoint = action === 'approve' 
        ? `/api/providers/${provider.id}/approve` 
        : `/api/providers/${provider.id}/reject`;
        
      const res = await fetch(endpoint, { method: 'PATCH' });
      if (res.ok) {
        setIsOpen(false);
        router.refresh();
      } else {
        alert(`Failed to ${action} provider`);
      }
    } catch (e) {
      alert(`Error during ${action}`);
    }
    setLoading(false);
  };

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
      >
        Review Details
      </button>

      {isOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in duration-200">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50 flex-shrink-0">
              <h2 className="text-xl font-bold text-gray-900">Provider Application Review</h2>
              <button onClick={() => setIsOpen(false)} className="text-gray-400 hover:text-gray-600">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="p-6 space-y-4 overflow-y-auto flex-1">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Business Name</label>
                  <p className="text-gray-900 font-medium">{provider.businessName}</p>
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Owner Name</label>
                  <p className="text-gray-900 font-medium">{provider.ownerName}</p>
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Category</label>
                  <p className="text-gray-900 font-medium">{provider.category}</p>
                </div>
                <div>
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Experience</label>
                  <p className="text-gray-900 font-medium">{provider.experience} Years</p>
                </div>
                <div className="col-span-2">
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Email Address</label>
                  <p className="text-gray-900 font-medium">{provider.email}</p>
                </div>
                <div className="col-span-2">
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Phone Number</label>
                  <p className="text-gray-900 font-medium">{provider.phone}</p>
                </div>
                <div className="col-span-2">
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Address</label>
                  <p className="text-gray-900 font-medium">{provider.address || 'Not Provided'}</p>
                </div>
                <div className="col-span-2">
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Business Bio</label>
                  <p className="text-gray-900 text-sm">{provider.bio || 'No bio provided'}</p>
                </div>
                <div className="col-span-2 bg-blue-50 p-3 rounded-lg border border-blue-100">
                  <label className="text-xs font-semibold text-blue-600 uppercase tracking-wider">Profile Completion</label>
                  <div className="flex items-center space-x-3 mt-1">
                    <div className="flex-1 h-2 bg-blue-100 rounded-full overflow-hidden">
                      <div className="h-full bg-blue-600 transition-all duration-500" style={{ width: `${provider.profileCompletion}%` }}></div>
                    </div>
                    <span className="text-sm font-bold text-blue-700">{provider.profileCompletion}%</span>
                  </div>
                </div>
                
                <div className="col-span-2 pt-4">
                  <label className="text-sm font-bold text-gray-900 block mb-3">KYC Documents</label>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <span className="text-xs font-medium text-gray-500">Aadhar Card</span>
                      {provider.aadharCard ? (
                        <div className="aspect-video bg-gray-100 rounded-lg overflow-hidden border border-gray-200">
                          <img src={provider.aadharCard} alt="Aadhar" className="w-full h-full object-cover" />
                        </div>
                      ) : (
                        <div className="aspect-video bg-gray-50 rounded-lg flex items-center justify-center border border-dashed border-gray-300 text-gray-400 text-xs">
                          Missing
                        </div>
                      )}
                    </div>
                    <div className="space-y-2">
                      <span className="text-xs font-medium text-gray-500">PAN Card</span>
                      {provider.panCard ? (
                        <div className="aspect-video bg-gray-100 rounded-lg overflow-hidden border border-gray-200">
                          <img src={provider.panCard} alt="PAN" className="w-full h-full object-cover" />
                        </div>
                      ) : (
                        <div className="aspect-video bg-gray-50 rounded-lg flex items-center justify-center border border-dashed border-gray-300 text-gray-400 text-xs">
                          Missing
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                <div className="col-span-2">
                  <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Submitted On</label>
                  <p className="text-gray-900 font-medium">{new Date(provider.createdAt).toLocaleDateString()}</p>
                </div>
              </div>
            </div>

            <div className="px-6 py-4 bg-gray-50 border-t border-gray-100 flex space-x-3 flex-shrink-0">
              <button
                onClick={() => handleAction('reject')}
                disabled={loading}
                className="flex-1 bg-red-50 hover:bg-red-100 text-red-600 font-semibold py-2.5 rounded-xl transition-colors disabled:opacity-50"
              >
                Reject Account
              </button>
              <button
                onClick={() => handleAction('approve')}
                disabled={loading}
                className="flex-1 bg-green-600 hover:bg-green-700 text-white font-semibold py-2.5 rounded-xl transition-colors shadow-lg shadow-green-200 disabled:opacity-50"
              >
                {loading ? 'Processing...' : 'Approve Account'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
