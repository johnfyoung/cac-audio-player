#!/bin/bash

# scan_audio_directory.sh
# This script scans a directory of audio files and generates a JSON file
# in the format needed by the loadAvailableTracks function.

# Default values
AUDIO_DIR="./audio"
OUTPUT_FILE="available_tracks.json"
SUPPORTED_EXTENSIONS=("mp3" "wav" "ogg" "m4a" "flac")

# Check if ffprobe (ffmpeg) is installed
if ! command -v ffprobe &> /dev/null; then
    echo "Error: ffprobe is required but not installed."
    echo "Please install ffmpeg: sudo apt-get install ffmpeg (Ubuntu/Debian)"
    echo "or: brew install ffmpeg (macOS with Homebrew)"
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

echo "Scanning audio files in '$AUDIO_DIR'..."

# Start JSON array
echo "[" > "$OUTPUT_FILE"

# Initialize counter
id=1
first_file=true

# Function to extract metadata from audio file
extract_metadata() {
    local file="$1"
    local filename=$(basename "$file")
    
    # Get artist and title using ffprobe
    artist=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$file")
    title=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$file")
    
    # If title is empty, use filename without extension
    if [ -z "$title" ]; then
        title="${filename%.*}"
    fi
    
    # If artist is empty, use "Unknown Artist"
    if [ -z "$artist" ]; then
        artist="Unknown Artist"
    fi
    
    # Escape special characters for JSON
    title=$(echo "$title" | sed 's/"/\\"/g')
    artist=$(echo "$artist" | sed 's/"/\\"/g')
    
    # Output JSON object for this file
    if [ "$first_file" = false ]; then
        echo "," >> "$OUTPUT_FILE"
    else
        first_file=false
    fi
    
    echo "    {" >> "$OUTPUT_FILE"
    echo "        \"id\": $id," >> "$OUTPUT_FILE"
    echo "        \"title\": \"$title\"," >> "$OUTPUT_FILE"
    echo "        \"artist\": \"$artist\"," >> "$OUTPUT_FILE"
    echo "        \"filename\": \"$filename\"" >> "$OUTPUT_FILE"
    echo "    }" >> "$OUTPUT_FILE"
    
    # Increment ID
    ((id++))
}

# Find all audio files in the directory and process them
for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
    while IFS= read -r -d '' file; do
        extract_metadata "$file"
    done < <(find "$AUDIO_DIR" -type f -name "*.$ext" -print0)
done

# Close JSON array
echo "]" >> "$OUTPUT_FILE"

# Count audio files found
file_count=$((id - 1))
echo "Found $file_count audio files. JSON data saved to '$OUTPUT_FILE'."

# Help message for next steps
echo ""
echo "Next steps:"
echo "1. Place this JSON file in your web directory"
echo "2. Update your web page to load the tracks using fetch():"
echo ""
echo "fetch('$OUTPUT_FILE')"
echo "    .then(response => response.json())"
echo "    .then(data => {"
echo "        availableTracks = data;"
echo "        renderTrackList();"
echo "    })"
echo "    .catch(error => console.error('Error loading tracks:', error));"
