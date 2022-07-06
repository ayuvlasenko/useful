# syntax:docker/dockerfile:1
FROM node:16-alpine as builder
RUN apk add --no-cache bash
WORKDIR /build
COPY package*.json ./
RUN npm install
COPY src ./src
COPY nest-cli.json tsconfig.json tsconfig.build.json ./
RUN npm run build

FROM node:16-alpine
RUN apk add --no-cache bash
WORKDIR /app
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/dist .
CMD ["node", "/app/main.js"]
