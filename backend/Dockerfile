FROM python:3.9-slim

WORKDIR /app

# Copiar requirements primero (para cache de Docker)
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar TODO el contenido del backend
COPY . .

# Verificar que main.py existe
RUN ls -la /app/

EXPOSE 8000

CMD ["python", "main.py"]