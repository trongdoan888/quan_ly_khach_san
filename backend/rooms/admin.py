from django.contrib import admin
from .models import Room, RoomType


@admin.register(RoomType)
class RoomTypeAdmin(admin.ModelAdmin):
    list_display = ['name', 'base_price', 'created_at']
    search_fields = ['name', 'description']
    ordering = ['name']


@admin.register(Room)
class RoomAdmin(admin.ModelAdmin):
    list_display = ['room_number', 'room_type', 'floor', 'capacity', 'price_per_night', 'status', 'created_at']
    list_filter = ['status', 'room_type', 'floor']
    search_fields = ['room_number', 'description']
    ordering = ['room_number']
    readonly_fields = ['created_at', 'updated_at']