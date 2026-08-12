from django.urls import path
from .views import CustomerListCreateView, CustomerDetailView, customer_search

urlpatterns = [
    path('search/', customer_search, name='customer-search'),
    path('', CustomerListCreateView.as_view(), name='customer-list-create'),
    path('<str:customer_id>/', CustomerDetailView.as_view(), name='customer-detail'),
]