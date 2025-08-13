# Version Management and Testing Workflow

This document explains the automated workflow for keeping your Moodle-Dockerized project up to date with the latest PHP and Moodle versions.

## Overview

The workflow consists of three main components:

1. **Manual Testing Workflow** (`test-and-update.yml`) - For testing specific versions on demand
2. **Scheduled Version Check** (`scheduled-version-check.yml`) - Automatic monitoring for new versions
3. **Update Script** (`scripts/update-versions.sh`) - Local testing and updating tool

## Manual Testing Workflow

### Triggering the Workflow

Go to **Actions → Test and Update Versions** in your GitHub repository and click "Run workflow". You can specify:

- **PHP Version** (e.g., 8.2, 8.3)
- **Moodle Version** (e.g., 404, 405)
- **Create Release** (whether to create a release if all tests pass)

### What It Does

1. **Version Check**: Compares requested versions with latest available
2. **Docker Build**: Creates a test image with specified PHP/Moodle versions
3. **Container Testing**: Starts the container and verifies Moodle responds
4. **PHPUnit Tests**: Runs all configuration and compatibility tests
5. **Update Creation**: Creates a PR with updated Dockerfile
6. **Release Creation**: Optionally creates a new release with proper tagging

### Test Matrix

The workflow tests the specified versions in a matrix to ensure compatibility.

## Scheduled Version Check

### Automatic Monitoring

Runs every Monday at 9 AM UTC to check for:
- New PHP versions from the Sury repository
- New Moodle LTS versions from official releases

### Issue Creation

When updates are available, it automatically:
- Creates or updates a GitHub issue with version details
- Provides instructions for manual testing
- Includes comparison tables showing current vs. latest versions

## Local Update Script

### Usage

```bash
# Check for available updates
./scripts/update-versions.sh check

# Update to latest stable versions (conservative)
./scripts/update-versions.sh update

# Update to bleeding edge versions (latest available)
./scripts/update-versions.sh update-bleeding-edge

# Update to specific versions
./scripts/update-versions.sh update 8.3 404

# Update to specific bleeding edge versions
./scripts/update-versions.sh update-bleeding-edge 8.4 500

# Run full test suite
./scripts/update-versions.sh test
```

### Version Strategy

The script now offers two update strategies:

- **Conservative (`update`)**: Uses stable, well-tested versions (PHP 8.3, Moodle 4.x LTS)
- **Bleeding Edge (`update-bleeding-edge`)**: Uses the absolute latest available versions (PHP 8.4, Moodle 5.x)

This approach ensures you can stay current while choosing your risk tolerance.

### What It Does

- **check**: Compares current versions with latest available
- **update**: Updates Dockerfile and runs tests
- **test**: Runs PHPUnit tests and Docker build verification

## Release Strategy

### Automatic Releases

When using the manual workflow with "Create Release" enabled:
- Release tags follow the format: `v{moodle_version}-php{php_version}` (e.g., `v404-php8.2`)
- Docker images are tagged with the same version
- Release notes include version details and test results

### Manual Releases

After successful local testing:
1. Commit updated Dockerfile
2. Create a new release with proper versioning
3. The existing docker-image workflow will build and push the image

## PHPUnit Tests

### Test Coverage

The test suite verifies:
- ✅ PHP configuration validity
- ✅ Nginx configuration validity  
- ✅ Dockerfile component presence
- ✅ Supervisor configuration exists
- ✅ Cron configuration exists
- ✅ Entrypoint script exists and is executable
- ✅ PHP version compatibility (8.1, 8.2, 8.3)
- ✅ Moodle version compatibility (4.0+)

### Running Tests

```bash
# Run all tests
./vendor/bin/phpunit

# Run specific test
./vendor/bin/phpunit tests/DockerContainerTest.php
```

## Docker Testing

### Build Verification

The workflow includes Docker-specific tests:
- Image builds successfully with new versions
- Container starts without errors
- Moodle web interface is accessible
- Health checks pass

### Local Testing

```bash
# Build test image
docker build -t moodle-test .

# Run container
docker run -d -p 8080:80 --name moodle-test moodle-test

# Test access
curl http://localhost:8080/moodle/

# Cleanup
docker stop moodle-test && docker rm moodle-test
```

## Version Compatibility

### Supported PHP Versions
- PHP 8.1 (minimum)
- PHP 8.2 (recommended)
- PHP 8.3 (latest)

### Supported Moodle Versions
- Moodle 4.0+ (stable400+)
- Focus on LTS releases

### Dependencies
- Nginx (latest)
- Supervisor
- Cron

## Troubleshooting

### Common Issues

1. **Docker Build Fails**
   - Check if PHP version is available in Sury repository
   - Verify Moodle version exists in download URL
   - Review build logs for specific errors

2. **Container Won't Start**
   - Check entrypoint script permissions
   - Verify supervisor configuration
   - Review container logs: `docker logs <container_name>`

3. **Moodle Not Accessible**
   - Wait 30-60 seconds for full startup
   - Check if PHP-FPM is running in container
   - Verify Nginx configuration

4. **Tests Fail**
   - Update test assertions if configuration changes
   - Check file permissions and paths
   - Ensure all required files exist

### Getting Help

- Check workflow logs in GitHub Actions
- Review test output in PHPUnit results
- Use the local update script for debugging
- Create issues for persistent problems

## Best Practices

1. **Test Before Release**: Always run the full test suite before creating releases
2. **Monitor Issues**: Keep an eye on automatically created version update issues
3. **Regular Updates**: Don't let versions fall too far behind
4. **Local Testing**: Use the update script for quick local verification
5. **Backup Strategy**: Keep the Dockerfile.backup when using update scripts

---

This workflow ensures your Moodle Docker environment stays current, secure, and functional with minimal manual intervention.
