'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function ApproveButton({ providerId }: { providerId: string }) {
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleApprove = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/providers/${providerId}/approve`, {
        method: 'PATCH',
      });
      if (res.ok) {
        router.refresh();
      } else {
        alert('Failed to approve provider');
      }
    } catch (e) {
      alert('Error approving provider');
    }
    setLoading(false);
  };

  return (
    <button
      onClick={handleApprove}
      disabled={loading}
      className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors disabled:opacity-50"
    >
      {loading ? 'Approving...' : 'Approve'}
    </button>
  );
}
