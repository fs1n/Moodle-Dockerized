

# Moodle-Dockerized

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

## License
See [LICENSE](LICENSE).
