from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
from rooms.models import Room
from customers.models import Customer


class Reservation(models.Model):
    BOOKING_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('cancelled', 'Cancelled'),
        ('completed', 'Completed'),
    ]
    
    reservation_number = models.CharField(max_length=20, unique=True, primary_key=True)
    customer = models.ForeignKey(Customer, on_delete=models.SET_NULL, null=True, blank=True, related_name='reservations')
    room = models.ForeignKey(Room, on_delete=models.SET_NULL, null=True, blank=True, related_name='reservations')
    check_in_date = models.DateField()
    check_out_date = models.DateField()
    number_of_guests = models.IntegerField()
    booking_status = models.CharField(max_length=20, choices=BOOKING_STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'reservations'
        verbose_name = 'Reservation'
        verbose_name_plural = 'Reservations'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['reservation_number']),
            models.Index(fields=['customer']),
            models.Index(fields=['room']),
            models.Index(fields=['check_in_date', 'check_out_date']),
            models.Index(fields=['booking_status']),
        ]
    
    def __str__(self):
        return f"Reservation {self.reservation_number} - {self.customer.full_name}"
    
    def clean(self):
        # Validate check-out date is after check-in date
        if self.check_out_date <= self.check_in_date:
            raise ValidationError({"check_out_date": "Check-out date must be after check-in date."})
        
        # Validate number of guests doesn't exceed room capacity
        if self.room and self.number_of_guests > self.room.capacity:
            raise ValidationError({"number_of_guests": f"Number of guests cannot exceed room capacity of {self.room.capacity}."})
        
        # Validate room is not in maintenance
        if self.room and self.room.status == 'maintenance':
            raise ValidationError({"room": "Cannot book a room that is under maintenance."})
        
        # Check for double booking (critical business rule)
        # Only check if room is set
        if self.room:
            overlapping_reservations = Reservation.objects.filter(
                room=self.room,
                booking_status__in=['pending', 'confirmed', 'completed']
            ).exclude(
                reservation_number=self.reservation_number if self.reservation_number else None
            ).filter(
                # Overlap condition: existing_check_in < requested_check_out AND existing_check_out > requested_check_in
                check_in_date__lt=self.check_out_date,
                check_out_date__gt=self.check_in_date
            )
            
            if overlapping_reservations.exists():
                raise ValidationError({
                    "room": "This room is already booked for the selected dates. Please choose different dates or another room."
                })
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)
