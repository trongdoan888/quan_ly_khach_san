from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from django.db.models import Q, Count, Sum
from datetime import datetime, timedelta
from .models import Reservation
from .serializers import ReservationSerializer, ReservationCreateSerializer, AvailabilitySerializer
from rooms.models import Room


class ReservationListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Reservation.objects.select_related('customer', 'room').all()
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['booking_status', 'room', 'customer']
    search_fields = ['reservation_number', 'customer__full_name']
    ordering_fields = ['check_in_date', 'created_at']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ReservationCreateSerializer
        return ReservationSerializer


class ReservationDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Reservation.objects.select_related('customer', 'room').all()
    serializer_class = ReservationSerializer
    lookup_field = 'reservation_number'
    
    def perform_update(self, serializer):
        # Both admin and staff can update reservations
        serializer.save()
    
    def perform_destroy(self, instance):
        # Only admins can delete reservations
        if self.request.user.role != 'admin':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only admins can delete reservations")
        instance.delete()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_availability(request):
    """
    Check room availability for given dates
    """
    check_in = request.query_params.get('check_in_date')
    check_out = request.query_params.get('check_out_date')
    room_id = request.query_params.get('room')
    number_of_guests = request.query_params.get('number_of_guests')
    
    if not check_in or not check_out:
        return Response(
            {"error": "check_in_date and check_out_date are required"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        from datetime import datetime
        check_in = datetime.strptime(check_in, '%Y-%m-%d').date()
        check_out = datetime.strptime(check_out, '%Y-%m-%d').date()
    except ValueError:
        return Response(
            {"error": "Invalid date format. Use YYYY-MM-DD"},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if check_out <= check_in:
        return Response(
            {"error": "Check-out date must be after check-in date."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Get all rooms that are not in maintenance
    available_rooms = Room.objects.filter(status__in=['available', 'occupied'])
    
    # If a specific room is provided, filter by it
    if room_id:
        available_rooms = available_rooms.filter(id=room_id)
    
    # Find rooms that have overlapping reservations (excluding cancelled)
    overlapping_reservations = Reservation.objects.filter(
        booking_status__in=['pending', 'confirmed', 'completed'],
        check_in_date__lt=check_out,
        check_out_date__gt=check_in
    ).values_list('room_id', flat=True)
    
    # Filter out rooms with overlapping reservations
    available_rooms = available_rooms.exclude(id__in=overlapping_reservations)
    
    # Filter by number of guests if provided
    if number_of_guests:
        available_rooms = available_rooms.filter(capacity__gte=number_of_guests)
    
    # Serialize the results
    from rooms.serializers import RoomSerializer
    serializer = RoomSerializer(available_rooms, many=True)
    
    return Response({
        "check_in_date": check_in,
        "check_out_date": check_out,
        "available_rooms": serializer.data,
        "total_available": available_rooms.count()
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def reservation_statistics(request):
    """
    Get reservation statistics for dashboard
    """
    from django.utils import timezone
    from rooms.models import Room
    
    today = timezone.now().date()
    
    # Total rooms
    total_rooms = Room.objects.count()
    
    # Available rooms (not in maintenance and not occupied today)
    available_rooms = Room.objects.filter(status='available').count()
    
    # Occupied rooms
    occupied_rooms = Room.objects.filter(status='occupied').count()
    
    # Active reservations (pending, confirmed, or currently staying)
    active_reservations = Reservation.objects.filter(
        booking_status__in=['pending', 'confirmed']
    ).count()
    
    # Today's check-ins
    today_checkins = Reservation.objects.filter(
        check_in_date=today,
        booking_status__in=['confirmed', 'completed']
    ).count()
    
    # Today's check-outs
    today_checkouts = Reservation.objects.filter(
        check_out_date=today,
        booking_status__in=['confirmed', 'completed']
    ).count()
    
    # Total customers
    from customers.models import Customer
    total_customers = Customer.objects.count()
    
    return Response({
        "total_rooms": total_rooms,
        "available_rooms": available_rooms,
        "occupied_rooms": occupied_rooms,
        "active_reservations": active_reservations,
        "total_customers": total_customers,
        "today_checkins": today_checkins,
        "today_checkouts": today_checkouts,
        "occupancy_rate": round((occupied_rooms / total_rooms * 100) if total_rooms > 0 else 0, 2)
    })