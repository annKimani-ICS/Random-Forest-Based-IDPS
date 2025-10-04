import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { authAPI } from '../api';
import { ArrowLeft, Shield } from 'lucide-react';
import './SettingsPage.css';

function MFAEnrollPage() {
  const { reloadUser } = useAuth();
  const navigate = useNavigate();
  const [step, setStep] = useState(1); // 1: generate QR, 2: verify code
  const [qrCode, setQrCode] = useState('');
  const [secret, setSecret] = useState('');
  const [verifyCode, setVerifyCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    enrollMFA();
  }, []);

  const enrollMFA = async () => {
    try {
      setLoading(true);
      const response = await authAPI.enrollMFA();
      setQrCode(response.data.qr_code);
      setSecret(response.data.secret);
    } catch (err) {
      console.error('Error enrolling MFA:', err);
      setError('Failed to generate MFA credentials');
    } finally {
      setLoading(false);
    }
  };

  const handleActivate = async (e) => {
    e.preventDefault();
    
    try {
      setLoading(true);
      setError('');
      
      await authAPI.activateMFA(verifyCode);
      alert('2FA activated successfully! Save your recovery codes securely.');
      await reloadUser();
      navigate('/dashboard');
    } catch (err) {
      console.error('Error activating MFA:', err);
      setError(err.response?.data?.detail || 'Invalid code. Please try again.');
      setVerifyCode('');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="settings-page">
      <div className="settings-header">
        <button className="back-button" onClick={() => navigate('/dashboard')}>
          <ArrowLeft size={20} />
          Back to Dashboard
        </button>
        <h1>Enable Two-Factor Authentication</h1>
      </div>

      <div className="settings-content">
        <div className="settings-card">
          <div className="card-header">
            <Shield size={24} />
            <h2>Setup Authenticator App</h2>
          </div>

          {error && <div className="error-banner">{error}</div>}

          {step === 1 && (
            <div className="mfa-setup">
              <p className="card-description">
                Scan the QR code below with Google Authenticator, Authy, or any compatible TOTP app.
              </p>

              {loading ? (
                <p>Generating QR code...</p>
              ) : (
                <>
                  <div className="qr-container">
                    {qrCode && <img src={qrCode} alt="QR Code" style={{ maxWidth: '300px' }} />}
                  </div>

                  <div className="secret-container">
                    <p className="secret-label">Or enter this code manually:</p>
                    <code className="secret-code">{secret}</code>
                  </div>

                  <button
                    className="btn btn-primary"
                    onClick={() => setStep(2)}
                  >
                    Next: Verify Code
                  </button>
                </>
              )}
            </div>
          )}

          {step === 2 && (
            <div className="mfa-verify">
              <p className="card-description">
                Enter the 6-digit code from your authenticator app to complete setup.
              </p>

              <form onSubmit={handleActivate} className="verify-form">
                <div className="form-group">
                  <label>Authentication Code</label>
                  <input
                    type="text"
                    value={verifyCode}
                    onChange={(e) => setVerifyCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                    placeholder="000000"
                    required
                    autoFocus
                    style={{ fontSize: '1.5rem', textAlign: 'center', letterSpacing: '0.5rem' }}
                    maxLength={6}
                  />
                </div>

                <div className="form-actions">
                  <button
                    type="submit"
                    className="btn btn-primary"
                    disabled={loading || verifyCode.length !== 6}
                  >
                    {loading ? 'Verifying...' : 'Activate 2FA'}
                  </button>
                  <button
                    type="button"
                    className="btn"
                    onClick={() => setStep(1)}
                    style={{ background: '#f1f5f9', color: '#475569' }}
                  >
                    Back
                  </button>
                </div>
              </form>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default MFAEnrollPage;

