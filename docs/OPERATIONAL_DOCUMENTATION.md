# PriceBreak Flight Features - Operational Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Deployment](#deployment)
4. [Monitoring](#monitoring)
5. [Maintenance](#maintenance)
6. [Troubleshooting](#troubleshooting)
7. [Performance Optimization](#performance-optimization)
8. [Security](#security)
9. [Backup and Recovery](#backup-and-recovery)
10. [Scaling](#scaling)
11. [API Documentation](#api-documentation)
12. [Configuration](#configuration)
13. [Logging](#logging)
14. [Alerting](#alerting)
15. [Disaster Recovery](#disaster-recovery)

## System Overview

### Purpose
PriceBreak Flight Features is a comprehensive flight monitoring and alerting system that allows users to create personalized flight search criteria and receive automated notifications when flights matching their criteria drop to desirable prices.

### Key Components
- **Flight Filter System**: User-created search criteria with comprehensive parameters
- **Price Monitoring Engine**: Continuous background monitoring across multiple providers
- **Alert System**: Intelligent notification delivery with spam prevention
- **Analytics Dashboard**: User behavior tracking and system performance metrics
- **Multi-API Integration**: Skyscanner, Amadeus, and Google Flights integration
- **Background Processing**: Sidekiq-based job processing with intelligent scheduling

### Technology Stack
- **Backend**: Ruby on Rails 8.0
- **Database**: PostgreSQL with Redis for caching
- **Background Jobs**: Sidekiq with Redis
- **Frontend**: React with TypeScript
- **APIs**: RESTful APIs with JSON responses
- **Monitoring**: Custom monitoring dashboard with health checks

## Architecture

### System Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │    │   Mobile App    │    │   API Client    │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │      Load Balancer        │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │     Rails Application     │
                    │   (Multiple Instances)    │
                    └─────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────┴─────────┐  ┌─────────┴─────────┐  ┌─────────┴─────────┐
│    PostgreSQL     │  │       Redis         │  │      Sidekiq       │
│    (Primary DB)   │  │   (Cache & Jobs)    │  │  (Background Jobs) │
└───────────────────┘  └────────────────────┘  └───────────────────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────┴─────────────┐
                    │    External APIs          │
                    │  (Skyscanner, Amadeus,    │
                    │   Google Flights)         │
                    └───────────────────────────┘
```

### Data Flow
1. **User Creates Filter**: User sets up flight search criteria through web interface
2. **Filter Validation**: System validates filter parameters and stores in database
3. **Background Monitoring**: Sidekiq jobs continuously monitor prices for active filters
4. **Price Data Collection**: Multiple APIs provide price data with normalization
5. **Alert Processing**: System detects meaningful price drops and triggers alerts
6. **Notification Delivery**: Multi-channel notifications sent to users
7. **Analytics Collection**: User behavior and system performance data collected

### Database Schema
- **flight_filters**: User-created search criteria
- **flight_alerts**: Price monitoring and alert history
- **flight_price_histories**: Historical price data for trends
- **flight_provider_data**: Normalized data from multiple providers
- **users**: User accounts and preferences

## Deployment

### Environment Setup
```bash
# Production environment variables
export RAILS_ENV=production
export DATABASE_URL=postgresql://user:password@host:port/database
export REDIS_URL=redis://host:port/0
export SIDEKIQ_REDIS_URL=redis://host:port/1
export SKYSCANNER_API_KEY=your_api_key
export AMADEUS_API_KEY=your_api_key
export GOOGLE_FLIGHTS_API_KEY=your_api_key
```

### Deployment Process
1. **Code Deployment**
   ```bash
   git pull origin main
   bundle install --deployment
   rails assets:precompile
   rails db:migrate
   ```

2. **Service Restart**
   ```bash
   sudo systemctl restart pricebreak
   sudo systemctl restart sidekiq
   sudo systemctl restart redis
   ```

3. **Health Check**
   ```bash
   curl -f http://localhost:3000/health || exit 1
   ```

### Docker Deployment
```dockerfile
FROM ruby:3.2.0-alpine

WORKDIR /app
COPY Gemfile* ./
RUN bundle install --deployment

COPY . .
RUN rails assets:precompile

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
```

## Monitoring

### Health Checks
- **Application Health**: `GET /health`
- **Database Health**: `GET /health/database`
- **Redis Health**: `GET /health/redis`
- **Sidekiq Health**: `GET /health/sidekiq`

### Key Metrics
- **System Uptime**: Target 99.5%
- **Response Time**: Target < 500ms
- **Error Rate**: Target < 1%
- **Memory Usage**: Target < 80%
- **CPU Usage**: Target < 70%
- **Database Connections**: Target < 80% of pool

### Monitoring Dashboard
Access the monitoring dashboard at `/monitoring/dashboard` (admin only)

Key metrics displayed:
- System health status
- Active filters count
- Alert delivery rates
- API response times
- Background job status
- Error rates and logs

### Performance Monitoring
```ruby
# Enable performance monitoring
PerformanceOptimizationService.optimize_system

# Get performance report
report = PerformanceOptimizationService.get_system_performance_report
```

## Maintenance

### Daily Tasks
- Monitor system health and performance
- Check error logs for issues
- Verify background job processing
- Monitor API rate limits and costs

### Weekly Tasks
- Review performance metrics and trends
- Update monitoring thresholds if needed
- Clean up old log files
- Review and update documentation

### Monthly Tasks
- Analyze user behavior and engagement
- Review and optimize database queries
- Update security patches
- Review and update API integrations

### Maintenance Commands
```bash
# Start monitoring system
rails monitoring:start

# Stop monitoring system
rails monitoring:stop

# Check system status
rails monitoring:status

# Run edge case handling
rails edge_cases:handle

# Run comprehensive testing
rails testing:comprehensive

# Optimize system performance
rails performance:optimize
```

## Troubleshooting

### Common Issues

#### High Memory Usage
**Symptoms**: Slow response times, memory warnings
**Solutions**:
```bash
# Check memory usage
rails performance:check_memory

# Clear caches
rails cache:clear

# Restart services
sudo systemctl restart pricebreak sidekiq
```

#### Database Connection Issues
**Symptoms**: Database connection errors, timeouts
**Solutions**:
```bash
# Check database connections
rails db:connections

# Restart database
sudo systemctl restart postgresql

# Check connection pool
rails db:pool_status
```

#### Background Job Failures
**Symptoms**: Jobs stuck in queue, processing delays
**Solutions**:
```bash
# Check Sidekiq status
rails sidekiq:status

# Restart Sidekiq
sudo systemctl restart sidekiq

# Clear failed jobs
rails sidekiq:clear_failed
```

#### API Rate Limiting
**Symptoms**: API errors, reduced data collection
**Solutions**:
```bash
# Check API status
rails apis:status

# Adjust rate limiting
rails apis:adjust_limits

# Switch to backup providers
rails apis:switch_backup
```

### Error Codes
- **E001**: Database connection failed
- **E002**: Redis connection failed
- **E003**: API rate limit exceeded
- **E004**: Memory limit exceeded
- **E005**: Background job failed
- **E006**: Invalid filter parameters
- **E007**: Alert delivery failed

### Log Analysis
```bash
# View recent errors
tail -f log/production.log | grep ERROR

# View monitoring logs
tail -f log/monitoring.log

# View API logs
tail -f log/api.log
```

## Performance Optimization

### Caching Strategy
- **Price History**: 1 hour cache
- **Route Analysis**: 6 hours cache
- **Provider Stats**: 24 hours cache
- **Filter Analysis**: 2 hours cache
- **Monitoring Metrics**: 30 minutes cache

### Database Optimization
- Proper indexing on frequently queried columns
- Query optimization with EXPLAIN analysis
- Connection pool management
- Regular VACUUM and ANALYZE operations

### Background Job Optimization
- Intelligent scheduling based on urgency
- Batch processing for large datasets
- Circuit breaker pattern for API calls
- Exponential backoff for retries

### Memory Management
- Regular garbage collection
- Cache size limits
- Memory usage monitoring
- Automatic cache cleanup

## Security

### Authentication
- Firebase authentication integration
- JWT token validation
- Session management with Redis
- Password policy enforcement

### Authorization
- Role-based access control
- Admin-only endpoints protection
- API key validation
- Rate limiting per user

### Data Protection
- Sensitive data encryption
- SQL injection prevention
- XSS protection
- CSRF protection

### API Security
- HTTPS enforcement
- API key rotation
- Request validation
- Response sanitization

## Backup and Recovery

### Database Backups
```bash
# Daily backup
pg_dump pricebreak_production > backup_$(date +%Y%m%d).sql

# Weekly full backup
pg_dump -Fc pricebreak_production > backup_full_$(date +%Y%m%d).dump
```

### Redis Backups
```bash
# Redis backup
redis-cli BGSAVE

# Copy backup file
cp /var/lib/redis/dump.rdb /backup/redis_$(date +%Y%m%d).rdb
```

### Recovery Procedures
1. **Database Recovery**
   ```bash
   # Restore from backup
   psql pricebreak_production < backup_20240101.sql
   ```

2. **Redis Recovery**
   ```bash
   # Stop Redis
   sudo systemctl stop redis
   
   # Restore backup
   cp /backup/redis_20240101.rdb /var/lib/redis/dump.rdb
   
   # Start Redis
   sudo systemctl start redis
   ```

## Scaling

### Horizontal Scaling
- Multiple Rails application instances
- Load balancer configuration
- Database read replicas
- Redis cluster setup

### Vertical Scaling
- Increase server memory and CPU
- Optimize database configuration
- Increase connection pool sizes
- Upgrade Redis memory

### Auto-scaling Triggers
- CPU usage > 70%
- Memory usage > 80%
- Response time > 1000ms
- Queue length > 1000 jobs

## API Documentation

### Flight Filters API
```http
GET /api/flight_filters
POST /api/flight_filters
GET /api/flight_filters/:id
PUT /api/flight_filters/:id
DELETE /api/flight_filters/:id
```

### Analytics API
```http
GET /api/analytics/dashboard
GET /api/analytics/metrics
GET /api/analytics/trends
GET /api/analytics/export
```

### Monitoring API
```http
GET /api/monitoring/health
GET /api/monitoring/status
GET /api/monitoring/metrics
```

## Configuration

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:password@host:port/database

# Redis
REDIS_URL=redis://host:port/0
SIDEKIQ_REDIS_URL=redis://host:port/1

# APIs
SKYSCANNER_API_KEY=your_key
AMADEUS_API_KEY=your_key
GOOGLE_FLIGHTS_API_KEY=your_key

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email
SMTP_PASSWORD=your_password

# SMS
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE_NUMBER=your_number
```

### Application Configuration
```ruby
# config/application.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
config.active_job.queue_adapter = :sidekiq
config.force_ssl = true
```

## Logging

### Log Levels
- **DEBUG**: Detailed information for debugging
- **INFO**: General information about system operation
- **WARN**: Warning messages for potential issues
- **ERROR**: Error messages for failed operations
- **FATAL**: Critical errors that cause system failure

### Log Files
- `log/production.log`: Main application logs
- `log/monitoring.log`: Monitoring system logs
- `log/api.log`: API request/response logs
- `log/sidekiq.log`: Background job logs

### Log Rotation
```bash
# Configure logrotate
sudo nano /etc/logrotate.d/pricebreak

# Log rotation configuration
/var/www/pricebreak/log/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        sudo systemctl reload pricebreak
    endscript
}
```

## Alerting

### System Alerts
- **High Memory Usage**: > 80%
- **High CPU Usage**: > 70%
- **Database Connection Issues**: > 90% pool usage
- **API Failures**: > 5% error rate
- **Background Job Failures**: > 10 failed jobs

### User Alerts
- **Price Drops**: Configurable thresholds
- **Schedule Changes**: Flight time changes
- **Route Discontinuation**: Seasonal route issues
- **Filter Issues**: Invalid or conflicting filters

### Alert Channels
- **Email**: Primary notification channel
- **SMS**: Urgent alerts only
- **Push Notifications**: Mobile app notifications
- **Browser Notifications**: Web browser notifications

## Disaster Recovery

### Recovery Time Objectives (RTO)
- **Critical Systems**: 1 hour
- **Non-Critical Systems**: 4 hours
- **Full System**: 24 hours

### Recovery Point Objectives (RPO)
- **Database**: 15 minutes
- **User Data**: 1 hour
- **Analytics Data**: 24 hours

### Disaster Recovery Plan
1. **Assessment**: Evaluate the scope and impact
2. **Communication**: Notify stakeholders and users
3. **Recovery**: Execute recovery procedures
4. **Validation**: Verify system functionality
5. **Monitoring**: Enhanced monitoring during recovery
6. **Documentation**: Document lessons learned

### Backup Testing
```bash
# Test database backup
rails db:test_backup

# Test Redis backup
rails redis:test_backup

# Test full system recovery
rails disaster:test_recovery
```

## Support and Maintenance

### Support Channels
- **Email**: support@pricebreak.com
- **Documentation**: https://docs.pricebreak.com
- **Status Page**: https://status.pricebreak.com
- **Emergency**: +1-800-PRICEBREAK

### Maintenance Windows
- **Weekly**: Sundays 2:00 AM - 4:00 AM UTC
- **Monthly**: First Saturday 1:00 AM - 6:00 AM UTC
- **Emergency**: As needed with 2-hour notice

### Change Management
1. **Request**: Submit change request
2. **Review**: Technical review and approval
3. **Schedule**: Schedule maintenance window
4. **Implement**: Execute changes
5. **Validate**: Verify changes work correctly
6. **Document**: Update documentation

---

*This documentation is maintained by the PriceBreak development team. Last updated: January 2024*

