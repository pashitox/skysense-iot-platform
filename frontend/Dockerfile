FROM node:18 as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=build /app/dist/skysense-dashboard ./dist/skysense-dashboard
COPY --from=build /app/server.js ./
COPY --from=build /app/package.json ./

RUN npm install express

EXPOSE 80
CMD ["node", "server.js"]
