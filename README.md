# n8n and InfluxDB Docker Stack for IoT Sensor Data

This repository contains a complete Docker Compose setup for running n8n workflow automation platform with InfluxDB for time-series data storage, specifically designed for IoT sensor data processing.

## Features

- **Automated IoT Data Processing**: Process data from different sensor types (vs330, AM103, gs301, WS301)
- **Webhook Integration**: Receive data via webhooks and process based on device type
- **Time-Series Storage**: Store processed sensor data in InfluxDB for analysis and visualization
- **Easy Deployment**: Simple setup with Docker Compose
- **Automated Workflow Import**: Scripts to automatically import the workflow into n8n

## Prerequisites

- Docker and Docker Compose installed
- Git (for cloning the repository)

## Quick Start

### Linux/macOS

1. Clone this repository:
   ```bash
   git clone https://github.com/dvirchakim/iot_stack.git
   cd iot_stack
   ```

2. Start the stack:
   ```bash
   chmod +x start.sh
   ./start.sh
   ```

3. Import the workflow:
   ```bash
   chmod +x import-workflow.sh
   ./import-workflow.sh
   ```

### Windows

1. Clone this repository:
   ```powershell
   git clone https://github.com/dvirchakim/iot_stack.git
   cd iot_stack
   ```

2. Start the stack:
   ```powershell
   .\start.ps1
   ```

3. Import the workflow:
   ```powershell
   .\import-workflow.ps1
   ```

## Access the Services

- **n8n**: http://localhost:5678
  - Default credentials: admin@example.com / password123
- **InfluxDB**: http://localhost:8087
  - Default credentials: admin / adminpassword

## Configuration

### Environment Variables

The stack uses environment variables for configuration. You can modify these in the `.env` file:

```bash
# n8n Configuration
N8N_HOST=n8n
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678/
GENERIC_TIMEZONE=UTC

# InfluxDB Configuration
INFLUXDB_USERNAME=admin
INFLUXDB_PASSWORD=adminpassword
INFLUXDB_ORG=myorg
INFLUXDB_BUCKET=sensors
INFLUXDB_TOKEN=my-super-secret-auth-token
```

### Sensor Data Processing

The workflow is configured to process data from four different sensor types:

1. **VS330**: Temperature/humidity sensor
2. **AM103**: Air quality sensor (CO2, TVOC, PM2.5)
3. **GS301**: Soil sensor (moisture, temperature, conductivity)
4. **WS301**: Weather station (temperature, humidity, pressure, wind, rainfall)

Each sensor type has its own processing logic in the n8n workflow.

## Webhook Endpoints

The workflow exposes a webhook endpoint for receiving sensor data:

```bash
http://your-server:5678/webhook/9155033d-6ed0-47cb-aa97-967d5822f58e
```

Send a POST request with the following JSON structure:

```json
{
  "body": {
    "deviceInfo": {
      "deviceName": "Sensor-123",
      "deviceProfileName": "vs330",  // or "AM103", "gs301", "WS301"
      "devEui": "1234567890abcdef"
    },
    "time": "2023-01-01T12:00:00Z",
    "object": {
      "temperature": 25.5,
      "humidity": 60,
      "battery": 95
      // Other sensor-specific fields
    }
  }
}
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**: If you see errors about ports already in use, edit the `docker-compose.yml` file to change the port mappings.

2. **n8n Secure Cookie Error**: If you see a message about secure cookies, this is already handled in the configuration. Access n8n using `http://localhost:5678`.

3. **Workflow Import Fails**: Run the import script after n8n is fully started. The script will retry several times, but if it still fails, check if n8n is running properly.

4. **Container Startup Issues**: Check container logs with:
   ```bash
   docker-compose logs n8n
   docker-compose logs influxdb
   ```

### Restarting the Stack

If you need to restart the stack:

```bash
docker-compose down
docker-compose up -d
```

Then run the import script again if needed.

## Backup and Persistence

Data is persisted in Docker volumes:
- **n8n_data**: Contains n8n workflows and credentials
- **influxdb_data**: Contains InfluxDB data

To backup these volumes:

```bash
docker run --rm -v n8n_data:/source -v $(pwd):/backup alpine tar -czf /backup/n8n_data_backup.tar.gz -C /source .
docker run --rm -v influxdb_data:/source -v $(pwd):/backup alpine tar -czf /backup/influxdb_data_backup.tar.gz -C /source .
```

## Security Considerations

For production use:
1. Change all default passwords and tokens in the `.env` file
2. Consider setting up HTTPS with a reverse proxy
3. Restrict network access to the services
4. Use a more secure authentication method for n8n

## License

This project is open source and available for use and modification.
