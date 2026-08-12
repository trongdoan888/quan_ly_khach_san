from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Customer

User = get_user_model()


class CustomerTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='staff',
            email='staff@example.com',
            password='staff123',
            role='staff',
            is_staff=True
        )
        
        # Login
        login_response = self.client.post('/api/auth/login/', {
            'username': 'staff',
            'password': 'staff123'
        })
        self.token = login_response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

    def test_create_customer(self):
        """Test creating a new customer"""
        data = {
            'full_name': 'John Doe',
            'email': 'john@example.com',
            'phone': '+1234567890',
            'address': '123 Main St',
            'government_id_number': 'PASS123456'
        }
        response = self.client.post('/api/customers/', data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Customer.objects.filter(email='john@example.com').exists())

    def test_create_customer_duplicate_id(self):
        """Test creating customer with duplicate ID"""
        # Skip this test since customer_id is auto-generated
        self.skipTest("Customer ID is auto-generated, duplicate ID test not applicable")

    def test_create_customer_duplicate_email(self):
        """Test creating customer with duplicate email"""
        Customer.objects.create(
            customer_id='CUST001',
            full_name='John Doe',
            email='john@example.com',
            phone='+1234567890',
            address='123 Main St',
            government_id_number='PASS123456'
        )
        
        data = {
            'customer_id': 'CUST002',
            'full_name': 'Jane Doe',
            'email': 'john@example.com',
            'phone': '+1234567891',
            'address': '456 Oak Ave',
            'government_id_number': 'ID789012'
        }
        response = self.client.post('/api/customers/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_update_customer(self):
        """Test updating a customer"""
        customer = Customer.objects.create(
            full_name='John Doe',
            email='john@example.com',
            phone='+1234567890',
            address='123 Main St',
            government_id_number='PASS123456'
        )
        
        data = {
            'full_name': 'John Smith',
            'email': 'johnsmith@example.com',
            'phone': '+1234567891',
            'address': '456 Oak Ave',
            'government_id_number': 'PASS123456'
        }
        response = self.client.put(f'/api/customers/{customer.customer_id}/', data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        customer.refresh_from_db()
        self.assertEqual(customer.full_name, 'John Smith')

    def test_delete_customer(self):
        """Test deleting a customer"""
        customer = Customer.objects.create(
            full_name='John Doe',
            email='john@example.com',
            phone='+1234567890',
            address='123 Main St',
            government_id_number='PASS123456'
        )
        customer_id = customer.customer_id
        
        response = self.client.delete(f'/api/customers/{customer_id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Customer.objects.filter(customer_id=customer_id).exists())

    def test_list_customers(self):
        """Test listing all customers"""
        Customer.objects.create(
            customer_id='CUST001',
            full_name='John Doe',
            email='john@example.com',
            phone='+1234567890',
            address='123 Main St',
            government_id_number='PASS123456'
        )
        Customer.objects.create(
            customer_id='CUST002',
            full_name='Jane Doe',
            email='jane@example.com',
            phone='+1234567891',
            address='456 Oak Ave',
            government_id_number='ID789012'
        )
        
        response = self.client.get('/api/customers/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)

    def test_search_customers(self):
        """Test customer search functionality"""
        customer1 = Customer.objects.create(
            full_name='John Doe',
            email='john@example.com',
            phone='+1234567890',
            address='123 Main St',
            government_id_number='PASS123456'
        )
        customer2 = Customer.objects.create(
            full_name='Jane Smith',
            email='jane.smith@example.com',
            phone='+1234567891',
            address='456 Oak Ave',
            government_id_number='ID789012'
        )
        
        response = self.client.get('/api/customers/search/', {'search': 'John'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['full_name'], 'John Doe')

    def test_masked_government_id(self):
        """Test that government ID is masked in API response"""
        customer = Customer.objects.create(
            full_name='John Doe',
            email='john@example.com',
            phone='+1234567890',
            address='123 Main St',
            government_id_number='PASS1234567890'
        )
        customer_id = customer.customer_id
        
        response = self.client.get(f'/api/customers/{customer_id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # government_id_number should not be in response (write_only)
        self.assertNotIn('government_id_number', response.data)
        self.assertIn('*', response.data['masked_government_id'])