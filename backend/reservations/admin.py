from django.contrib import admin
from .models import Reservation


@admin.register(Reservation)
class ReservationAdmin(admin.ModelAdmin):
    list_display = ['reservation_number', 'customer', 'room', 'check_in_date', 'check_out_date', 'booking_status', 'created_at']
    list_filter = ['booking_status', 'check_in_date', 'check_out_date', 'room']
    search_fields = ['reservation_number', 'customer__full_name', 'room__room_number']
    ordering = ['-created_at']
    readonly_fields = ['reservation_number', 'created_at', 'updated_at']