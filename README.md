# IT Helpdesk AI System

A comprehensive IT support system powered by n8n automation, featuring a modern frontend, knowledge base, and ticketing system.

## 🏗️ Architecture

- **n8n**: Workflow automation and orchestration
- **Frontend**: Modern web interface with dark theme
- **BookStack**: Knowledge base management
- **osTicket**: Ticketing system
- **PostgreSQL**: Database for n8n
- **MySQL**: Database for BookStack and osTicket
- **Nginx**: Reverse proxy and load balancer

## 🚀 Quick Start

### Windows Deployment

1. Ensure Docker Desktop is installed and running
2. Clone or download this repository
3. Open Command Prompt as Administrator
4. Navigate to the project directory
5. Run the deployment script:
   ```cmd
   deploy.bat
   ```

### Linux Deployment

1. Ensure Docker and Docker Compose are installed
2. Clone or download this repository
3. Navigate to the project directory
4. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

## 🌐 Access URLs

After successful deployment, access the system via:

- **Main Application**: http://localhost
- **n8n Workflow Editor**: http://localhost/n8n
- **Knowledge Base**: http://localhost/knowledge
- **Ticketing System**: http://localhost/tickets

## 🔐 Default Credentials

### n8n
- Username: `admin`
- Password: `admin123`

### BookStack
- Email: `admin@admin.com`
- Password: Set during first setup

### osTicket
- Configure during first setup

## 📋 System Requirements

### Minimum Requirements
- **RAM**: 4GB
- **Storage**: 10GB free space
- **CPU**: 2 cores
- **OS**: Windows 10/11 with Docker Desktop or Linux with Docker

### Recommended Requirements
- **RAM**: 8GB or more
- **Storage**: 20GB free space
- **CPU**: 4 cores or more
- **Network**: Stable internet connection for initial setup

## 🛠️ Management Commands

### Start the system
```bash
docker compose up -d
```

### Stop the system
```bash
docker compose down
```

### View logs
```bash
docker compose logs
```

### Restart services
```bash
docker compose restart
```

### Update system
```bash
git pull
docker compose pull
docker compose up -d
```

## 🔧 Configuration

### Environment Variables
Edit the `.env` file to customize:
- Database passwords
- n8n authentication
- Timezone settings
- Port configurations

### Custom Frontend
The frontend is built with:
- HTML5 + Tailwind CSS 3
- Native JavaScript
- Anime.js for animations
- ECharts for data visualization

### n8n Workflows
Access the n8n editor at `/n8n` to create and manage automation workflows:
- Ticket categorization
- Knowledge base integration
- Automated responses
- Reporting and analytics

## 📊 Features

### Frontend Interface
- Modern dark theme design
- Responsive layout
- Multi-language support (Japanese/English)
- Real-time status dashboard
- Ticket submission forms

### Automation Capabilities
- Automatic ticket categorization
- Knowledge base article suggestions
- Automated email responses
- Data synchronization between systems
- Custom workflow creation

### Knowledge Management
- Easy article creation and editing
- Full-text search capabilities
- Category organization
- Version control
- API access for automation

### Ticketing System
- Multi-channel ticket creation
- Assignment and tracking
- Communication logs
- Reporting and analytics
- API integration

## 🔒 Security

- All services run in isolated Docker containers
- Environment variables for sensitive data
- Nginx reverse proxy with security headers
- Optional firewall configuration
- Regular security updates via Docker images

## 🐛 Troubleshooting

### Common Issues

1. **Docker not running**
   - Ensure Docker Desktop is started
   - Check Docker daemon status: `docker info`

2. **Port conflicts**
   - Check if ports 80, 5678, 6875, 8080 are available
   - Modify port mappings in `docker-compose.yml` if needed

3. **Database connection errors**
   - Wait for databases to fully initialize (30-60 seconds)
   - Check container logs: `docker compose logs [service_name]`

4. **Memory issues**
   - Ensure sufficient RAM is available
   - Consider increasing Docker memory limits

### Log Analysis
```bash
# View all logs
docker compose logs

# View specific service logs
docker compose logs n8n
docker compose logs bookstack
docker compose logs osticket

# Follow logs in real-time
docker compose logs -f
```

## 📞 Support

For technical support or questions:
1. Check the troubleshooting section above
2. Review Docker and service logs
3. Consult the official documentation for each component
4. Create an issue in the project repository

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📚 Documentation

- [n8n Documentation](https://docs.n8n.io/)
- [BookStack Documentation](https://www.bookstackapp.com/docs/)
- [osTicket Documentation](https://docs.osticket.com/)
- [Docker Documentation](https://docs.docker.com/)

