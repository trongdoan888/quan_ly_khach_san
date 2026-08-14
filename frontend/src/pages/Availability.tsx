import React, { useState } from 'react';
import { reservationService } from '../services/reservationService';
import { roomService, Room } from '../services/roomService';
import { useToast } from '../contexts/ToastContext';

const Availability: React.FC = () => {
  const [checkInDate, setCheckInDate] = useState('');
  const [checkOutDate, setCheckOutDate] = useState('');
  const [numberOfGuests, setNumberOfGuests] = useState(1);
  const [availableRooms, setAvailableRooms] = useState<Room[]>([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const { addToast } = useToast();

  const handleCheckAvailability = async () => {
    if (!checkInDate || !checkOutDate) {
      addToast('error', 'Please select check-in and check-out dates');
      return;
    }

    if (new Date(checkOutDate) <= new Date(checkInDate)) {
      addToast('error', 'Check-out date must be after check-in date');
      return;
    }

    try {
      setLoading(true);
      setSearched(false);
      
      // First, get all available rooms for the dates
      const response = await reservationService.checkAvailability({
        check_in_date: checkInDate,
        check_out_date: checkOutDate,
        number_of_guests: numberOfGuests,
      });
      
      console.log('Availability response:', response);
      console.log('Available rooms:', response.available_rooms);
      
      setAvailableRooms(response.available_rooms);
      setSearched(true);
      
      if (response.available_rooms.length === 0) {
        addToast('warning', 'No rooms available for the selected dates');
      } else {
        addToast('success', `Found ${response.available_rooms.length} available room(s)`);
      }
    } catch (error: any) {
      console.error('Availability check error:', error);
      addToast('error', error.response?.data?.error || 'Failed to check availability');
    } finally {
      setLoading(false);
    }
  };

  const handleBookRoom = (room: Room) => {
    // Redirect to reservations page with pre-filled data
    // In a real app, you might want to pass this via state or URL params
    addToast('info', `Room ${room.room_number} selected. Please create a reservation.`);
    // You could implement navigation to the reservations page with pre-filled data
  };

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <h1 style={{ marginBottom: '0.5rem' }}>Room Availability</h1>
        <p style={{ color: '#6B7280' }}>Check room availability for your desired dates</p>
      </div>

      {/* Search Form */}
      <div className="card" style={{ marginBottom: '2rem' }}>
        <div className="card-header">
          <h3 style={{ fontSize: '1.25rem', marginBottom: '0.5rem' }}>Search Available Rooms</h3>
          <p style={{ color: '#6B7280', fontSize: '0.875rem' }}>Enter your stay details to find available rooms</p>
        </div>
        <div className="card-body">
          <div className="grid grid-cols-4" style={{ gap: '1rem', alignItems: 'end' }}>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Check-in Date</label>
              <input
                type="date"
                className="form-input"
                value={checkInDate}
                onChange={(e) => setCheckInDate(e.target.value)}
                min={new Date().toISOString().split('T')[0]}
              />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Check-out Date</label>
              <input
                type="date"
                className="form-input"
                value={checkOutDate}
                onChange={(e) => setCheckOutDate(e.target.value)}
                min={checkInDate || new Date().toISOString().split('T')[0]}
              />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Number of Guests</label>
              <input
                type="number"
                className="form-input"
                value={numberOfGuests}
                onChange={(e) => setNumberOfGuests(parseInt(e.target.value))}
                min="1"
                max="20"
              />
            </div>
            <button
              className="btn btn-primary"
              onClick={handleCheckAvailability}
              disabled={loading}
              style={{ height: '42px' }}
            >
              {loading ? <div className="spinner" style={{ width: '16px', height: '16px' }}></div> : '🔍 Check Availability'}
            </button>
          </div>
        </div>
      </div>

      {/* Results */}
      {searched && (
        <div>
          <div style={{ marginBottom: '1rem' }}>
            <h2 style={{ fontSize: '1.5rem', marginBottom: '0.5rem' }}>
              Available Rooms
              <span className="badge badge-success" style={{ marginLeft: '0.75rem' }}>
                {availableRooms.length} found
              </span>
            </h2>
            <p style={{ color: '#6B7280' }}>
              {checkInDate && checkOutDate && (
                <>
                  {new Date(checkInDate).toLocaleDateString()} - {new Date(checkOutDate).toLocaleDateString()} 
                  ({numberOfGuests} guest{numberOfGuests > 1 ? 's' : ''})
                </>
              )}
            </p>
          </div>

          {!availableRooms || availableRooms.length === 0 ? (
            <div className="card">
              <div className="empty-state">
                <div className="empty-state-icon">🔍</div>
                <div className="empty-state-text">No rooms available</div>
                <div className="empty-state-subtext">
                  Try adjusting your dates or number of guests
                </div>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-3" style={{ gap: '1.5rem' }}>
              {availableRooms.map((room) => (
                <div
                  key={room.id}
                  className="card"
                  style={{
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
                  <div
                    style={{
                      height: '150px',
                      backgroundColor: '#F8F7F3',
                      borderRadius: '8px',
                      marginBottom: '1rem',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '4rem',
                    }}
                  >
                    🏠
                  </div>
                  <div style={{ marginBottom: '1rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                      <h3 style={{ fontSize: '1.25rem', marginBottom: 0 }}>{room.room_number}</h3>
                      <span className="badge badge-success">{room.status}</span>
                    </div>
                    <p style={{ color: '#6B7280', fontSize: '0.875rem', marginBottom: '0.5rem' }}>
                      {room.room_type_name || 'Unknown Room Type'}
                    </p>
                    <p style={{ color: '#6B7280', fontSize: '0.875rem', marginBottom: '0.5rem' }}>
                      Floor {room.floor} • Capacity: {room.capacity} guests
                    </p>
                  </div>
                  <div style={{ borderTop: '1px solid #E5E7EB', paddingTop: '1rem', marginBottom: '1rem' }}>
                    <div style={{ fontSize: '1.5rem', fontWeight: 600, color: '#C9A227', marginBottom: '0.25rem' }}>
                      ${parseFloat(String(room.price_per_night)).toFixed(2)}
                    </div>
                    <div style={{ fontSize: '0.75rem', color: '#6B7280' }}>per night</div>
                  </div>
                  {room.description && (
                    <p style={{ fontSize: '0.875rem', color: '#6B7280', marginBottom: '1rem', lineHeight: 1.5 }}>
                      {room.description}
                    </p>
                  )}
                  <button
                    className="btn btn-primary"
                    style={{ width: '100%' }}
                    onClick={() => handleBookRoom(room)}
                  >
                    Book This Room
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Info Card */}
      {!searched && (
        <div className="card" style={{ backgroundColor: '#F8F7F3', border: '1px dashed #C9A227' }}>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'start' }}>
            <div style={{ fontSize: '2rem' }}>💡</div>
            <div>
              <h3 style={{ fontSize: '1.125rem', marginBottom: '0.5rem', color: '#0F172A' }}>
                How to use the availability checker
              </h3>
              <ul style={{ color: '#6B7280', fontSize: '0.875rem', paddingLeft: '1.25rem', lineHeight: 1.6 }}>
                <li>Select your desired check-in and check-out dates</li>
                <li>Specify the number of guests in your party</li>
                <li>Click "Check Availability" to see available rooms</li>
                <li>Review room details and pricing</li>
                <li>Book your preferred room by creating a reservation</li>
              </ul>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Availability;
