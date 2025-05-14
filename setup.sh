#!/bin/bash

# Initialize Git repository
git init

# Copy example env file to .env
cp .env.example .env

# Create a first commit
git add .
git commit -m "Initial commit: n8n and InfluxDB stack"

echo "Repository initialized successfully!"
echo "To deploy on another machine:"
echo "1. git clone <your-repository-url>"
echo "2. cd n8n-influxdb-stack"
echo "3. cp .env.example .env (and edit as needed)"
echo "4. docker-compose up -d"
