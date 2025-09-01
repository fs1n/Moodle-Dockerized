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
        $this->assertStringContainsString('contents: write', $content, 'Workflow should have contents write permission for badge updates');
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
    
    public function testVersionBadgesExist()
    {
        $readmePath = __DIR__ . '/../README.md';
        $content = file_get_contents($readmePath);
        
        // Check that version badges are present
        $this->assertStringContainsString('![PHP Version]', $content, 'README should contain PHP version badge');
        $this->assertStringContainsString('![Moodle Version]', $content, 'README should contain Moodle version badge');
        $this->assertStringContainsString('![Database Support]', $content, 'README should contain database support badge');
        
        // Check badge URLs
        $this->assertStringContainsString('https://img.shields.io/badge/PHP-', $content, 'PHP badge should use shields.io');
        $this->assertStringContainsString('https://img.shields.io/badge/Moodle-', $content, 'Moodle badge should use shields.io');
        $this->assertStringContainsString('https://img.shields.io/badge/Database-', $content, 'Database badge should use shields.io');
        
        // Verify current versions in badges match Dockerfile
        $dockerfilePath = __DIR__ . '/../Dockerfile';
        $dockerfileContent = file_get_contents($dockerfilePath);
        
        preg_match('/php(\d+\.\d+)/', $dockerfileContent, $phpMatches);
        if (!empty($phpMatches)) {
            $expectedPhpVersion = $phpMatches[1];
            $this->assertStringContainsString("PHP-{$expectedPhpVersion}-blue", $content, 
                "README PHP badge should show current PHP version {$expectedPhpVersion}");
        }
        
        preg_match('/stable(\d+)/', $dockerfileContent, $moodleMatches);
        if (!empty($moodleMatches)) {
            $moodleVersion = $moodleMatches[1];
            // Convert to display format
            $moodleDisplay = $moodleVersion === '404' ? '4.4_LTS' : $moodleVersion;
            $this->assertStringContainsString("Moodle-{$moodleDisplay}-green", $content, 
                "README Moodle badge should show current Moodle version {$moodleDisplay}");
        }
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
    
    public function testWorkflowVersionComparisonLogic()
    {
        $workflowPath = __DIR__ . '/../.github/workflows/scheduled-version-check.yml';
        $content = file_get_contents($workflowPath);
        
        // Check that the workflow uses proper variable expansion in comparisons
        // The bug was using single quotes around variables which treats them as literals
        $this->assertStringContainsString('"$CURRENT_PHP" != "$LATEST_PHP"', $content, 
            'PHP comparison should use double quotes for variable expansion');
        $this->assertStringContainsString('"$CURRENT_MOODLE" != "$LATEST_MOODLE"', $content, 
            'Moodle comparison should use double quotes for variable expansion');
            
        // Ensure we don't have the buggy literal string comparison
        $this->assertStringNotContainsString('\'$CURRENT_PHP\' != \'$LATEST_PHP\'', $content, 
            'Should not use single quotes around variables (causes literal comparison bug)');
        $this->assertStringNotContainsString('\'$CURRENT_MOODLE\' != \'$LATEST_MOODLE\'', $content, 
            'Should not use single quotes around variables (causes literal comparison bug)');
    }
}