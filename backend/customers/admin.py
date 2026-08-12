from django.contrib import admin
from .models import Customer


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ['customer_id', 'full_name', 'email', 'phone', 'created_at']
    search_fields = ['customer_id', 'full_name', 'email', 'phone']
    ordering = ['full_name']
    readonly_fields = ['customer_id', 'created_at', 'updated_at']