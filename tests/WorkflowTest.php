<?php

use PHPUnit\Framework\TestCase;

class WorkflowTest extends TestCase
{
    public function testScheduledVersionCheckWorkflowExists()
    {
        $workflowPath = __DIR__ . '/../.github/workflows/scheduled-version-check.yml';
        $this->assertFileExists($workflowPath, 'Scheduled version check workflow should exist');
    }
    
    public function testScheduledVersionCheckWorkflowHasPermissions()
    {
        $workflowPath = __DIR__ . '/../.github/workflows/scheduled-version-check.yml';
        $content = file_get_contents($workflowPath);
        
        // Check that permissions are defined
        $this->assertStringContainsString('permissions:', $content, 'Workflow should have permissions section');
        $this->assertStringContainsString('issues: write', $content, 'Workflow should have issues write permission');
        $this->assertStringContainsString('contents: read', $content, 'Workflow should have contents read permission');
    }
    
    public function testVersionExtractionWorks()
    {
        $dockerfilePath = __DIR__ . '/../Dockerfile';
        $content = file_get_contents($dockerfilePath);
        
        // Test PHP version extraction
        preg_match('/php(\d+\.\d+)/', $content, $phpMatches);
        $this->assertNotEmpty($phpMatches, 'Should be able to extract PHP version from Dockerfile');
        
        // Test Moodle version extraction  
        preg_match('/stable(\d+)/', $content, $moodleMatches);
        $this->assertNotEmpty($moodleMatches, 'Should be able to extract Moodle version from Dockerfile');
    }
    
    public function testWorkflowHasErrorHandling()
    {
        $workflowPath = __DIR__ . '/../.github/workflows/scheduled-version-check.yml';
        $content = file_get_contents($workflowPath);
        
        // Check for timeout settings to prevent hanging
        $this->assertStringContainsString('--connect-timeout', $content, 'Workflow should have connection timeout');
        $this->assertStringContainsString('--max-time', $content, 'Workflow should have max time limit');
        
        // Check for fallback logic
        $this->assertStringContainsString('echo ""', $content, 'Workflow should have fallback for empty API responses');
    }
}