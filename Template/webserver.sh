#!/usr/bin/env bash

# Students:
#    Roggerio Hartmann 1014804 
#    Erik Maan 1033231

# Define global variable here
config_file="dev.conf"
install_dir=""

# TODO: Add required and additional packagenas dependecies 
# for your implementation
declare -a packages=("unzip" "wget" "curl")

# TODO: define a function to handle errors
# This funtion accepts two parameters one as the error message and one as the command to be excecuted when error occurs.
function handle_error() {
    # Do not remove next line!
    echo "function handle_error"

   # TODO Display error and return an exit code
   # Display the given error code
    echo -e "Error: $1"
   # On error executable
    eval "$2"
   # Exit script
    exit 1
}
 
# Function to solve dependencies
function setup() {
    # Do not remove next line!
    echo "function setup"

    # TODO check if nessassary dependecies and folder structure exists and 
    # print the outcome for each checking step
    
    # TODO installation from online package requires values for
    # package_name package_url install_dir
    # Setting install_dir to value from .conf
    install_dir=$(get_install_dir)

    # TODO check if required dependency is not already installed otherwise install it
    # if a a problem occur during the this process 
    # use the function handle_error() to print a messgage and handle the error
    check_dependencies

    # TODO check if required folders and files exists before installations
    # For example: the folder ./apps/ and the file "dev.conf"
    # Checking the file & folder structure
    check_folders

    echo "Setup finished!"
}

# Checking single dependency with package_name, (true/false) auto install
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

# Install all nessisary packages
function check_dependencies()
{
    echo -e "\nChecking required dependencies"
    for pkg in "${packages[@]}";
    do
        echo "Checking dependency: $pkg"
        check_dependency "$pkg"
    done
}

# Function to install a package from a URL
# TODO assign the required parameter needed for the logic
# complete the implementation of the following function.
function install_package() {
    # Do not remove next line!
    echo "function install_package"

    pgk_name="$1"
    pkg_url="$2"

    # Check for nessisary folders for installing
    check_folders

    # Check if dependencies are installed
    check_dependencies

    # Set install_dir to install folder
    install_dir=$(get_install_dir)

    # TODO The logic for downloading from a URL and unizpping the downloaded files of different applications must be generic
    # Check if file name and url are not empty
    if [ -z "$pgk_name" ] || [ -z "$pkg_url" ]; then
        handle_error "Package info could not be received, please run setup first"
    fi

    # TODO Specific actions that need to be taken for a specific application during this process should be handeld in a separate if-else

    # TODO Every intermediate steps need to be handeld carefully. error handeling should be dealt with using handle_error() and/or rolleback()

    # TODO If a file is downloaded but cannot be zipped a rollback is needed to be able to start from scratch
    # for example: package names and urls that are needed are passed or extracted from the config file

    # TODO check if the application-folder and the url of the dependency exist
    # TODO create a specific installation folder for the current package
    # Check if package folder exists ortherwise create it
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

    # TODO Download and unzip the package
    # if a a problem occur during the this proces use the function handle_error() to print a messgage and handle the error
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

    # TODO extract the package to the installation folder and store it into a dedicated folder
    # If a problem occur during the this proces use the function handle_error() to print a messgage and handle the error
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

    # TODO this section can be used to implement application specifc logic
    # nosecrets might have additional commands that needs to be executed
    # make sure the user is allowed to remove this folder during uninstall
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

    # TODO rollback intermiediate steps when installation fails
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

    # TODO rollback intermiediate steps when installation fails
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

    # TODO test nosecrets
    # kill this webserver process after it has finished its job
    # Check if nosecrets installed & test if command reachable
    echo "Testing nosecrets"
    if [ ! -d "apps/nosecrets" ] || [ "$(cmd_exists "nms")" = 1 ]; then
        handle_error "Could not test nosecrets: install directory missing or not fully installed"
    fi

    # Run instructed command
    ls -l | nms

    echo "Test successfull!"
}

function test_pywebserver() {
    # Do not remove next line!
    echo "function test_pywebserver"    

    # TODO test the webserver
    # server and port number must be extracted from config.conf
    # test data must be read from test.json  
    # kill this webserver process after it has finished its job
    if [ ! "$(cmd_exists "webserver")" = 0 ] || [ ! -d ./"apps"/pywebserver ]; then
        handle_error "Pywebserver is not installed, please run setup before attempting to test"
    fi

    # Extract server and port number from dev.conf & remove quote marks
    IP="$(grep -E "WEBSERVER_IP"= "$config_file" | cut -d= -f2 | bc)"
    PORT="$(grep -E "WEBSERVER_PORT"= "$config_file" | cut -d= -f2 | bc)"

    # Start the webserver
    apps/pywebserver/webserver "$IP:$PORT"

    # Server has time to start up
    sleep 3

    Test the pywebserver using instruction
    if ! curl "$IP:$PORT"/ \
        -H "Content-Type: application/json" \
        -X POST --data @test.json; then
        handle_error "The test could not be concluded: missing curl dependency, please run setup"
    fi

    # Close the open server
    kill %1

    echo "Test succesfull!"
}

function uninstall_nosecrets() {
    # Do not remove next line!
    echo "function uninstall_nosecrets"  

    #TODO uninstall nosecrets application
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
    echo "function uninstall_pywebserver"    
    #TODO uninstall pywebserver application
    # Uninstall the pywebserver at root
    echo "Uninstalling pywebserver"
    if ! sudo rm -rf /usr/local/bin/webserver; then
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

    # Remove each package that was installed during setup
    # Group by date from dpkg.log, outsorts the logs with "install", removes duplicate installations & removes the downloads
    grep -e "$(date +%Y-%m-%d)" /var/log/dpkg.log | awk '/install / {print $4}' | uniq | xargs sudo apt-get -y remove
}

function main() {
    # Do not remove next line!
    echo "function main"

    # TODO
    # Read global variables from configfile

    # Get arguments from the commandline
    # Check if the first argument is valid
    # allowed values are "setup" "nosecrets" "pywebserver" "remove"
    # bash must exit if value does not match one of those values
    # Check if the second argument is provided on the command line
    # Check if the second argument is valid
    # allowed values are "--install" "--uninstall" "--test"
    # bash must exit if value does not match one of those values

    # Execute the appropriate command based on the arguments
    # TODO In case of setup
    # excute the function check_dependency and provide necessary arguments
    # expected arguments are the installation directory specified in dev.conf

    # Command and action given at excecution of script
    command="${1,,}"
    action="${2,,}"

    single_commands=("setup" "remove")
    multiple_commands=("nosecrets" "pywebserver" )

    if [[ "${single_commands[*]}" =~ ${command} ]]; then
        eval "$command"
    elif [[ "${multiple_commands[*]}" =~ ${command} ]] && [[ "(--install --test --uninstall)" =~ ${action} ]]; then
        if [ "$action" = "--install" ]; then
            if [ "$command" = "nosecrets" ]; then
                install_package "$command" "$(grep -E "APP1_URL"= "$config_file" | cut -d= -f2)"
            elif [ "$command" = "pywebserver" ]; then
                install_package "$command" "$(grep -E "APP2_URL"= "$config_file" | cut -d= -f2)"
            fi
        elif [ "$action" = "--uninstall" ]; then
            eval uninstall_"$command"
        elif [ "$action" = "--test" ]; then
            eval test_"$command"
        else
            echo "Could not find accompanied command:
            ./webserver nosecrets --install/--uninstall/--test
            ./webserver pywebserver --install/--uninstall/--test"
        fi
    else
        echo "Could not find command:
        ./webserver setup
        ./webserver remove
        ./webserver nosecrets --install/--uninstall/--test
        ./webserver pywebserver --install/--uninstall/--test"
    fi
}

# Function returns the install_dir from .conf file
function get_install_dir()
{
    echo | grep -E "INSTALL_DIR=" "$config_file" | cut -d= -f2
}

# Function checks all folders for existance & installs them if not existing
function check_folders()
{
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

# Pass commandline arguments to function main
main "$@"