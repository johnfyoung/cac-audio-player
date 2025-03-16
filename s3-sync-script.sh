#!/bin/bash

# s3-syc-script.sh
# This script syncs the audio player files to an S3 bucket

# Load environment variables from .env file if it exists
ENV_FILE=".env"
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from $ENV_FILE"
    set -o allexport
    source "$ENV_FILE"
    set +o allexport
fi

# Default values
S3_BUCKET=${S3_BUCKET}
HTML_FILE="index.html"
AUDIO_DIR="./audio"
ICONS_DIR="./icons"
LOGO_FILE="audio-player-logo.png"
FAVICON="favicon.png"
PLAYLISTS_JSON="playlists.json"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -b|--bucket)
            S3_BUCKET="$2"
            shift
            shift
            ;;
        -h|--html)
            HTML_FILE="$2"
            shift
            shift
            ;;
        -a|--audio-dir)
            AUDIO_DIR="$2"
            shift
            shift
            ;;
        -l|--logo)
            LOGO_FILE="$2"
            shift
            shift
            ;;
        -i|--icon)
            FAVICON="$2"
            shift
            shift
            ;;
        -p|--playlists)
            PLAYLISTS_JSON="$2"
            shift
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -b, --bucket BUCKET   Specify the S3 bucket (default: s3://cac-audio-player)"
            echo "  -h, --html FILE       Specify the HTML file (default: index.html)"
            echo "  -a, --audio-dir DIR   Specify the audio directory (default: ./audio)"
            echo "  -l, --logo FILE       Specify the logo file (default: mossback_logo.png)"
            echo "  -i, --icon FILE       Specify the favicon (default: favicon.png)"
            echo "  -p, --playlists FILE  Specify the playlists JSON file (default: playlists.json)"
            echo "  --help                Display this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed."
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS CLI configuration
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured correctly."
    echo "Please run 'aws configure' to set up your AWS credentials."
    exit 1
fi

# Check if files exist
if [ ! -f "$HTML_FILE" ]; then
    echo "Error: HTML file '$HTML_FILE' does not exist."
    exit 1
fi

if [ ! -d "$AUDIO_DIR" ]; then
    echo "Error: Audio directory '$AUDIO_DIR' does not exist."
    exit 1
fi

if [ ! -f "$ICONS_DIR" ]; then
    echo "Warning: Tracks JSON file '$TRACKS_JSON' does not exist."
fi

if [ ! -f "$LOGO_FILE" ]; then
    echo "Warning: Logo file '$LOGO_FILE' does not exist."
fi

if [ ! -f "$FAVICON" ]; then
    echo "Warning: Logo file '$LOGO_FILE' does not exist."
fi

if [ ! -f "$PLAYLISTS_JSON" ]; then
    echo "Warning: Playlists JSON file '$PLAYLISTS_JSON' does not exist."
fi

# Function to sync a file with appropriate content type
sync_file() {
    local file="$1"
    local content_type="$2"
    
    if [ -f "$file" ]; then
        echo "Uploading $file..."
        aws s3 cp "$file" "$S3_BUCKET/$file" --content-type "$content_type"
    fi
}

# Function to sync the audio directory with appropriate content type
sync_audio_dir() {
    echo "Uploading audio files from $AUDIO_DIR..."
    aws s3 sync "$AUDIO_DIR" "$S3_BUCKET/audio" --content-type "audio/mpeg"
}

sync_icons_dir() {
    echo "Uploading audio files from $ICONS_DIR..."
    aws s3 sync "$ICONS_DIR" "$S3_BUCKET/icons" --content-type "audio/mpeg"
}

# Upload files with appropriate content types
echo "Starting upload to $S3_BUCKET..."

# Upload HTML file
sync_file "$HTML_FILE" "text/html"

# Upload JSON files
sync_file "$PLAYLISTS_JSON" "application/json"

# Upload manifest files
sync_file "manifest.json" "application/json"

# Upload service-worker files
sync_file "service-worker.js" "application/javascript"

# Upload logo
if [[ "$LOGO_FILE" == *.png ]]; then
    sync_file "$LOGO_FILE" "image/png"
elif [[ "$LOGO_FILE" == *.jpg || "$LOGO_FILE" == *.jpeg ]]; then
    sync_file "$LOGO_FILE" "image/jpeg"
elif [[ "$LOGO_FILE" == *.svg ]]; then
    sync_file "$LOGO_FILE" "image/svg+xml"
else
    sync_file "$LOGO_FILE" "image/png"
fi

sync_file "$FAVICON" "image/png"

# Sync audio directory
sync_audio_dir

# Sync audio directory
sync_icons_dir

echo "Upload completed successfully!"
echo "Your audio player should be accessible at: https://$(echo $S3_BUCKET | cut -d/ -f3)/index.html"
echo ""
echo "Note: Make sure your S3 bucket is configured for static website hosting and has appropriate public access permissions."
echo "You can configure this in the AWS Management Console under S3 -> Your Bucket -> Properties -> Static website hosting"
