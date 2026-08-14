import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useToast } from '../contexts/ToastContext';

const Register: React.FC = () => {
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    first_name: '',
    last_name: '',
    password: '',
    password2: '',
    role: 'staff',
  });
  const [loading, setLoading] = useState(false);
  const { register } = useAuth();
  const { addToast } = useToast();
  const navigate = useNavigate();

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      await register(formData);
      addToast('success', 'Registration successful! Please login.');
      navigate('/login');
    } catch (error: any) {
      const errors = error.response?.data;
      if (typeof errors === 'object') {
        Object.entries(errors).forEach(([field, messages]) => {
          addToast('error', `${field}: ${Array.isArray(messages) ? messages.join(', ') : messages}`);
        });
      } else {
        addToast('error', 'Registration failed. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        backgroundColor: '#F8F7F3',
      }}
    >
      {/* Left Side - Hotel Content */}
      <div
        style={{
          flex: '1',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          padding: '3rem',
          background: 'linear-gradient(135deg, #0F172A 0%, #1E293B 100%)',
          color: 'white',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Background Pattern */}
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundImage: 'radial-gradient(circle at 20% 50%, rgba(201, 162, 39, 0.1) 0%, transparent 50%)',
            pointerEvents: 'none',
          }}
        />

        <div style={{ position: 'relative', zIndex: 1, maxWidth: '500px', textAlign: 'center' }}>
          {/* Professional Hotel Icon */}
          <div
            style={{
              width: '120px',
              height: '120px',
              margin: '0 auto 2rem',
              background: 'rgba(201, 162, 39, 0.1)',
              borderRadius: '20px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              border: '2px solid rgba(201, 162, 39, 0.3)',
            }}
          >
            <svg
              width="60"
              height="60"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#C9A227"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
              <circle cx="8.5" cy="7" r="4" />
              <line x1="20" y1="8" x2="20" y2="14" />
              <line x1="23" y1="11" x2="17" y2="11" />
            </svg>
          </div>

          <h1
            style={{
              fontSize: '2.5rem',
              fontWeight: 700,
              marginBottom: '1rem',
              color: '#C9A227',
            }}
          >
            Join Our Team
          </h1>
          <p
            style={{
              fontSize: '1.125rem',
              color: '#94A3B8',
              marginBottom: '2rem',
              lineHeight: '1.6',
            }}
          >
            Create your account to access our hotel management system. 
            Start managing reservations, guests, and operations efficiently.
          </p>

          {/* Features */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', textAlign: 'left' }}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '1rem',
                padding: '1rem',
                background: 'rgba(255, 255, 255, 0.05)',
                borderRadius: '12px',
                transition: 'all 0.3s ease',
                cursor: 'default',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = 'rgba(255, 255, 255, 0.1)';
                e.currentTarget.style.transform = 'translateX(8px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = 'rgba(255, 255, 255, 0.05)';
                e.currentTarget.style.transform = 'translateX(0)';
              }}
            >
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#C9A227"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
              </svg>
              <span style={{ color: '#E2E8F0' }}>Secure & Reliable Platform</span>
            </div>

            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '1rem',
                padding: '1rem',
                background: 'rgba(255, 255, 255, 0.05)',
                borderRadius: '12px',
                transition: 'all 0.3s ease',
                cursor: 'default',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = 'rgba(255, 255, 255, 0.1)';
                e.currentTarget.style.transform = 'translateX(8px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = 'rgba(255, 255, 255, 0.05)';
                e.currentTarget.style.transform = 'translateX(0)';
              }}
            >
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#C9A227"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="12" cy="12" r="10" />
                <polyline points="12 6 12 12 16 14" />
              </svg>
              <span style={{ color: '#E2E8F0' }}>24/7 System Access</span>
            </div>

            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '1rem',
                padding: '1rem',
                background: 'rgba(255, 255, 255, 0.05)',
                borderRadius: '12px',
                transition: 'all 0.3s ease',
                cursor: 'default',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.background = 'rgba(255, 255, 255, 0.1)';
                e.currentTarget.style.transform = 'translateX(8px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.background = 'rgba(255, 255, 255, 0.05)';
                e.currentTarget.style.transform = 'translateX(0)';
              }}
            >
              <svg
                width="24"
                height="24"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#C9A227"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
              </svg>
              <span style={{ color: '#E2E8F0' }}>Premium Support</span>
            </div>
          </div>
        </div>
      </div>

      {/* Right Side - Registration Form */}
      <div
        style={{
          flex: '1',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '3rem',
          backgroundColor: '#F8F7F3',
        }}
      >
        <div
          style={{
            maxWidth: '500px',
            width: '100%',
          }}
        >
          <div style={{ marginBottom: '2rem' }}>
            <h2
              style={{
                fontSize: '2rem',
                fontWeight: 700,
                marginBottom: '0.5rem',
                color: '#0F172A',
              }}
            >
              Create Account
            </h2>
            <p style={{ color: '#6B7280', fontSize: '1rem' }}>
              Fill in your details to get started
            </p>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="form-group" style={{ marginBottom: '1.5rem' }}>
              <label
                className="form-label"
                style={{
                  display: 'block',
                  marginBottom: '0.5rem',
                  color: '#374151',
                  fontWeight: 500,
                  fontSize: '0.875rem',
                }}
              >
                Username
              </label>
              <input
                type="text"
                name="username"
                className="form-input"
                value={formData.username}
                onChange={handleChange}
                required
                placeholder="Choose a username"
                style={{
                  width: '100%',
                  padding: '0.75rem 1rem',
                  border: '1px solid #E5E7EB',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  transition: 'all 0.2s ease',
                  outline: 'none',
                }}
                onFocus={(e) => {
                  e.currentTarget.style.borderColor = '#C9A227';
                  e.currentTarget.style.boxShadow = '0 0 0 3px rgba(201, 162, 39, 0.1)';
                }}
                onBlur={(e) => {
                  e.currentTarget.style.borderColor = '#E5E7EB';
                  e.currentTarget.style.boxShadow = 'none';
                }}
              />
            </div>

            <div className="form-group" style={{ marginBottom: '1.5rem' }}>
              <label
                className="form-label"
                style={{
                  display: 'block',
                  marginBottom: '0.5rem',
                  color: '#374151',
                  fontWeight: 500,
                  fontSize: '0.875rem',
                }}
              >
                Email
              </label>
              <input
                type="email"
                name="email"
                className="form-input"
                value={formData.email}
                onChange={handleChange}
                required
                placeholder="your@email.com"
                style={{
                  width: '100%',
                  padding: '0.75rem 1rem',
                  border: '1px solid #E5E7EB',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  transition: 'all 0.2s ease',
                  outline: 'none',
                }}
                onFocus={(e) => {
                  e.currentTarget.style.borderColor = '#C9A227';
                  e.currentTarget.style.boxShadow = '0 0 0 3px rgba(201, 162, 39, 0.1)';
                }}
                onBlur={(e) => {
                  e.currentTarget.style.borderColor = '#E5E7EB';
                  e.currentTarget.style.boxShadow = 'none';
                }}
              />
            </div>

            <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem' }}>
              <div className="form-group" style={{ flex: 1 }}>
                <label
                  className="form-label"
                  style={{
                    display: 'block',
                    marginBottom: '0.5rem',
                    color: '#374151',
                    fontWeight: 500,
                    fontSize: '0.875rem',
                  }}
                >
                  First Name
                </label>
                <input
                  type="text"
                  name="first_name"
                  className="form-input"
                  value={formData.first_name}
                  onChange={handleChange}
                  required
                  placeholder="John"
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: '1px solid #E5E7EB',
                    borderRadius: '8px',
                    fontSize: '1rem',
                    transition: 'all 0.2s ease',
                    outline: 'none',
                  }}
                  onFocus={(e) => {
                    e.currentTarget.style.borderColor = '#C9A227';
                    e.currentTarget.style.boxShadow = '0 0 0 3px rgba(201, 162, 39, 0.1)';
                  }}
                  onBlur={(e) => {
                    e.currentTarget.style.borderColor = '#E5E7EB';
                    e.currentTarget.style.boxShadow = 'none';
                  }}
                />
              </div>
              <div className="form-group" style={{ flex: 1 }}>
                <label
                  className="form-label"
                  style={{
                    display: 'block',
                    marginBottom: '0.5rem',
                    color: '#374151',
                    fontWeight: 500,
                    fontSize: '0.875rem',
                  }}
                >
                  Last Name
                </label>
                <input
                  type="text"
                  name="last_name"
                  className="form-input"
                  value={formData.last_name}
                  onChange={handleChange}
                  required
                  placeholder="Doe"
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: '1px solid #E5E7EB',
                    borderRadius: '8px',
                    fontSize: '1rem',
                    transition: 'all 0.2s ease',
                    outline: 'none',
                  }}
                  onFocus={(e) => {
                    e.currentTarget.style.borderColor = '#C9A227';
                    e.currentTarget.style.boxShadow = '0 0 0 3px rgba(201, 162, 39, 0.1)';
                  }}
                  onBlur={(e) => {
                    e.currentTarget.style.borderColor = '#E5E7EB';
                    e.currentTarget.style.boxShadow = 'none';
                  }}
                />
              </div>
            </div>

            <div className="form-group" style={{ marginBottom: '1.5rem' }}>
              <label
                className="form-label"
                style={{
                  display: 'block',
                  marginBottom: '0.5rem',
                  color: '#374151',
                  fontWeight: 500,
                  fontSize: '0.875rem',
                }}
              >
                Role
              </label>
              <select
                name="role"
                className="form-select"
                value={formData.role}
                onChange={handleChange}
                style={{
                  width: '100%',
                  padding: '0.75rem 1rem',
                  border: '1px solid #E5E7EB',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  transition: 'all 0.2s ease',
                  outline: 'none',
                  backgroundColor: 'white',
                }}
                onFocus={(e) => {
                  e.currentTarget.style.borderColor = '#C9A227';
                  e.currentTarget.style.boxShadow = '0 0 0 3px rgba(201, 162, 39, 0.1)';
                }}
                onBlur={(e) => {
                  e.currentTarget.style.borderColor = '#E5E7EB';
                  e.currentTarget.style.boxShadow = 'none';
                }}
              >
                <option value="staff">Staff</option>
                <option value="admin">Admin</option>
              </select>
            </div>

            <div className="form-group" style={{ marginBottom: '1.5rem' }}>
              <label
                className="form-label"
                style={{
                  display: 'block',
                  marginBottom: '0.5rem',
                  color: '#374151',
                  fontWeight: 500,
                  fontSize: '0.875rem',
                }}
              >
                Password
              </label>
              <input
                type="password"
                name="password"
                className="form-input"
                value={formData.password}
                onChange={handleChange}
                required
                placeholder="Min. 8 characters"
                style={{
                  width: '100%',
                  padding: '0.75rem 1rem',
                  border: '1px solid #E5E7EB',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  transition: 'all 0.2s ease',
                  outline: 'none',
                }}
                onFocus={(e) => {
                  e.currentTarget.style.borderColor = '#C9A227';
                  e.currentTarget.style.boxShadow = '0 0 0 3px rgba(201, 162, 39, 0.1)';
                }}
                onBlur={(e) => {
                  e.currentTarget.style.borderColor = '#E5E7EB';
                  e.currentTarget.style.boxShadow = 'none';
                }}
              />
            </div>

            <div className="form-group" style={{ marginBottom: '2rem' }}>
              <label
                className="form-label"
                style={{
                  display: 'block',
                  marginBottom: '0.5rem',
                  color: '#374151',
                  fontWeight: 500,
                  fontSize: '0.875rem',
                }}
              >
                Confirm Password
              </label>
              <input
                type="password"
                name="password2"
                className="form-input"
                value={formData.password2}
                onChange={handleChange}
                required
                placeholder="Re-enter password"
                style={{
                  width: '100%',
                  padding: '0.75rem 1rem',
                  border: '1px solid #E5E7EB',
                  borderRadius: '8px',
                  fontSize: '1rem',
                  transition: 'all 0.2s ease',
                  outline: 'none',
                }}
                onFocus={(e) => {
                  e.currentTarget.style.borderColor = '#C9A227';
                  e.currentTarget.style.boxShadow = '0 0 0 3px rgba(201, 162, 39, 0.1)';
                }}
                onBlur={(e) => {
                  e.currentTarget.style.borderColor = '#E5E7EB';
                  e.currentTarget.style.boxShadow = 'none';
                }}
              />
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              style={{
                width: '100%',
                padding: '0.875rem',
                backgroundColor: '#C9A227',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                fontSize: '1rem',
                fontWeight: 600,
                cursor: loading ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s ease',
                opacity: loading ? 0.6 : 1,
              }}
              disabled={loading}
              onMouseEnter={(e) => {
                if (!loading) {
                  e.currentTarget.style.backgroundColor = '#B8921F';
                  e.currentTarget.style.transform = 'translateY(-2px)';
                  e.currentTarget.style.boxShadow = '0 4px 12px rgba(201, 162, 39, 0.3)';
                }
              }}
              onMouseLeave={(e) => {
                if (!loading) {
                  e.currentTarget.style.backgroundColor = '#C9A227';
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = 'none';
                }
              }}
            >
              {loading ? (
                <div className="spinner" style={{ width: '16px', height: '16px' }}></div>
              ) : (
                'Create Account'
              )}
            </button>
          </form>

          <div style={{ textAlign: 'center', marginTop: '1.5rem', color: '#6B7280' }}>
            Already have an account?{' '}
            <Link
              to="/login"
              style={{
                color: '#C9A227',
                textDecoration: 'none',
                fontWeight: 600,
                transition: 'color 0.2s ease',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.color = '#B8921F';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.color = '#C9A227';
              }}
            >
              Sign In
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Register;