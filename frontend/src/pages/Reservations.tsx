import React, { useState, useEffect } from 'react';
import { reservationService, Reservation } from '../services/reservationService';
import { customerService, Customer } from '../services/customerService';
import { roomService, Room } from '../services/roomService';
import { useToast } from '../contexts/ToastContext';
import { useAuth } from '../contexts/AuthContext';

const Reservations: React.FC = () => {
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [rooms, setRooms] = useState<Room[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingReservation, setEditingReservation] = useState<Reservation | null>(null);
  const [filters, setFilters] = useState({
    status: '',
    customer: '',
    room: '',
  });
  const { addToast } = useToast();
  const { user } = useAuth();

  const [formData, setFormData] = useState({
    customer: '',
    room: 0,
    check_in_date: '',
    check_out_date: '',
    number_of_guests: 1,
    booking_status: 'pending' as 'pending' | 'confirmed' | 'cancelled' | 'completed',
  });

  useEffect(() => {
    fetchReservations();
    fetchCustomers();
    fetchRooms();
  }, []);

  const fetchReservations = async () => {
    try {
      setLoading(true);
      const data = await reservationService.getReservations();
      setReservations(data.results);
    } catch (error) {
      addToast('error', 'Failed to load reservations');
    } finally {
      setLoading(false);
    }
  };

  const fetchCustomers = async () => {
    try {
      const data = await customerService.getCustomers();
      setCustomers(data.results);
    } catch (error) {
      addToast('error', 'Failed to load customers');
    }
  };

  const fetchRooms = async () => {
    try {
      const data = await roomService.getRooms();
      setRooms(Array.isArray(data) ? data : data.results);
    } catch (error) {
      addToast('error', 'Failed to load rooms');
    }
  };

  const handleFilter = async () => {
    try {
      setLoading(true);
      const params: any = {};
      if (filters.status) params.booking_status = filters.status;
      if (filters.customer) params.customer = filters.customer;
      if (filters.room) params.room = filters.room;
      
      const data = await reservationService.getReservations(params);
      setReservations(data.results);
    } catch (error) {
      addToast('error', 'Failed to filter reservations');
    } finally {
      setLoading(false);
    }
  };

  const handleClearFilters = () => {
    setFilters({ status: '', customer: '', room: '' });
    fetchReservations();
  };

  const handleEdit = (reservation: Reservation) => {
    setEditingReservation(reservation);
    setFormData({
      customer: reservation.customer,
      room: reservation.room,
      check_in_date: reservation.check_in_date,
      check_out_date: reservation.check_out_date,
      number_of_guests: reservation.number_of_guests,
      booking_status: reservation.booking_status,
    });
    setShowModal(true);
  };

  const handleDelete = async (reservation_number: string) => {
    if (!confirm('Are you sure you want to delete this reservation?')) return;
    
    try {
      await reservationService.deleteReservation(reservation_number);
      addToast('success', 'Reservation deleted successfully');
      fetchReservations();
    } catch (error: any) {
      if (error.response?.status === 403) {
        addToast('error', 'Only admins can delete reservations');
      } else {
        addToast('error', 'Failed to delete reservation');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingReservation) {
        await reservationService.updateReservation(editingReservation.reservation_number, formData);
        addToast('success', 'Reservation updated successfully');
      } else {
        await reservationService.createReservation(formData);
        addToast('success', 'Reservation created successfully');
      }
      setShowModal(false);
      setEditingReservation(null);
      fetchReservations();
    } catch (error: any) {
      if (error.response?.status === 403) {
        addToast('error', 'Only admins can create or update reservations');
      } else {
        const errors = error.response?.data;
        if (typeof errors === 'object') {
          Object.entries(errors).forEach(([field, messages]) => {
            addToast('error', `${field}: ${Array.isArray(messages) ? messages.join(', ') : messages}`);
          });
        } else {
          addToast('error', 'Failed to save reservation');
        }
      }
    }
  };

  const getStatusBadge = (status: string) => {
    const colors = {
      pending: 'badge-warning',
      confirmed: 'badge-success',
      cancelled: 'badge-error',
      completed: 'badge-info',
    };
    return <span className={`badge ${colors[status as keyof typeof colors]}`}>{status}</span>;
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '400px' }}>
        <div className="spinner"></div>
      </div>
    );
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1 style={{ marginBottom: '0.5rem' }}>Reservations</h1>
          <p style={{ color: '#6B7280' }}>Manage hotel reservations</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>
          <span>➕</span> New Reservation
        </button>
      </div>

      {/* Filters */}
      <div className="card" style={{ marginBottom: '1.5rem' }}>
        <div className="card-body">
          <div className="grid grid-cols-4" style={{ gap: '1rem', alignItems: 'end' }}>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Status</label>
              <select
                className="form-select"
                value={filters.status}
                onChange={(e) => setFilters({ ...filters, status: e.target.value })}
              >
                <option value="">All Status</option>
                <option value="pending">Pending</option>
                <option value="confirmed">Confirmed</option>
                <option value="cancelled">Cancelled</option>
                <option value="completed">Completed</option>
              </select>
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Customer</label>
              <select
                className="form-select"
                value={filters.customer}
                onChange={(e) => setFilters({ ...filters, customer: e.target.value })}
              >
                <option value="">All Customers</option>
                {customers.map((customer) => (
                  <option key={customer.customer_id} value={customer.customer_id}>
                    {customer.full_name}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Room</label>
              <select
                className="form-select"
                value={filters.room}
                onChange={(e) => setFilters({ ...filters, room: e.target.value })}
              >
                <option value="">All Rooms</option>
                {rooms.map((room) => (
                  <option key={room.id} value={room.id}>
                    {room.room_number}
                  </option>
                ))}
              </select>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <button className="btn btn-primary" onClick={handleFilter}>
                🔍 Filter
              </button>
              <button className="btn btn-secondary" onClick={handleClearFilters}>
                Clear
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Reservations Table */}
      <div className="card">
        <div className="table-container">
          <table className="table">
            <thead>
              <tr>
                <th>Reservation #</th>
                <th>Customer</th>
                <th>Room</th>
                <th>Check-in</th>
                <th>Check-out</th>
                <th>Guests</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {reservations.length === 0 ? (
                <tr>
                  <td colSpan={8} style={{ textAlign: 'center', padding: '2rem' }}>
                    <div className="empty-state">
                      <div className="empty-state-icon">📅</div>
                      <div className="empty-state-text">No reservations found</div>
                      <div className="empty-state-subtext">Try adjusting your filters or create a new reservation</div>
                    </div>
                  </td>
                </tr>
              ) : (
                reservations.map((reservation) => (
                  <tr key={reservation.reservation_number}>
                    <td style={{ fontWeight: 600 }}>{reservation.reservation_number}</td>
                    <td>{reservation.customer_name}</td>
                    <td>{reservation.room_number}</td>
                    <td>{new Date(reservation.check_in_date).toLocaleDateString()}</td>
                    <td>{new Date(reservation.check_out_date).toLocaleDateString()}</td>
                    <td>{reservation.number_of_guests}</td>
                    <td>{getStatusBadge(reservation.booking_status)}</td>
                    <td>
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        <button
                          className="btn btn-sm btn-secondary"
                          onClick={() => handleEdit(reservation)}
                        >
                          Edit
                        </button>
                        <button
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDelete(reservation.reservation_number)}
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '600px' }}>
            <div className="modal-header">
              <h3>{editingReservation ? 'Edit Reservation' : 'New Reservation'}</h3>
              <button
                onClick={() => setShowModal(false)}
                style={{ background: 'none', border: 'none', fontSize: '1.5rem', cursor: 'pointer' }}
              >
                ×
              </button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Customer</label>
                  <select
                    className="form-select"
                    value={formData.customer}
                    onChange={(e) => setFormData({ ...formData, customer: e.target.value })}
                    required
                  >
                    <option value="">Select customer</option>
                    {customers.map((customer) => (
                      <option key={customer.customer_id} value={customer.customer_id}>
                        {customer.full_name} ({customer.customer_id})
                      </option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Room</label>
                  <select
                    className="form-select"
                    value={formData.room}
                    onChange={(e) => setFormData({ ...formData, room: parseInt(e.target.value) })}
                    required
                  >
                    <option value="">Select room</option>
                    {rooms.filter(r => r.status !== 'maintenance').map((room) => (
                      <option key={room.id} value={room.id}>
                        {room.room_number} - {room.room_type_name} (${room.price_per_night}/night, Capacity: {room.capacity})
                      </option>
                    ))}
                  </select>
                </div>
                <div className="grid grid-cols-2" style={{ gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label">Check-in Date</label>
                    <input
                      type="date"
                      className="form-input"
                      value={formData.check_in_date}
                      onChange={(e) => setFormData({ ...formData, check_in_date: e.target.value })}
                      required
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Check-out Date</label>
                    <input
                      type="date"
                      className="form-input"
                      value={formData.check_out_date}
                      onChange={(e) => setFormData({ ...formData, check_out_date: e.target.value })}
                      required
                    />
                  </div>
                </div>
                <div className="form-group">
                  <label className="form-label">Number of Guests</label>
                  <input
                    type="number"
                    className="form-input"
                    value={formData.number_of_guests}
                    onChange={(e) => setFormData({ ...formData, number_of_guests: parseInt(e.target.value) })}
                    required
                    min="1"
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Booking Status</label>
                  <select
                    className="form-select"
                    value={formData.booking_status}
                    onChange={(e) => setFormData({ ...formData, booking_status: e.target.value as any })}
                    required
                  >
                    <option value="pending">Pending</option>
                    <option value="confirmed">Confirmed</option>
                    <option value="cancelled">Cancelled</option>
                    <option value="completed">Completed</option>
                  </select>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  {editingReservation ? 'Update Reservation' : 'Create Reservation'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Reservations;
