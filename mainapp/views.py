from django.shortcuts import render
import json
import requests
from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings

# Create your views here.
def index(request):
    return render(request, 'mainapp/index.html')

def coins(request):
    return render(request, 'mainapp/coins.html')

def guide(request):
    return render(request, 'mainapp/guide.html')

def docs(request):
    return render(request, 'mainapp/docs.html')

@csrf_exempt
def solana_proxy(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            response = requests.post(
                settings.SOLANA_RPC_URL,
                json=data,
                headers={'Content-Type': 'application/json'}
            )
            return JsonResponse(response.json())
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
    else:
        return JsonResponse({'error': 'Only POST requests are allowed.'}, status=405)

def health_check(request):
    return HttpResponse("OK")