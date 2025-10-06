<?php

use PHPUnit\Framework\TestCase;

class DockerContainerTest extends TestCase
{
    public function testPhpConfigurationIsValid()
    {
        // Test that our PHP configuration file is valid
        $phpIniPath = __DIR__ . '/../php/moodle.ini';
        $this->assertFileExists($phpIniPath, 'PHP configuration file should exist');
        
        $content = file_get_contents($phpIniPath);
        $this->assertNotEmpty($content, 'PHP configuration should not be empty');
        
        // Check for important settings
        $this->assertStringContainsString('upload_max_filesize', $content);
        $this->assertStringContainsString('post_max_size', $content);
        $this->assertStringContainsString('memory_limit', $content);
    }

    public function testNginxConfigurationIsValid()
    {
        // Test that our Nginx configuration file exists and is valid
        $nginxConfigPath = __DIR__ . '/../nginx/default.conf';
        $this->assertFileExists($nginxConfigPath, 'Nginx configuration file should exist');
        
        $content = file_get_contents($nginxConfigPath);
        $this->assertNotEmpty($content, 'Nginx configuration should not be empty');
        
        // Check for important settings
        $this->assertStringContainsString('server {', $content);
        $this->assertStringContainsString('location ~ [^/]\.php', $content);
        $this->assertStringContainsString('fastcgi_pass', $content);
    }

    public function testDockerfileHasRequiredComponents()
    {
        // Test that Dockerfile contains all necessary components
        $dockerfilePath = __DIR__ . '/../Dockerfile';
        $this->assertFileExists($dockerfilePath, 'Dockerfile should exist');
        
        $content = file_get_contents($dockerfilePath);
        $this->assertNotEmpty($content, 'Dockerfile should not be empty');
        
        // Check for essential components
        $this->assertStringContainsString('FROM nginx:', $content);
        $this->assertStringContainsString('php8.', $content);
        $this->assertStringContainsString('moodle', $content);
        $this->assertStringContainsString('supervisor', $content);
        $this->assertStringContainsString('cron', $content);
    }

    public function testSupervisorConfigurationExists()
    {
        // Test supervisor configuration
        $supervisorConfigPath = __DIR__ . '/../docker/supervisor/supervisord.conf';
        $this->assertFileExists($supervisorConfigPath, 'Supervisor configuration should exist');
        
        $content = file_get_contents($supervisorConfigPath);
        $this->assertNotEmpty($content, 'Supervisor configuration should not be empty');
    }

    public function testCronConfigurationExists()
    {
        // Test cron configuration
        $cronConfigPath = __DIR__ . '/../cron/crontab';
        $this->assertFileExists($cronConfigPath, 'Cron configuration should exist');
        
        $content = file_get_contents($cronConfigPath);
        $this->assertNotEmpty($content, 'Cron configuration should not be empty');
    }

    public function testEntrypointScriptExists()
    {
        // Test entrypoint script
        $entrypointPath = __DIR__ . '/../docker/entrypoint.sh';
        $this->assertFileExists($entrypointPath, 'Entrypoint script should exist');
        
        $content = file_get_contents($entrypointPath);
        $this->assertNotEmpty($content, 'Entrypoint script should not be empty');
        
        // Check for shebang
        $this->assertStringStartsWith('#!/', $content, 'Entrypoint should have proper shebang');
    }

    public function testPhpVersionCompatibility()
    {
        // Test that we're using a supported PHP version
        $dockerfilePath = __DIR__ . '/../Dockerfile';
        $content = file_get_contents($dockerfilePath);
        
        // Extract PHP version from Dockerfile
        preg_match('/php(\d+\.\d+)/', $content, $matches);
        $this->assertNotEmpty($matches, 'Should find PHP version in Dockerfile');
        
        $phpVersion = $matches[1];
        // Support current stable PHP versions
        $supportedVersions = ['8.1', '8.2', '8.3', '8.4'];
        $this->assertContains($phpVersion, $supportedVersions, 
            "PHP version {$phpVersion} should be in supported versions");
        
        // Additional check: version should be at least 8.1
        $this->assertGreaterThanOrEqual('8.1', $phpVersion, 
            'PHP version should be 8.1 or higher for Moodle compatibility');
    }

    public function testMoodleVersionCompatibility()
    {
        // Test that we're using a valid Moodle version
        $dockerfilePath = __DIR__ . '/../Dockerfile';
        $content = file_get_contents($dockerfilePath);
        
        // Extract Moodle version from Dockerfile
        preg_match('/stable(\d+)/', $content, $matches);
        $this->assertNotEmpty($matches, 'Should find Moodle version in Dockerfile');
        
        $moodleVersion = (int)$matches[1];
        $this->assertGreaterThanOrEqual(400, $moodleVersion, 
            'Moodle version should be 4.0 or higher');
    }

    public function testPhpVersionConsistencyBetweenDockerfileAndSupervisor()
    {
        // Test that PHP version in Dockerfile matches supervisord.conf
        $dockerfilePath = __DIR__ . '/../Dockerfile';
        $supervisorConfigPath = __DIR__ . '/../docker/supervisor/supervisord.conf';
        
        $dockerfileContent = file_get_contents($dockerfilePath);
        $supervisorContent = file_get_contents($supervisorConfigPath);
        
        // Extract PHP version from Dockerfile (e.g., php8.3)
        preg_match('/php(\d+\.\d+)/', $dockerfileContent, $dockerfileMatches);
        $this->assertNotEmpty($dockerfileMatches, 'Should find PHP version in Dockerfile');
        $dockerfilePhpVersion = $dockerfileMatches[1];
        
        // Extract PHP version from supervisord.conf (e.g., php-fpm8.3)
        preg_match('/php-fpm(\d+\.\d+)/', $supervisorContent, $supervisorMatches);
        $this->assertNotEmpty($supervisorMatches, 'Should find PHP-FPM version in supervisord.conf');
        $supervisorPhpVersion = $supervisorMatches[1];
        
        // They should match
        $this->assertEquals($dockerfilePhpVersion, $supervisorPhpVersion,
            "PHP version in Dockerfile ({$dockerfilePhpVersion}) should match supervisord.conf ({$supervisorPhpVersion})");
        
        // Also check the PHP config path in supervisord.conf
        preg_match('/\/etc\/php\/(\d+\.\d+)\//', $supervisorContent, $configPathMatches);
        $this->assertNotEmpty($configPathMatches, 'Should find PHP config path in supervisord.conf');
        $configPathPhpVersion = $configPathMatches[1];
        
        $this->assertEquals($dockerfilePhpVersion, $configPathPhpVersion,
            "PHP version in Dockerfile ({$dockerfilePhpVersion}) should match PHP config path in supervisord.conf ({$configPathPhpVersion})");
    }
}
