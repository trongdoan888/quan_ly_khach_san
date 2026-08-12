import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useToast } from '../contexts/ToastContext';

const Login: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const { addToast } = useToast();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      await login({ username, password });
      addToast('success', 'Login successful!');
      navigate('/dashboard');
    } catch (error: any) {
      addToast('error', error.response?.data?.detail || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#F8F7F3',
        padding: '1rem',
      }}
    >
      <div
        className="card"
        style={{
          maxWidth: '400px',
          width: '100%',
          boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
        }}
      >
        <div className="card-header" style={{ textAlign: 'center', borderBottom: 'none' }}>
          <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>🏨</div>
          <h1 style={{ marginBottom: '0.5rem', color: '#0F172A' }}>Hotel Manager</h1>
          <p style={{ color: '#6B7280', marginBottom: '1.5rem' }}>Sign in to your account</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Username</label>
            <input
              type="text"
              className="form-input"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              placeholder="Enter your username"
            />
          </div>

          <div className="form-group">
            <label className="form-label">Password</label>
            <input
              type="password"
              className="form-input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              placeholder="Enter your password"
            />
          </div>

          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: '100%' }}
            disabled={loading}
          >
            {loading ? <div className="spinner" style={{ width: '16px', height: '16px' }}></div> : 'Sign In'}
          </button>
        </form>

        <div style={{ textAlign: 'center', marginTop: '1.5rem', color: '#6B7280' }}>
          Don't have an account?{' '}
          <Link to="/register" style={{ color: '#C9A227', textDecoration: 'none', fontWeight: 500 }}>
            Register
          </Link>
        </div>

        <div style={{ marginTop: '2rem', padding: '1rem', backgroundColor: '#F8F7F3', borderRadius: '8px' }}>
          <p style={{ fontSize: '0.75rem', color: '#6B7280', marginBottom: '0.5rem' }}>Demo Credentials:</p>
          <p style={{ fontSize: '0.75rem', color: '#6B7280' }}>
            <strong>Admin:</strong> admin / admin123
          </p>
          <p style={{ fontSize: '0.75rem', color: '#6B7280' }}>
            <strong>Staff:</strong> staff / staff123
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
