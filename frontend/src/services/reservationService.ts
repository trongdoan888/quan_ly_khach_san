import api from './api';

export interface Reservation {
  reservation_number: string;
  customer: string;
  customer_details: {
    customer_id: string;
    full_name: string;
    email: string;
    phone: string;
  };
  customer_name: string;
  room: number;
  room_details: {
    id: number;
    room_number: string;
    room_type_name: string;
    capacity: number;
    price_per_night: number;
  };
  room_number: string;
  check_in_date: string;
  check_out_date: string;
  number_of_guests: number;
  booking_status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  created_at: string;
  updated_at: string;
}

export interface ReservationFormData {
  customer: string;
  room: number;
  check_in_date: string;
  check_out_date: string;
  number_of_guests: number;
  booking_status?: 'pending' | 'confirmed' | 'cancelled' | 'completed';
}

export interface AvailabilityCheckData {
  room: number;
  check_in_date: string;
  check_out_date: string;
  number_of_guests?: number;
}

export interface AvailabilityResponse {
  check_in_date: string;
  check_out_date: string;
  available_rooms: any[];
  total_available: number;
}

export interface DashboardStats {
  total_rooms: number;
  available_rooms: number;
  occupied_rooms: number;
  active_reservations: number;
  total_customers: number;
  today_checkins: number;
  today_checkouts: number;
  occupancy_rate: number;
}

export const reservationService = {
  getReservations: async (params?: any): Promise<{ results: Reservation[]; count: number }> => {
    const response = await api.get('/reservations/', { params });
    return response.data;
  },

  getReservation: async (reservation_number: string): Promise<Reservation> => {
    const response = await api.get(`/reservations/${reservation_number}/`);
    return response.data;
  },

  createReservation: async (data: ReservationFormData): Promise<Reservation> => {
    const response = await api.post('/reservations/', data);
    return response.data;
  },

  updateReservation: async (reservation_number: string, data: Partial<ReservationFormData>): Promise<Reservation> => {
    const response = await api.put(`/reservations/${reservation_number}/`, data);
    return response.data;
  },

  deleteReservation: async (reservation_number: string): Promise<void> => {
    await api.delete(`/reservations/${reservation_number}/`);
  },

  checkAvailability: async (data: AvailabilityCheckData): Promise<AvailabilityResponse> => {
    const params: any = {
      check_in_date: data.check_in_date,
      check_out_date: data.check_out_date,
    };
    if (data.room) params.room = data.room;
    if (data.number_of_guests) params.number_of_guests = data.number_of_guests;
    const response = await api.get('/reservations/check-availability/', { params });
    return response.data;
  },

  getStatistics: async (): Promise<DashboardStats> => {
    const response = await api.get('/reservations/statistics/');
    return response.data;
  },
};
