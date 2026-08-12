from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Room, RoomType

User = get_user_model()


class RoomTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='admin123',
            role='admin',
            is_staff=True
        )
        self.room_type = RoomType.objects.create(
            name='Standard',
            description='Standard room',
            base_price=100.00
        )
        
        # Login as admin
        login_response = self.client.post('/api/auth/login/', {
            'username': 'admin',
            'password': 'admin123'
        })
        self.token = login_response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')

    def test_create_room(self):
        """Test creating a new room"""
        data = {
            'room_number': '101',
            'room_type': self.room_type.id,
            'floor': 1,
            'capacity': 2,
            'price_per_night': 120.00,
            'status': 'available',
            'description': 'Test room'
        }
        response = self.client.post('/api/rooms/', data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Room.objects.filter(room_number='101').exists())

    def test_create_room_duplicate_number(self):
        """Test creating room with duplicate number"""
        Room.objects.create(
            room_number='101',
            room_type=self.room_type,
            floor=1,
            capacity=2,
            price_per_night=120.00,
            status='available'
        )
        
        data = {
            'room_number': '101',
            'room_type': self.room_type.id,
            'floor': 2,
            'capacity': 2,
            'price_per_night': 120.00,
            'status': 'available'
        }
        response = self.client.post('/api/rooms/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_update_room(self):
        """Test updating a room"""
        room = Room.objects.create(
            room_number='101',
            room_type=self.room_type,
            floor=1,
            capacity=2,
            price_per_night=120.00,
            status='available'
        )
        
        data = {
            'room_number': '101',
            'room_type': self.room_type.id,
            'floor': 1,
            'capacity': 3,
            'price_per_night': 150.00,
            'status': 'available'
        }
        response = self.client.put(f'/api/rooms/{room.id}/', data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        room.refresh_from_db()
        self.assertEqual(room.capacity, 3)
        self.assertEqual(room.price_per_night, 150.00)

    def test_delete_room(self):
        """Test deleting a room"""
        room = Room.objects.create(
            room_number='101',
            room_type=self.room_type,
            floor=1,
            capacity=2,
            price_per_night=120.00,
            status='available'
        )
        
        response = self.client.delete(f'/api/rooms/{room.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Room.objects.filter(id=room.id).exists())

    def test_list_rooms(self):
        """Test listing all rooms"""
        Room.objects.create(
            room_number='101',
            room_type=self.room_type,
            floor=1,
            capacity=2,
            price_per_night=120.00,
            status='available'
        )
        Room.objects.create(
            room_number='102',
            room_type=self.room_type,
            floor=1,
            capacity=2,
            price_per_night=120.00,
            status='occupied'
        )
        
        response = self.client.get('/api/rooms/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 2)

    def test_search_rooms(self):
        """Test room search functionality"""
        Room.objects.create(
            room_number='101',
            room_type=self.room_type,
            floor=1,
            capacity=2,
            price_per_night=120.00,
            status='available'
        )
        Room.objects.create(
            room_number='201',
            room_type=self.room_type,
            floor=2,
            capacity=3,
            price_per_night=150.00,
            status='available'
        )
        
        response = self.client.get('/api/rooms/search/', {'room_number': '101'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['room_number'], '101')

    def test_room_validation_negative_price(self):
        """Test room validation with negative price"""
        data = {
            'room_number': '101',
            'room_type': self.room_type.id,
            'floor': 1,
            'capacity': 2,
            'price_per_night': -50.00,
            'status': 'available'
        }
        response = self.client.post('/api/rooms/', data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)