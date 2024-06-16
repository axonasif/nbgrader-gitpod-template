#!/bin/bash

# Function to print usage information
usage() {
  echo "Usage: $0 --submissions <submissions_dir> --assignment <assignment_name> --idlist <idlist_file> [--course <course_name>]"
  exit 1
}

# Default values
COURSE_NAME="Assignments"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --submissions)
      SUBMISSIONS_DIR="$2"
      shift; shift
      ;;
    --assignment)
      ASSIGNMENT_NAME="$2"
      shift; shift
      ;;
    --idlist)
      IDLIST_FILE="$2"
      shift; shift
      ;;
    --course)
      COURSE_NAME="$2"
      shift; shift
      ;;
    *)
      usage
      ;;
  esac
done

# Check if required arguments are provided
if [[ -z "$SUBMISSIONS_DIR" || -z "$ASSIGNMENT_NAME" || -z "$IDLIST_FILE" ]]; then
  usage
fi

# Define the base directory
GITPOD_REPO_ROOT="${GITPOD_REPO_ROOT:-$PWD}"
NBGRADER_ASSIGNMENTS_DIR="$GITPOD_REPO_ROOT/nbgrader/$COURSE_NAME"

# Check for the existence of the nbgrader assignments directory
if [[ ! -d "$NBGRADER_ASSIGNMENTS_DIR" ]]; then
  echo "Directory $NBGRADER_ASSIGNMENTS_DIR not found."
  exit 1
fi

# Load student ID numbers from the idlist file
if [[ ! -f "$IDLIST_FILE" ]]; then
  echo "ID list file $IDLIST_FILE not found."
  exit 1
fi

# Read student IDs into an array
mapfile -t STUDENT_IDS < "$IDLIST_FILE"
echo "Total count of ID numbers loaded: ${#STUDENT_IDS[@]}"

# Check and create directories for each student ID
for ID in "${STUDENT_IDS[@]}"; do
  STUDENT_DIR="$NBGRADER_ASSIGNMENTS_DIR/$ID"
  if [[ ! -d "$STUDENT_DIR" ]]; then
    echo "Directory for student ID $ID not found, creating it."
    mkdir -p "$STUDENT_DIR"
  fi
done

# Check if submissions directory exists
if [[ ! -d "$SUBMISSIONS_DIR" ]]; then
  echo "Submissions directory $SUBMISSIONS_DIR not found."
  exit 1
fi

# Report total count of files without the .ipynb extension and delete them
NON_IPYNB_COUNT=$(find "$SUBMISSIONS_DIR" -type f ! -name "*.ipynb" | wc -l)
echo "Total count of files without .ipynb extension: $NON_IPYNB_COUNT"
find "$SUBMISSIONS_DIR" -type f ! -name "*.ipynb" -delete

# Report count of files with .ipynb extension
IPYNB_COUNT=$(find "$SUBMISSIONS_DIR" -type f -name "*.ipynb" | wc -l)
echo "Total count of files with .ipynb extension: $IPYNB_COUNT"

# Counter for the number of files moved
FILES_MOVED_COUNT=0

# Process each .ipynb file in the submissions directory
for file in "$SUBMISSIONS_DIR"/*.ipynb; do
  if [[ -f "$file" ]]; then
    # Extract the filename from the full path
    filename=$(basename "$file")
    
    # Use awk to extract the first run of numbers between underscores (student ID)
    SID=$(echo "$filename" | /usr/bin/awk -F'_' '{for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+$/) {print $i; exit}}')
    
    # If a student ID was found in the filename
    if [[ -n "$SID" ]]; then
      STUDENT_DIR="$NBGRADER_ASSIGNMENTS_DIR/$SID"
      
      # Check if the student directory exists
      if [[ -d "$STUDENT_DIR" ]]; then
        STUDENT_ASSIGNMENT_DIR="$STUDENT_DIR/$ASSIGNMENT_NAME"
        
        # Create the assignment directory if it does not exist
        if [[ ! -d "$STUDENT_ASSIGNMENT_DIR" ]]; then
          echo "Creating directory $STUDENT_ASSIGNMENT_DIR"
          mkdir -p "$STUDENT_ASSIGNMENT_DIR"
        fi

        TARGET_FILE="$STUDENT_ASSIGNMENT_DIR/$ASSIGNMENT_NAME.ipynb"
        
        # Check if the target file already exists
        if [[ -f "$TARGET_FILE" ]]; then
          echo "Skip submission: $SID"
          rm "$file"
        else
          echo "Moving file $filename to $TARGET_FILE"
          mv "$file" "$TARGET_FILE"
          FILES_MOVED_COUNT=$((FILES_MOVED_COUNT + 1))
        fi
      else
        echo "Student directory $STUDENT_DIR not found, skipping file $filename"
      fi
    else
      echo "No student ID found in filename $filename"
    fi
  fi
done

# Report the number of files moved
echo "Total number of files moved: $FILES_MOVED_COUNT"

# Report the number of .ipynb files remaining in the submissions directory
REMAINING_IPYNB_COUNT=$(find "$SUBMISSIONS_DIR" -type f -name "*.ipynb" | wc -l)
echo "Total number of .ipynb files remaining in the submissions directory: $REMAINING_IPYNB_COUNT"
