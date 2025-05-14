# n8n and InfluxDB Docker Stack

This repository contains a Docker Compose setup for running n8n workflow automation platform with InfluxDB for time-series data storage.

## Prerequisites

- Docker and Docker Compose installed
- Git (for cloning the repository)

## Quick Start

1. Clone this repository:
   ```
   git clone https://github.com/dvirchakim/iot_stack.git
   cd n8n-influxdb-stack
   ```

2. Start the stack:
   ```
   docker-compose up -d
   ```

3. Access the services:
   - n8n: http://localhost:5678
   - InfluxDB: http://localhost:8086

## Configuration

### InfluxDB

Default credentials:
- Username: admin
- Password: adminpassword
- Organization: myorg
- Bucket: sensors
- Token: my-super-secret-auth-token

**Important**: For production use, change these default values in the docker-compose.yml file.

### n8n

The n8n workflow included in this repository is configured to:
1. Receive webhook data from IoT devices
2. Process data based on device type (vs330, AM103, gs301, WS301)
3. Store the processed data in InfluxDB

## Importing the Workflow

1. Access n8n at http://localhost:5678
2. Go to Workflows > Import from file
3. Upload the `workflow.json` file from this repository

## Customization

- Modify the `workflow.json` file to adjust data processing for your specific device types
- Update InfluxDB configuration in docker-compose.yml for production environments

## Backup and Persistence

Data is persisted in Docker volumes:
- n8n_data: Contains n8n workflows and credentials
- influxdb_data: Contains InfluxDB data

To backup these volumes, use Docker's volume backup mechanisms.
