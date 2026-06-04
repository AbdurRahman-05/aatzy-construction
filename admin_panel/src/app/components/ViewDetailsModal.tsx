'use client';

import { useState } from 'react';

interface UserData {
  id: string;
  name: string;
  email: string;
  role: string;
  isApproved: boolean;
  createdAt: string;
}

interface PortfolioImage {
  id: string;
  title: string;
  description?: string | null;
  imageData: string;
}

interface ProviderData {
  id: string;
  businessName: string;
  ownerName: string;
  email: string;
  phone: string;
  category: string;
  experience: number;
  isVerified: boolean;
  isRejected: boolean;
  bio?: string | null;
  address?: string | null;
  aadharCard?: string | null;
  panCard?: string | null;
  profileCompletion: number;
  createdAt: string;
  portfolioImages?: PortfolioImage[];
}

type ViewDetailsModalProps =
  | { type: 'user'; data: UserData }
  | { type: 'provider'; data: ProviderData };

export default function ViewDetailsModal(props: ViewDetailsModalProps) {
  const [isOpen, setIsOpen] = useState(false);

  const getStatusBadge = () => {
    if (props.type === 'user') {
      return props.data.isApproved ? (
        <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-green-100 text-green-700">
          <span className="w-1.5 h-1.5 bg-green-500 rounded-full mr-1.5"></span>
          Active
        </span>
      ) : (
        <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-red-100 text-red-700">
          <span className="w-1.5 h-1.5 bg-red-500 rounded-full mr-1.5"></span>
          Suspended
        </span>
      );
    } else {
      const provider = props.data;
      if (provider.isRejected) {
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-red-100 text-red-700">
            <span className="w-1.5 h-1.5 bg-red-500 rounded-full mr-1.5"></span>
            Rejected
          </span>
        );
      }
      return provider.isVerified ? (
        <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-green-100 text-green-700">
          <span className="w-1.5 h-1.5 bg-green-500 rounded-full mr-1.5"></span>
          Verified
        </span>
      ) : (
        <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-700">
          <span className="w-1.5 h-1.5 bg-amber-500 rounded-full mr-1.5"></span>
          Pending
        </span>
      );
    }
  };

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="inline-flex items-center space-x-1.5 bg-blue-50 hover:bg-blue-100 text-blue-600 hover:text-blue-700 px-3.5 py-2 rounded-lg text-sm font-semibold transition-all duration-200 border border-blue-200 hover:border-blue-300 hover:shadow-sm"
        title="View Details"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
        </svg>
        <span>View Details</span>
      </button>

      {isOpen && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4" onClick={() => setIsOpen(false)}>
          <div
            className="bg-white rounded-2xl shadow-2xl max-w-lg w-full max-h-[90vh] flex flex-col overflow-hidden text-left"
            onClick={(e) => e.stopPropagation()}
            style={{ animation: 'modalIn 0.2s ease-out' }}
          >
            {/* Header */}
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gradient-to-r from-blue-50 to-indigo-50 flex-shrink-0">
              <div className="flex items-center space-x-3">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-white font-bold text-sm shadow-md ${
                  props.type === 'user'
                    ? 'bg-gradient-to-br from-blue-500 to-blue-600'
                    : 'bg-gradient-to-br from-indigo-500 to-purple-600'
                }`}>
                  {props.type === 'user'
                    ? props.data.name[0]?.toUpperCase() || 'U'
                    : props.data.businessName[0]?.toUpperCase() || 'P'}
                </div>
                <div>
                  <h2 className="text-lg font-bold text-gray-900">
                    {props.type === 'user' ? props.data.name : props.data.businessName}
                  </h2>
                  <p className="text-xs text-gray-500">
                    {props.type === 'user' ? 'Consumer Account' : 'Provider Account'}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setIsOpen(false)}
                className="text-gray-400 hover:text-gray-600 hover:bg-white/80 p-1.5 rounded-lg transition-colors"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Body */}
            <div className="p-6 space-y-5 overflow-y-auto flex-1">
              {/* Status Badge */}
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">Account Status</span>
                {getStatusBadge()}
              </div>

              <hr className="border-gray-100" />

              {props.type === 'user' ? (
                /* ─── USER DETAILS ─── */
                <div className="space-y-4">
                  <DetailRow label="Full Name" value={props.data.name} />
                  <DetailRow label="Email Address" value={props.data.email} />
                  <DetailRow label="Role" value={props.data.role} />
                  <DetailRow
                    label="Registered On"
                    value={new Date(props.data.createdAt).toLocaleDateString('en-IN', {
                      year: 'numeric', month: 'long', day: 'numeric',
                    })}
                  />
                </div>
              ) : (
                /* ─── PROVIDER DETAILS ─── */
                <div className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <DetailRow label="Business Name" value={props.data.businessName} />
                    <DetailRow label="Owner Name" value={props.data.ownerName} />
                    <DetailRow label="Category" value={props.data.category} />
                    <DetailRow label="Experience" value={`${props.data.experience} Years`} />
                  </div>

                  <DetailRow label="Email Address" value={props.data.email} />
                  <DetailRow label="Phone Number" value={props.data.phone || 'Not Provided'} />
                  <DetailRow label="Address" value={props.data.address || 'Not Provided'} />

                  {/* Bio */}
                  <div>
                    <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-1">Business Bio</label>
                    <p className="text-gray-700 text-sm bg-gray-50 p-3 rounded-lg border border-gray-100 leading-relaxed">
                      {props.data.bio || 'No bio provided'}
                    </p>
                  </div>

                  {/* Profile Completion */}
                  <div className="bg-blue-50 p-4 rounded-xl border border-blue-100">
                    <div className="flex items-center justify-between mb-2">
                      <label className="text-xs font-semibold text-blue-700 uppercase tracking-wider">Profile Completion</label>
                      <span className="text-sm font-black text-blue-700">{props.data.profileCompletion}%</span>
                    </div>
                    <div className="h-2.5 bg-blue-100 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full transition-all duration-700"
                        style={{ width: `${props.data.profileCompletion}%` }}
                      ></div>
                    </div>
                  </div>

                  {/* KYC Documents */}
                  <div>
                    <label className="text-sm font-bold text-gray-900 block mb-3">KYC Documents</label>
                    <div className="grid grid-cols-2 gap-4">
                      <DocumentCard label="Aadhar Card" src={props.data.aadharCard} />
                      <DocumentCard label="PAN Card" src={props.data.panCard} />
                    </div>
                  </div>

                  {/* Project Portfolio */}
                  {props.data.portfolioImages && props.data.portfolioImages.length > 0 && (
                    <div>
                      <label className="text-sm font-bold text-gray-900 block mb-3">Project Portfolio</label>
                      <div className="flex overflow-x-auto space-x-4 pb-2 scrollbar-thin scrollbar-thumb-gray-200">
                        {props.data.portfolioImages.map((img) => (
                          <div key={img.id} className="flex-shrink-0 w-48 bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
                            <div className="aspect-video bg-gray-100">
                              <img src={img.imageData} alt={img.title} className="w-full h-full object-cover" />
                            </div>
                            <div className="p-3">
                              <p className="text-xs font-bold text-gray-900 truncate">{img.title}</p>
                              {img.description && <p className="text-[10px] text-gray-500 truncate">{img.description}</p>}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  <DetailRow
                    label="Registered On"
                    value={new Date(props.data.createdAt).toLocaleDateString('en-IN', {
                      year: 'numeric', month: 'long', day: 'numeric',
                    })}
                  />
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="px-6 py-4 bg-gray-50 border-t border-gray-100 flex-shrink-0">
              <button
                onClick={() => setIsOpen(false)}
                className="w-full bg-gray-200 hover:bg-gray-300 text-gray-700 font-semibold py-2.5 rounded-xl transition-colors text-sm"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      <style jsx>{`
        @keyframes modalIn {
          from {
            opacity: 0;
            transform: scale(0.95) translateY(10px);
          }
          to {
            opacity: 1;
            transform: scale(1) translateY(0);
          }
        }
      `}</style>
    </>
  );
}

/* ─── Helper Components ─── */

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider block mb-0.5">{label}</label>
      <p className="text-gray-900 font-medium text-sm">{value}</p>
    </div>
  );
}

function DocumentCard({ label, src }: { label: string; src?: string | null }) {
  return (
    <div className="space-y-2">
      <span className="text-xs font-medium text-gray-500">{label}</span>
      {src ? (
        <div className="aspect-video bg-gray-100 rounded-lg overflow-hidden border border-gray-200 hover:border-blue-300 transition-colors group relative cursor-pointer">
          <img src={src} alt={label} className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors flex items-center justify-center">
            <svg className="w-6 h-6 text-white opacity-0 group-hover:opacity-100 transition-opacity" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0zM10 7v3m0 0v3m0-3h3m-3 0H7" />
            </svg>
          </div>
        </div>
      ) : (
        <div className="aspect-video bg-gray-50 rounded-lg flex items-center justify-center border border-dashed border-gray-300 text-gray-400">
          <div className="text-center">
            <svg className="w-6 h-6 mx-auto mb-1 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
            <span className="text-xs">Not Uploaded</span>
          </div>
        </div>
      )}
    </div>
  );
}
