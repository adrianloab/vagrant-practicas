#!/bin/bash
# ============================================================
# Script de Health-Check del cluster k3s
# Se ejecuta cada 5 minutos vía cron
# Extra: +0.5 puntos - Monitorización
# ============================================================

echo "========================================"
echo "  K3s Cluster Health Check"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

ERRORS=0

# ----------------------------------------------------------
# 1. Verificar que el servicio k3s está activo
# ----------------------------------------------------------
echo ""
echo ">>> Verificando servicio k3s..."
if systemctl is-active --quiet k3s; then
    echo "  [OK] k3s server está activo"
else
    echo "  [ERROR] k3s server NO está activo"
    ERRORS=$((ERRORS + 1))
fi

# ----------------------------------------------------------
# 2. Verificar estado de los nodos
# ----------------------------------------------------------
echo ""
echo ">>> Verificando nodos del cluster..."
NODES=$(kubectl get nodes --no-headers 2>/dev/null)
if [ $? -eq 0 ]; then
    TOTAL=$(echo "$NODES" | wc -l)
    READY=$(echo "$NODES" | grep -c " Ready")
    NOT_READY=$((TOTAL - READY))
    
    echo "  Nodos totales: $TOTAL"
    echo "  Nodos Ready:   $READY"
    echo "  Nodos NotReady: $NOT_READY"
    
    if [ "$NOT_READY" -gt 0 ]; then
        echo "  [AVISO] Hay nodos no disponibles:"
        echo "$NODES" | grep -v " Ready" | while read line; do
            echo "    - $line"
        done
        ERRORS=$((ERRORS + 1))
    else
        echo "  [OK] Todos los nodos están Ready"
    fi
else
    echo "  [ERROR] No se puede conectar al API server"
    ERRORS=$((ERRORS + 1))
fi

# ----------------------------------------------------------
# 3. Verificar pods de la aplicación
# ----------------------------------------------------------
echo ""
echo ">>> Verificando pods de la aplicación..."
PODS=$(kubectl get pods -n default --no-headers 2>/dev/null)
if [ $? -eq 0 ]; then
    RUNNING=$(echo "$PODS" | grep -c "Running")
    NOT_RUNNING=$(echo "$PODS" | grep -vc "Running" || true)
    
    echo "  Pods Running:     $RUNNING"
    echo "  Pods No-Running:  $NOT_RUNNING"
    
    if [ "$NOT_RUNNING" -gt 0 ]; then
        echo "  [AVISO] Hay pods con problemas:"
        echo "$PODS" | grep -v "Running" | while read line; do
            echo "    - $line"
        done
    else
        echo "  [OK] Todos los pods están Running"
    fi
else
    echo "  [ERROR] No se pueden listar los pods"
    ERRORS=$((ERRORS + 1))
fi

# ----------------------------------------------------------
# 4. Verificar servicios
# ----------------------------------------------------------
echo ""
echo ">>> Verificando servicios..."
kubectl get svc -n default --no-headers 2>/dev/null | while read line; do
    SVC_NAME=$(echo "$line" | awk '{print $1}')
    SVC_TYPE=$(echo "$line" | awk '{print $2}')
    SVC_PORTS=$(echo "$line" | awk '{print $5}')
    echo "  [OK] $SVC_NAME ($SVC_TYPE) - $SVC_PORTS"
done

# ----------------------------------------------------------
# 5. Verificar conectividad de la app web
# ----------------------------------------------------------
echo ""
echo ">>> Verificando aplicación web (HTTP)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:30080 2>/dev/null)
if [ "$HTTP_CODE" = "200" ]; then
    echo "  [OK] Webapp HTTP responde (código $HTTP_CODE)"
else
    echo "  [AVISO] Webapp HTTP no responde (código $HTTP_CODE)"
    ERRORS=$((ERRORS + 1))
fi

# ----------------------------------------------------------
# 6. Verificar conectividad entre nodos
# ----------------------------------------------------------
echo ""
echo ">>> Verificando conectividad entre nodos..."
for NODE_IP in 192.168.56.10 192.168.56.11 192.168.56.12; do
    if ping -c 1 -W 2 "$NODE_IP" > /dev/null 2>&1; then
        echo "  [OK] $NODE_IP responde al ping"
    else
        echo "  [ERROR] $NODE_IP no responde"
        ERRORS=$((ERRORS + 1))
    fi
done

# ----------------------------------------------------------
# Resumen
# ----------------------------------------------------------
echo ""
echo "========================================"
if [ "$ERRORS" -eq 0 ]; then
    echo "  RESULTADO: TODO OK - Sin errores"
else
    echo "  RESULTADO: $ERRORS problema(s) detectado(s)"
fi
echo "========================================"
