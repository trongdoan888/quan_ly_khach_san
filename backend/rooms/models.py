from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class RoomType(models.Model):
    name = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)
    base_price = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'room_types'
        verbose_name = 'Room Type'
        verbose_name_plural = 'Room Types'
        ordering = ['name']
    
    def __str__(self):
        return self.name


class Room(models.Model):
    ROOM_STATUS_CHOICES = [
        ('available', 'Available'),
        ('occupied', 'Occupied'),
        ('maintenance', 'Maintenance'),
    ]
    
    room_number = models.CharField(max_length=10, unique=True)
    room_type = models.ForeignKey(RoomType, on_delete=models.PROTECT, related_name='rooms')
    floor = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(100)])
    capacity = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(20)])
    price_per_night = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=ROOM_STATUS_CHOICES, default='available')
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'rooms'
        verbose_name = 'Room'
        verbose_name_plural = 'Rooms'
        ordering = ['room_number']
        indexes = [
            models.Index(fields=['room_number']),
            models.Index(fields=['status']),
            models.Index(fields=['room_type']),
        ]
    
    def __str__(self):
        return f"Room {self.room_number} ({self.room_type.name})"
