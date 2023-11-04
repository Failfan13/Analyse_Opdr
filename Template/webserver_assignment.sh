#!/usr/bin/env bash

# Define global variable here
config_file="dev.conf"
install_dir="$(grep -E "INSTALL_DIR=" "$config_file" | cut -d= -f2)"

# Declared necessary dependancies
declare -a dependancies=("unzip" "wget" "curl")

# Added necessary packages
declare -a packages=(
    "nosecrets APP1_URL"
    "pywebserver APP2_URL"
)

# Error handling function with 2 passable arguments
function handle_error() {
    # Do not remove next line!
    echo "function handle_error"

    #Display the given error code
    echo -e "Error: $1"

    #On error executable
    eval "$2"

    #Exit script
    exit 1
}
 
# Function to install dependencies & check folder structure
function setup() {
    # Do not remove next line!
    echo "function setup"

    # Function for checking folder structure
    folder_structure

    # Checks each dependency in $dependancies
    check_dependencies

    # Installer for packages in global variable
    install_packages
}

# Function to install packages with arguments package_name package_url
function install_package() {
    # Do not remove next line!
    echo "function install_package"

    pgk_name="$1"
    pkg_url="$2"

    # Checks each dependency in $dependancies
    check_dependencies

    # Check if file name and url are not empty
    if [ -z "$pgk_name" ] || [ -z "$pkg_url" ]; then
        handle_error "Package info could not be received"
    fi

    # Check if package folder already exists
    echo "Checking package folders"
    if [ ! -d "./$install_dir/$pgk_name" ]; then
        echo "Creating package folder"
        mkdir -p "./$install_dir/$pgk_name"
    elif [ -z "$(ls -A "./$install_dir/$pgk_name")" ]; then
        echo "Folder for $pgk_name already exists"
    else
        handle_error "$pgk_name already installed. Please remove if not working"
    fi

    # Check if URL is valid
    echo -e "\nValidating URL"
    if curl --output /dev/null --silent --head --fail "$pkg_url"; then
        echo "Url is accessable"
    else
        echo "Url is inaccessable"
        return
    fi

    # Download the zip file to downloads folder
    echo -e "\nDownloading package to downloads folder"
    mkdir ./downloads
    download="wget -qO ./downloads/$pgk_name.zip $pkg_url"

    # Download succesfull or not
    if [ -f "./downloads/$pgk_name.zip" ]; then
        echo "Package has already been downloaded"
    elif eval "$download"; then
        echo "Package succesfully downloaded"
    else
        handle_error "Package download failed, rolling back install" rollback_download
    fi

    # Unzipping downloaded file
    echo -e "\nUnzipping downloaded package"
    unzip="unzip ./downloads/$pgk_name.zip -d ./$install_dir"

    if [ ! -f "./downloads/$pgk_name.zip" ]; then
        echo "Package zip not found please re-install"
    elif eval "$unzip"; then
        echo "Package successfully unzipped"
    else
        handle_error "Failed to unzip, rolling back install" rollback_download
    fi

    # Install nosecrets
    if [ "$pgk_name" = "nosecrets" ]; then
        # Move all files from installation dir to "apps/nomoresecrets"
        mv apps/no-more-secrets-master/* apps/nosecrets

        # Instruction for "nms"
        if ! make -C "./apps/nosecrets" "nms"; then
            handle_error "Failed to setup the no-secrets file" rollback_nosecrets
        fi

        # Instruction for "make install"
        if ! sudo make install -C "./apps/nosecrets"; then
            handle_error "Installation of no-secrets has failed" rollback_nosecrets
        fi

        rm -rf apps/no-more-secrets-master

    # Install pywebserver
    elif [ "$pgk_name" = "pywebserver" ]; then
        # Move all files from installation dir to "apps/pywebserver"
        mv apps/webserver-master/* apps/pywebserver

        # Installation instruction for "pywebserver"
        if ! sudo curl \
            -L https://raw.githubusercontent.com/nickjj/webserver/v0.2.0/webserver \
            -o /usr/local/bin/webserver
        then
            handle_error "Installation of pywebserver has failed" rollback_pywebserver
        # Fix webserver no permission to /usr/local/bin/webserver error
        else
            sudo chmod +x /usr/local/bin/webserver;
        fi

        rm -rf apps/webserver-master
    fi
    echo "Installation of $pgk_name finished!"


# Clean download space
    rm ./downloads/"$pgk_name".zip
}

function rollback_nosecrets() {
    # Do not remove next line!
    echo "function rollback_nosecrets"

    # Remove nosecrets directives
    echo -e "Returning no-secrets to before installation state"
    rm -rf apps/nosecrets/
    rm -rf apps/no-more-secrets-master/
    rm -rf downloads/nosecrets.zip
    
    # Check if all folder removed 
    if [ -f "apps/nosecrets" ] || [ -f "apps/no-more-secrets-master" ] || [ -f "downloads/nosecrets.zip" ]; then
        handle_error "Some directives of no-secrets could not be removed"
    fi

    echo "Reversal of directives complete!"
}

function rollback_pywebserver() {
    # Do not remove next line!
    echo "function rollback_pywebserver"

    # Remove pywebserver directives
    echo -e "Returning no-secrets to before installation state"
    rm -rf apps/pywebserver/
    rm -rf apps/webserver-master/
    rm -rf downloads/pywebserver.zip
    
    # Check if all folder removed 
    if [ -f "apps/pywebserver" ] || [ -f "apps/webserver-master" ] || [ -f "downloads/pywebserver.zip" ]; then
        handle_error "The directives of pywebserver could not be removed"
    fi

    echo "Reversal of directives complete!"
}

function test_nosecrets() {
    # Do not remove next line!
    echo "function test_nosecrets"

    # Check if nosecrets installed & test if command reachable
    echo "Testing nosecrets"
    if [ ! -d "$install_dir/nosecrets" ] || [ "$(cmd_exists "nms")" = 1 ]; then
        handle_error "Could not test nosecrets: install directory missing or not fully installed"
    fi

    # Run instructed command
    ls -l | nms
}

function test_pywebserver() {
    # Do not remove next line!
    echo "function test_pywebserver"    

    # Extract server and port number from dev.conf & remove quote marks
    IP="$(grep -E "WEBSERVER_IP"= "$config_file" | cut -d= -f2 | bc)"
    PORT="$(grep -E "WEBSERVER_PORT"= "$config_file" | cut -d= -f2 | bc)"

    # Start the webserver
    "$install_dir"/pywebserver/webserver "$IP:$PORT" &

    # Server has time to start up
    sleep 3

    # 
    curl "$IP:$PORT"/ \
        -H "Content-Type: application/json" \
        -X POST --data @test.json

    kill %1
}

function uninstall_nosecrets() {
    # Do not remove next line!
    echo "function uninstall_nosecrets"  

    # Uninstalling nosecrets
    echo "Uninstalling no-secrets"
    if ! sudo make uninstall -C "./apps/nosecrets"; then
        handle_error "Could not be uninstalled! 
        Not installed or missing installation directory
        -- Please try running setup first"
    fi

    # Clean directives
    rollback_nosecrets

    echo "Succesfully removed!"
}

function uninstall_pywebserver() {
    # Do not remove next line!
    echo "function uninstall_pywebserver"    
    
    # Uninstall the pywebserver at root
    echo "Uninstalling pywebserver"
    if sudo rm -rf /usr/local/bin/webserver; then
        handle_error "Could not be uninstalled! 
        Not installed or missing installation directory
        -- Please try running setup first"
    fi

    # Clean directives
    rollback_pywebserver

    echo "Succesfully removed!"
}

#TODO removing installed dependency during setup() and restoring the folder structure to original state
function remove() {
    # Do not remove next line!
    echo "function remove"

    grep -e `date +%Y-%m-%d` /var/log/dpkg.log | awk '/install / {print $4}' | uniq | xargs sudo apt-get -y remove
    
}

function main() {
    # Do not remove next line!
    echo "function main"

# Verify supplied commands is 1 atleast
    if [ $# -lt 1 ]; then
        handle_error "No command supplied"
    fi

# Command and action given at excecution of script
    command="$1"
    action="$2"

# Format command(up/low) and action in particular style
    command_formatted_up="${command^^}"
    command_formatted_low="${command,,}"
    action_formatted="${action^^}"

# Verify command is available and run attachted function
    case $command_formatted_up in
        "SETUP")
            setup
            ;;
        "NOSECRETS" | "PYWEBSERVER")
# Add options for "install, uninstall and test"
            if [ "$action_formatted" = "--INSTALL" ];then
                for pkg in "${packages[@]}"; do
                    if [[ $pkg = *"$command_formatted_low"* ]]; then
                        read -ra pkg_url_arr <<< "$pkg"
                        install_package "$command_formatted_low" "$(grep -E "${pkg_url_arr[1]}"= "$config_file" | cut -d= -f2)"
                    fi
                done
            elif [ "$action_formatted" = "--UNINSTALL" ]; then
                eval uninstall_"$command_formatted_low"
            elif [ "$action_formatted" = "--TEST" ]; then
                eval test_"$command_formatted_low"
            else
                handle_error "Could not find accompanied action\nexiting..."
            fi
            ;;
        "REMOVE")
            remove
            ;;
        *)    
            handle_error "Could not find accompanied command\nexiting..."
        ;;
    esac
}

# Dependency checker arguments "package_name", "(true/false) auto install"
function check_dependency() {
    # Do not remove next line!
    echo "function check_dependency"

    # Check if dependency has a file location if to    yes (0/1) no
    installed=$(cmd_exists "$1")

    # If status installed found and return, otherwise provide installation instructions
    if [ "$installed" = 0 ]; then
        echo -e "Found and installed\n"
        return
    fi

    # Recursion for checking installed dependency
    echo -e "Missing dependency, trying to install\n"
    if [ "$2" != false ]; then
        "$(sudo apt-get install "$1")"
        check_dependency "$1" false
    else
        handle_error "$1 not able to install, To install please use: sudo apt install $1\n"
    fi
}

function check_dependencies()
{
    echo -e "\nChecking required dependencies"
    for pkg in "${dependancies[@]}";
    do
        echo "Checking dependency: $pkg"
        check_dependency "$pkg"
    done
}

# Installs all packages in the global variable $packages
function install_packages() 
{
    # Call install_package for each package in global packages variable
    echo -e "Installing packages"
    for pkg in "${packages[@]}"; 
    do
        read -ra pkg_url_arr <<< "$pkg"
        url="$(grep -E "${pkg_url_arr[1]}"= "$config_file" | cut -d= -f2)"
        install_package "${pkg_url_arr[0]}" "$url"
    done
}

# Checks if given command exists and returns 0/1 to caller
function cmd_exists()
{
    # If command response yes/0 or no/1
    if command -v "$1" > /dev/null; then
        echo 0
    else
        echo 1
    fi
}

# Folder checking one argument "install_dir"
function folder_structure()
{
    # Do not remove next line!
    echo "function folder_structure"

    # Checking the file & folder structure
    echo -e "\nChecking folder structure"

    echo "Checking config file"
    if [ ! -f "dev.conf" ]; then
        handle_error "Missing dev.conf file"
    else
        echo "Verified dev.conf"
    fi

    echo "Checking test file"
    if [ ! -f "test.json" ]; then
        handle_error "Missing test.json"
    else
        echo "Verified test.json"
    fi

    echo "Checking installation folder"
    if [ ! -d "./$install_dir/" ] && [ ! "$install_dir" = "" ]; then
        echo "Creating installation folder"
        mkdir "./$install_dir/"
    else
        echo "Verified apps folder"
    fi
    
    echo "Checking download folder"
    if [ ! -d "./downloads/" ]; then
        echo "Creating download folder"
        mkdir ./downloads/
    else
        echo "Verified download folder"
    fi

    echo "Folder structure verified"
}

# Remove most recent zip file
function rollback_download() 
{
    # Sorts download on time takes most recent and removes this
    rm "$(stat -c "%Y:%n" ./downloads/* | sort -t: -n | tail -1 | cut -d: -f2-)"
}

# Pass commandline arguments to function main
main "$@"