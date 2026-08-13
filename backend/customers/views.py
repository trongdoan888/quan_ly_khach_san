from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from django.db.models import Q
from .models import Customer
from .serializers import CustomerSerializer


class CustomerListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['email', 'phone']
    search_fields = ['full_name', 'email', 'customer_id', 'address']
    ordering_fields = ['full_name', 'created_at']
    ordering = ['full_name']
    
    def perform_create(self, serializer):
        # Only admins can create customers
        if self.request.user.role != 'admin':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only admins can create customers")
        serializer.save()


class CustomerDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer
    lookup_field = 'customer_id'
    
    def perform_update(self, serializer):
        # Only admins can update customers
        if self.request.user.role != 'admin':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only admins can update customers")
        serializer.save()
    
    def perform_destroy(self, instance):
        # Only admins can delete customers
        if self.request.user.role != 'admin':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only admins can delete customers")
        instance.delete()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_search(request):
    """
    Advanced customer search
    """
    search_query = request.query_params.get('search', '')
    if not search_query:
        return Response({"error": "Search query is required"}, status=status.HTTP_400_BAD_REQUEST)
    
    queryset = Customer.objects.filter(
        Q(full_name__icontains=search_query) |
        Q(email__icontains=search_query) |
        Q(customer_id__icontains=search_query) |
        Q(phone__icontains=search_query) |
        Q(address__icontains=search_query)
    )
    
    serializer = CustomerSerializer(queryset, many=True)
    return Response(serializer.data)