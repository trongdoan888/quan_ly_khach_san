from rest_framework import serializers
from .models import Reservation
from rooms.serializers import RoomSerializer
from customers.serializers import CustomerSerializer


class ReservationSerializer(serializers.ModelSerializer):
    customer_details = CustomerSerializer(source='customer', read_only=True)
    room_details = RoomSerializer(source='room', read_only=True)
    room_number = serializers.CharField(source='room.room_number', read_only=True)
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    
    class Meta:
        model = Reservation
        fields = [
            'reservation_number', 'customer', 'customer_details', 'customer_name',
            'room', 'room_details', 'room_number', 'check_in_date', 'check_out_date',
            'number_of_guests', 'booking_status', 'created_at', 'updated_at'
        ]
        read_only_fields = ['reservation_number', 'created_at', 'updated_at']
    
    def validate(self, attrs):
        # Validate check-out date is after check-in date
        if attrs.get('check_out_date') and attrs.get('check_in_date'):
            if attrs['check_out_date'] <= attrs['check_in_date']:
                raise serializers.ValidationError({
                    "check_out_date": "Check-out date must be after check-in date."
                })
        
        # Validate number of guests doesn't exceed room capacity
        if attrs.get('number_of_guests') and attrs.get('room'):
            if attrs['number_of_guests'] > attrs['room'].capacity:
                raise serializers.ValidationError({
                    "number_of_guests": f"Number of guests cannot exceed room capacity of {attrs['room'].capacity}."
                })
        
        # Validate room is not in maintenance
        if attrs.get('room') and attrs['room'].status == 'maintenance':
            raise serializers.ValidationError({
                "room": "Cannot book a room that is under maintenance."
            })
        
        # Check for double booking (critical business rule)
        if attrs.get('room') and attrs.get('check_in_date') and attrs.get('check_out_date'):
            from .models import Reservation
            overlapping_reservations = Reservation.objects.filter(
                room=attrs['room'],
                booking_status__in=['pending', 'confirmed', 'completed']
            ).exclude(
                reservation_number=self.instance.reservation_number if self.instance else None
            ).filter(
                check_in_date__lt=attrs['check_out_date'],
                check_out_date__gt=attrs['check_in_date']
            )
            
            if overlapping_reservations.exists():
                raise serializers.ValidationError({
                    "room": "This room is already booked for the selected dates. Please choose different dates or another room."
                })
        
        return attrs


class ReservationCreateSerializer(ReservationSerializer):
    class Meta(ReservationSerializer.Meta):
        fields = ReservationSerializer.Meta.fields
    
    def create(self, validated_data):
        # Generate reservation number
        import uuid
        validated_data['reservation_number'] = f"RES-{uuid.uuid4().hex[:12].upper()}"
        return super().create(validated_data)


class AvailabilitySerializer(serializers.Serializer):
    room = serializers.IntegerField(required=False, allow_null=True)
    check_in_date = serializers.DateField()
    check_out_date = serializers.DateField()
    number_of_guests = serializers.IntegerField(required=False, allow_null=True)