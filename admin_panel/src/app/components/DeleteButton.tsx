'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface DeleteButtonProps {
  id: string;
  type: 'user' | 'provider';
  name: string;
}

export default function DeleteButton({ id, type, name }: DeleteButtonProps) {
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleDelete = async () => {
    if (!confirm(`Are you sure you want to delete the ${type} "${name}"? This action cannot be undone.`)) {
      return;
    }

    setLoading(true);
    try {
      const endpoint = type === 'user' ? `/api/users/${id}` : `/api/providers/${id}`;
      const res = await fetch(endpoint, { method: 'DELETE' });

      if (res.ok) {
        router.refresh();
      } else {
        alert(`Failed to delete ${type}`);
      }
    } catch (e) {
      alert('Error during deletion');
    }
    setLoading(false);
  };

  return (
    <button
      onClick={handleDelete}
      disabled={loading}
      className="p-2 text-gray-400 hover:text-red-600 transition-colors rounded-lg hover:bg-red-50 disabled:opacity-50"
      title={`Delete ${type}`}
    >
      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
      </svg>
    </button>
  );
}
