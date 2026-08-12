from django.urls import path
from .views import (
    RoomTypeListCreateView, RoomTypeDetailView,
    RoomListCreateView, RoomDetailView, room_search
)

urlpatterns = [
    path('types/', RoomTypeListCreateView.as_view(), name='room-type-list-create'),
    path('types/<int:pk>/', RoomTypeDetailView.as_view(), name='room-type-detail'),
    path('', RoomListCreateView.as_view(), name='room-list-create'),
    path('<int:pk>/', RoomDetailView.as_view(), name='room-detail'),
    path('search/', room_search, name='room-search'),
]