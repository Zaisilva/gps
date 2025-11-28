#!/bin/bash

echo "Iniciando Blue-Green Deployment..."

# Variables
IMAGE_NAME="gps-backend"
PORT_BLUE=3001
PORT_GREEN=3002

# Detectar cuál está activo actualmente
ACTIVE_ENV=$(cat /tmp/active_env 2>/dev/null || echo "none")

echo "Ambiente activo actual: $ACTIVE_ENV"

# Determinar el nuevo ambiente
if [ "$ACTIVE_ENV" == "blue" ]; then
    NEW_ENV="green"
    NEW_PORT=$PORT_GREEN
    OLD_ENV="blue"
    OLD_PORT=$PORT_BLUE
else
    NEW_ENV="blue"
    NEW_PORT=$PORT_BLUE
    OLD_ENV="green"
    OLD_PORT=$PORT_GREEN
fi

echo "Desplegando en ambiente: $NEW_ENV (puerto $NEW_PORT)"

# Construir nueva imagen
echo "Construyendo imagen Docker..."
docker build -t ${IMAGE_NAME}:${NEW_ENV} .

# Detener y eliminar contenedor anterior del nuevo ambiente (si existe)
echo "Limpiando ambiente $NEW_ENV..."
docker stop backend-app-${NEW_ENV} 2>/dev/null || true
docker rm backend-app-${NEW_ENV} 2>/dev/null || true

# Iniciar nuevo contenedor con la variable de entorno correcta
echo "Iniciando contenedor en ambiente $NEW_ENV..."
docker run -d \
  --name backend-app-${NEW_ENV} \
  -p ${NEW_PORT}:${NEW_PORT} \
  -e DEPLOY_ENV=${NEW_ENV} \
  --restart unless-stopped \
  ${IMAGE_NAME}:${NEW_ENV}

# Esperar a que el contenedor esté listo
echo "Esperando que el servicio esté listo..."
sleep 5

# Verificar que el nuevo contenedor funciona
echo "Verificando salud del nuevo ambiente..."
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${NEW_PORT}/api/health)

if [ "$HEALTH_CHECK" != "200" ]; then
    echo "ERROR: El nuevo ambiente no responde correctamente"
    echo "Rollback: manteniendo ambiente $OLD_ENV activo"
    docker stop backend-app-${NEW_ENV}
    docker rm backend-app-${NEW_ENV}
    exit 1
fi

echo "Nuevo ambiente funcionando correctamente"

# Cambiar NGINX para apuntar al nuevo ambiente
echo "Cambiando tráfico a ambiente $NEW_ENV..."

# Crear configuración de NGINX
sudo tee /etc/nginx/sites-available/backend-${NEW_ENV}.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location /