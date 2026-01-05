# Sample API Application

A simple Flask-based REST API for testing the backend infrastructure.

## Features

- **Health Check**: `/api/health` - For Application Gateway health probes
- **Service Info**: `/api/info` - Information about the service
- **Test Endpoint**: `/api/test` - Returns sample test data
- **Echo Endpoint**: `/api/echo` - Echoes POST request body
- **Environment**: `/api/environment` - Shows non-sensitive environment variables

## API Endpoints

### GET /
Welcome message with available endpoints

**Response**:
```json
{
  "message": "Welcome to ZTF Sample API",
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2025-12-30T10:00:00.000000",
  "endpoints": {...}
}
```

### GET /api/health
Health check endpoint (used by Application Gateway probe)

**Response**:
```json
{
  "status": "healthy",
  "service": "sample-api",
  "timestamp": "2025-12-30T10:00:00.000000"
}
```

### GET /api/info
Service information and available endpoints

**Response**:
```json
{
  "service": "sample-api",
  "version": "1.0.0",
  "environment": "Production",
  "endpoints": [...]
}
```

### GET /api/test
Test endpoint with sample data

**Response**:
```json
{
  "message": "Test endpoint working correctly",
  "status": "success",
  "data": {...}
}
```

### POST /api/echo
Echo the posted JSON data

**Request Body**:
```json
{
  "key": "value",
  "data": "sample"
}
```

**Response**:
```json
{
  "message": "Echo successful",
  "received_data": {...},
  "timestamp": "2025-12-30T10:00:00.000000"
}
```

### GET /api/environment
Display non-sensitive environment variables

**Response**:
```json
{
  "message": "Environment variables (non-sensitive)",
  "environment": {...}
}
```

## Local Development

### Prerequisites
- Python 3.11+
- pip

### Setup

1. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the application:
```bash
python app.py
```

4. Test locally:
```bash
curl http://localhost:80/api/health
```

## Docker Build

### Build Image
```bash
docker build -t sample-api:latest .
```

### Run Container
```bash
docker run -p 8080:80 sample-api:latest
```

### Test Container
```bash
curl http://localhost:8080/api/health
```

## Deploy to Azure

### Push to Azure Container Registry

```bash
# Login to Azure and ACR
az login
az acr login --name <your-acr-name>

# Build and push
docker build -t sample-api:latest .
docker tag sample-api:latest <your-acr-name>.azurecr.io/sample-api:latest
docker push <your-acr-name>.azurecr.io/sample-api:latest
```

### Update Container App

```bash
az containerapp update \
  --name <container-app-name> \
  --resource-group <resource-group> \
  --image <your-acr-name>.azurecr.io/sample-api:latest
```

## Testing

### Using cURL

```bash
# Health check
curl https://<app-gateway-ip>/api/health

# Get info
curl https://<app-gateway-ip>/api/info

# Test endpoint
curl https://<app-gateway-ip>/api/test

# Echo endpoint
curl -X POST https://<app-gateway-ip>/api/echo \
  -H "Content-Type: application/json" \
  -d '{"test": "data", "number": 123}'

# Environment variables
curl https://<app-gateway-ip>/api/environment
```

### Using PowerShell

```powershell
# Health check
Invoke-WebRequest -Uri "https://<app-gateway-ip>/api/health" -SkipCertificateCheck

# Test endpoint
Invoke-WebRequest -Uri "https://<app-gateway-ip>/api/test" -SkipCertificateCheck

# Echo endpoint
$body = @{
    test = "data"
    number = 123
} | ConvertTo-Json

Invoke-WebRequest -Uri "https://<app-gateway-ip>/api/echo" `
  -Method POST `
  -Body $body `
  -ContentType "application/json" `
  -SkipCertificateCheck
```

## Environment Variables

The application reads the following environment variables (configured in Container App):

- `Common__environment` - Environment name (Production, Development, etc.)
- `SeverMode__ServerType` - Server type (azure, local, etc.)
- `CosmosDb__DatabaseName` - Database name
- `AzureBlobSettings__ContainerName` - Blob container name
- `EmailSettings__SendEmailStatus` - Email enabled status
- `EmailSettings__SenderEmail` - Sender email address

**Note**: Sensitive variables (keys, passwords, connection strings) are not displayed by the `/api/environment` endpoint.

## Monitoring

### View Logs in Azure

```bash
az containerapp logs show \
  --name <container-app-name> \
  --resource-group <resource-group> \
  --follow
```

### Check Health Status

```bash
curl https://<app-gateway-ip>/api/health
```

Expected response: `{"status": "healthy", ...}`

## Troubleshooting

### Container fails to start
- Check logs: `az containerapp logs show ...`
- Verify image was pushed to ACR
- Check ACR credentials in Container App

### Health probe fails
- Test health endpoint directly: `curl http://localhost:80/api/health`
- Check path is `/` or `/api/health` in Application Gateway probe
- Verify port 80 is exposed

### 502 Bad Gateway from Application Gateway
- Container App may not be running
- Health probe path incorrect
- Backend pool FQDN incorrect
- Container App must be accessible from App Gateway subnet

## License

This is a sample application for testing purposes.
