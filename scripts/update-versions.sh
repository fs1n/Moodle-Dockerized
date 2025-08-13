#!/bin/bash

# Version Update Script for Moodle-Dockerized
# This script helps check for new versions and update the Dockerfile

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Moodle-Dockerized Version Checker ===${NC}"

# Function to get latest PHP version
get_latest_php_version() {
    # Get latest stable PHP version, but prefer 8.3 over 8.4 for stability
    local latest=$(curl -s "https://www.php.net/releases/active" | grep -oP 'PHP \K8\.\d+' | sort -V | tail -1 2>/dev/null)
    # If 8.4 is latest but we want to be conservative, return 8.3
    if [[ "$latest" == "8.4" ]]; then
        echo "8.3"  # More stable choice
    else
        echo "${latest:-8.3}"  # Default to 8.3 if nothing found
    fi
}

# Function to get latest Moodle LTS version
get_latest_moodle_version() {
    # Get latest Moodle version, but prefer LTS versions
    local latest=$(curl -s "https://download.moodle.org/releases/latest/" | grep -oP 'stable\K\d+' | sort -n | tail -1 2>/dev/null)
    # For now, prefer 4.x versions over 5.x for stability
    if [[ "$latest" == "500" ]]; then
        echo "404"  # Moodle 4.4 LTS is more stable
    else
        echo "${latest:-404}"  # Default to 404 if nothing found
    fi
}

# Function to get absolute latest versions (bleeding edge)
get_bleeding_edge_php_version() {
    curl -s "https://www.php.net/releases/active" | grep -oP 'PHP \K8\.\d+' | sort -V | tail -1 2>/dev/null || echo "8.3"
}

get_bleeding_edge_moodle_version() {
    curl -s "https://download.moodle.org/releases/latest/" | grep -oP 'stable\K\d+' | sort -n | tail -1 2>/dev/null || echo "404"
}

# Function to get current versions from Dockerfile
get_current_versions() {
    if [[ -f "Dockerfile" ]]; then
        CURRENT_PHP=$(grep -oP 'php\K8\.\d+' Dockerfile | head -1)
        CURRENT_MOODLE=$(grep -oP 'stable\K\d+' Dockerfile | head -1)
        echo -e "${BLUE}Current PHP version: ${CURRENT_PHP}${NC}"
        echo -e "${BLUE}Current Moodle version: ${CURRENT_MOODLE}${NC}"
    else
        echo -e "${RED}Dockerfile not found!${NC}"
        exit 1
    fi
}

# Function to update Dockerfile
update_dockerfile() {
    local php_version=$1
    local moodle_version=$2
    
    echo -e "${YELLOW}Updating Dockerfile...${NC}"
    
    # Backup original Dockerfile
    cp Dockerfile Dockerfile.backup
    
    # Update PHP version - use | as delimiter to avoid conflicts with /
    sed -i "s|php8\.[0-9]|php${php_version}|g" Dockerfile
    sed -i "s|/8\.[0-9]/|/${php_version}/|g" Dockerfile
    
    # Update Moodle version
    sed -i "s|stable[0-9]\+|stable${moodle_version}|g" Dockerfile
    sed -i "s|latest-[0-9]\+|latest-${moodle_version}|g" Dockerfile
    
    echo -e "${GREEN}Dockerfile updated successfully!${NC}"
    echo -e "${BLUE}Backup saved as Dockerfile.backup${NC}"
}

# Function to run tests
run_tests() {
    echo -e "${YELLOW}Running tests...${NC}"
    
    if [[ -f "vendor/bin/phpunit" ]]; then
        ./vendor/bin/phpunit --configuration phpunit.xml
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}All tests passed!${NC}"
            return 0
        else
            echo -e "${RED}Some tests failed!${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}PHPUnit not found, skipping tests${NC}"
        return 0
    fi
}

# Function to build and test Docker image
test_docker_build() {
    local php_version=$1
    local moodle_version=$2
    
    echo -e "${YELLOW}Testing Docker build...${NC}"
    
    # Build test image
    docker build -t moodle-test:latest .
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Docker build successful!${NC}"
        
        # Quick test - start container and check if it responds
        echo -e "${YELLOW}Testing container startup...${NC}"
        docker run -d --name moodle-test-container -p 8080:80 moodle-test:latest
        
        sleep 30  # Wait for startup
        
        if curl -f http://localhost:8080/moodle/ > /dev/null 2>&1; then
            echo -e "${GREEN}Container test successful!${NC}"
            docker stop moodle-test-container
            docker rm moodle-test-container
            return 0
        else
            echo -e "${RED}Container test failed!${NC}"
            docker logs moodle-test-container
            docker stop moodle-test-container
            docker rm moodle-test-container
            return 1
        fi
    else
        echo -e "${RED}Docker build failed!${NC}"
        return 1
    fi
}

# Main script logic
main() {
    case ${1:-"check"} in
        "check")
            echo -e "${BLUE}Checking current and latest versions...${NC}"
            get_current_versions
            
            echo -e "${YELLOW}Checking latest PHP version...${NC}"
            LATEST_PHP=$(get_latest_php_version)
            echo -e "${YELLOW}Checking latest Moodle version...${NC}"
            LATEST_MOODLE=$(get_latest_moodle_version)
            
            echo -e "${GREEN}Latest PHP version: ${LATEST_PHP}${NC}"
            echo -e "${GREEN}Latest Moodle version: ${LATEST_MOODLE}${NC}"
            
            if [[ "$CURRENT_PHP" != "$LATEST_PHP" ]] || [[ "$CURRENT_MOODLE" != "$LATEST_MOODLE" ]]; then
                echo -e "${YELLOW}Updates available!${NC}"
                echo -e "${BLUE}Run './scripts/update-versions.sh update' to update${NC}"
            else
                echo -e "${GREEN}Everything is up to date!${NC}"
            fi
            ;;
            
        "update")
            PHP_VERSION=${2:-}
            MOODLE_VERSION=${3:-}
            
            # If no versions specified, get latest stable (conservative)
            if [[ -z "$PHP_VERSION" ]]; then
                echo -e "${YELLOW}Getting latest stable PHP version...${NC}"
                PHP_VERSION=$(get_latest_php_version)
            fi
            
            if [[ -z "$MOODLE_VERSION" ]]; then
                echo -e "${YELLOW}Getting latest stable Moodle version...${NC}"
                MOODLE_VERSION=$(get_latest_moodle_version)
            fi
            
            echo -e "${BLUE}Updating to PHP ${PHP_VERSION} and Moodle ${MOODLE_VERSION}...${NC}"
            
            update_dockerfile "$PHP_VERSION" "$MOODLE_VERSION"
            
            if run_tests; then
                echo -e "${GREEN}Update completed successfully!${NC}"
                echo -e "${BLUE}Changes made to Dockerfile:${NC}"
                git diff --no-index --color=always Dockerfile.backup Dockerfile || true
                echo -e "${BLUE}You can now commit the changes and create a new release.${NC}"
                echo -e "${YELLOW}Commands to commit:${NC}"
                echo "  git add Dockerfile"
                echo "  git commit -m 'Update to PHP ${PHP_VERSION} and Moodle ${MOODLE_VERSION}'"
            else
                echo -e "${RED}Tests failed! Restoring backup...${NC}"
                mv Dockerfile.backup Dockerfile
                exit 1
            fi
            ;;
            
        "update-bleeding-edge")
            echo -e "${YELLOW}Using bleeding edge versions (latest available)...${NC}"
            PHP_VERSION=${2:-$(get_bleeding_edge_php_version)}
            MOODLE_VERSION=${3:-$(get_bleeding_edge_moodle_version)}
            
            echo -e "${BLUE}Updating to bleeding edge PHP ${PHP_VERSION} and Moodle ${MOODLE_VERSION}...${NC}"
            echo -e "${RED}Warning: These are the latest versions and may not be fully stable!${NC}"
            
            update_dockerfile "$PHP_VERSION" "$MOODLE_VERSION"
            
            if run_tests; then
                echo -e "${GREEN}Update completed successfully!${NC}"
                echo -e "${BLUE}Changes made to Dockerfile:${NC}"
                git diff --no-index --color=always Dockerfile.backup Dockerfile || true
                echo -e "${BLUE}You can now commit the changes and create a new release.${NC}"
                echo -e "${YELLOW}Commands to commit:${NC}"
                echo "  git add Dockerfile"
                echo "  git commit -m 'Update to bleeding edge PHP ${PHP_VERSION} and Moodle ${MOODLE_VERSION}'"
            else
                echo -e "${RED}Tests failed! Restoring backup...${NC}"
                mv Dockerfile.backup Dockerfile
                exit 1
            fi
            ;;
            
        "test")
            echo -e "${BLUE}Running full test suite...${NC}"
            get_current_versions
            
            if run_tests && test_docker_build "$CURRENT_PHP" "$CURRENT_MOODLE"; then
                echo -e "${GREEN}All tests passed!${NC}"
            else
                echo -e "${RED}Some tests failed!${NC}"
                exit 1
            fi
            ;;
            
        "help"|*)
            echo -e "${BLUE}Usage: $0 [command] [php_version] [moodle_version]${NC}"
            echo ""
            echo "Commands:"
            echo "  check                 - Check for available updates (default)"
            echo "  update                - Update to latest stable versions"
            echo "  update-bleeding-edge  - Update to absolute latest versions (may be unstable)"
            echo "  test                  - Run full test suite including Docker build"
            echo "  help                  - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 check"
            echo "  $0 update"
            echo "  $0 update 8.3 404"
            echo "  $0 update-bleeding-edge"
            echo "  $0 update-bleeding-edge 8.4 500"
            echo "  $0 test"
            echo ""
            echo "Version Strategy:"
            echo "  - 'update' uses conservative/stable versions (PHP 8.3, Moodle 4.x)"
            echo "  - 'update-bleeding-edge' uses absolute latest (PHP 8.4, Moodle 5.x)"
            ;;
    esac
}

# Create scripts directory if it doesn't exist
mkdir -p scripts

# Run main function with all arguments
main "$@"
