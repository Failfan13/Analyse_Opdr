#!/usr/bin/env bash

# Define global variable here
config_file="dev.conf"
install_dir=""

# Declared necessary dependancies
declare -a dependancies=("unzip" "wget" "curl")

# Added necessary packages
declare -a packages=("nosecrets" "pywebserver")

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
 
# Function to solve dependencies
function setup() {
    # Do not remove next line!
    echo "function setup"

    # Set install directory to conf specified and use cut to remove variable name
    install_dir="$(grep -E "INSTALL_DIR=" "$config_file" | cut -d= -f2)"

    # Function for checking folder structure
    folder_structure

    # Checks each dependency in $dependancies
    echo -e "\nChecking required dependencies"
    for pkg in "${dependancies[@]}";
    do
        echo "Checking dependency: $pkg"
        check_dependency "$pkg"
    done

    # Call install_package for each package in global packages variable
    echo -e "Installing packages"
    iter=0
    for pkg in "${packages[@]}"; 
    do
        url="$(grep -E "APP"$(("$iter" + 1))"_URL=" "$config_file" | cut -d= -f2)"
        install_package "$pkg" "$url"
        iter=$(("iter" + 1))
    done
}

# Function to install a package from a URL
# TODO assign the required parameter needed for the logic
# complete the implementation of the following function.

# Function to install packages with arguments package_name
function install_package() {
    # Do not remove next line!
    echo "function install_package"

    pgk_name="$1"
    pkg_url="$2"

# Check if file name and url are not empty
    if [ -z "$pgk_name" ] || [ -z "$pkg_url" ]; then
        handle_error "Package info could not be received"
    fi

# Check if package folder already exists
    echo "Checking package folders"
    if [ ! -d "./$install_dir/$pgk_name" ]; then
        echo "Creating package folder"
        mkdir "./$install_dir/$pgk_name"
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
    download="wget -qO ./downloads/$pgk_name.zip $pkg_url"

# Download succesfull or not
    if [ -f "./downloads/$pgk_name.zip" ]; then
        echo "Package has already been downloaded"
    elif eval "$download"; then
        echo "Package succesfully downloaded"
    else
        handle_error "Package download failed, rolling back install"
# ---------------- rollback hiero
    fi

# Unzipping downloaded file
    echo -e "\nUnzipping downloaded package"
    unzip="unzip -j ./downloads/$pgk_name -d ./$install_dir/$pgk_name"
    if [ ! -f "./downloads/$pgk_name.zip" ]; then
        echo "Package zip not found please re-install"
    elif eval "$unzip"; then
        echo "Package successfully unzipped"
    else
        handle_error "Failed to unzip, rolling back install"
    fi

    # TODO this section can be used to implement application specifc logic
    # nosecrets might have additional commands that needs to be executed
    # make sure the user is allowed to remove this folder during uninstall
}

function rollback_nosecrets() {
    # Do not remove next line!
    echo "function rollback_nosecrets"

    # TODO rollback intermiediate steps when installation fails
}

function rollback_pywebserver() {
    # Do not remove next line!
    echo "function rollback_pywebserver"

    # TODO rollback intermiediate steps when installation fails
}

function test_nosecrets() {
    # Do not remove next line!
    echo "function test_nosecrets"

    # TODO test nosecrets
    # kill this webserver process after it has finished its job

}

function test_pywebserver() {
    # Do not remove next line!
    echo "function test_pywebserver"    

    # TODO test the webserver
    # server and port number must be extracted from config.conf
    # test data must be read from test.json  
    # kill this webserver process after it has finished its job

}

function uninstall_nosecrets() {
    # Do not remove next line!
    echo "function uninstall_nosecrets"  

    #TODO uninstall nosecrets application
}

function uninstall_pywebserver() {
    echo "function uninstall_pywebserver"    
    #TODO uninstall pywebserver application
}

#TODO removing installed dependency during setup() and restoring the folder structure to original state
function remove() {
    # Do not remove next line!
    echo "function remove"

    # Remove each package that was installed during setup
    
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
                echo $command_formatted_low"--install"
            elif [ "$action_formatted" = "--UNINSTALL" ]; then
                echo $command_formatted_low"--uninstall"
            elif [ "$action_formatted" = "--TEST" ]; then
                echo $command_formatted_low"--test"
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

    # Execute the appropriate command based on the arguments
    # TODO In case of setup
    # excute the function check_dependency and provide necessary arguments
    # expected arguments are the installation directory specified in dev.conf
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
    echo -e "Checking folder structure\n"

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

# Pass commandline arguments to function main
main "$@"