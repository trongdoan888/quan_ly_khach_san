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


def generate_sample_data():
    """Generate sample data for testing: 50 customers, 80 rooms (4 floors × 20), 3 months of reservations"""
    print("Generating sample data...")
    
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
    
    # Clear existing rooms and reservations
    print("Clearing existing data...")
    Reservation.objects.all().delete()
    Room.objects.all().delete()
    Customer.objects.all().delete()
    
    # Create Rooms - 4 floors × 20 rooms = 80 rooms total
    print("Creating 80 rooms (4 floors × 20 rooms per floor)...")
    room_types = [standard_type, deluxe_type, suite_type]
    room_type_weights = [0.5, 0.35, 0.15]  # 50% Standard, 35% Deluxe, 15% Suite
    
    rooms = []
    for floor in range(1, 5):  # Floors 1-4
        for room_num in range(1, 21):  # 20 rooms per floor
            room_number = f"{floor}{room_num:02d}"
            room_type = random.choices(room_types, weights=room_type_weights)[0]
            
            # Capacity based on room type
            if room_type.name == 'Standard':
                capacity = random.choice([2, 3])
                price = 100.00 + (floor * 5) + (capacity * 5)
            elif room_type.name == 'Deluxe':
                capacity = random.choice([3, 4])
                price = 200.00 + (floor * 10) + (capacity * 10)
            else:  # Suite
                capacity = random.choice([4, 5])
                price = 400.00 + (floor * 15) + (capacity * 15)
            
            # Random status
            status = random.choices(
                ['available', 'occupied', 'maintenance'],
                weights=[0.6, 0.3, 0.1]
            )[0]
            
            room = Room.objects.create(
                room_number=room_number,
                room_type=room_type,
                floor=floor,
                capacity=capacity,
                price_per_night=price,
                status=status,
                description=f'{room_type.name} room on floor {floor} with capacity for {capacity} guests.'
            )
            rooms.append(room)
    
    print(f"Created {len(rooms)} rooms")
    
    # Create 50 Customers
    print("Creating 50 customers...")
    first_names = ['John', 'Jane', 'Robert', 'Emily', 'Michael', 'Sarah', 'David', 'Lisa', 'James', 'Maria',
                   'William', 'Jennifer', 'Richard', 'Patricia', 'Joseph', 'Linda', 'Thomas', 'Barbara', 'Charles', 'Susan',
                   'Christopher', 'Jessica', 'Daniel', 'Karen', 'Matthew', 'Nancy', 'Anthony', 'Betty', 'Mark', 'Helen', 'Donald',
                   'Sandra', 'Paul', 'Ashley', 'Steven', 'Dorothy', 'Andrew', 'Carol', 'Joshua', 'Michelle', 'Kenneth', 'Laura',
                   'Kevin', 'Shirley', 'Brian', 'Kimberly', 'George', 'Angela', 'Edward', 'Melissa', 'Ronald', 'Donna']
    
    last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
                  'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
                  'Lee', 'Perez', 'Thompson', 'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker',
                  'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores', 'Green', 'Adams',
                  'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell', 'Carter', 'Roberts']
    
    customers = []
    for i in range(50):
        customer_id = f"CUST{(i + 1):03d}"
        first_name = random.choice(first_names)
        last_name = random.choice(last_names)
        full_name = f"{first_name} {last_name}"
        email = f"{first_name.lower()}.{last_name.lower()}{i}@email.com"
        phone = f"+1{random.randint(200, 999)}{random.randint(100, 999)}{random.randint(1000, 9999)}"
        address = f"{random.randint(1, 999)} {random.choice(['Main St', 'Oak Ave', 'Pine Rd', 'Elm St', 'Maple Dr', 'Cedar Ln', 'Birch Blvd', 'Spruce Way'])}, {random.choice(['City', 'Town', 'Village', 'County'])}, USA"
        gov_id = f"{random.choice(['PASS', 'ID', 'LIC', 'DOC'])}{random.randint(100000, 999999)}"
        
        customer = Customer.objects.create(
            customer_id=customer_id,
            full_name=full_name,
            email=email,
            phone=phone,
            address=address,
            government_id_number=gov_id
        )
        customers.append(customer)
    
    print(f"Created {len(customers)} customers")
    
    # Create Reservations for 3 months
    print("Creating reservations for 3 months...")
    today = datetime.now().date()
    start_date = today - timedelta(days=30)  # Start 30 days ago
    end_date = today + timedelta(days=90)  # End 90 days in future
    
    available_rooms = [r for r in rooms if r.status != 'maintenance']
    
    reservations = []
    current_date = start_date
    
    while current_date <= end_date:
        # Generate 5-10 reservations per day
        num_reservations = random.randint(5, 10)
        
        for _ in range(num_reservations):
            customer = random.choice(customers)
            room = random.choice(available_rooms)
            
            # Random stay duration (1-7 days)
            stay_duration = random.randint(1, 7)
            check_in = current_date
            check_out = current_date + timedelta(days=stay_duration)
            
            # Skip if check_out is beyond our range
            if check_out > end_date:
                continue
            
            # Check for double booking
            overlapping = Reservation.objects.filter(
                room=room,
                booking_status__in=['pending', 'confirmed', 'completed'],
                check_in_date__lt=check_out,
                check_out_date__gt=check_in
            ).exists()
            
            if overlapping:
                continue
            
            # Random booking status
            if check_in < today:
                status = random.choice(['completed', 'cancelled'])
            elif check_in == today:
                status = random.choice(['confirmed', 'pending'])
            else:
                status = random.choice(['pending', 'confirmed'])
            
            # Number of guests based on room capacity
            num_guests = random.randint(1, room.capacity)
            
            reservation = Reservation.objects.create(
                reservation_number=f"RES-{uuid.uuid4().hex[:12].upper()}",
                customer=customer,
                room=room,
                check_in_date=check_in,
                check_out_date=check_out,
                number_of_guests=num_guests,
                booking_status=status
            )
            reservations.append(reservation)
        
        current_date += timedelta(days=1)
    
    print(f"Created {len(reservations)} reservations")
    
    print("\n" + "="*50)
    print("Sample data generation completed successfully!")
    print("="*50)
    print(f"Users: {User.objects.count()}")
    print(f"Room Types: {RoomType.objects.count()}")
    print(f"Rooms: {Room.objects.count()} (4 floors × 20 rooms)")
    print(f"Customers: {Customer.objects.count()}")
    print(f"Reservations: {Reservation.objects.count()} (3 months)")
    print("\nDemo credentials:")
    print("  Admin: admin / admin123")
    print("  Staff: staff / staff123")
    print("="*50)


def seed_data():
    """Original seed data function for backward compatibility"""
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
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == '--sample':
        generate_sample_data()
    else:
        seed_data()
