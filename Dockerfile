FROM node:22-alpine

WORKDIR /app

# Install dependencies needed for native modules / Prisma
RUN apk add --no-cache openssl libc6-compat

# Copy package manifests
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy Prisma schema and generate client
COPY prisma ./prisma
RUN npx prisma generate

# Copy application source
COPY . .

# Expose server port
EXPOSE 8000

ENV PORT=8000
ENV NODE_ENV=production

CMD ["node", "src/server.js"]

