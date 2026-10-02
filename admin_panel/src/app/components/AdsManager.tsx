'use client';

import React, { useState, useRef } from 'react';

export interface Ad {
  id: string;
  title: string;
  desc: string;
  badge: string;
  icon?: string;
  gradient?: string;
  imageUrl?: string | null;
  targetSide?: string; // 'ALL' | 'CLIENT' | 'PROVIDER'
  actionUrl?: string | null;
  actionText?: string | null;
  isActive?: boolean;
  createdAt: string;
}

interface AdsManagerProps {
  initialAds: Ad[];
}

export default function AdsManager({ initialAds }: AdsManagerProps) {
  const [ads, setAds] = useState<Ad[]>(initialAds);
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [badge, setBadge] = useState('SPECIAL PROMO');
  const [targetSide, setTargetSide] = useState<'ALL' | 'CLIENT' | 'PROVIDER'>('ALL');
  const [imageUrl, setImageUrl] = useState('');
  const [actionUrl, setActionUrl] = useState('');
  const [actionText, setActionText] = useState('Explore Now');
  const [isActive, setIsActive] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [showPreviewModal, setShowPreviewModal] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Handle local file selection and convert to Base64 Data URL
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      setError('Please select a valid image file (PNG, JPG, WebP).');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      setError('Image file size should be under 5MB.');
      return;
    }

    setError('');
    const reader = new FileReader();
    reader.onload = () => {
      setImageUrl(reader.result as string);
    };
    reader.onerror = () => {
      setError('Failed to read image file.');
    };
    reader.readAsDataURL(file);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) {
      setError('Ad Title is required.');
      return;
    }
    setError('');
    setIsSubmitting(true);

    try {
      const response = await fetch('/api/ads', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: title.trim(),
          desc: desc.trim(),
          badge: badge.trim() || 'PROMOTION',
          imageUrl: imageUrl || null,
          targetSide,
          actionUrl: actionUrl.trim() || null,
          actionText: actionText.trim() || 'Explore Now',
          isActive,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setAds([data.ad, ...ads]);
        // Reset form
        setTitle('');
        setDesc('');
        setBadge('SPECIAL PROMO');
        setImageUrl('');
        setActionUrl('');
        setActionText('Explore Now');
        setIsActive(true);
        if (fileInputRef.current) fileInputRef.current.value = '';
      } else {
        const errData = await response.json();
        setError(errData.error || 'Failed to create ad.');
      }
    } catch {
      setError('Network error. Failed to save ad.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleActive = async (id: string, currentStatus: boolean) => {
    try {
      const newStatus = !currentStatus;
      const res = await fetch(`/api/ads/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isActive: newStatus }),
      });
      if (res.ok) {
        setAds(ads.map((ad) => (ad.id === id ? { ...ad, isActive: newStatus } : ad)));
      } else {
        alert('Failed to update ad status.');
      }
    } catch {
      alert('Network error while updating ad status.');
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this ad?')) return;
    try {
      const response = await fetch(`/api/ads/${id}`, {
        method: 'DELETE',
      });
      if (response.ok) {
        setAds(ads.filter((ad) => ad.id !== id));
      } else {
        alert('Failed to delete ad.');
      }
    } catch {
      alert('Network error. Failed to delete.');
    }
  };

  return (
    <div className="space-y-8">
      {/* Create / Publish Ad Form */}
      <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 p-8">
        <div className="flex flex-col md:flex-row md:items-center justify-between pb-6 border-b border-gray-100 mb-6 gap-4">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Run App Ads & Login Posters</h2>
            <p className="text-sm text-gray-500 mt-1">
              Upload promo posters displayed in a popup when clients or service providers log in or open the app.
            </p>
          </div>
          {imageUrl && (
            <button
              type="button"
              onClick={() => setShowPreviewModal(true)}
              className="inline-flex items-center px-4 py-2 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 text-xs font-bold rounded-xl transition"
            >
              <svg className="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
              </svg>
              Preview App Popup
            </button>
          )}
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <div className="p-4 bg-red-50 text-red-700 text-sm font-semibold rounded-xl border border-red-200">
              {error}
            </div>
          )}

          {/* 1. Target Audience Selection */}
          <div>
            <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-3">
              Target Audience / App Side *
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <button
                type="button"
                onClick={() => setTargetSide('ALL')}
                className={`flex items-center p-3.5 rounded-2xl border-2 transition text-left cursor-pointer ${
                  targetSide === 'ALL'
                    ? 'border-emerald-600 bg-emerald-50/70 text-emerald-950 font-bold shadow-sm'
                    : 'border-gray-200 bg-white hover:border-gray-300 text-gray-700 font-medium'
                }`}
              >
                <span className="text-xl mr-2.5">🌐</span>
                <div>
                  <div className="text-sm font-bold">Both Sides (All Users)</div>
                  <div className="text-xs text-gray-500">Clients & Providers</div>
                </div>
              </button>

              <button
                type="button"
                onClick={() => setTargetSide('CLIENT')}
                className={`flex items-center p-3.5 rounded-2xl border-2 transition text-left cursor-pointer ${
                  targetSide === 'CLIENT'
                    ? 'border-blue-600 bg-blue-50/70 text-blue-950 font-bold shadow-sm'
                    : 'border-gray-200 bg-white hover:border-gray-300 text-gray-700 font-medium'
                }`}
              >
                <span className="text-xl mr-2.5">👤</span>
                <div>
                  <div className="text-sm font-bold">Client Side Only</div>
                  <div className="text-xs text-gray-500">Homeowners & Buyers</div>
                </div>
              </button>

              <button
                type="button"
                onClick={() => setTargetSide('PROVIDER')}
                className={`flex items-center p-3.5 rounded-2xl border-2 transition text-left cursor-pointer ${
                  targetSide === 'PROVIDER'
                    ? 'border-purple-600 bg-purple-50/70 text-purple-950 font-bold shadow-sm'
                    : 'border-gray-200 bg-white hover:border-gray-300 text-gray-700 font-medium'
                }`}
              >
                <span className="text-xl mr-2.5">🔨</span>
                <div>
                  <div className="text-sm font-bold">Service Provider Side</div>
                  <div className="text-xs text-gray-500">Contractors & Suppliers</div>
                </div>
              </button>
            </div>
          </div>

          {/* 2. Poster Image Upload & Preview */}
          <div>
            <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
              Ad Poster Image / Banner
            </label>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
              <div className="md:col-span-2 space-y-3">
                <div className="border-2 border-dashed border-gray-200 hover:border-blue-400 rounded-2xl p-6 text-center transition bg-gray-50/50">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    className="hidden"
                    id="ad-poster-file"
                  />
                  <label htmlFor="ad-poster-file" className="cursor-pointer block">
                    <svg
                      className="mx-auto h-10 w-10 text-gray-400 mb-2"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        strokeWidth="2"
                        d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                      />
                    </svg>
                    <span className="text-sm font-bold text-blue-600 hover:text-blue-700">
                      Click to upload poster image
                    </span>
                    <p className="text-xs text-gray-500 mt-1">PNG, JPG, or WebP up to 5MB</p>
                  </label>
                </div>

                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-400 font-semibold uppercase">Or Image URL:</span>
                  <input
                    type="url"
                    value={imageUrl.startsWith('data:') ? '' : imageUrl}
                    onChange={(e) => setImageUrl(e.target.value)}
                    placeholder="https://example.com/poster.jpg"
                    className="flex-1 px-3 py-1.5 text-xs rounded-lg border border-gray-200 focus:outline-none focus:ring-1 focus:ring-blue-500 text-gray-700"
                  />
                </div>
              </div>

              {/* Poster Preview thumbnail */}
              <div className="flex flex-col items-center justify-center p-3 rounded-2xl border border-gray-200 bg-gray-50 min-h-[160px]">
                {imageUrl ? (
                  <div className="relative group w-full">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={imageUrl}
                      alt="Ad Preview"
                      className="w-full h-40 object-cover rounded-xl shadow-sm border border-gray-200"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        setImageUrl('');
                        if (fileInputRef.current) fileInputRef.current.value = '';
                      }}
                      className="absolute top-2 right-2 bg-red-600 text-white rounded-full p-1.5 shadow-md hover:bg-red-700 transition"
                      title="Remove image"
                    >
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                    <div className="text-center mt-1.5">
                      <span className="text-[11px] font-bold text-emerald-600">✓ Poster Loaded</span>
                    </div>
                  </div>
                ) : (
                  <div className="text-center text-gray-400">
                    <span className="text-3xl block mb-1">🖼️</span>
                    <span className="text-xs font-semibold">Poster Preview</span>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* 3. Title & Badge */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            <div className="md:col-span-2">
              <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
                Ad Headline / Title *
              </label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Mega Summer Discount on TMT Steel & Cement"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-gray-800"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
                Badge / Tag Label
              </label>
              <input
                type="text"
                value={badge}
                onChange={(e) => setBadge(e.target.value)}
                placeholder="e.g. 30% OFF or LIMITED"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-gray-800"
              />
            </div>
          </div>

          {/* 4. Description */}
          <div>
            <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
              Ad Description / Details
            </label>
            <textarea
              value={desc}
              onChange={(e) => setDesc(e.target.value)}
              placeholder="e.g. Get direct factory pricing with next-day site delivery. Limited stock available."
              rows={2}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-gray-800"
            />
          </div>

          {/* 5. Action / CTA Button Configuration */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
                CTA Button Text
              </label>
              <input
                type="text"
                value={actionText}
                onChange={(e) => setActionText(e.target.value)}
                placeholder="e.g. Explore Offers or Call Now"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm font-medium text-gray-800"
              />
            </div>
            <div>
              <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
                Action Route / Web URL (Optional)
              </label>
              <input
                type="text"
                value={actionUrl}
                onChange={(e) => setActionUrl(e.target.value)}
                placeholder="e.g. /b2b-materials, /create-project, or https://..."
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm font-medium text-gray-800"
              />
            </div>
          </div>

          {/* Submit & Status Bar */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between pt-4 border-t border-gray-100 gap-4">
            <label className="flex items-center space-x-3 cursor-pointer">
              <input
                type="checkbox"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
                className="h-5 w-5 rounded border-gray-300 text-blue-600 focus:ring-blue-500 cursor-pointer"
              />
              <span className="text-sm font-semibold text-gray-700">
                Activate immediately (Show on next user login)
              </span>
            </label>

            <button
              type="submit"
              disabled={isSubmitting}
              className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold text-sm rounded-xl shadow-lg shadow-blue-500/30 transition disabled:opacity-50 cursor-pointer"
            >
              {isSubmitting ? 'Publishing Ad...' : 'Publish Ad & Poster'}
            </button>
          </div>
        </form>
      </div>

      {/* Live / Existing Ads Table */}
      <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 p-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Active Ads & Posters</h2>
            <p className="text-sm text-gray-500">Currently configured popups & promos running in the app.</p>
          </div>
          <span className="px-3 py-1 bg-gray-100 text-gray-700 text-xs font-black rounded-full">
            {ads.length} Total
          </span>
        </div>

        {ads.length === 0 ? (
          <div className="text-center py-12 border-2 border-dashed border-gray-200 rounded-2xl">
            <span className="text-4xl block mb-2">📢</span>
            <p className="text-sm font-semibold text-gray-500">No ads running currently.</p>
            <p className="text-xs text-gray-400 mt-1">Create your first ad poster above to show it to app users.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {ads.map((ad) => {
              const side = ad.targetSide || 'ALL';
              return (
                <div
                  key={ad.id}
                  className={`rounded-2xl border p-5 transition flex flex-col justify-between ${
                    ad.isActive !== false ? 'bg-white border-gray-200 shadow-sm' : 'bg-gray-50 border-gray-200 opacity-60'
                  }`}
                >
                  <div>
                    {/* Poster thumbnail if available */}
                    {ad.imageUrl && (
                      <div className="relative mb-3 rounded-xl overflow-hidden bg-gray-100 border border-gray-200">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={ad.imageUrl}
                          alt={ad.title}
                          className="w-full h-32 object-cover hover:scale-105 transition duration-300"
                        />
                        <span className="absolute top-2 left-2 px-2 py-0.5 bg-black/70 text-white text-[10px] font-bold rounded-md backdrop-blur-sm">
                          {ad.badge || 'PROMO'}
                        </span>
                      </div>
                    )}

                    <div className="flex items-center justify-between gap-2 mb-2">
                      {/* Target Side Badge */}
                      <span
                        className={`text-[10px] font-black tracking-wider uppercase px-2.5 py-1 rounded-full ${
                          side === 'CLIENT'
                            ? 'bg-blue-100 text-blue-800'
                            : side === 'PROVIDER'
                            ? 'bg-purple-100 text-purple-800'
                            : 'bg-emerald-100 text-emerald-800'
                        }`}
                      >
                        {side === 'CLIENT' ? '👤 Client Side' : side === 'PROVIDER' ? '🔨 Provider Side' : '🌐 Both Sides'}
                      </span>

                      {/* Active toggle */}
                      <button
                        type="button"
                        onClick={() => handleToggleActive(ad.id, ad.isActive !== false)}
                        className={`text-[11px] font-bold px-2 py-0.5 rounded-full transition cursor-pointer ${
                          ad.isActive !== false
                            ? 'bg-green-100 text-green-700 hover:bg-green-200'
                            : 'bg-gray-200 text-gray-600 hover:bg-gray-300'
                        }`}
                        title="Click to toggle status"
                      >
                        {ad.isActive !== false ? '● Active' : '○ Paused'}
                      </button>
                    </div>

                    <h3 className="font-bold text-gray-900 text-sm leading-tight line-clamp-2">{ad.title}</h3>
                    {ad.desc && <p className="text-xs text-gray-500 mt-1 line-clamp-2 leading-relaxed">{ad.desc}</p>}
                    {ad.actionUrl && (
                      <div className="mt-2 text-[11px] text-blue-600 font-semibold truncate">
                        🔗 Action: {ad.actionUrl}
                      </div>
                    )}
                  </div>

                  <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between text-xs text-gray-400">
                    <span>{new Date(ad.createdAt).toLocaleDateString()}</span>
                    <button
                      type="button"
                      onClick={() => handleDelete(ad.id)}
                      className="text-red-500 hover:text-red-700 font-semibold transition cursor-pointer"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Interactive Mobile Popup Preview Modal */}
      {showPreviewModal && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-sm w-full overflow-hidden shadow-2xl relative animate-in fade-in zoom-in-95 duration-200">
            {/* Top Close Button */}
            <button
              type="button"
              onClick={() => setShowPreviewModal(false)}
              className="absolute top-3 right-3 z-10 bg-black/60 hover:bg-black/80 text-white rounded-full p-2 backdrop-blur-sm transition"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>

            {/* Poster Image */}
            {imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={imageUrl} alt="Poster" className="w-full max-h-72 object-cover" />
            ) : (
              <div className="h-48 bg-gradient-to-br from-teal-700 to-emerald-900 flex items-center justify-center text-white">
                <span className="text-4xl">📢</span>
              </div>
            )}

            {/* Content area */}
            <div className="p-5">
              <div className="inline-block px-2.5 py-1 bg-amber-500 text-white text-[10px] font-black rounded-lg uppercase tracking-wider mb-2">
                {badge || 'SPECIAL OFFER'}
              </div>
              <h3 className="font-extrabold text-gray-900 text-lg leading-snug">{title || 'Special Announcement'}</h3>
              {desc && <p className="text-xs text-gray-600 mt-1.5 leading-relaxed">{desc}</p>}

              {/* Action Button */}
              <button
                type="button"
                onClick={() => setShowPreviewModal(false)}
                className="w-full mt-4 py-3 bg-gradient-to-r from-teal-700 to-emerald-600 text-white font-bold text-sm rounded-xl shadow-lg shadow-teal-700/20"
              >
                {actionText || 'Explore Now'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
