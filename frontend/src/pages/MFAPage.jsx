import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './LoginPage.css';

function MFAPage() {
  const [code, setCode] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { verifyMFA } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const mfaTicket = location.state?.mfa_ticket;

  if (!mfaTicket) {
    navigate('/login');
    return null;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await verifyMFA(mfaTicket, code);
      navigate('/dashboard');
    } catch (err) {
      console.error('MFA verification error:', err);
      setError(err.response?.data?.detail || 'Invalid code. Please try again.');
      setCode('');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-box">
        <div className="login-header">
          <h1>Two-Factor Authentication</h1>
          <p>Enter your 6-digit code from Google Authenticator</p>
        </div>
        
        <form onSubmit={handleSubmit} className="login-form">
          {error && <div className="error-message">{error}</div>}
          
          <div className="form-group">
            <label htmlFor="code">Authentication Code</label>
            <input
              id="code"
              type="text"
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
              placeholder="000000"
              required
              autoFocus
              style={{ fontSize: '1.5rem', textAlign: 'center', letterSpacing: '0.5rem' }}
              maxLength={6}
            />
          </div>

          <button type="submit" className="btn btn-primary" disabled={loading || code.length !== 6}>
            {loading ? 'Verifying...' : 'Verify'}
          </button>

          <button
            type="button"
            className="btn"
            onClick={() => navigate('/login')}
            style={{ background: '#f1f5f9', color: '#475569' }}
          >
            Back to Login
          </button>
        </form>
      </div>
    </div>
  );
}

export default MFAPage;

