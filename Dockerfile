FROM node:14.21.3-bullseye AS build

WORKDIR /app

COPY package*.json ./
RUN npm install -g npm@8.19.4 && npm ci

COPY . .
RUN npm run build -- --configuration production

FROM nginx:1.25-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/CajaFrontend /usr/share/nginx/html

EXPOSE 80

