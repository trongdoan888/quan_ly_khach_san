import os
import django
from datetime import datetime, timedelta
import random
import uuid

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'hotel_reservation.settings')
django.setup()

from authentication.models import User
from rooms.models import Room, RoomType
from customers.models import Customer
from reservations.models import Reservation


def seed_data():
    print("Seeding data...")
    
    # Create Users
    print("Creating users...")
    admin_user, created = User.objects.get_or_create(
        username='admin',
        defaults={
            'email': 'admin@hotel.com',
            'first_name': 'Admin',
            'last_name': 'User',
            'role': 'admin',
            'is_staff': True,
            'is_superuser': True
        }
    )
    if created:
        admin_user.set_password('admin123')
        admin_user.save()
    
    staff_user, created = User.objects.get_or_create(
        username='staff',
        defaults={
            'email': 'staff@hotel.com',
            'first_name': 'Staff',
            'last_name': 'User',
            'role': 'staff',
            'is_staff': True
        }
    )
    if created:
        staff_user.set_password('staff123')
        staff_user.save()
    
    # Create Room Types
    print("Creating room types...")
    standard_type, _ = RoomType.objects.get_or_create(
        name='Standard',
        defaults={
            'description': 'Comfortable standard room with basic amenities',
            'base_price': 100.00
        }
    )
    
    deluxe_type, _ = RoomType.objects.get_or_create(
        name='Deluxe',
        defaults={
            'description': 'Spacious deluxe room with premium amenities',
            'base_price': 200.00
        }
    )
    
    suite_type, _ = RoomType.objects.get_or_create(
        name='Suite',
        defaults={
            'description': 'Luxury suite with separate living area and premium services',
            'base_price': 400.00
        }
    )
    
    # Create Rooms
    print("Creating rooms...")
    rooms_data = [
        # Standard rooms (Floor 1-3)
        ('101', standard_type, 1, 2, 120.00, 'available'),
        ('102', standard_type, 1, 2, 120.00, 'available'),
        ('103', standard_type, 1, 2, 120.00, 'occupied'),
        ('104', standard_type, 1, 3, 130.00, 'available'),
        ('201', standard_type, 2, 2, 125.00, 'available'),
        ('202', standard_type, 2, 2, 125.00, 'maintenance'),
        ('203', standard_type, 2, 3, 135.00, 'available'),
        ('301', standard_type, 3, 2, 130.00, 'available'),
        ('302', standard_type, 3, 2, 130.00, 'available'),
        ('303', standard_type, 3, 3, 140.00, 'available'),
        
        # Deluxe rooms (Floor 4-6)
        ('401', deluxe_type, 4, 3, 220.00, 'available'),
        ('402', deluxe_type, 4, 3, 220.00, 'occupied'),
        ('403', deluxe_type, 4, 4, 240.00, 'available'),
        ('501', deluxe_type, 5, 3, 230.00, 'available'),
        ('502', deluxe_type, 5, 4, 250.00, 'available'),
        ('503', deluxe_type, 5, 4, 250.00, 'available'),
        ('601', deluxe_type, 6, 3, 240.00, 'available'),
        ('602', deluxe_type, 6, 4, 260.00, 'available'),
        
        # Suite rooms (Floor 7-8)
        ('701', suite_type, 7, 4, 450.00, 'available'),
        ('702', suite_type, 7, 5, 500.00, 'occupied'),
        ('801', suite_type, 8, 4, 480.00, 'available'),
        ('802', suite_type, 8, 5, 520.00, 'available'),
    ]
    
    rooms = []
    for room_number, room_type, floor, capacity, price, status in rooms_data:
        room, created = Room.objects.get_or_create(
            room_number=room_number,
            defaults={
                'room_type': room_type,
                'floor': floor,
                'capacity': capacity,
                'price_per_night': price,
                'status': status,
                'description': f'{room_type.name} room on floor {floor} with capacity for {capacity} guests.'
            }
        )
        rooms.append(room)
    
    # Create Customers
    print("Creating customers...")
    customers_data = [
        ('CUST001', 'John Smith', 'john.smith@email.com', '+1234567890', '123 Main St, City, Country', 'PASS123456'),
        ('CUST002', 'Jane Doe', 'jane.doe@email.com', '+1234567891', '456 Oak Ave, Town, Country', 'ID7890123'),
        ('CUST003', 'Robert Johnson', 'robert.j@email.com', '+1234567892', '789 Pine Rd, Village, Country', 'LIC345678'),
        ('CUST004', 'Emily Williams', 'emily.w@email.com', '+1234567893', '321 Elm St, County, Country', 'DOC901234'),
        ('CUST005', 'Michael Brown', 'michael.b@email.com', '+1234567894', '654 Maple Dr, District, Country', 'PASS567890'),
        ('CUST006', 'Sarah Davis', 'sarah.d@email.com', '+1234567895', '987 Cedar Ln, Province, Country', 'ID234567'),
        ('CUST007', 'David Miller', 'david.m@email.com', '+1234567896', '147 Birch Blvd, State, Country', 'LIC890123'),
        ('CUST008', 'Lisa Wilson', 'lisa.w@email.com', '+1234567897', '258 Spruce Way, Region, Country', 'DOC456789'),
    ]
    
    customers = []
    for customer_id, full_name, email, phone, address, gov_id in customers_data:
        customer, created = Customer.objects.get_or_create(
            customer_id=customer_id,
            defaults={
                'full_name': full_name,
                'email': email,
                'phone': phone,
                'address': address,
                'government_id_number': gov_id
            }
        )
        customers.append(customer)
    
    # Create Reservations
    print("Creating reservations...")
    today = datetime.now().date()
    
    # Clear existing reservations to avoid conflicts
    Reservation.objects.all().delete()
    
    reservations_data = [
        # Current active reservations
        (customers[0], rooms[2], today - timedelta(days=2), today + timedelta(days=3), 2, 'confirmed'),
        (customers[1], rooms[10], today - timedelta(days=1), today + timedelta(days=5), 3, 'confirmed'),
        (customers[2], rooms[13], today, today + timedelta(days=7), 3, 'pending'),
        (customers[3], rooms[20], today - timedelta(days=3), today + timedelta(days=1), 4, 'confirmed'),
        
        # Past completed reservations
        (customers[4], rooms[0], today - timedelta(days=20), today - timedelta(days=15), 2, 'completed'),
        (customers[5], rooms[1], today - timedelta(days=15), today - timedelta(days=10), 2, 'completed'),
        
        # Cancelled reservations
        (customers[6], rooms[4], today + timedelta(days=10), today + timedelta(days=15), 2, 'cancelled'),
        
        # Future reservations (use room 6 instead of 5 which is maintenance)
        (customers[7], rooms[6], today + timedelta(days=30), today + timedelta(days=35), 2, 'pending'),
    ]
    
    for customer, room, check_in, check_out, guests, status in reservations_data:
        # Skip if room is in maintenance
        if room.status == 'maintenance':
            continue
            
        reservation = Reservation.objects.create(
            reservation_number=f"RES-{uuid.uuid4().hex[:12].upper()}",
            customer=customer,
            room=room,
            check_in_date=check_in,
            check_out_date=check_out,
            number_of_guests=guests,
            booking_status=status
        )
    
    print("Data seeding completed successfully!")
    print(f"Created {User.objects.count()} users")
    print(f"Created {RoomType.objects.count()} room types")
    print(f"Created {Room.objects.count()} rooms")
    print(f"Created {Customer.objects.count()} customers")
    print(f"Created {Reservation.objects.count()} reservations")


if __name__ == '__main__':
    seed_data()