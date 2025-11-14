#!/bin/bash

# SkySense - Script de Verificación Simple
# Verifica que la aplicación esté funcionando

echo "🔍 Verificando SkySense IoT Platform..."
echo "======================================"

# 1. Verificar pods
echo ""
echo "1. 📊 Estado de los pods:"
kubectl get pods -n skysense

# 2. Verificar servicios
echo ""
echo "2. 🌐 Estado de los servicios:"
kubectl get services -n skysense

# 3. Verificar logs del backend
echo ""
echo "3. 📝 Logs del backend:"
kubectl logs -n skysense -l app=backend --tail=3 2>/dev/null || echo "   Backend aún no tiene logs"

# 4. Verificar logs del frontend
echo ""
echo "4. 📝 Logs del frontend:"
kubectl logs -n skysense -l app=frontend --tail=2 2>/dev/null || echo "   Frontend aún no tiene logs"

# 5. URL de acceso
echo ""
echo "5. 🚀 Para acceder a la aplicación:"
echo "   minikube service frontend-service -n skysense"
echo ""
echo "   O visita: http://192.168.49.2:$(kubectl get service frontend-service -n skysense -o jsonpath='{.spec.ports[0].nodePort}')"

echo ""
echo "✅ Verificación completada"