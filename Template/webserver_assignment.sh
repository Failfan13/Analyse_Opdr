@@ -1,13 +1,14 @@
#!/usr/bin/env bash

# Define global variable here
config_file="config.conf"
config_file="dev.conf"
install_dir=""

# Declared necessary dependancies
declare -a dependancies=("unzip" "wget" "curl")

# Added necessary packages
declare -a packages=("")
declare -a packages=("nosecrets" "pywebserver")

# Error handling function with 2 passable arguments
function handle_error() {
@ -29,29 +30,54 @@ function setup() {
    # Do not remove next line!
    echo "function setup"
    
# Checks each dependency in $dependancies
    for pkg in "${dependancies[@]}"; do
    # Checks each dependency in $dependancies
    for pkg in "${dependancies[@]}";
    do
        echo "Checking dependency: $pkg"
        check_dependency "$pkg"
    done

    # TODO check if nessassary dependecies and folder structure exists and 
    # print the outcome for each checking step
    
    # TODO installation from online package requires values for
    # package_name package_url install_dir
    # Set install directory to conf specified and use cut to remove variable name
    install_dir="$(grep -E "INSTALL_DIR=" "$config_file" | cut -d= -f2)"

    # Function for checking folder structure
    folder_structure

    # Call install_package for each package in global packages variable
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

    setup
    pgk_name="$1"
    pkg_url="$2"

# Check if file name and url are not empty
    if [ "$pgk_name" = "" ] || [ "$pkg_url" = "" ]; then
        handle_error "Package info could not be received"
    fi

# Check if package folder already exists
    echo "Checkinf package folders"
    if [ ! -d "./$install_dir/$pgk_name" ]; then
        echo "Creating package folder"
        mkdir "./$install_dir/$pgk_name"
    elif [ -z "$(ls -A "./$install_dir/$pgk_name")" ]; then
        echo "Package $pgk_name already exists"
    fi

    # TODO The logic for downloading from a URL and unizpping the downloaded files of different applications must be generic
    echo "Downloading $pgk_name"
    powershell -Command "Invoke-WebRequest $pkg_url -Outfile $pgk_name.exe name"
    echo "Done!"
    echo "Unzipping $pgk_name.."
    

@ -63,7 +89,7 @@ function install_package() {
    # for example: package names and urls that are needed are passed or extracted from the config file

    # TODO check if the application-folder and the url of the dependency exist
    if $pkg_url %errorlevel% ==0 (
    echo "Done.."
    ) else (
    echo "Not Done...!"
    )
    if $pgk_name %errorlevel% ==0 (
    echo "Done.."
    ) else (
    echo "Not Done...!"
    )
    # TODO create a specific installation folder for the current package
    powershell md Install

    # TODO Download and unzip the package
    powershell "Expand-Archive $pgk_name -DestinationPath C:\Users\Roggerio\Install"
    # if a a problem occur during the this proces use the function handle_error() to print a messgage and handle the error
@ -168,7 +194,7 @@ function main() {
            fi
            ;;
        "REMOVE")
                remove
            remove
            ;;
        *)    
            handle_error "Could not find accompanied command\nexiting..."
@ -185,16 +211,17 @@ function main() {
function check_dependency() {
    # Do not remove next line!
    echo "function check_dependency"
# Find dependency by name in installed packages and save the Status

    # Find dependency by name in installed packages and save the Status
    installed=$(dpkg-query -W -f='${Status}' "$1")

# If status installed found and return, otherwise provide installation instructions
    # If status installed found and return, otherwise provide installation instructions
    if [ "$installed" = "install ok installed" ]; then
        echo -e "Found and installed\n"
        return
    fi

# Recursion for checking installed dependency
    # Recursion for checking installed dependency
    echo -e "Missing dependency, trying to install\n"
    if [ "$2" != false ]; then
        "$(sudo apt-get install "$1")"
@ -204,39 +231,47 @@
    fi
}

# Folder checking one argument "install_dir"
function folder_structure()
{
    # Do not remove next line!
    echo "function folder_structure"

# Checking the file & folder structure
    # Checking the file & folder structure
    echo -e "Checking folder structure\n"


    echo "Checking apps folder"
    if [ ! -d "./apps/" ]; then
        echo "Creating apps folder"
        mkdir ./apps/
    else
        echo "Verified apps folder"
    fi

    echo "Checking dev.conf"
    echo "Checking config file"
    if [ ! -f "dev.conf" ]; then
        handle_error "Missing dev.conf file"
    else
        echo "Verified dev.conf"
    fi

    echo "Checking test.json"
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