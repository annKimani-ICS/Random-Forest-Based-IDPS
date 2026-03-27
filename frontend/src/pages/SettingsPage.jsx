import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { dashboardAPI } from '../api';
import { ArrowLeft, Shield } from 'lucide-react';
import './SettingsPage.css';

function SettingsPage() {
  const { user, isAdmin } = useAuth();
  const navigate = useNavigate();
  const [threshold, setThreshold] = useState(0.5);
  const [originalThreshold, setOriginalThreshold] = useState(0.5);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [blocks, setBlocks] = useState([]);

  useEffect(() => {
    if (!isAdmin()) {
      navigate('/dashboard');
      return;
    }
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      setLoading(true);
      const [thresholdRes, blocksRes] = await Promise.all([
        dashboardAPI.getThreshold(),
        dashboardAPI.getActiveBlocks()
      ]);
      
      const thresholdValue = parseFloat(thresholdRes.data.current_value);
      setThreshold(thresholdValue);
      setOriginalThreshold(thresholdValue);
      setBlocks(blocksRes.data);
    } catch (err) {
      console.error('Error loading settings:', err);
      setError('Failed to load settings');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveThreshold = async () => {
    try {
      setSaving(true);
      setError('');
      setSuccess('');
      
      await dashboardAPI.updateThreshold(threshold);
      setOriginalThreshold(threshold);
      setSuccess('Threshold updated successfully');
      
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      console.error('Error updating threshold:', err);
      setError(err.response?.data?.detail || 'Failed to update threshold');
    } finally {
      setSaving(false);
    }
  };

  const handleDeactivateBlock = async (blockId) => {
    if (!confirm('Deactivate this block rule?')) return;

    try {
      await dashboardAPI.deactivateBlock(blockId);
      setSuccess('Block rule deactivated');
      loadSettings();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      console.error('Error deactivating block:', err);
      setError(err.response?.data?.detail || 'Failed to deactivate block');
    }
  };

  if (loading) {
    return <div className="loading-screen"><p>Loading settings...</p></div>;
  }

  return (
    <div className="settings-page">
      <div className="settings-header">
        <button className="back-button" onClick={() => navigate('/dashboard')}>
          <ArrowLeft size={20} />
          Back to Dashboard
        </button>
        <h1>Settings</h1>
      </div>

      <div className="settings-content">
        {error && <div className="error-banner">{error}</div>}
        {success && <div className="success-banner">{success}</div>}

        {/* Threshold Control */}
        <div className="settings-card">
          <div className="card-header">
            <Shield size={24} />
            <h2>Detection Threshold</h2>
          </div>
          <p className="card-description">
            Adjust the detection threshold to control the sensitivity of malicious traffic detection.
            Higher values reduce false positives but may miss some attacks.
          </p>

          <div className="threshold-control">
            <div className="threshold-display">
              <span className="threshold-value">{threshold.toFixed(2)}</span>
              <span className="threshold-label">Current Threshold</span>
            </div>

            <input
              type="range"
              min="0"
              max="1"
              step="0.01"
              value={threshold}
              onChange={(e) => setThreshold(parseFloat(e.target.value))}
              className="threshold-slider"
            />

            <div className="threshold-range">
              <span>0.00 (More Sensitive)</span>
              <span>1.00 (Less Sensitive)</span>
            </div>
          </div>

          <button
            className="btn btn-primary"
            onClick={handleSaveThreshold}
            disabled={saving || threshold === originalThreshold}
          >
            {saving ? 'Saving...' : 'Save Threshold'}
          </button>
        </div>

        {/* Active Blocks */}
        <div className="settings-card">
          <div className="card-header">
            <h2>Active Block Rules</h2>
            <span className="badge">{blocks.length} active</span>
          </div>

          {blocks.length === 0 ? (
            <p className="empty-message">No active block rules</p>
          ) : (
            <div className="blocks-list">
              {blocks.map((block) => (
                <div key={block.id} className="block-item">
                  <div className="block-info">
                    <code className="block-ip">{block.src_ip}</code>
                    <span className="block-reason">{block.reason}</span>
                    <span className="block-date">
                      Applied: {new Date(block.applied_at).toLocaleString()}
                    </span>
                  </div>
                  <button
                    className="btn-small btn-danger"
                    onClick={() => handleDeactivateBlock(block.id)}
                  >
                    Deactivate
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default SettingsPage;

