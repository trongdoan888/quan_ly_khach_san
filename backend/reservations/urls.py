from django.urls import path
from .views import (
    ReservationListCreateView, ReservationDetailView,
    check_availability, reservation_statistics
)

urlpatterns = [
    path('check-availability/', check_availability, name='check-availability'),
    path('statistics/', reservation_statistics, name='reservation-statistics'),
    path('', ReservationListCreateView.as_view(), name='reservation-list-create'),
    path('<str:reservation_number>/', ReservationDetailView.as_view(), name='reservation-detail'),
]