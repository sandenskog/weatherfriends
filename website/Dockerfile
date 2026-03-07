FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --production

COPY server.js ./
COPY views/ ./views/
COPY public/ ./public/
COPY .well-known/ ./.well-known/

EXPOSE 80

CMD ["node", "server.js"]
