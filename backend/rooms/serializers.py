from rest_framework import serializers
from .models import Room, RoomType


class RoomTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoomType
        fields = ['id', 'name', 'description', 'base_price', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class RoomSerializer(serializers.ModelSerializer):
    room_type_name = serializers.CharField(source='room_type.name', read_only=True)
    room_type_details = RoomTypeSerializer(source='room_type', read_only=True)
    
    class Meta:
        model = Room
        fields = [
            'id', 'room_number', 'room_type', 'room_type_name', 'room_type_details',
            'floor', 'capacity', 'price_per_night', 'status', 'description',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def validate_room_number(self, value):
        # Check if room number already exists (excluding current instance for updates)
        queryset = Room.objects.filter(room_number=value)
        if self.instance:
            queryset = queryset.exclude(id=self.instance.id)
        if queryset.exists():
            raise serializers.ValidationError("A room with this number already exists.")
        return value
    
    def validate(self, attrs):
        # Validate that price is positive
        if attrs.get('price_per_night') and attrs['price_per_night'] <= 0:
            raise serializers.ValidationError({"price_per_night": "Price must be positive."})
        return attrs


class RoomSearchSerializer(serializers.Serializer):
    room_type = serializers.IntegerField(required=False)
    min_price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    max_price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    min_capacity = serializers.IntegerField(required=False)
    max_capacity = serializers.IntegerField(required=False)
    status = serializers.CharField(required=False)
    room_number = serializers.CharField(required=False)