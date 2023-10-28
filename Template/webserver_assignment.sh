#!/usr/bin/env bash

# Define global variable here
config_file="config.conf"

# TODO: Add required and additional packagenas dependecies 
# for your implementation
# declare -a packages=()
declare -a packages=""

# TODO: define a function to handle errors
# This funtion accepts two parameters one as the error message and one as the command to be excecuted when error occurs.
function handle_error() {
    # Do not remove next line!
    echo "function handle_error"

   # TODO Display error and return an exit code
   echo -e "Error: $1"
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

    # TODO check if required dependency is not already installed otherwise install it
    # if a a problem occur during the this process 
    # use the function handle_error() to print a messgage and handle the error

    # TODO check if required folders and files exists before installations
    # For example: the folder ./apps/ and the file "dev.conf"

}

# Function to install a package from a URL
# TODO assign the required parameter needed for the logic
# complete the implementation of the following function.
function install_package() {
    # Do not remove next line!
    echo "function install_package"

    # TODO The logic for downloading from a URL and unizpping the downloaded files of different applications must be generic

    # TODO Specific actions that need to be taken for a specific application during this process should be handeld in a separate if-else

    # TODO Every intermediate steps need to be handeld carefully. error handeling should be dealt with using handle_error() and/or rolleback()

    # TODO If a file is downloaded but cannot be zipped a rollback is needed to be able to start from scratch
    # for example: package names and urls that are needed are passed or extracted from the config file

    # TODO check if the application-folder and the url of the dependency exist
    # TODO create a specific installation folder for the current package

    # TODO Download and unzip the package
    # if a a problem occur during the this proces use the function handle_error() to print a messgage and handle the error

    # TODO extract the package to the installation folder and store it into a dedicated folder
    # If a problem occur during the this proces use the function handle_error() to print a messgage and handle the error

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

    # TODO
    # Add verification that a command has been passed to script

# Command and action given at excecution of script
    command="$1"
    action="$2"

# Format command and action in particular style
    command_formatted="${command^^}"
    action_formatted="${action^^}"

# Verify command is available and run attachted function
    case $command_formatted in
        "SETUP")
            echo -n "Setup..."
            ;;
        "NOSECRETS")
# Add options for "install, uninstall and test"
            if [ "$action_formatted" = "--INSTALL" ];then
                echo $action_formatted"inst"
            elif [ "$action_formatted" = "--UNINSTALL" ]; then
                echo $action_formatted"uninst"
            elif [ "$action_formatted" = "--TEST" ]; then
                echo $action_formatted"test"
            else
                handle_error "Could not find accompanied action\nexiting..."
            fi
            ;;
        "PYWEBSERVER")
            echo -n "Pywebserver..."
            ;;
        "REMOVE")
            echo -n "Removing..."
            ;;
        *)    
            handle_error "Could not find accompanied command\nexiting..."
        ;;
    esac

    # Check if the second argument is provided on the command line
    # Check if the second argument is valid
    # allowed values are "--install" "--uninstall" "--test"
    # bash must exit if value does not match one of those values

    # Execute the appropriate command based on the arguments
    # TODO In case of setup
    # excute the function check_dependency and provide necessary arguments
    # expected arguments are the installation directory specified in dev.conf

}

# Pass commandline arguments to function main
main "$@"


# # Add user input reqest
#     read -rp "Enter command: " u_input
# #Convert input to upper & remove spaces from input
#     u_input_lower="${u_input^^}"
#     u_input_converted="${u_input_lower// /}"