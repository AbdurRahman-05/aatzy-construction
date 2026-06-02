'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface StatusToggleProps {
  id: string;
  initialStatus: boolean;
  type: 'user' | 'provider';
}

export default function StatusToggle({ id, initialStatus, type }: StatusToggleProps) {
  const [isActive, setIsActive] = useState(initialStatus);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleToggle = async () => {
    setLoading(true);
    try {
      const endpoint = type === 'user' 
        ? `/api/users/${id}/toggle-status` 
        : `/api/providers/${id}/toggle-status`;
        
      const res = await fetch(endpoint, { method: 'PATCH' });
      if (res.ok) {
        setIsActive(!isActive);
        router.refresh();
      } else {
        alert(`Failed to update ${type} status`);
      }
    } catch (e) {
      alert('Error updating status');
    }
    setLoading(false);
  };

  return (
    <button
      onClick={handleToggle}
      disabled={loading}
      className={`px-3 py-1 rounded-full text-xs font-bold transition-all ${
        isActive 
          ? 'bg-green-100 text-green-700 hover:bg-green-200' 
          : 'bg-red-100 text-red-700 hover:bg-red-200'
      } disabled:opacity-50`}
    >
      {loading ? '...' : (isActive ? 'Active' : 'Inactive')}
    </button>
  );
}
