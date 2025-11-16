# Build stage
FROM node:18 as build-stage

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application - CORREGIDO: solo producción sin estilos problemáticos
RUN npm run build -- --configuration=production

# Production stage
FROM nginx:alpine

# Copy built app
COPY --from=build-stage /app/dist/skysense-dashboard/ /usr/share/nginx/html/

# Copy nginx config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
