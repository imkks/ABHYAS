import React, { useState, useEffect } from 'react';
import { loadMockConfig, saveMockConfig } from '../configService';

export const ConfigEditor: React.FC = () => {
  const [configJson, setConfigJson] = useState<string>('{\n  "loading": true\n}');
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    loadMockConfig().then((config) => {
      setConfigJson(JSON.stringify(config, null, 2));
      setLoading(false);
    });
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setConfigJson(e.target.value);
    setError(null);
    setSaved(false);
  };

  const handleSave = async () => {
    try {
      const parsed = JSON.parse(configJson);
      setError(null);
      await saveMockConfig(parsed);
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch (err: any) {
      setError(`Invalid JSON: ${err.message}`);
    }
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif', marginTop: '20px', backgroundColor: '#eef7fa', borderRadius: '8px' }}>
      <h2>Practice Configuration Editor</h2>
      <p style={{ color: '#555' }}>Remote configuration schema defining ratios, safety hold caps, weaning rules, and levels.</p>

      {error && <div style={{ color: 'red', marginBottom: '10px', fontWeight: 'bold' }}>{error}</div>}
      {saved && <div style={{ color: 'green', marginBottom: '10px', fontWeight: 'bold' }}>Configuration saved successfully!</div>}

      <textarea
        value={configJson}
        onChange={handleChange}
        disabled={loading}
        style={{
          width: '100%',
          height: '400px',
          fontFamily: 'monospace',
          fontSize: '14px',
          padding: '10px',
          borderRadius: '4px',
          border: '1px solid #ccc',
          boxSizing: 'border-box'
        }}
      />

      <button
        onClick={handleSave}
        disabled={loading}
        style={{ marginTop: '15px', backgroundColor: '#2196F3', color: 'white', border: 'none', padding: '10px 20px', borderRadius: '4px', cursor: 'pointer', fontSize: '16px' }}
      >
        {loading ? 'Loading...' : 'Validate & Save Draft'}
      </button>
    </div>
  );
};
