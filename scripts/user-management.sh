#!/bin/bash

# Jitsi Meet User Management Script
# This script helps manage Jitsi Meet users and administrators

DOCKER_COMPOSE_FILE="docker-compose.yml"
PROSODY_CONTAINER="jitsi-prosody"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to check if containers are running
check_containers() {
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Jitsi containers are not running. Please start them first:"
        print_status "docker-compose up -d"
        exit 1
    fi
}

# Function to create a new user
create_user() {
    local username=$1
    local password=$2
    
    if [ -z "$username" ] || [ -z "$password" ]; then
        print_error "Usage: create_user <username> <password>"
        return 1
    fi
    
    print_status "Creating user: $username"
    
    # Execute prosodyctl in the container
    docker exec -it $PROSODY_CONTAINER prosodyctl --config /config/prosody.cfg.lua register "$username" "auth.meet.jitsi" "$password"
    
    if [ $? -eq 0 ]; then
        print_status "User '$username' created successfully!"
        print_warning "Please save these credentials securely:"
        echo "Username: $username"
        echo "Password: $password"
        echo "Domain: auth.meet.jitsi"
    else
        print_error "Failed to create user '$username'"
    fi
}

# Function to delete a user
delete_user() {
    local username=$1
    
    if [ -z "$username" ]; then
        print_error "Usage: delete_user <username>"
        return 1
    fi
    
    print_warning "Deleting user: $username"
    
    docker exec -it $PROSODY_CONTAINER prosodyctl --config /config/prosody.cfg.lua unregister "$username" "auth.meet.jitsi"
    
    if [ $? -eq 0 ]; then
        print_status "User '$username' deleted successfully!"
    else
        print_error "Failed to delete user '$username'"
    fi
}

# Function to list users
list_users() {
    print_status "Listing registered users:"
    # Alternative method since mod_listusers is not available
    docker exec $PROSODY_CONTAINER ls -la /config/data/auth%2emeet%2ejitsi/accounts/ | grep '\.dat$' | awk '{print $9}' | sed 's/\.dat$//' | while read user; do
        if [ "$user" != "focus" ] && [ "$user" != "jvb" ]; then
            echo "User: $user@auth.meet.jitsi"
        fi
    done
}

# Function to change user password
change_password() {
    local username=$1
    local new_password=$2
    
    if [ -z "$username" ] || [ -z "$new_password" ]; then
        print_error "Usage: change_password <username> <new_password>"
        return 1
    fi
    
    print_status "Changing password for user: $username"
    
    docker exec -it $PROSODY_CONTAINER prosodyctl --config /config/prosody.cfg.lua passwd "$username@auth.meet.jitsi" "$new_password"
    
    if [ $? -eq 0 ]; then
        print_status "Password changed successfully for user '$username'!"
    else
        print_error "Failed to change password for user '$username'"
    fi
}

# Function to create admin user
create_admin() {
    local admin_username=$1
    local admin_password=$2
    
    if [ -z "$admin_username" ] || [ -z "$admin_password" ]; then
        print_error "Usage: create_admin <admin_username> <admin_password>"
        return 1
    fi
    
    print_status "Creating admin user: $admin_username"
    
    # Create the user first
    create_user "$admin_username" "$admin_password"
    
    # Add admin privileges (this would require additional Prosody configuration)
    print_status "Admin user '$admin_username' created!"
    print_warning "To enable full admin features, you need to:"
    print_status "1. Set ENABLE_AUTH=1 in your .env file"
    print_status "2. Set ENABLE_GUESTS=0 to disable guest access"
    print_status "3. Restart services: docker-compose restart"
}

# Function to enable authentication
enable_auth() {
    print_status "Enabling authentication..."
    
    if [ -f ".env" ]; then
        # Update .env file
        sed -i 's/ENABLE_AUTH=0/ENABLE_AUTH=1/' .env
        sed -i 's/ENABLE_GUESTS=1/ENABLE_GUESTS=0/' .env
        
        print_status "Authentication enabled in .env file"
        print_warning "Please restart services: docker-compose restart"
    else
        print_error ".env file not found. Please create it from .env.example"
    fi
}

# Function to disable authentication (back to public)
disable_auth() {
    print_status "Disabling authentication (making public)..."
    
    if [ -f ".env" ]; then
        # Update .env file
        sed -i 's/ENABLE_AUTH=1/ENABLE_AUTH=0/' .env
        sed -i 's/ENABLE_GUESTS=0/ENABLE_GUESTS=1/' .env
        
        print_status "Authentication disabled in .env file"
        print_warning "Please restart services: docker-compose restart"
    else
        print_error ".env file not found. Please create it from .env.example"
    fi
}

# Function to show help
show_help() {
    print_header "Jitsi Meet User Management"
    echo
    echo "Usage: $0 <command> [arguments]"
    echo
    echo "Commands:"
    echo "  create_user <username> <password>     - Create a new user"
    echo "  create_admin <username> <password>    - Create an admin user"
    echo "  delete_user <username>                - Delete a user"
    echo "  list_users                            - List all registered users"
    echo "  change_password <username> <password> - Change user password"
    echo "  enable_auth                           - Enable authentication (private mode)"
    echo "  disable_auth                          - Disable authentication (public mode)"
    echo "  help                                  - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 create_admin admin secretpassword123"
    echo "  $0 create_user john mypassword456"
    echo "  $0 enable_auth"
    echo "  $0 list_users"
    echo
}

# Main script logic
case "$1" in
    "create_user")
        check_containers
        create_user "$2" "$3"
        ;;
    "create_admin")
        check_containers
        create_admin "$2" "$3"
        ;;
    "delete_user")
        check_containers
        delete_user "$2"
        ;;
    "list_users")
        check_containers
        list_users
        ;;
    "change_password")
        check_containers
        change_password "$2" "$3"
        ;;
    "enable_auth")
        enable_auth
        ;;
    "disable_auth")
        disable_auth
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    "")
        print_error "No command specified"
        show_help
        exit 1
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
