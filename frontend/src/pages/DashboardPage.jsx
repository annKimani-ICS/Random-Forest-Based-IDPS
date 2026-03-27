import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { dashboardAPI } from '../api';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { Shield, AlertTriangle, Ban, Activity, LogOut, Settings, Users, Menu, TrendingUp } from 'lucide-react';
import './DashboardPage.css';

function DashboardPage() {
  const { user, logout, isAdmin } = useAuth();
  const navigate = useNavigate();
  const [kpis, setKpis] = useState(null);
  const [metrics, setMetrics] = useState(null);
  const [alerts, setAlerts] = useState([]);
  const [trends, setTrends] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalAlerts, setTotalAlerts] = useState(0);
  const [filters, setFilters] = useState({
    attack_type: '',
    status: '',
    malicious: ''
  });

  // Treat backend timestamps as UTC and display in the browser's local time
  const toLocal = (utcString) => {
    if (!utcString) return '';
    const s = utcString.endsWith('Z') ? utcString : `${utcString}Z`;
    return new Date(s).toLocaleString();
  };

  useEffect(() => {
    loadDashboardData();
  }, [currentPage, filters]);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [kpisRes, metricsRes, alertsRes, trendsRes] = await Promise.all([
        dashboardAPI.getKPIs(),
        dashboardAPI.getMetrics(),
        dashboardAPI.getAlerts({
          page: currentPage,
          page_size: 25,
          ...filters
        }),
        dashboardAPI.getAttackTrends(8)
      ]);

      setKpis(kpisRes.data);
      setMetrics(metricsRes.data);
      setAlerts(alertsRes.data.alerts);
      setTotalAlerts(alertsRes.data.total);
      setTrends(trendsRes.data.trends);
      setError('');
    } catch (err) {
      console.error('Error loading dashboard:', err);
      setError('Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusUpdate = async (alertId, newStatus) => {
    try {
      await dashboardAPI.updateAlertStatus(alertId, newStatus);
      loadDashboardData();
    } catch (err) {
      console.error('Error updating alert:', err);
      alert('Failed to update alert status');
    }
  };

  const handleBlockIP = async (srcIp) => {
    const reason = prompt(`Block IP ${srcIp}? Enter reason:`);
    if (!reason) return;

    try {
      await dashboardAPI.createBlock(srcIp, reason);
      alert('IP blocked successfully');
      loadDashboardData();
    } catch (err) {
      console.error('Error blocking IP:', err);
      alert(err.response?.data?.detail || 'Failed to block IP');
    }
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const totalPages = Math.ceil(totalAlerts / 25);

  if (loading && !kpis) {
    return <div className="loading-screen"><p>Loading dashboard...</p></div>;
  }

  return (
    <div className="dashboard">
      {/* Header */}
      <header className="dashboard-header">
        <div className="header-left">
          <Shield size={32} />
          <div>
            <h1>IDS/IDPS Dashboard</h1>
            <p className="header-subtitle">{metrics?.model_version || 'Loading...'}</p>
          </div>
        </div>
        <div className="header-right">
          <span className="user-badge">{user?.email} ({user?.role})</span>
          {isAdmin() && (
            <>
              <button className="icon-btn" onClick={() => navigate('/users')} title="Manage Users">
                <Users size={20} />
              </button>
              <button className="icon-btn" onClick={() => navigate('/settings')} title="Settings">
                <Settings size={20} />
              </button>
            </>
          )}
          <button className="icon-btn" onClick={handleLogout} title="Logout">
            <LogOut size={20} />
          </button>
        </div>
      </header>

      <div className="dashboard-content">
        {error && <div className="error-banner">{error}</div>}

        {/* KPI Cards */}
        <div className="kpi-grid">
          <div className="kpi-card">
            <div className="kpi-icon" style={{ background: '#dbeafe' }}>
              <AlertTriangle size={24} color="#2563eb" />
            </div>
            <div className="kpi-content">
              <h3>Alerts (24h)</h3>
              <p className="kpi-value">{kpis?.alerts_24h || 0}</p>
            </div>
          </div>

          <div className="kpi-card">
            <div className="kpi-icon" style={{ background: '#fee2e2' }}>
              <Ban size={24} color="#ef4444" />
            </div>
            <div className="kpi-content">
              <h3>Active Blocks</h3>
              <p className="kpi-value">{kpis?.active_blocks || 0}</p>
            </div>
          </div>

          <div className="kpi-card">
            <div className="kpi-icon" style={{ background: '#dcfce7' }}>
              <Activity size={24} color="#10b981" />
            </div>
            <div className="kpi-content">
              <h3>Precision</h3>
              <p className="kpi-value">{(metrics?.precision * 100 || 0).toFixed(2)}%</p>
            </div>
          </div>

          <div className="kpi-card">
            <div className="kpi-icon" style={{ background: '#fef3c7' }}>
              <Shield size={24} color="#f59e0b" />
            </div>
            <div className="kpi-content">
              <h3>Threshold</h3>
              <p className="kpi-value">{(kpis?.threshold || 0).toFixed(2)}</p>
            </div>
          </div>
        </div>

        {/* Model Metrics */}
        {metrics && (
          <div className="metrics-card">
            <h2>Model Performance</h2>
            <div className="metrics-grid">
              <div className="metric-item">
                <span className="metric-label">Recall:</span>
                <span className="metric-value">{(metrics.recall * 100).toFixed(2)}%</span>
              </div>
              <div className="metric-item">
                <span className="metric-label">F1 Score:</span>
                <span className="metric-value">{(metrics.f1 * 100).toFixed(2)}%</span>
              </div>
              <div className="metric-item">
                <span className="metric-label">AUC:</span>
                <span className="metric-value">{(metrics.auc * 100).toFixed(2)}%</span>
              </div>
              <div className="metric-item">
                <span className="metric-label">Trained:</span>
                <span className="metric-value">{toLocal(metrics.trained_at)}</span>
              </div>
            </div>
          </div>
        )}

        {/* Attack Trends Chart */}
        {trends && trends.length > 0 && (
          <div className="trends-card">
            <div className="section-header">
              <h2>
                <TrendingUp size={24} style={{ marginRight: '8px', verticalAlign: 'middle' }} />
                Attack Trends Over Time
              </h2>
            </div>
            <div style={{ marginTop: '20px' }}>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={trends} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis 
                    dataKey="week_start" 
                    label={{ value: 'Week Starting', position: 'insideBottom', offset: -5 }}
                  />
                  <YAxis label={{ value: 'Number of Alerts', angle: -90, position: 'insideLeft' }} />
                  <Tooltip 
                    content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        const data = payload[0].payload;
                        return (
                          <div style={{ 
                            backgroundColor: 'white', 
                            padding: '10px', 
                            border: '1px solid #ccc',
                            borderRadius: '4px'
                          }}>
                            <p style={{ fontWeight: 'bold' }}>Week of {data.week_start}</p>
                            <p style={{ color: '#ef4444' }}>Malicious: {data.malicious_count}</p>
                            <p style={{ color: '#10b981' }}>Benign: {data.benign_count}</p>
                            <p style={{ fontWeight: 'bold' }}>Total: {data.total_attacks}</p>
                            {Object.keys(data.attack_types).length > 0 && (
                              <>
                                <hr style={{ margin: '5px 0' }} />
                                <p style={{ fontWeight: 'bold', fontSize: '12px' }}>Attack Types:</p>
                                {Object.entries(data.attack_types).map(([type, count]) => (
                                  <p key={type} style={{ fontSize: '12px' }}>{type}: {count}</p>
                                ))}
                              </>
                            )}
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                  <Legend />
                  <Line 
                    type="monotone" 
                    dataKey="malicious_count" 
                    name="Malicious" 
                    stroke="#ef4444" 
                    strokeWidth={2}
                    dot={{ r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="benign_count" 
                    name="Benign" 
                    stroke="#10b981" 
                    strokeWidth={2}
                    dot={{ r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="total_attacks" 
                    name="Total" 
                    stroke="#2563eb" 
                    strokeWidth={2}
                    dot={{ r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        )}

        {/* Alerts Table */}
        <div className="alerts-section">
          <div className="section-header">
            <h2>Recent Alerts</h2>
            <div className="filters">
              <select
                value={filters.malicious}
                onChange={(e) => setFilters({ ...filters, malicious: e.target.value })}
              >
                <option value="">All Alerts</option>
                <option value="true">Malicious Only</option>
                <option value="false">Benign Only</option>
              </select>
              <select
                value={filters.status}
                onChange={(e) => setFilters({ ...filters, status: e.target.value })}
              >
                <option value="">All Status</option>
                <option value="NEW">New</option>
                <option value="ACK">Acknowledged</option>
                <option value="BLOCKED">Blocked</option>
                <option value="CLOSED">Closed</option>
              </select>
            </div>
          </div>

          <div className="table-container">
            <table className="alerts-table">
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Source IP</th>
                  <th>Dest IP</th>
                  <th>Attack Type</th>
                  <th>Score</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {alerts.map((alert) => (
                  <tr key={alert.id}>
                    <td>{toLocal(alert.event_ts)}</td>
                    <td><code>{alert.src_ip}</code></td>
                    <td><code>{alert.dst_ip}</code></td>
                    <td>
                      <span className={`badge ${alert.is_malicious ? 'badge-danger' : 'badge-success'}`}>
                        {alert.attack_type}
                      </span>
                    </td>
                    <td>
                      <span className={alert.is_malicious ? 'text-danger' : 'text-success'}>
                        {alert.score.toFixed(4)}
                      </span>
                    </td>
                    <td>
                      <span className={`badge badge-${alert.status.toLowerCase()}`}>
                        {alert.status}
                      </span>
                    </td>
                    <td>
                      <div className="action-buttons">
                        {alert.status === 'NEW' && (
                          <button
                            className="btn-small"
                            onClick={() => handleStatusUpdate(alert.id, 'ACK')}
                          >
                            ACK
                          </button>
                        )}
                        {(alert.status === 'NEW' || alert.status === 'ACK') && alert.is_malicious && (
                          <button
                            className="btn-small btn-danger"
                            onClick={() => handleBlockIP(alert.src_ip)}
                          >
                            Block
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="pagination">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className="btn-small"
            >
              Previous
            </button>
            <span>Page {currentPage} of {totalPages}</span>
            <button
              onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
              disabled={currentPage === totalPages}
              className="btn-small"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default DashboardPage;

