import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { dashboardAPI } from '../api';
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend, PieChart, Pie, Cell } from 'recharts';
import { Shield, AlertTriangle, Ban, Activity, LogOut, Settings, Users, Menu, TrendingUp } from 'lucide-react';
import './DashboardPage.css';

function DashboardPage() {
  const { user, logout, isAdmin } = useAuth();
  const navigate = useNavigate();
  const [kpis, setKpis] = useState(null);
  const [metrics, setMetrics] = useState(null);
  const [alerts, setAlerts] = useState([]);
  const [trends, setTrends] = useState([]);
  const [alertAnalytics, setAlertAnalytics] = useState(null);
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
      const [kpisRes, metricsRes, alertsRes, trendsRes, analyticsRes] = await Promise.all([
        dashboardAPI.getKPIs(),
        dashboardAPI.getMetrics(),
      dashboardAPI.getAlerts({
        page: currentPage,
        page_size: 25,
        malicious: true,  // Only get malicious alerts
        ...filters
      }),
        dashboardAPI.getAttackTrends(8),
        dashboardAPI.getAlertAnalytics().catch(err => {
          console.error('Error loading analytics:', err);
          return { data: null };
        })
      ]);

      setKpis(kpisRes.data);
      setMetrics(metricsRes.data);
      // Filter out any benign alerts that might have slipped through
      const maliciousAlerts = alertsRes.data.alerts.filter(alert => alert.is_malicious === true);
      setAlerts(maliciousAlerts);
      setTotalAlerts(maliciousAlerts.length);
      setTrends(trendsRes.data.trends);
      
      // Set analytics only if we got valid data
      if (analyticsRes && analyticsRes.data) {
        console.log('Analytics data loaded:', analyticsRes.data);
        console.log('Status distribution:', analyticsRes.data.status_distribution);
        console.log('Top IPs:', analyticsRes.data.top_source_ips);
        console.log('Time series:', analyticsRes.data.alerts_over_time);
        setAlertAnalytics(analyticsRes.data);
      } else {
        console.warn('No analytics data received');
        setAlertAnalytics(null);
      }
      
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
          <Shield size={32} color="white" />
          <div>
            <h1>IDS/IDPS Dashboard</h1>
            <p className="header-subtitle">
              Model: {metrics?.model_version ? 
                (metrics.model_version.includes('random_forest') || metrics.model_version.includes('Random Forest') ? 
                  'Random Forest (Iteration 4)' : 
                  metrics.model_version.replace('iteration4_voting_ensemble', 'Random Forest (Iteration 4)')
                ) : 
                'Loading...'
              }
              {metrics?.trained_at && ` • Trained: ${new Date(metrics.trained_at).toLocaleDateString()}`}
            </p>
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
      
      {/* Debug info - remove in production */}
      {process.env.NODE_ENV === 'development' && alertAnalytics && (
        <div style={{ padding: '10px', background: '#f1f5f9', marginBottom: '1rem', borderRadius: '8px', fontSize: '12px' }}>
          <strong>Debug:</strong> Analytics loaded - Total: {alertAnalytics.total_alerts}, 
          Attack Types: {Object.keys(alertAnalytics.attack_type_distribution || {}).length},
          Statuses: {Object.keys(alertAnalytics.status_distribution || {}).length},
          Top IPs: {alertAnalytics.top_source_ips?.length || 0},
          Time Points: {alertAnalytics.alerts_over_time?.length || 0}
        </div>
      )}

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

        {/* Alert Analytics */}
        {alertAnalytics && alertAnalytics.total_alerts > 0 && (
          <div className="analytics-section">
            <div className="section-header">
              <h2>Alert Analytics</h2>
            </div>
            
            <div className="analytics-grid">
              {/* Attack Type Distribution */}
              <div className="analytics-card">
                <h3>Attack Type Distribution</h3>
                {alertAnalytics.attack_type_distribution && Object.keys(alertAnalytics.attack_type_distribution).length > 0 ? (
                  <ResponsiveContainer width="100%" height={280}>
                    <BarChart 
                      data={Object.entries(alertAnalytics.attack_type_distribution)
                        .map(([name, value]) => ({ name, value }))
                        .sort((a, b) => b.value - a.value)}
                      margin={{ top: 5, right: 30, left: 20, bottom: 80 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                      <XAxis 
                        dataKey="name" 
                        angle={-45} 
                        textAnchor="end" 
                        height={100}
                        stroke="#64748b"
                        tick={{ fontSize: 11 }}
                      />
                      <YAxis stroke="#64748b" />
                      <Tooltip 
                        contentStyle={{ backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px' }}
                        formatter={(value) => [value, 'Alerts']}
                      />
                      <Bar dataKey="value" fill="#2563eb" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <p>No attack type data available</p>
                )}
              </div>

              {/* Status Distribution */}
              <div className="analytics-card">
                <h3>Status Distribution</h3>
                {alertAnalytics.status_distribution && Object.keys(alertAnalytics.status_distribution).length > 0 ? (
                  <ResponsiveContainer width="100%" height={280}>
                    <PieChart>
                      <Pie
                        data={Object.entries(alertAnalytics.status_distribution)
                          .map(([name, value]) => ({ name, value }))
                          .filter(item => item.value > 0)}
                        cx="50%"
                        cy="50%"
                        labelLine={false}
                        label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                        outerRadius={90}
                        fill="#8884d8"
                        dataKey="value"
                      >
                        {Object.entries(alertAnalytics.status_distribution)
                          .filter(([_, value]) => value > 0)
                          .map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={['#ef4444', '#10b981', '#f59e0b', '#6366f1', '#8b5cf6'][index % 5]} />
                          ))}
                      </Pie>
                      <Tooltip 
                        formatter={(value, name) => [value, name]}
                        contentStyle={{ backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px' }}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                ) : (
                  <p>No status data available</p>
                )}
              </div>

              {/* Top Source IPs */}
              <div className="analytics-card">
                <h3>Top Source IPs</h3>
                {alertAnalytics.top_source_ips && alertAnalytics.top_source_ips.length > 0 ? (
                  <ResponsiveContainer width="100%" height={280}>
                    <BarChart 
                      data={alertAnalytics.top_source_ips.slice(0, 10)} 
                      layout="vertical"
                      margin={{ top: 5, right: 30, left: 100, bottom: 5 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                      <XAxis type="number" stroke="#64748b" />
                      <YAxis 
                        dataKey="ip" 
                        type="category" 
                        width={120}
                        stroke="#64748b"
                        tick={{ fontSize: 12 }}
                      />
                      <Tooltip 
                        contentStyle={{ backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px' }}
                        formatter={(value) => [value, 'Alerts']}
                      />
                      <Bar dataKey="count" fill="#10b981" radius={[0, 4, 4, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                ) : (
                  <p>No source IP data available</p>
                )}
              </div>

              {/* Alerts Over Time */}
              <div className="analytics-card" style={{ gridColumn: '1 / -1' }}>
                <h3>Alerts Over Time</h3>
                {alertAnalytics.alerts_over_time && alertAnalytics.alerts_over_time.length > 0 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart 
                      data={alertAnalytics.alerts_over_time}
                      margin={{ top: 5, right: 30, left: 20, bottom: 60 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                      <XAxis 
                        dataKey="date" 
                        stroke="#64748b"
                        angle={-45}
                        textAnchor="end"
                        height={80}
                        tick={{ fontSize: 11 }}
                      />
                      <YAxis stroke="#64748b" />
                      <Tooltip 
                        contentStyle={{ backgroundColor: 'white', border: '1px solid #e2e8f0', borderRadius: '8px' }}
                      />
                      <Legend 
                        wrapperStyle={{ paddingTop: '20px' }}
                        iconType="line"
                      />
                      <Line 
                        type="monotone" 
                        dataKey="count" 
                        name="Total" 
                        stroke="#2563eb" 
                        strokeWidth={2.5}
                        dot={{ r: 4 }}
                        activeDot={{ r: 6 }}
                      />
                      <Line 
                        type="monotone" 
                        dataKey="malicious" 
                        name="Malicious" 
                        stroke="#ef4444" 
                        strokeWidth={2.5}
                        dot={{ r: 4 }}
                        activeDot={{ r: 6 }}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                ) : (
                  <p>No time series data available</p>
                )}
              </div>
            </div>

            {/* Summary Stats */}
            <div className="analytics-summary">
              <div className="summary-item">
                <span className="summary-label">Total Alerts:</span>
                <span className="summary-value">{alertAnalytics.total_alerts}</span>
              </div>
              <div className="summary-item">
                <span className="summary-label">Malicious:</span>
                <span className="summary-value" style={{ color: '#ef4444' }}>{alertAnalytics.malicious_count}</span>
              </div>
          </div>
        )}

        {/* Alerts Table */}
        <div className="alerts-section">
          <div className="section-header">
            <h2>Recent Alerts</h2>
            <div className="filters">
              <select
                value={filters.attack_type}
                onChange={(e) => setFilters({ ...filters, attack_type: e.target.value })}
              >
                <option value="">All Attack Types</option>
                {alertAnalytics && Object.keys(alertAnalytics.attack_type_distribution).map(type => (
                  <option key={type} value={type}>{type}</option>
                ))}
              </select>
              <select
                value={filters.malicious}
                onChange={(e) => setFilters({ ...filters, malicious: e.target.value })}
              >
                <option value="">All Alerts</option>
                <option value="true">Malicious Only</option>
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
                      <span className="badge badge-danger">
                        {alert.attack_type}
                      </span>
                    </td>
                    <td>
                      <span className="text-danger">
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
                        {(alert.status === 'NEW' || alert.status === 'ACK') && (
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

