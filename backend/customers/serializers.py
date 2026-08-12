from rest_framework import serializers
from .models import Customer


class CustomerSerializer(serializers.ModelSerializer):
    masked_government_id = serializers.SerializerMethodField()
    
    class Meta:
        model = Customer
        fields = [
            'customer_id', 'full_name', 'email', 'phone', 'address',
            'government_id_number', 'masked_government_id', 'created_at', 'updated_at'
        ]
        read_only_fields = ['customer_id', 'created_at', 'updated_at']
        extra_kwargs = {
            'government_id_number': {'write_only': True}
        }
    
    def get_masked_government_id(self, obj):
        return obj.get_masked_government_id()
    
    def validate_email(self, value):
        # Check if email already exists (excluding current instance for updates)
        queryset = Customer.objects.filter(email=value)
        if self.instance:
            queryset = queryset.exclude(customer_id=self.instance.customer_id)
        if queryset.exists():
            raise serializers.ValidationError("A customer with this email already exists.")
        return value
    
    def validate_government_id_number(self, value):
        # Check if government ID already exists (excluding current instance for updates)
        queryset = Customer.objects.filter(government_id_number=value)
        if self.instance:
            queryset = queryset.exclude(customer_id=self.instance.customer_id)
        if queryset.exists():
            raise serializers.ValidationError("A customer with this government ID already exists.")
        return value
    
    def validate_phone(self, value):
        # Basic phone validation
        if not value or len(value) < 10:
            raise serializers.ValidationError("Phone number must be at least 10 characters.")
        return value