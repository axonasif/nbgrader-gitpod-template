#!/bin/bash

# Function to display usage and exit
usage() {
    echo "Usage: $0 <directory>"
    echo "   where <directory> is one of: A, Ass, Assignment, W, Work, Workshops."
    exit 1
}

# Validate and process the argument
if [ $# -ne 1 ]; then
    usage
fi


# Persist state for auto-start on workspace reboot
statefile=/workspace/.gogostate
if test ! -e "${statefile}"; then {
    printf '%s,%s\n' "${GITPOD_INSTANCE_ID}" "${arg}" > "${statefile}"
} else {
    IFS=',' read -r iid sarg < "${statefile}"
    if test "${iid}" != "${GITPOD_INSTANCE_ID}"; then
        printf '%s,%s\n' "${GITPOD_INSTANCE_ID}" "${arg}" > "${statefile}"
        # Set arg
        arg="${sarg}"
    fi
} fi


# Convert argument to lowercase for case-insensitive comparison
if test ! -v arg; then
    arg=$(echo "$1" | tr '[:upper:]' '[:lower:]')
fi

# Navigate to the appropriate directory based on the argument
case "$arg" in
    a|ass|assignments)
        target_dir="$GITPOD_REPO_ROOT/nbgrader/Assignments"
        ;;
    w|work|workshops)
        target_dir="$GITPOD_REPO_ROOT/nbgrader/Workshops"
        ;;
    *)
        echo "Error: Invalid argument '$1'."
        usage
        ;;
esac

# Check if the target directory exists
if [ ! -d "$target_dir" ]; then
    echo "Error: Directory '$target_dir' does not exist."
    exit 1
fi

# Change to the target directory
cd "$target_dir" || exit

# Launch Jupyter Lab with desired options
jupyter lab --port 8888 --ServerApp.token='' --ServerApp.allow_remote_access=true --no-browser