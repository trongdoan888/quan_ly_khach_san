from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q
from .models import Room, RoomType
from .serializers import RoomSerializer, RoomTypeSerializer, RoomSearchSerializer


class RoomTypeListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]  # Changed from [IsAuthenticated, IsAdminUser]
    queryset = RoomType.objects.all()
    serializer_class = RoomTypeSerializer


class RoomTypeDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, IsAdminUser]
    queryset = RoomType.objects.all()
    serializer_class = RoomTypeSerializer


class RoomListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Room.objects.select_related('room_type').all()
    serializer_class = RoomSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['room_type', 'status', 'floor', 'capacity']
    search_fields = ['room_number', 'description']
    ordering_fields = ['room_number', 'price_per_night', 'floor']
    ordering = ['room_number']


class RoomDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, IsAdminUser]
    queryset = Room.objects.select_related('room_type').all()
    serializer_class = RoomSerializer


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def room_search(request):
    """
    Advanced room search with multiple filters
    """
    serializer = RoomSearchSerializer(data=request.query_params)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    queryset = Room.objects.select_related('room_type').all()
    
    # Apply filters
    data = serializer.validated_data
    
    if data.get('room_type'):
        queryset = queryset.filter(room_type_id=data['room_type'])
    
    if data.get('min_price'):
        queryset = queryset.filter(price_per_night__gte=data['min_price'])
    
    if data.get('max_price'):
        queryset = queryset.filter(price_per_night__lte=data['max_price'])
    
    if data.get('min_capacity'):
        queryset = queryset.filter(capacity__gte=data['min_capacity'])
    
    if data.get('max_capacity'):
        queryset = queryset.filter(capacity__lte=data['max_capacity'])
    
    if data.get('status'):
        queryset = queryset.filter(status=data['status'])
    
    if data.get('room_number'):
        queryset = queryset.filter(room_number__icontains=data['room_number'])
    
    serializer = RoomSerializer(queryset, many=True)
    return Response(serializer.data)