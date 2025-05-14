#!/bin/bash

echo -e "\e[32mStarting n8n and InfluxDB Docker stack...\e[0m"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "\e[31mError: Docker is not running. Please start Docker and try again.\e[0m"
    exit 1
fi

# Start the Docker Compose stack
echo -e "\e[33mStarting containers...\e[0m"
docker-compose up -d

if [ $? -eq 0 ]; then
    echo -e "\n\e[32mDocker stack started successfully!\e[0m"
    echo -e "\nServices available at:"
    echo "- n8n: http://localhost:5678"
    echo "- InfluxDB: http://localhost:8086"
    echo -e "\nTo import the workflow in n8n:"
    echo "1. Go to http://localhost:5678"
    echo "2. Navigate to Workflows > Import from file"
    echo "3. Upload the workflow.json file"
else
    echo -e "\n\e[31mFailed to start Docker stack. Check the error messages above.\e[0m"
fi
