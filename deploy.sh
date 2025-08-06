#!/bin/bash

# IT Helpdesk AI System Deployment Script for Linux
# This script deploys the complete IT Helpdesk AI system using Docker Compose

set -e

echo "========================================"
echo "IT Helpdesk AI System Deployment Script"
echo "========================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. Consider using a non-root user with Docker permissions."
fi

# Check if Docker is installed
print_status "[1/8] Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    echo "Please install Docker and try again"
    echo "Installation guide: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    echo "Please start Docker daemon and try again"
    echo "Try: sudo systemctl start docker"
    exit 1
fi

print_success "Docker is installed and running"
echo

# Check Docker Compose
print_status "[2/8] Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available"
    echo "Please install Docker Compose and try again"
    exit 1
fi

print_success "Docker Compose is available"
echo

# Create necessary directories
print_status "[3/8] Creating directories..."
mkdir -p logs data
print_success "Directories created"
echo

# Set environment variables
print_status "[4/8] Setting up environment..."
export COMPOSE_PROJECT_NAME=it-helpdesk-ai
export DOCKER_BUILDKIT=1
print_success "Environment configured"
echo

# Pull latest images
print_status "[5/8] Pulling Docker images..."
echo "This may take several minutes depending on your internet connection..."
if ! docker compose pull; then
    print_warning "Some images failed to pull, continuing with build..."
fi
echo

# Build custom images
print_status "[6/8] Building custom images..."
if ! docker compose build; then
    print_error "Failed to build images"
    exit 1
fi
print_success "Images built successfully"
echo

# Start services
print_status "[7/8] Starting services..."
if ! docker compose up -d; then
    print_error "Failed to start services"
    echo "Checking logs..."
    docker compose logs
    exit 1
fi
echo

# Wait for services to be ready
print_status "[8/8] Waiting for services to start..."
sleep 30

# Check service status
print_status "Checking service status..."
docker compose ps

echo
echo "========================================"
print_success "Deployment completed successfully!"
echo "========================================"
echo
echo "Service URLs:"
echo "- Main Application: http://localhost"
echo "- n8n Workflow Editor: http://localhost/n8n"
echo "- Knowledge Base (BookStack): http://localhost/knowledge"
echo "- Ticketing System (osTicket): http://localhost/tickets"
echo
echo "Default Credentials:"
echo "- n8n: admin / admin123"
echo "- BookStack: admin@admin.com / password (set during first setup)"
echo "- osTicket: Configure during first setup"
echo
echo "Management Commands:"
echo "- Stop system: docker compose down"
echo "- View logs: docker compose logs"
echo "- Restart: docker compose restart"
echo "- Update: git pull && docker compose pull && docker compose up -d"
echo

# Configure firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    print_status "Configuring firewall..."
    if ufw status | grep -q "Status: active"; then
        if ! ufw status | grep -q "80/tcp"; then
            if ufw allow 80/tcp &> /dev/null; then
                print_success "Firewall rule added for port 80"
            else
                print_warning "Failed to add firewall rule for port 80"
            fi
        else
            print_success "Firewall rule for port 80 already exists"
        fi
    else
        print_warning "UFW firewall is not active"
    fi
fi

echo
print_success "System is ready! Open http://localhost in your browser"
echo

# Show system resource usage
print_status "System resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

