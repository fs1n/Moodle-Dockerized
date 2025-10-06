## Issue Description
The workflow "Test and Update Versions" is failing because of a PHP version mismatch. While PHP 8.3 is specified as the target version, the container is attempting to use PHP 8.2.

## Details
In the job logs from run [18285337471](https://github.com/fs1n/Moodle-Dockerized/actions/runs/18285337471/job/52058788755), there's a critical error:

```
2025-10-06 15:07:20,850 INFO spawnerr: can't find command 'php-fpm8.2'
2025-10-06 15:07:26,743 INFO gave up: php-fpm_00 entered FATAL state, too many start retries too quickly
```

The container is looking for `php-fpm8.2` but fails to find it, suggesting that:
1. The PHP version in the Docker configuration doesn't match the version specified in the workflow
2. The supervisord configuration is looking for the wrong PHP-FPM version

## Impact
- The workflow fails because PHP-FPM can't start
- Nginx shows "Connection refused" errors when trying to connect to the FastCGI backend (PHP-FPM)
- The Moodle instance doesn't respond to HTTP requests

## Suggested Solutions
1. Update the supervisord configuration to use the correct PHP-FPM version (`php-fpm8.3` instead of `php-fpm8.2`)
2. Ensure the Dockerfile installs the correct PHP version
3. Verify that all configuration files in the Docker container are aligned with the PHP version specified in the workflow

## Additional Context
This issue appears in the workflow that is supposed to update and test Moodle versions with specific PHP versions. The test fails because of a version mismatch between the configured PHP version and what's expected in the container.