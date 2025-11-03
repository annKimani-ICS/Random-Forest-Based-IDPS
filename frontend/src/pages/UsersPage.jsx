import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { usersAPI } from '../api';
import { ArrowLeft, UserPlus, Shield, User, Trash } from 'lucide-react';
import './SettingsPage.css';

function UsersPage() {
  const { isAdmin, user: currentUser } = useAuth();
  const navigate = useNavigate();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newUser, setNewUser] = useState({
    email: '',
    password: '',
    role: 'ANALYST'
  });

  useEffect(() => {
    if (!isAdmin()) {
      navigate('/dashboard');
      return;
    }
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const response = await usersAPI.listUsers();
      setUsers(response.data);
    } catch (err) {
      console.error('Error loading users:', err);
      setError('Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = async (e) => {
    e.preventDefault();
    
    try {
      setError('');
      setSuccess('');
      
      await usersAPI.createUser(newUser.email, newUser.password, newUser.role);
      setSuccess(`User ${newUser.email} created successfully`);
      setShowCreateForm(false);
      setNewUser({ email: '', password: '', role: 'ANALYST' });
      loadUsers();
      
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      console.error('Error creating user:', err);
      setError(err.response?.data?.detail || 'Failed to create user');
    }
  };

  const handleToggleActive = async (userId, currentStatus) => {
    try {
      await usersAPI.updateUser(userId, { is_active: !currentStatus });
      setSuccess('User status updated');
      loadUsers();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      console.error('Error updating user:', err);
      setError(err.response?.data?.detail || 'Failed to update user');
    }
  };

  const handleChangeRole = async (userId, newRole) => {
    try {
      await usersAPI.updateUser(userId, { role: newRole });
      setSuccess('User role updated');
      loadUsers();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      console.error('Error updating user:', err);
      setError(err.response?.data?.detail || 'Failed to update user');
    }
  };

  const handleDeleteUser = async (userId, email) => {
    const confirmed = window.confirm(`Delete user ${email}? This action cannot be undone.`);
    if (!confirmed) return;
    try {
      setError('');
      setSuccess('');
      await usersAPI.deleteUser(userId);
      setSuccess(`User ${email} deleted`);
      loadUsers();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      console.error('Error deleting user:', err);
      setError(err.response?.data?.detail || 'Failed to delete user');
    }
  };

  if (loading) {
    return <div className="loading-screen"><p>Loading users...</p></div>;
  }

  return (
    <div className="settings-page">
      <div className="settings-header">
        <button className="back-button" onClick={() => navigate('/dashboard')}>
          <ArrowLeft size={20} />
          Back to Dashboard
        </button>
        <h1>User Management</h1>
      </div>

      <div className="settings-content">
        {error && <div className="error-banner">{error}</div>}
        {success && <div className="success-banner">{success}</div>}

        {/* Create User */}
        <div className="settings-card">
          <div className="card-header">
            <UserPlus size={24} />
            <h2>Create New User</h2>
          </div>

          {!showCreateForm ? (
            <button
              className="btn btn-primary"
              onClick={() => setShowCreateForm(true)}
            >
              <UserPlus size={18} />
              Create User
            </button>
          ) : (
            <form onSubmit={handleCreateUser} className="create-user-form">
              <div className="form-row">
                <div className="form-group">
                  <label>Email</label>
                  <input
                    type="email"
                    value={newUser.email}
                    onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                    required
                    placeholder="user@example.com"
                  />
                </div>

                <div className="form-group">
                  <label>Password</label>
                  <input
                    type="password"
                    value={newUser.password}
                    onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                    required
                    minLength={8}
                    placeholder="Min 8 characters"
                  />
                </div>

                <div className="form-group">
                  <label>Role</label>
                  <select
                    value={newUser.role}
                    onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
                  >
                    <option value="ANALYST">Analyst</option>
                    <option value="ADMIN">Admin</option>
                  </select>
                </div>
              </div>

              <div className="form-actions">
                <button type="submit" className="btn btn-primary">
                  Create User
                </button>
                <button
                  type="button"
                  className="btn"
                  onClick={() => setShowCreateForm(false)}
                  style={{ background: '#f1f5f9', color: '#475569' }}
                >
                  Cancel
                </button>
              </div>
            </form>
          )}
        </div>

        {/* Users List */}
        <div className="settings-card">
          <div className="card-header">
            <h2>All Users</h2>
            <span className="badge">{users.length} users</span>
          </div>

          <div className="users-list">
            {users.map((user) => (
              <div key={user.id} className="user-item">
                <div className="user-info">
                  <div className="user-header">
                    {user.role === 'ADMIN' ? <Shield size={20} /> : <User size={20} />}
                    <span className="user-email">{user.email}</span>
                    <span className={`badge ${user.role === 'ADMIN' ? 'badge-danger' : 'badge-success'}`}>
                      {user.role}
                    </span>
                    {user.mfa_enabled && (
                      <span className="badge" style={{ background: '#dbeafe', color: '#1e40af' }}>
                        2FA Enabled
                      </span>
                    )}
                    {!user.is_active && (
                      <span className="badge" style={{ background: '#f1f5f9', color: '#475569' }}>
                        Inactive
                      </span>
                    )}
                  </div>
                  <div className="user-meta">
                    <span>Created: {new Date(user.created_at).toLocaleDateString()}</span>
                    {user.last_login && (
                      <span>Last login: {new Date(user.last_login).toLocaleString()}</span>
                    )}
                  </div>
                </div>

                <div className="user-actions">
                  <select
                    value={user.role}
                    onChange={(e) => handleChangeRole(user.id, e.target.value)}
                    className="role-select"
                  >
                    <option value="ANALYST">Analyst</option>
                    <option value="ADMIN">Admin</option>
                  </select>

                  <button
                    className={`btn-small ${user.is_active ? 'btn-danger' : ''}`}
                    onClick={() => handleToggleActive(user.id, user.is_active)}
                  >
                    {user.is_active ? 'Deactivate' : 'Activate'}
                  </button>

                  <button
                    className="btn-small btn-danger"
                    title="Delete user"
                    onClick={() => handleDeleteUser(user.id, user.email)}
                    disabled={currentUser?.id === user.id}
                    aria-disabled={currentUser?.id === user.id}
                  >
                    <Trash size={14} />
                    <span style={{ marginLeft: 6 }}>Delete</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export default UsersPage;

