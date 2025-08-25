

# Moodle-Dockerized

[![Scheduled Version Check](https://github.com/fs1n/Moodle-Dockerized/actions/workflows/scheduled-version-check.yml/badge.svg)](https://github.com/fs1n/Moodle-Dockerized/actions/workflows/scheduled-version-check.yml)

This repository provides a ready-to-use Docker environment for running Moodle, the popular open-source learning management system. It includes all necessary configuration files and scripts to deploy Moodle with PHP, Nginx, and supporting services in containers.

## Features
- Quick and easy Moodle deployment using Docker
- Pre-configured PHP and Nginx setup
- Integrated cron job and Supervisor support
- Customizable configuration for all components

## Directory Structure
- `docker/` – Entrypoint scripts and Supervisor configuration
- `nginx/` – Nginx configuration for Moodle
- `php/` – PHP configuration for Moodle
- `cron/` – Cron job configuration
- `Dockerfile` – Docker build instructions

## Usage
1. Clone this repository:
	```bash
	git clone https://github.com/fs1n/Moodle-Dockerized.git
	cd Moodle-Dockerized
	```
2. Build and run the container:
	```bash
	docker build -t moodle-dockerized .
	docker run -d -p 8080:80 moodle-dockerized
	```
3. Access Moodle in your browser at [http://localhost:8080](http://localhost:8080).

## Notes
- This setup is intended for development and testing only. For production use, further security and configuration adjustments are required.
- **Version Management**: Automated workflows are available to keep PHP and Moodle versions up to date. See [docs/VERSION_MANAGEMENT.md](docs/VERSION_MANAGEMENT.md) for details.

## Version Management

This repository includes automated workflows for keeping PHP and Moodle versions current:

- **Manual Testing**: Go to Actions → "Test and Update Versions" to test specific versions
- **Automatic Monitoring**: Weekly checks for new versions with issue creation
- **Local Tools**: Use `./scripts/update-versions.sh` for local version management

For detailed information, see the [Version Management Guide](docs/VERSION_MANAGEMENT.md).

## License
See [LICENSE](LICENSE).
