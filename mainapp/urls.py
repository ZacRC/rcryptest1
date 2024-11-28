from django.urls import path
from . import views
from django.contrib import admin

urlpatterns = [
    path('', views.index, name='index'),
    path('coins', views.coins, name='coins'),
    path('guide', views.guide, name='guide'),
    path('docs', views.docs, name='docs'),
    path('api/solana/', views.solana_proxy, name='solana_proxy'),
    path('admin/', admin.site.urls),
    path('health/', views.health_check, name='health_check'),
]
