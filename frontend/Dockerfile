# Build stage
FROM node:18 as build-stage

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build the application - CORREGIDO: usar la ruta correcta del output
RUN npm run build -- --configuration=production

# Production stage
FROM nginx:alpine

# Copy built app - CORREGIDO: usar la ruta correcta según angular.json
COPY --from=build-stage /app/dist/skysense-dashboard/ /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]