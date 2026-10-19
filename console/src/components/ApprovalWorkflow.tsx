import React, { useState, useEffect } from 'react';
import { loadUnlockRequests, saveUnlockRequests } from '../configService';

interface UnlockRequest {
  id: string;
  studentName: string;
  requestedLevel: number;
  recentFlags: string[];
  status: 'pending' | 'approved' | 'denied';
}

export const ApprovalWorkflow: React.FC = () => {
  const [requests, setRequests] = useState<UnlockRequest[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    loadUnlockRequests().then((data: any) => {
      setRequests(data);
      setLoading(false);
    });
  }, []);

  const handleAction = async (id: string, newStatus: 'approved' | 'denied') => {
    const updatedRequests = requests.map(req => req.id === id ? { ...req, status: newStatus } : req);
    setRequests(updatedRequests);
    await saveUnlockRequests(updatedRequests);
  };

  if (loading) {
    return <div>Loading requests...</div>;
  }

  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif', marginTop: '20px', backgroundColor: '#f9f9f9', borderRadius: '8px' }}>
      <h2>Guru Anumati (Unlock Requests)</h2>
      {requests.length === 0 ? (
        <p>No pending requests.</p>
      ) : (
        <ul style={{ listStyleType: 'none', padding: 0 }}>
          {requests.map(req => (
            <li key={req.id} style={{ marginBottom: '15px', padding: '15px', border: '1px solid #ddd', borderRadius: '4px', backgroundColor: 'white' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <strong>{req.studentName}</strong> is requesting to unlock Level {req.requestedLevel}.
                  {req.recentFlags && req.recentFlags.length > 0 && (
                    <div style={{ color: 'red', marginTop: '5px' }}>
                      <span role="img" aria-label="warning">⚠️</span> Recent flags: {req.recentFlags.join(', ')}
                    </div>
                  )}
                  <div style={{ marginTop: '5px', color: '#666', fontStyle: 'italic' }}>Status: {req.status.toUpperCase()}</div>
                </div>
                {req.status === 'pending' && (
                  <div>
                    <button
                      onClick={() => handleAction(req.id, 'approved')}
                      style={{ marginRight: '10px', backgroundColor: '#4CAF50', color: 'white', border: 'none', padding: '8px 16px', borderRadius: '4px', cursor: 'pointer' }}
                    >
                      Approve
                    </button>
                    <button
                      onClick={() => handleAction(req.id, 'denied')}
                      style={{ backgroundColor: '#f44336', color: 'white', border: 'none', padding: '8px 16px', borderRadius: '4px', cursor: 'pointer' }}
                    >
                      Deny
                    </button>
                  </div>
                )}
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};
