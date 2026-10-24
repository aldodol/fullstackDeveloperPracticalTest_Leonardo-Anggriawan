# Stage 1: Build & Dependencies
FROM node:22-alpine AS runner

WORKDIR /app

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy dependency manifests
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy application source code
COPY . .

# Expose API port
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Start application
CMD ["node", "src/server.js"]
