import React, { useState, useEffect } from 'react';
import { roomService, Room, RoomType } from '../services/roomService';
import { useToast } from '../contexts/ToastContext';
import { useAuth } from '../contexts/AuthContext';

const Rooms: React.FC = () => {
  const [rooms, setRooms] = useState<Room[]>([]);
  const [roomTypes, setRoomTypes] = useState<RoomType[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingRoom, setEditingRoom] = useState<Room | null>(null);
  const [filters, setFilters] = useState({
    room_type: '',
    status: '',
    search: '',
  });
  const { addToast } = useToast();
  const { user } = useAuth();
  const isAdmin = user?.role === 'admin';

  const [formData, setFormData] = useState({
    room_number: '',
    room_type: '',
    floor: 1,
    capacity: 2,
    price_per_night: 100,
    status: 'available' as 'available' | 'occupied' | 'maintenance',
    description: '',
  });

  useEffect(() => {
    fetchRooms();
    fetchRoomTypes();
  }, []);

  const fetchRooms = async () => {
    try {
      setLoading(true);
      const data = await roomService.getRooms();
      setRooms(data.results);
    } catch (error) {
      addToast('error', 'Failed to load rooms');
    } finally {
      setLoading(false);
    }
  };

  const fetchRoomTypes = async () => {
    try {
      const data = await roomService.getRoomTypes();
      setRoomTypes(data);
    } catch (error) {
      addToast('error', 'Failed to load room types');
    }
  };

  const handleFilter = async () => {
    try {
      setLoading(true);
      const params: any = {};
      if (filters.room_type) params.room_type = filters.room_type;
      if (filters.status) params.status = filters.status;
      if (filters.search) params.search = filters.search;
      
      const data = await roomService.getRooms(params);
      setRooms(data.results);
    } catch (error) {
      addToast('error', 'Failed to filter rooms');
    } finally {
      setLoading(false);
    }
  };

  const handleClearFilters = () => {
    setFilters({ room_type: '', status: '', search: '' });
    fetchRooms();
  };

  const handleEdit = (room: Room) => {
    setEditingRoom(room);
    setFormData({
      room_number: room.room_number,
      room_type: room.room_type.toString(),
      floor: room.floor,
      capacity: room.capacity,
      price_per_night: room.price_per_night,
      status: room.status,
      description: room.description,
    });
    setShowModal(true);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this room?')) return;
    
    try {
      await roomService.deleteRoom(id);
      addToast('success', 'Room deleted successfully');
      fetchRooms();
    } catch (error) {
      addToast('error', 'Failed to delete room');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingRoom) {
        await roomService.updateRoom(editingRoom.id, formData);
        addToast('success', 'Room updated successfully');
      } else {
        await roomService.createRoom(formData);
        addToast('success', 'Room created successfully');
      }
      setShowModal(false);
      setEditingRoom(null);
      fetchRooms();
    } catch (error: any) {
      const errors = error.response?.data;
      if (typeof errors === 'object') {
        Object.entries(errors).forEach(([field, messages]) => {
          addToast('error', `${field}: ${Array.isArray(messages) ? messages.join(', ') : messages}`);
        });
      } else {
        addToast('error', 'Failed to save room');
      }
    }
  };

  const getStatusBadge = (status: string) => {
    const colors = {
      available: 'badge-success',
      occupied: 'badge-warning',
      maintenance: 'badge-error',
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
          <h1 style={{ marginBottom: '0.5rem' }}>Rooms</h1>
          <p style={{ color: '#6B7280' }}>Manage your hotel rooms</p>
        </div>
        {isAdmin && (
          <button className="btn btn-primary" onClick={() => setShowModal(true)}>
            <span>➕</span> Add Room
          </button>
        )}
      </div>

      {/* Filters */}
      <div className="card" style={{ marginBottom: '1.5rem' }}>
        <div className="card-body">
          <div className="grid grid-cols-4" style={{ gap: '1rem', alignItems: 'end' }}>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Room Type</label>
              <select
                className="form-select"
                value={filters.room_type}
                onChange={(e) => setFilters({ ...filters, room_type: e.target.value })}
              >
                <option value="">All Types</option>
                {roomTypes.map((type) => (
                  <option key={type.id} value={type.id}>
                    {type.name}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Status</label>
              <select
                className="form-select"
                value={filters.status}
                onChange={(e) => setFilters({ ...filters, status: e.target.value })}
              >
                <option value="">All Status</option>
                <option value="available">Available</option>
                <option value="occupied">Occupied</option>
                <option value="maintenance">Maintenance</option>
              </select>
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Search</label>
              <input
                type="text"
                className="form-input"
                placeholder="Room number..."
                value={filters.search}
                onChange={(e) => setFilters({ ...filters, search: e.target.value })}
              />
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

      {/* Rooms Table */}
      <div className="card">
        <div className="table-container">
          <table className="table">
            <thead>
              <tr>
                <th>Room Number</th>
                <th>Type</th>
                <th>Floor</th>
                <th>Capacity</th>
                <th>Price/Night</th>
                <th>Status</th>
                {isAdmin && <th>Actions</th>}
              </tr>
            </thead>
            <tbody>
              {rooms.length === 0 ? (
                <tr>
                  <td colSpan={isAdmin ? 7 : 6} style={{ textAlign: 'center', padding: '2rem' }}>
                    <div className="empty-state">
                      <div className="empty-state-icon">🏠</div>
                      <div className="empty-state-text">No rooms found</div>
                      <div className="empty-state-subtext">Try adjusting your filters or add a new room</div>
                    </div>
                  </td>
                </tr>
              ) : (
                rooms.map((room) => (
                  <tr key={room.id}>
                    <td style={{ fontWeight: 600 }}>{room.room_number}</td>
                    <td>{room.room_type_name}</td>
                    <td>{room.floor}</td>
                    <td>{room.capacity} guests</td>
                    <td>${room.price_per_night.toFixed(2)}</td>
                    <td>{getStatusBadge(room.status)}</td>
                    {isAdmin && (
                      <td>
                        <div style={{ display: 'flex', gap: '0.5rem' }}>
                          <button
                            className="btn btn-sm btn-secondary"
                            onClick={() => handleEdit(room)}
                          >
                            Edit
                          </button>
                          <button
                            className="btn btn-sm btn-danger"
                            onClick={() => handleDelete(room.id)}
                          >
                            Delete
                          </button>
                        </div>
                      </td>
                    )}
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
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{editingRoom ? 'Edit Room' : 'Add New Room'}</h3>
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
                  <label className="form-label">Room Number</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.room_number}
                    onChange={(e) => setFormData({ ...formData, room_number: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Room Type</label>
                  <select
                    className="form-select"
                    value={formData.room_type}
                    onChange={(e) => setFormData({ ...formData, room_type: e.target.value })}
                    required
                  >
                    <option value="">Select type</option>
                    {roomTypes.map((type) => (
                      <option key={type.id} value={type.id}>
                        {type.name} (${type.base_price}/night)
                      </option>
                    ))}
                  </select>
                </div>
                <div className="grid grid-cols-2" style={{ gap: '1rem' }}>
                  <div className="form-group">
                    <label className="form-label">Floor</label>
                    <input
                      type="number"
                      className="form-input"
                      value={formData.floor}
                      onChange={(e) => setFormData({ ...formData, floor: parseInt(e.target.value) })}
                      required
                      min="1"
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Capacity</label>
                    <input
                      type="number"
                      className="form-input"
                      value={formData.capacity}
                      onChange={(e) => setFormData({ ...formData, capacity: parseInt(e.target.value) })}
                      required
                      min="1"
                    />
                  </div>
                </div>
                <div className="form-group">
                  <label className="form-label">Price Per Night ($)</label>
                  <input
                    type="number"
                    className="form-input"
                    value={formData.price_per_night}
                    onChange={(e) => setFormData({ ...formData, price_per_night: parseFloat(e.target.value) })}
                    required
                    min="0"
                    step="0.01"
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Status</label>
                  <select
                    className="form-select"
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value as any })}
                    required
                  >
                    <option value="available">Available</option>
                    <option value="occupied">Occupied</option>
                    <option value="maintenance">Maintenance</option>
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Description</label>
                  <textarea
                    className="form-textarea"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    rows={3}
                  />
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  {editingRoom ? 'Update Room' : 'Create Room'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Rooms;
