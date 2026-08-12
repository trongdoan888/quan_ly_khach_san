import api from './api';

export interface Customer {
  customer_id: string;
  full_name: string;
  email: string;
  phone: string;
  address: string;
  government_id_number: string;
  masked_government_id: string;
  created_at: string;
  updated_at: string;
}

export interface CustomerFormData {
  customer_id?: string;
  full_name: string;
  email: string;
  phone: string;
  address: string;
  government_id_number: string;
}

export const customerService = {
  getCustomers: async (params?: any): Promise<{ results: Customer[]; count: number }> => {
    const response = await api.get('/customers/', { params });
    return response.data;
  },

  getCustomer: async (customer_id: string): Promise<Customer> => {
    const response = await api.get(`/customers/${customer_id}/`);
    return response.data;
  },

  createCustomer: async (data: CustomerFormData): Promise<Customer> => {
    const response = await api.post('/customers/', data);
    return response.data;
  },

  updateCustomer: async (customer_id: string, data: Partial<CustomerFormData>): Promise<Customer> => {
    const response = await api.put(`/customers/${customer_id}/`, data);
    return response.data;
  },

  deleteCustomer: async (customer_id: string): Promise<void> => {
    await api.delete(`/customers/${customer_id}/`);
  },

  searchCustomers: async (search: string): Promise<Customer[]> => {
    const response = await api.get('/customers/search/', { params: { search } });
    return response.data;
  },
};
