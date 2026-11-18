FROM node:20-alpine

WORKDIR /app

# Install dependencies required for Prisma engines
RUN apk add --no-cache openssl

# Copy package manifests & prisma schema
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies and generate Prisma client
RUN npm install --production=false
RUN npx prisma generate

# Copy source code
COPY . .

# Set default production environment
ENV NODE_ENV=production
ENV PORT=4000

EXPOSE 4000

CMD ["node", "src/server.js"]

