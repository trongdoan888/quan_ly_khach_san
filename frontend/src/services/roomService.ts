import api from './api';

export interface RoomType {
  id: number;
  name: string;
  description: string;
  base_price: number;
  created_at: string;
  updated_at: string;
}

export interface Room {
  id: number;
  room_number: string;
  room_type: number;
  room_type_name: string;
  room_type_details: RoomType;
  floor: number;
  capacity: number;
  price_per_night: number;
  status: 'available' | 'occupied' | 'maintenance';
  description: string;
  created_at: string;
  updated_at: string;
}

export interface RoomFormData {
  room_number: string;
  room_type: number;
  floor: number;
  capacity: number;
  price_per_night: number;
  status: 'available' | 'occupied' | 'maintenance';
  description: string;
}

export interface RoomSearchParams {
  room_type?: number;
  min_price?: number;
  max_price?: number;
  min_capacity?: number;
  max_capacity?: number;
  status?: string;
  room_number?: string;
}

export const roomService = {
  getRooms: async (params?: any): Promise<{ results: Room[]; count: number }> => {
    const response = await api.get('/rooms/', { params });
    return response.data;
  },

  getRoom: async (id: number): Promise<Room> => {
    const response = await api.get(`/rooms/${id}/`);
    return response.data;
  },

  createRoom: async (data: RoomFormData): Promise<Room> => {
    const response = await api.post('/rooms/', data);
    return response.data;
  },

  updateRoom: async (id: number, data: Partial<RoomFormData>): Promise<Room> => {
    const response = await api.put(`/rooms/${id}/`, data);
    return response.data;
  },

  deleteRoom: async (id: number): Promise<void> => {
    await api.delete(`/rooms/${id}/`);
  },

  searchRooms: async (params: RoomSearchParams): Promise<Room[]> => {
    const response = await api.get('/rooms/search/', { params });
    return response.data;
  },

  getRoomTypes: async (): Promise<RoomType[]> => {
    const response = await api.get('/rooms/types/');
    return response.data;
  },

  createRoomType: async (data: { name: string; description: string; base_price: number }): Promise<RoomType> => {
    const response = await api.post('/rooms/types/', data);
    return response.data;
  },

  updateRoomType: async (id: number, data: Partial<RoomType>): Promise<RoomType> => {
    const response = await api.put(`/rooms/types/${id}/`, data);
    return response.data;
  },

  deleteRoomType: async (id: number): Promise<void> => {
    await api.delete(`/rooms/types/${id}/`);
  },
};
