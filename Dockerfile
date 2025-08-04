# Dockerfile for Node.js Application
# This Dockerfile uses multi-stage builds to optimize the final image size


# ---------- Stage 1: build ----------
# Use official Node.js LTS as base    
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package definition files
COPY package*.json ./

# Install dependencies
# (Use npm ci for production builds if you have a package-lock.json)
RUN npm install

# Copy the rest of the application code
# (This assumes your app is in the same directory as the Dockerfile)
COPY . .
# (If you eventually add a React/Vue frontend, run npm run build here)

# ---------- Stage 2: runtime ----------
# Use a lightweight Node.js image for runtime
# This stage will only contain the built application
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy only the necessary files from the builder stage
COPY --from=builder /app .

# app listens inside container on 8888
EXPOSE 3033

# Run the app
CMD ["node", "server.js"]