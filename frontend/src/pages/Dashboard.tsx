import React, { useState, useEffect } from 'react';
import { reservationService, DashboardStats } from '../services/reservationService';
import { useToast } from '../contexts/ToastContext';
import { useNavigate } from 'react-router-dom';

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const { addToast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      const data = await reservationService.getStatistics();
      setStats(data);
    } catch (error) {
      addToast('error', 'Failed to load dashboard statistics');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '400px' }}>
        <div className="spinner"></div>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Rooms',
      value: stats?.total_rooms || 0,
      icon: '🏠',
      color: '#0F172A',
      trend: '+2 from last month',
    },
    {
      title: 'Available Rooms',
      value: stats?.available_rooms || 0,
      icon: '✅',
      color: '#10B981',
      trend: 'Ready for booking',
    },
    {
      title: 'Occupied Rooms',
      value: stats?.occupied_rooms || 0,
      icon: '🔑',
      color: '#F59E0B',
      trend: 'Currently in use',
    },
    {
      title: 'Active Reservations',
      value: stats?.active_reservations || 0,
      icon: '📅',
      color: '#3B82F6',
      trend: 'Pending & Confirmed',
    },
    {
      title: 'Total Customers',
      value: stats?.total_customers || 0,
      icon: '👥',
      color: '#8B5CF6',
      trend: 'Registered guests',
    },
    {
      title: 'Occupancy Rate',
      value: `${stats?.occupancy_rate || 0}%`,
      icon: '📊',
      color: '#C9A227',
      trend: 'Current utilization',
    },
  ];

  const activityItems = [
    { type: 'check-in', text: 'Guest checked in to Room 101', time: '2 hours ago', icon: '📥' },
    { type: 'check-out', text: 'Guest checked out from Room 205', time: '3 hours ago', icon: '📤' },
    { type: 'booking', text: 'New reservation for Room 401', time: '5 hours ago', icon: '📝' },
    { type: 'cancellation', text: 'Reservation cancelled for Room 302', time: '6 hours ago', icon: '❌' },
  ];

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <h1 style={{ marginBottom: '0.5rem' }}>Dashboard</h1>
        <p style={{ color: '#6B7280' }}>Welcome to your hotel management dashboard</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-3" style={{ gap: '1.5rem', marginBottom: '2rem' }}>
        {statCards.map((stat, index) => (
          <div
            key={index}
            className="card"
            style={{
              padding: '1.5rem',
              borderLeft: `4px solid ${stat.color}`,
              transition: 'transform 0.2s ease, box-shadow 0.2s ease',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-4px)';
              e.currentTarget.style.boxShadow = '0 20px 25px -5px rgba(0, 0, 0, 0.1)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
              <div style={{ fontSize: '2rem' }}>{stat.icon}</div>
              <span className="badge badge-info" style={{ fontSize: '0.625rem' }}>
                Live
              </span>
            </div>
            <div style={{ fontSize: '2rem', fontWeight: 600, color: '#0F172A', marginBottom: '0.5rem' }}>
              {stat.value}
            </div>
            <div style={{ fontSize: '0.875rem', color: '#6B7280', marginBottom: '0.25rem' }}>
              {stat.title}
            </div>
            <div style={{ fontSize: '0.75rem', color: '#10B981' }}>
              {stat.trend}
            </div>
          </div>
        ))}
      </div>

      {/* Today's Activity */}
      <div className="grid grid-cols-2" style={{ gap: '1.5rem' }}>
        <div className="card">
          <div className="card-header">
            <h3 style={{ fontSize: '1.25rem', marginBottom: '0.5rem' }}>Today's Activity</h3>
            <p style={{ color: '#6B7280', fontSize: '0.875rem' }}>Recent hotel activities</p>
          </div>
          <div className="card-body">
            {activityItems.map((item, index) => (
              <div
                key={index}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '1rem',
                  padding: '1rem 0',
                  borderBottom: index < activityItems.length - 1 ? '1px solid #E5E7EB' : 'none',
                }}
              >
                <div
                  style={{
                    width: '40px',
                    height: '40px',
                    borderRadius: '50%',
                    backgroundColor: '#F8F7F3',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1.25rem',
                  }}
                >
                  {item.icon}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.875rem', fontWeight: 500, color: '#0F172A' }}>
                    {item.text}
                  </div>
                  <div style={{ fontSize: '0.75rem', color: '#6B7280' }}>{item.time}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <h3 style={{ fontSize: '1.25rem', marginBottom: '0.5rem' }}>Quick Actions</h3>
            <p style={{ color: '#6B7280', fontSize: '0.875rem' }}>Common tasks</p>
          </div>
          <div className="card-body">
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              <button 
                className="btn btn-secondary" 
                style={{ justifyContent: 'flex-start' }}
                onClick={() => {
                  addToast('info', 'Navigating to Reservations page');
                  navigate('/reservations');
                }}
              >
                <span>➕</span> New Reservation
              </button>
              <button 
                className="btn btn-secondary" 
                style={{ justifyContent: 'flex-start' }}
                onClick={() => {
                  addToast('info', 'Navigating to Customers page');
                  navigate('/customers');
                }}
              >
                <span>👤</span> Add Customer
              </button>
              <button 
                className="btn btn-secondary" 
                style={{ justifyContent: 'flex-start' }}
                onClick={() => {
                  addToast('info', 'Navigating to Rooms page');
                  navigate('/rooms');
                }}
              >
                <span>🏠</span> Add Room
              </button>
              <button 
                className="btn btn-secondary" 
                style={{ justifyContent: 'flex-start' }}
                onClick={() => {
                  addToast('info', 'Navigating to Availability page');
                  navigate('/availability');
                }}
              >
                <span>🔍</span> Check Availability
              </button>
              <button 
                className="btn btn-secondary" 
                style={{ justifyContent: 'flex-start' }}
                onClick={() => addToast('info', 'Reports feature coming soon!')}
              >
                <span>📊</span> View Reports
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Additional Stats */}
      <div className="card" style={{ marginTop: '1.5rem' }}>
        <div className="card-header">
          <h3 style={{ fontSize: '1.25rem', marginBottom: '0.5rem' }}>Today's Overview</h3>
          <p style={{ color: '#6B7280', fontSize: '0.875rem' }}>Check-ins and check-outs for today</p>
        </div>
        <div className="card-body">
          <div className="grid grid-cols-2" style={{ gap: '2rem' }}>
            <div style={{ textAlign: 'center', padding: '2rem', backgroundColor: '#F8F7F3', borderRadius: '12px' }}>
              <div style={{ fontSize: '3rem', marginBottom: '0.5rem' }}>📥</div>
              <div style={{ fontSize: '2rem', fontWeight: 600, color: '#0F172A', marginBottom: '0.5rem' }}>
                {stats?.today_checkins || 0}
              </div>
              <div style={{ fontSize: '0.875rem', color: '#6B7280' }}>Today's Check-ins</div>
            </div>
            <div style={{ textAlign: 'center', padding: '2rem', backgroundColor: '#F8F7F3', borderRadius: '12px' }}>
              <div style={{ fontSize: '3rem', marginBottom: '0.5rem' }}>📤</div>
              <div style={{ fontSize: '2rem', fontWeight: 600, color: '#0F172A', marginBottom: '0.5rem' }}>
                {stats?.today_checkouts || 0}
              </div>
              <div style={{ fontSize: '0.875rem', color: '#6B7280' }}>Today's Check-outs</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
