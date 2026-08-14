import React, { useState, useEffect } from 'react';
import { customerService, Customer } from '../services/customerService';
import { useToast } from '../contexts/ToastContext';
import { useAuth } from '../contexts/AuthContext';

const Customers: React.FC = () => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const { addToast } = useToast();
  const { user } = useAuth();

  const [formData, setFormData] = useState({
    customer_id: '',
    full_name: '',
    email: '',
    phone: '',
    address: '',
    government_id_number: '',
  });

  useEffect(() => {
    fetchCustomers();
  }, []);

  const fetchCustomers = async () => {
    try {
      setLoading(true);
      const data = await customerService.getCustomers();
      setCustomers(data.results);
    } catch (error) {
      addToast('error', 'Failed to load customers');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async () => {
    if (!searchQuery.trim()) {
      fetchCustomers();
      return;
    }
    try {
      setLoading(true);
      const data = await customerService.searchCustomers(searchQuery);
      setCustomers(data);
    } catch (error) {
      addToast('error', 'Search failed');
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (customer: Customer) => {
    setEditingCustomer(customer);
    setFormData({
      customer_id: customer.customer_id,
      full_name: customer.full_name,
      email: customer.email,
      phone: customer.phone,
      address: customer.address,
      government_id_number: customer.government_id_number,
    });
    setShowModal(true);
  };

  const handleDelete = async (customer_id: string) => {
    if (!confirm('Are you sure you want to delete this customer?')) return;
    
    try {
      await customerService.deleteCustomer(customer_id);
      addToast('success', 'Customer deleted successfully');
      fetchCustomers();
    } catch (error: any) {
      if (error.response?.status === 403) {
        addToast('error', 'Only admins can delete customers');
      } else {
        addToast('error', 'Failed to delete customer');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      if (editingCustomer) {
        await customerService.updateCustomer(editingCustomer.customer_id, formData);
        addToast('success', 'Customer updated successfully');
      } else {
        await customerService.createCustomer(formData);
        addToast('success', 'Customer created successfully');
      }
      setShowModal(false);
      setEditingCustomer(null);
      fetchCustomers();
    } catch (error: any) {
      if (error.response?.status === 403) {
        addToast('error', 'Only admins can create or update customers');
      } else {
        const errors = error.response?.data;
        if (typeof errors === 'object') {
          Object.entries(errors).forEach(([field, messages]) => {
            addToast('error', `${field}: ${Array.isArray(messages) ? messages.join(', ') : messages}`);
          });
        } else {
          addToast('error', 'Failed to save customer');
        }
      }
    }
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
          <h1 style={{ marginBottom: '0.5rem' }}>Customers</h1>
          <p style={{ color: '#6B7280' }}>Manage your hotel customers</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>
          <span>➕</span> Add Customer
        </button>
      </div>

      {/* Search */}
      <div className="card" style={{ marginBottom: '1.5rem' }}>
        <div className="card-body">
          <div style={{ display: 'flex', gap: '1rem' }}>
            <input
              type="text"
              className="form-input"
              placeholder="Search by name, email, phone, or ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
              style={{ flex: 1 }}
            />
            <button className="btn btn-primary" onClick={handleSearch}>
              🔍 Search
            </button>
            <button className="btn btn-secondary" onClick={() => { setSearchQuery(''); fetchCustomers(); }}>
              Clear
            </button>
          </div>
        </div>
      </div>

      {/* Customers Table */}
      <div className="card">
        <div className="table-container">
          <table className="table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Phone</th>
                <th>Government ID</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {customers.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '2rem' }}>
                    <div className="empty-state">
                      <div className="empty-state-icon">👥</div>
                      <div className="empty-state-text">No customers found</div>
                      <div className="empty-state-subtext">Try a different search or add a new customer</div>
                    </div>
                  </td>
                </tr>
              ) : (
                customers.map((customer) => (
                  <tr key={customer.customer_id}>
                    <td style={{ fontWeight: 600 }}>{customer.customer_id}</td>
                    <td>{customer.full_name}</td>
                    <td>{customer.email}</td>
                    <td>{customer.phone}</td>
                    <td>{customer.masked_government_id}</td>
                    <td>
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        <button
                          className="btn btn-sm btn-secondary"
                          onClick={() => handleEdit(customer)}
                        >
                          Edit
                        </button>
                        <button
                          className="btn btn-sm btn-danger"
                          onClick={() => handleDelete(customer.customer_id)}
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
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{editingCustomer ? 'Edit Customer' : 'Add New Customer'}</h3>
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
                  <label className="form-label">Customer ID</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.customer_id}
                    onChange={(e) => setFormData({ ...formData, customer_id: e.target.value })}
                    required
                    disabled={!!editingCustomer}
                    placeholder="e.g., CUST001"
                  />
                  {!editingCustomer && <p className="form-hint">Unique identifier for the customer</p>}
                </div>
                <div className="form-group">
                  <label className="form-label">Full Name</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.full_name}
                    onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                    required
                    placeholder="John Doe"
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Email</label>
                  <input
                    type="email"
                    className="form-input"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    required
                    placeholder="john@example.com"
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Phone</label>
                  <input
                    type="tel"
                    className="form-input"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    required
                    placeholder="+1234567890"
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Address</label>
                  <textarea
                    className="form-textarea"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    required
                    rows={3}
                    placeholder="Full street address"
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Government ID Number</label>
                  <input
                    type="text"
                    className="form-input"
                    value={formData.government_id_number}
                    onChange={(e) => setFormData({ ...formData, government_id_number: e.target.value })}
                    required
                    placeholder="Passport, ID card, etc."
                  />
                  <p className="form-hint">This information is sensitive and will be masked in the UI</p>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  {editingCustomer ? 'Update Customer' : 'Create Customer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Customers;
