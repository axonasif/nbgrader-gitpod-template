#!/bin/bash

# Function to display usage and exit
usage() {
    echo "Usage: $0 <directory>"
    echo "   where <directory> is one of: A, Ass, Assignment, W, Workshops, Work"
    exit 1
}

# Validate and process the argument
if [ $# -ne 1 ]; then
    usage
fi

# Convert argument to lowercase for case-insensitive comparison
arg=$(echo "$1" | tr '[:upper:]' '[:lower:]')

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

# Launch Jupyter Notebook with desired options
jupyter notebook --NotebookApp.allow_origin='*' \
                 --NotebookApp.allow_remote_access=True \
                 --NotebookApp.token='' \
                 --NotebookApp.password='' \
                 --no-browser \
                 --port=8888