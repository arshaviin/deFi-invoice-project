import React, { useState } from 'react';
import axios from 'axios';

function App() {
  const [features, setFeatures] = useState({});
  const [user, setUser] = useState('');
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleChange = (e) => {
    const { name, value } = e.target;
    if (name === 'user') {
      setUser(value);
    } else {
      setFeatures({ ...features, [name]: parseFloat(value) });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const res = await axios.post('/predict', { user, features });
      setResult(res.data);
    } catch (err) {
      console.error(err);
      setResult({ error: err.response?.data?.error || 'Server error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '600px', margin: '0 auto', padding: '2rem' }}>
      <h2>AI-Powered Credit Risk Scoring</h2>
      <form onSubmit={handleSubmit}>
        <label>User Wallet Address:</label>
        <input type="text" name="user" value={user} onChange={handleChange} required /><br /><br />

        <label>Wallet Age (days):</label>
        <input type="number" name="wallet_age" onChange={handleChange} required /><br />

        <label>Invoice Amount:</label>
        <input type="number" name="invoice_amount" onChange={handleChange} required /><br />

        <label>Repaid Ratio (0-1):</label>
        <input type="number" step="0.01" name="repaid_ratio" onChange={handleChange} required /><br />

        <label>Days Past Due:</label>
        <input type="number" name="days_past_due" onChange={handleChange} required /><br /><br />

        <button type="submit" disabled={loading}>{loading ? 'Scoring...' : 'Get Score'}</button>
      </form>

      {result && (
        <div style={{ marginTop: '2rem' }}>
          <h3>Result:</h3>
          <pre>{JSON.stringify(result, null, 2)}</pre>
        </div>
      )}
    </div>
  );
}

export default App;