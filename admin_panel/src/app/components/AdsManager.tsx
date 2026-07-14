'use client';

import React, { useState } from 'react';

interface Ad {
  id: string;
  title: string;
  desc: string;
  badge: string;
  icon: string;
  gradient: string;
  createdAt: string;
}

interface AdsManagerProps {
  initialAds: Ad[];
}

const ICON_OPTIONS = [
  { name: 'Verified User', value: 'verified_user_rounded' },
  { name: 'Security Shield', value: 'security_rounded' },
  { name: 'Shopping Bag', value: 'shopping_bag_rounded' },
  { name: 'Compare Arrows', value: 'compare_arrows_rounded' },
  { name: 'Calculator', value: 'calculate_rounded' },
  { name: 'Photo Library', value: 'photo_library_rounded' },
  { name: 'Storefront', value: 'storefront_rounded' },
  { name: 'Flash Bolt', value: 'flash_on_rounded' },
  { name: 'Build/Construction', value: 'construction_rounded' },
  { name: 'Home/House', value: 'home_rounded' },
];

const GRADIENT_OPTIONS = [
  { name: 'Deep Emerald Green', value: '0xFF2E7D32,0xFF1B5E20' },
  { name: 'Premium Navy Teal', value: '0xFF064354,0xFF0B7C8E' },
  { name: 'Vibrant Aqua Teal', value: '0xFF0F9B8E,0xFF0E5E6F' },
  { name: 'Royal Purple Indigo', value: '0xFF8E2DE2,0xFF4A00E0' },
  { name: 'Warm Amber Orange', value: '0xFFF39C12,0xFFD35400' },
];

export default function AdsManager({ initialAds }: AdsManagerProps) {
  const [ads, setAds] = useState<Ad[]>(initialAds);
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [badge, setBadge] = useState('');
  const [icon, setIcon] = useState('verified_user_rounded');
  const [gradient, setGradient] = useState('0xFF2E7D32,0xFF1B5E20');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !desc || !badge) {
      setError('Please fill in all required fields.');
      return;
    }
    setError('');
    setIsSubmitting(true);

    try {
      const response = await fetch('/api/ads', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, desc, badge, icon, gradient }),
      });

      if (response.ok) {
        const data = await response.json();
        setAds([data.ad, ...ads]);
        // Reset form
        setTitle('');
        setDesc('');
        setBadge('');
      } else {
        const errData = await response.json();
        setError(errData.error || 'Failed to create ad.');
      }
    } catch (err) {
      setError('Network error. Failed to send ad.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this ad/banner?')) return;
    try {
      const response = await fetch(`/api/ads/${id}`, {
        method: 'DELETE',
      });
      if (response.ok) {
        setAds(ads.filter((ad) => ad.id !== id));
      } else {
        alert('Failed to delete ad.');
      }
    } catch (err) {
      alert('Network error. Failed to delete.');
    }
  };

  return (
    <div className="space-y-8">
      {/* Create Ad Form */}
      <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 p-8">
        <h2 className="text-xl font-bold text-gray-900 mb-6">Create New Ad / Carousel Banner</h2>
        <form onSubmit={handleSubmit} className="space-y-5">
          {error && (
            <div className="p-4 bg-red-50 text-red-700 text-sm font-semibold rounded-xl border border-red-150">
              {error}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
                Ad Title *
              </label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Vetted Local Builders"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-gray-800"
                required
              />
            </div>
            <div>
              <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
                Badge / Tag Label *
              </label>
              <input
                type="text"
                value={badge}
                onChange={(e) => setBadge(e.target.value)}
                placeholder="e.g. VERIFIED ONLY"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-gray-800"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
              Description / Promotion Text *
            </label>
            <textarea
              value={desc}
              onChange={(e) => setDesc(e.target.value)}
              placeholder="e.g. Connect directly with certified, licensed, and top-rated local contractors."
              rows={3}
              className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-gray-800"
              required
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
                Representative Icon
              </label>
              <select
                value={icon}
                onChange={(e) => setIcon(e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-gray-800"
              >
                {ICON_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-black text-gray-400 uppercase tracking-widest mb-2">
                Card Gradient Theme
              </label>
              <select
                value={gradient}
                onChange={(e) => setGradient(e.target.value)}
                className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500 font-medium text-gray-800"
              >
                {GRADIENT_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="pt-2">
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-6 py-3.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl shadow-lg shadow-blue-200 transition-colors disabled:bg-gray-400 disabled:shadow-none"
            >
              {isSubmitting ? 'Creating Ad Banner...' : 'Publish Advertisement'}
            </button>
          </div>
        </form>
      </div>

      {/* Ads List */}
      <div className="bg-white rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100 overflow-hidden">
        <div className="px-8 py-6 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-lg font-bold text-gray-900">Active Mobile Ads ({ads.length})</h2>
        </div>
        
        {ads.length === 0 ? (
          <div className="p-12 text-center text-gray-400">
            <svg className="w-16 h-16 mx-auto text-gray-200 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z" />
            </svg>
            <p className="text-lg font-medium">No custom ads published. Showing default app features carousel.</p>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {ads.map((ad) => {
              const gradColors = ad.gradient.split(',');
              const displayGrad = gradColors.map(c => c.replace('0xFF', '#')).join(', ');

              return (
                <div key={ad.id} className="p-6 flex flex-col md:flex-row md:items-center justify-between gap-4 hover:bg-gray-50/50 transition-colors">
                  <div className="flex-1 space-y-2">
                    <div className="flex items-center space-x-3">
                      <span className="bg-blue-50 text-blue-700 text-xxs font-extrabold px-2.5 py-1 rounded-md uppercase tracking-wider">
                        {ad.badge}
                      </span>
                      <h3 className="font-bold text-gray-950 text-base">{ad.title}</h3>
                    </div>
                    <p className="text-sm text-gray-600">{ad.desc}</p>
                    <div className="flex items-center space-x-6 text-xs text-gray-400 font-semibold">
                      <span>Icon: <code className="bg-gray-100 px-1.5 py-0.5 rounded text-gray-700">{ad.icon}</code></span>
                      <span className="flex items-center space-x-1.5">
                        <span>Gradient:</span>
                        <div 
                          className="w-4 h-4 rounded-full border border-gray-300"
                          style={{ background: `linear-gradient(135deg, ${gradColors.map(c => c.replace('0xFF', '#')).join(', ')})` }}
                        />
                        <span className="font-mono text-gray-500">{ad.gradient}</span>
                      </span>
                    </div>
                  </div>
                  <div>
                    <button
                      onClick={() => handleDelete(ad.id)}
                      className="px-4 py-2 border border-red-200 text-red-600 hover:bg-red-50 font-bold text-sm rounded-xl transition-all"
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
    </div>
  );
}
