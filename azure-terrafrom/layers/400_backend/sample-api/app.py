from flask import Flask, jsonify, request
import os
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    """Root endpoint - Welcome message"""
    return jsonify({
        "message": "Welcome to ZTF Sample API",
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat(),
        "endpoints": {
            "health": "/api/health",
            "info": "/api/info",
            "test": "/api/test",
            "echo": "/api/echo (POST)",
            "environment": "/api/environment"
        }
    }), 200


@app.route('/api/health')
def health():
    """Health check endpoint for Application Gateway probe"""
    return jsonify({
        "status": "healthy",
        "service": "sample-api",
        "timestamp": datetime.utcnow().isoformat()
    }), 200


@app.route('/api/info')
def info():
    """Information about the service and environment"""
    return jsonify({
        "service": "sample-api",
        "version": "1.0.0",
        "environment": os.getenv("Common__environment", "unknown"),
        "server_type": os.getenv("SeverMode__ServerType", "unknown"),
        "endpoints": [
            {"path": "/", "method": "GET", "description": "Welcome message"},
            {"path": "/api/health", "method": "GET", "description": "Health check"},
            {"path": "/api/info", "method": "GET", "description": "Service information"},
            {"path": "/api/test", "method": "GET", "description": "Test endpoint"},
            {"path": "/api/echo", "method": "POST", "description": "Echo request body"},
            {"path": "/api/environment", "method": "GET", "description": "Environment variables"}
        ],
        "timestamp": datetime.utcnow().isoformat()
    }), 200


@app.route('/api/test')
def test():
    """Test endpoint with sample data"""
    return jsonify({
        "message": "Test endpoint working correctly",
        "status": "success",
        "data": {
            "key1": "value1",
            "key2": "value2",
            "array": [1, 2, 3, 4, 5],
            "nested": {
                "item1": "data1",
                "item2": "data2"
            }
        },
        "timestamp": datetime.utcnow().isoformat()
    }), 200


@app.route('/api/echo', methods=['POST'])
def echo():
    """Echo endpoint - returns the posted data"""
    try:
        data = request.get_json()
        return jsonify({
            "message": "Echo successful",
            "received_data": data,
            "timestamp": datetime.utcnow().isoformat()
        }), 200
    except Exception as e:
        return jsonify({
            "error": "Invalid JSON",
            "message": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }), 400


@app.route('/api/environment')
def environment():
    """Display non-sensitive environment variables"""
    safe_env_vars = {
        "Common__environment": os.getenv("Common__environment", "not set"),
        "SeverMode__ServerType": os.getenv("SeverMode__ServerType", "not set"),
        "CosmosDb__DatabaseName": os.getenv("CosmosDb__DatabaseName", "not set"),
        "AzureBlobSettings__ContainerName": os.getenv("AzureBlobSettings__ContainerName", "not set"),
        "EmailSettings__SendEmailStatus": os.getenv("EmailSettings__SendEmailStatus", "not set"),
        "EmailSettings__SenderEmail": os.getenv("EmailSettings__SenderEmail", "not set")
    }

    return jsonify({
        "message": "Environment variables (non-sensitive)",
        "environment": safe_env_vars,
        "timestamp": datetime.utcnow().isoformat()
    }), 200


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        "error": "Not Found",
        "message": "The requested endpoint does not exist",
        "available_endpoints": ["/", "/api/health", "/api/info", "/api/test", "/api/echo", "/api/environment"],
        "timestamp": datetime.utcnow().isoformat()
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        "error": "Internal Server Error",
        "message": "An unexpected error occurred",
        "timestamp": datetime.utcnow().isoformat()
    }), 500


if __name__ == '__main__':
    port = int(os.getenv('PORT', 80))
    app.run(host='0.0.0.0', port=port, debug=False)
