from django.db import models
import re
import uuid


class Customer(models.Model):
    customer_id = models.CharField(max_length=20, unique=True, primary_key=True, editable=False)
    full_name = models.CharField(max_length=200)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20)
    address = models.TextField()
    government_id_number = models.CharField(max_length=50, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'customers'
        verbose_name = 'Customer'
        verbose_name_plural = 'Customers'
        ordering = ['full_name']
        indexes = [
            models.Index(fields=['customer_id']),
            models.Index(fields=['email']),
            models.Index(fields=['government_id_number']),
        ]
    
    def __str__(self):
        return f"{self.full_name} ({self.customer_id})"
    
    def save(self, *args, **kwargs):
        if not self.customer_id:
            self.customer_id = f"CUST-{uuid.uuid4().hex[:10].upper()}"
        super().save(*args, **kwargs)
    
    def get_masked_government_id(self):
        """Return masked government ID for display purposes"""
        if len(self.government_id_number) <= 4:
            return "****"
        return self.government_id_number[:2] + "*" * (len(self.government_id_number) - 4) + self.government_id_number[-2:]
