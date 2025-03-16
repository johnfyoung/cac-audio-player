#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 source_directory destination_directory [file_extensions]"
    echo "Creates symlinks in destination_directory for files in source_directory"
    echo ""
    echo "Options:"
    echo "  source_directory      Directory containing original files"
    echo "  destination_directory Directory where symlinks will be created"
    echo "  file_extensions       Optional: Space-separated list of file extensions to include (e.g. 'mp3 wav m4a')"
    echo "                        If not specified, all files will be symlinked"
    echo ""
    echo "Example: $0 ~/Music/Collection ~/WebApp/audio 'mp3 wav flac'"
    exit 1
}

# Check if we have at least two arguments
if [ $# -lt 2 ]; then
    usage
fi

SOURCE_DIR="$1"
DEST_DIR="$2"
FILE_TYPES="$3"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

# Check if destination directory exists, create it if not
if [ ! -d "$DEST_DIR" ]; then
    echo "Destination directory '$DEST_DIR' does not exist. Creating it..."
    mkdir -p "$DEST_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create destination directory."
        exit 1
    fi
fi

# Convert to absolute paths
SOURCE_DIR=$(cd "$SOURCE_DIR" && pwd)
DEST_DIR=$(cd "$DEST_DIR" && pwd)

echo "Creating symlinks from $SOURCE_DIR to $DEST_DIR"

# Build find command based on whether file types were specified
if [ -z "$FILE_TYPES" ]; then
    echo "No file types specified. Creating symlinks for all files."
    FIND_CMD="find \"$SOURCE_DIR\" -type f"
else
    # Convert space-separated file types to find -name arguments
    FIND_ARGS=""
    for ext in $FILE_TYPES; do
        # Remove any dots that might be included
        ext="${ext#.}"
        if [ -z "$FIND_ARGS" ]; then
            FIND_ARGS="-name \"*.${ext}\""
        else
            FIND_ARGS="$FIND_ARGS -o -name \"*.${ext}\""
        fi
    done
    
    FIND_CMD="find \"$SOURCE_DIR\" -type f \\( $FIND_ARGS \\)"
    echo "Creating symlinks only for files with extensions: $FILE_TYPES"
fi

# Count the number of files matching our criteria
FILE_COUNT=$(eval $FIND_CMD | wc -l | tr -d ' ')
echo "Found $FILE_COUNT matching files in source directory"

if [ "$FILE_COUNT" -eq 0 ]; then
    echo "No matching files found. Check your file extensions or source directory."
    exit 0
fi

# Counter for created symlinks
CREATED=0
SKIPPED=0
ERRORS=0

# Create symlinks for each matching file in the source directory
eval $FIND_CMD | while read -r file; do
    # Get just the filename
    filename=$(basename "$file")
    target_link="$DEST_DIR/$filename"
    
    # Check if a file with that name already exists in the destination
    if [ -e "$target_link" ]; then
        echo "Skipping: '$filename' already exists in destination"
        SKIPPED=$((SKIPPED + 1))
    else
        # Create the symlink
        ln -s "$file" "$target_link"
        if [ $? -eq 0 ]; then
            echo "Created: $filename -> $file"
            CREATED=$((CREATED + 1))
        else
            echo "Error: Failed to create symlink for '$filename'"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

echo "Summary: Created $CREATED symlinks, skipped $SKIPPED files, encountered $ERRORS errors"
echo "Done!"
