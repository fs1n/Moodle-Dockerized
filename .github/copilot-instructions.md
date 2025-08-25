# Moodle-Dockerized Development Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites
- Docker must be installed and running
- PHP 8.0+ and PHPUnit for local testing
- Bash shell environment
- Internet access for Docker builds (external package repositories required)

### Bootstrap and Test the Repository
1. **Clone and navigate**: 
   ```bash
   git clone https://github.com/fs1n/Moodle-Dockerized.git
   cd Moodle-Dockerized
   ```

2. **Run tests** (takes 1-2 seconds):
   ```bash
   phpunit tests/
   ```
   - Expected: 13 tests, 41 assertions, all passing
   - Warning about phpunit.xml cache configuration is normal
   - Tests validate configuration files, Dockerfile structure, and PHP/Moodle version compatibility

3. **Make scripts executable**:
   ```bash
   chmod +x scripts/update-versions.sh
   ```

4. **Test version checking** (takes 5-10 seconds):
   ```bash
   ./scripts/update-versions.sh check
   ```
   - May fail in network-restricted environments but usually works
   - Shows current PHP (8.3) and Moodle (404) versions

### Docker Build and Testing
⚠️ **CRITICAL BUILD REQUIREMENTS**:
- **NEVER CANCEL** Docker builds - they can take 15-45 minutes depending on network and system
- **Set timeout to 60+ minutes** for Docker build commands
- Builds require external internet access to:
  - packages.sury.org (PHP packages)
  - download.moodle.org (Moodle releases)
  - External apt repositories

**Standard Docker Build** (takes 15-45 minutes, NEVER CANCEL):
```bash
# Set timeout to 3600 seconds (60 minutes) minimum
time docker build -t moodle-test .
```
**Note**: In network-restricted environments, builds will fail at the package download step with "No address associated with hostname" errors. This is expected.

**Test Docker container** (if build succeeds):
```bash
# Start container (takes 30-60 seconds for full startup)
docker run -d -p 8080:80 --name moodle-test moodle-test

# Wait for startup
sleep 60

# Test accessibility 
curl http://localhost:8080/moodle/

# Cleanup
docker stop moodle-test && docker rm moodle-test
```

**Alternative Docker testing** (using update script):
```bash
# Test Docker build with built-in error handling (15-45 minutes)
./scripts/update-versions.sh test
```

### Version Management
- **Check versions**: `./scripts/update-versions.sh check`
- **Update conservatively**: `./scripts/update-versions.sh update`
- **Update bleeding edge**: `./scripts/update-versions.sh update-bleeding-edge`
- **Test everything**: `./scripts/update-versions.sh test` (includes Docker build, 15-45 mins)

## Validation Requirements

### Always Run Before Committing
1. **PHPUnit tests** (required, takes ~100ms):
   ```bash
   phpunit tests/
   ```
   - **Expected output**: "OK (13 tests, 41 assertions)"
   - **Normal warning**: PHPUnit configuration cache warning is expected and does not affect test results
   - All tests should pass; investigate any failures before proceeding

2. **Configuration validation**:
   - All configuration files must exist and be readable
   - Dockerfile must contain valid PHP and Moodle versions
   - Entrypoint script must be executable

### Manual Testing Scenarios
When making changes to container configuration, ALWAYS validate:

1. **Configuration File Changes**:
   - Run PHPUnit tests to verify file existence and basic syntax
   - Check that PHP, Nginx, and supervisor configs are valid

2. **Dockerfile Changes**:
   - Test PHP version compatibility (8.1, 8.2, 8.3, 8.4 supported)
   - Test Moodle version compatibility (4.0+ supported)
   - Run full Docker build and container test (15-45 minutes)

3. **Script Changes**:
   - Test version check functionality
   - Verify help command works
   - Test backup/restore functionality

### Network-Restricted Environment Validation
In environments without external internet access:
- **PHPUnit tests**: ✅ Will work (no network required)
- **Docker builds**: ❌ Will FAIL at step 4/30 with "packages.sury.org: No address associated with hostname"
- **Version checking**: ⚠️ May fail (API calls required)
- **Script validation**: ✅ Use `./scripts/update-versions.sh help` to verify script functionality

**Expected failure pattern for Docker builds in restricted environments**:
```
ERROR: failed to solve: process "/bin/sh -c wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg" did not complete successfully: exit code: 4
```
This failure is normal and expected when external package repositories are not accessible.

## Common Development Tasks

### Key Configuration Files
- `Dockerfile` - Main container definition (PHP 8.3, Moodle 404)
- `php/moodle.ini` - PHP configuration (memory, uploads, etc.)
- `nginx/default.conf` - Nginx web server configuration
- `docker/supervisor/supervisord.conf` - Process management
- `docker/entrypoint.sh` - Container startup script
- `cron/crontab` - Moodle cron job configuration

### Frequent File Locations
- **Tests**: `tests/` - PHPUnit tests for validation
- **Scripts**: `scripts/update-versions.sh` - Version management
- **Workflows**: `.github/workflows/` - CI/CD automation
- **Documentation**: `docs/VERSION_MANAGEMENT.md` - Detailed guides

### Version Strategy
- **Conservative**: PHP 8.3, Moodle 4.x (LTS) - Use `update` command
- **Bleeding Edge**: PHP 8.4, Moodle 5.x - Use `update-bleeding-edge` command
- **Current Stable**: PHP 8.3, Moodle 404 (4.4 LTS)

## Timing Expectations and Timeouts

### Critical Timing Information
- **PHPUnit Tests**: ~100ms (fast feedback, documented warning is normal)
- **Version Check**: ~25ms (may fail in restricted networks)
- **Docker Build**: 15-45 minutes (NEVER CANCEL - set 60+ minute timeout)
- **Container Startup**: 30-60 seconds (wait for full initialization)
- **Full Test Suite**: 15-45 minutes (includes Docker build)

### Timeout Recommendations
- PHPUnit tests: 30 seconds
- Script commands: 60 seconds  
- Docker builds: 3600+ seconds (60+ minutes)
- Container tests: 300 seconds (5 minutes)

## Troubleshooting

### Common Issues
1. **Docker Build Fails**:
   - Usually network connectivity to external repositories
   - Check if running in restricted environment
   - Verify PHP version exists in Sury repository
   - Verify Moodle version exists in download URLs

2. **Tests Fail**:
   - Check file permissions on entrypoint script
   - Verify all configuration files exist
   - Update PHPUnit configuration if needed

3. **Container Won't Start**:
   - Wait full 60 seconds for startup
   - Check supervisor configuration
   - Review container logs: `docker logs <container_name>`

4. **Moodle Not Accessible**:
   - Allow 30-60 seconds for PHP-FPM initialization
   - Verify port 8080 is available
   - Check Nginx configuration syntax

### Known Limitations
- **Docker builds require external internet access** - will fail in network-restricted environments
- **Version checking requires API access** - may fail behind firewalls
- **PHPUnit cache warnings** - configuration format issue, but tests work correctly
- **Supervisor PHP version** - may need manual update when changing PHP versions

## Project Structure Quick Reference
```
.
├── Dockerfile              # Main container definition
├── docker/
│   ├── entrypoint.sh       # Container startup script
│   └── supervisor/         # Process management config
├── php/moodle.ini          # PHP configuration
├── nginx/default.conf      # Web server configuration  
├── cron/crontab           # Scheduled tasks
├── tests/                 # PHPUnit validation tests
├── scripts/               # Version management tools
├── .github/workflows/     # CI/CD automation
└── docs/                  # Detailed documentation
```

This repository provides a Docker-based Moodle development environment optimized for testing PHP and Moodle version combinations. Always test thoroughly and allow sufficient time for builds and validation.