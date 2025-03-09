#!/bin/bash

# concatenate_playlists.sh
# This script concatenates multiple JSON playlist files into a single playlists.json file

# Default values
PLAYLISTS_DIR="./playlists"
OUTPUT_FILE="playlists.json"
TEMP_FILE=$(mktemp)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--directory)
            PLAYLISTS_DIR="$2"
            shift
            shift
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -d, --directory DIR   Specify the playlists directory (default: ./playlists)"
            echo "  -o, --output FILE     Specify the output JSON file (default: playlists.json)"
            echo "  -h, --help            Display this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Please install jq: sudo apt-get install jq (Ubuntu/Debian)"
    echo "or: brew install jq (macOS with Homebrew)"
    exit 1
fi

# Check if playlists directory exists
if [ ! -d "$PLAYLISTS_DIR" ]; then
    echo "Error: Directory '$PLAYLISTS_DIR' does not exist."
    exit 1
fi

echo "Looking for playlist files in '$PLAYLISTS_DIR'..."

# Find all JSON files in the playlists directory
json_files=($(find "$PLAYLISTS_DIR" -type f -name "*.json"))
file_count=${#json_files[@]}

if [ $file_count -eq 0 ]; then
    echo "Error: No JSON files found in '$PLAYLISTS_DIR'."
    exit 1
fi

echo "Found $file_count playlist files."

# Initialize empty JSON array
echo "[]" > "$TEMP_FILE"

# Process each JSON file
for json_file in "${json_files[@]}"; do
    echo "Processing: $(basename "$json_file")"
    
    # Check if file is valid JSON
    if ! jq empty "$json_file" 2>/dev/null; then
        echo "Warning: Skipping invalid JSON file: $json_file"
        continue
    fi
    
    # Check if file contains an array
    if ! jq 'if type != "array" then error("Not an array") else empty end' "$json_file" &>/dev/null; then
        # If it's not an array, assume it's a single playlist and wrap it in an array
        single_playlist=$(jq '.' "$json_file")
        
        # Add the wrapped playlist to our growing array
        jq --argjson playlist "$single_playlist" '. + [$playlist]' "$TEMP_FILE" > "${TEMP_FILE}.new"
        mv "${TEMP_FILE}.new" "$TEMP_FILE"
    else
        # If it's already an array, concatenate the items with our growing array
        jq -s '.[0] + .[1]' "$TEMP_FILE" "$json_file" > "${TEMP_FILE}.new"
        mv "${TEMP_FILE}.new" "$TEMP_FILE"
    fi
done

# Pretty-print the final result
jq '.' "$TEMP_FILE" > "$OUTPUT_FILE"

# Cleanup
rm "$TEMP_FILE"

echo "Successfully concatenated $file_count playlist files into '$OUTPUT_FILE'."

# Count playlists in the output file
playlist_count=$(jq 'length' "$OUTPUT_FILE")
echo "The output file contains $playlist_count playlists."

# Preview first few playlists
echo -e "\nPreview of playlists in output file:"
jq 'map({name: .name, tracks: (.tracks | length)}) | .[0:3]' "$OUTPUT_FILE"

echo -e "\nNext steps:"
echo "1. Place '$OUTPUT_FILE' in your web directory"
echo "2. Make sure your audio player is configured to load this file"
