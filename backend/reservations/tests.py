from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from datetime import datetime, timedelta
from .models import Reservation
from rooms.models import Room, RoomType
from customers.models import Customer

User = get_user_model()


class ReservationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='staff',
            email='staff@example.com',
            password='staff123',
            role='staff',
            is_staff=True
        )
        
        self.room_type = RoomType.objects.create(
            name='Standard',
            description='Standard room',
            base_price=100.00
        )
        
        self.room = Room.objects.create(
            room_number='101',
            room_type=self.room_type,
            floor=1,
            capacity=2,
            price_per_night=120.00,
            status='available'
        )
        
        self.customer = Customer.objects.create(
            customer_id='CUST001',
            full_name='John Doe',
            email='john@example.com',
            phone='+1234567890',
            address='123 Main St',
            government_id_number='PASS123456'
        )
        
        # Login
        login_response = self.client.post('/api/auth/login/', {
            'username': 'staff',
            'password': 'staff123'
        })
        self.token = login_response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

    def test_create_reservation(self):
        """Test creating a new reservation"""
        today = datetime.now().date()
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today,
            'check_out_date': today + timedelta(days=3),
            'number_of_guests': 2,
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Reservation.objects.filter(room=self.room).exists())

    def test_create_reservation_checkout_before_checkin(self):
        """Test creating reservation with checkout before checkin"""
        today = datetime.now().date()
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today + timedelta(days=3),
            'check_out_date': today,
            'number_of_guests': 2,
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_reservation_exceeds_capacity(self):
        """Test creating reservation with guests exceeding room capacity"""
        today = datetime.now().date()
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today,
            'check_out_date': today + timedelta(days=3),
            'number_of_guests': 5,  # Room capacity is 2
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_reservation_maintenance_room(self):
        """Test creating reservation for room in maintenance"""
        self.room.status = 'maintenance'
        self.room.save()
        
        today = datetime.now().date()
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today,
            'check_out_date': today + timedelta(days=3),
            'number_of_guests': 2,
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_double_booking_exact_overlap(self):
        """Test double booking prevention - exact overlap"""
        today = datetime.now().date()
        
        # Create first reservation
        Reservation.objects.create(
            reservation_number='RES001',
            customer=self.customer,
            room=self.room,
            check_in_date=today,
            check_out_date=today + timedelta(days=3),
            number_of_guests=2,
            booking_status='confirmed'
        )
        
        # Try to create overlapping reservation
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today,
            'check_out_date': today + timedelta(days=3),
            'number_of_guests': 2,
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_double_booking_partial_overlap(self):
        """Test double booking prevention - partial overlap"""
        today = datetime.now().date()
        
        # Create first reservation
        Reservation.objects.create(
            reservation_number='RES001',
            customer=self.customer,
            room=self.room,
            check_in_date=today,
            check_out_date=today + timedelta(days=5),
            number_of_guests=2,
            booking_status='confirmed'
        )
        
        # Try to create overlapping reservation (days 3-7)
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today + timedelta(days=3),
            'check_out_date': today + timedelta(days=7),
            'number_of_guests': 2,
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_double_booking_nested_overlap(self):
        """Test double booking prevention - nested overlap"""
        today = datetime.now().date()
        
        # Create first reservation (days 0-10)
        Reservation.objects.create(
            reservation_number='RES001',
            customer=self.customer,
            room=self.room,
            check_in_date=today,
            check_out_date=today + timedelta(days=10),
            number_of_guests=2,
            booking_status='confirmed'
        )
        
        # Try to create nested reservation (days 3-5)
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today + timedelta(days=3),
            'check_out_date': today + timedelta(days=5),
            'number_of_guests': 2,
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_checkout_equals_next_checkin(self):
        """Test that checkout can equal next checkin (allowed)"""
        today = datetime.now().date()
        
        # Create first reservation
        Reservation.objects.create(
            reservation_number='RES001',
            customer=self.customer,
            room=self.room,
            check_in_date=today,
            check_out_date=today + timedelta(days=3),
            number_of_guests=2,
            booking_status='confirmed'
        )
        
        # Create second reservation starting exactly when first ends
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today + timedelta(days=3),
            'check_out_date': today + timedelta(days=6),
            'number_of_guests': 2,
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_cancelled_reservation_does_not_block(self):
        """Test that cancelled reservations don't block availability"""
        today = datetime.now().date()
        
        # Create cancelled reservation
        Reservation.objects.create(
            reservation_number='RES001',
            customer=self.customer,
            room=self.room,
            check_in_date=today,
            check_out_date=today + timedelta(days=3),
            number_of_guests=2,
            booking_status='cancelled'
        )
        
        # Should be able to create new reservation for same dates
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today,
            'check_out_date': today + timedelta(days=3),
            'number_of_guests': 2,
            'booking_status': 'pending'
        }
        response = self.client.post('/api/reservations/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_update_reservation(self):
        """Test updating a reservation"""
        today = datetime.now().date()
        reservation = Reservation.objects.create(
            reservation_number='RES001',
            customer=self.customer,
            room=self.room,
            check_in_date=today,
            check_out_date=today + timedelta(days=3),
            number_of_guests=2,
            booking_status='pending'
        )
        
        data = {
            'customer': self.customer.customer_id,
            'room': self.room.id,
            'check_in_date': today,
            'check_out_date': today + timedelta(days=5),
            'number_of_guests': 2,
            'booking_status': 'confirmed'
        }
        response = self.client.put(f'/api/reservations/{reservation.reservation_number}/', data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        reservation.refresh_from_db()
        self.assertEqual(reservation.booking_status, 'confirmed')

    def test_delete_reservation(self):
        """Test deleting a reservation"""
        today = datetime.now().date()
        reservation = Reservation.objects.create(
            reservation_number='RES001',
            customer=self.customer,
            room=self.room,
            check_in_date=today,
            check_out_date=today + timedelta(days=3),
            number_of_guests=2,
            booking_status='pending'
        )
        
        response = self.client.delete(f'/api/reservations/{reservation.reservation_number}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Reservation.objects.filter(reservation_number='RES001').exists())

    def test_check_availability(self):
        """Test room availability checking"""
        today = datetime.now().date()
        
        # Create a reservation
        Reservation.objects.create(
            reservation_number='RES001',
            customer=self.customer,
            room=self.room,
            check_in_date=today,
            check_out_date=today + timedelta(days=3),
            number_of_guests=2,
            booking_status='confirmed'
        )
        
        # Check availability for overlapping dates
        data = {
            'room': self.room.id,
            'check_in_date': today.isoformat(),
            'check_out_date': (today + timedelta(days=3)).isoformat(),
            'number_of_guests': 2
        }
        response = self.client.post('/api/reservations/check-availability/', data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Room should not be in available rooms
        room_ids = [room['id'] for room in response.data['available_rooms']]
        self.assertNotIn(self.room.id, room_ids)

    def test_get_statistics(self):
        """Test getting dashboard statistics"""
        response = self.client.get('/api/reservations/statistics/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_rooms', response.data)
        self.assertIn('available_rooms', response.data)
        self.assertIn('occupied_rooms', response.data)
        self.assertIn('active_reservations', response.data)
        self.assertIn('total_customers', response.data)