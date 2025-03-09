#!/bin/bash

# scan_audio_directory.sh - Scans audio files and generates a JSON manifest
# Modified to follow symbolic links and handle macOS Alias files

# Default values
AUDIO_DIR="./audio"
OUTPUT_FILE="available_tracks.json"
SUPPORTED_EXTENSIONS=("mp3" "wav" "ogg" "m4a" "flac")
TEMP_FILE="/tmp/audio_file_list.txt"

# Check if we're on macOS
ON_MACOS=false
if [[ "$(uname)" == "Darwin" ]]; then
    ON_MACOS=true
fi

# Check if ffprobe is installed
if ! command -v ffprobe &> /dev/null; then
    echo "Error: ffprobe is required but not installed."
    echo "Please install ffmpeg: brew install ffmpeg (macOS) or apt-get install ffmpeg (Linux)"
    exit 1
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--directory)
            AUDIO_DIR="$2"
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
            echo "  -d, --directory DIR   Specify the audio directory (default: ./audio)"
            echo "  -o, --output FILE     Specify the output JSON file (default: available_tracks.json)"
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

# Check if audio directory exists
if [ ! -d "$AUDIO_DIR" ]; then
    echo "Error: Directory '$AUDIO_DIR' does not exist."
    exit 1
fi

echo "Scanning audio files in '$AUDIO_DIR' (including symbolic links)..."

# First, create a list of all audio files
echo "Finding all supported audio files..."
> "$TEMP_FILE"  # Clear the temp file

for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
    find -L "$AUDIO_DIR" -type f -name "*.$ext" >> "$TEMP_FILE"
done

# Initialize JSON file
echo "[" > "$OUTPUT_FILE"
first_file=true
id=1

# Process each file
while IFS= read -r file; do
    echo "Processing: $file"
    filename=$(basename "$file")
    
    # For macOS Alias files - try to resolve them
    if [ "$ON_MACOS" = true ]; then
        file_type=$(file -b "$file")
        if [[ "$file_type" == *"MacOS Alias"* ]]; then
            echo "Detected macOS Alias file, attempting to resolve..."
            resolved=$(osascript -e "tell application \"Finder\" to get the POSIX path of (original item of POSIX file \"$file\" as alias)" 2>/dev/null)
            if [ -n "$resolved" ] && [ -f "$resolved" ]; then
                echo "Resolved to: $resolved"
                file="$resolved"
            else
                echo "Could not resolve alias, using original file path"
            fi
        fi
    fi
    
    # Try to get artist and title using ffprobe
    artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    title=$(ffprobe -v quiet -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    
    # Default values if metadata is missing
    if [ -z "$title" ]; then
        title="${filename%.*}"
    fi
    
    if [ -z "$artist" ]; then
        artist="Unknown Artist"
    fi
    
    # Escape special characters for JSON
    title=$(echo "$title" | sed 's/"/\\"/g')
    artist=$(echo "$artist" | sed 's/"/\\"/g')
    
    # Add to JSON
    if [ "$first_file" = false ]; then
        echo "," >> "$OUTPUT_FILE"
    else
        first_file=false
    fi
    
    # Write the JSON entry
    cat >> "$OUTPUT_FILE" << EOF
    {
        "id": $id,
        "title": "$title",
        "artist": "$artist",
        "filename": "$filename"
    }
EOF
    
    # Increment ID counter
    ((id++))
done < "$TEMP_FILE"

# Close JSON array
echo "]" >> "$OUTPUT_FILE"

# Clean up
rm -f "$TEMP_FILE"

# Count completed files
file_count=$((id - 1))
echo "Found $file_count audio files. JSON data saved to '$OUTPUT_FILE'."

# Help message
echo ""
echo "Next steps:"
echo "1. Place this JSON file in your web directory"
echo "2. Use fetch() to load the tracks in your web page"
