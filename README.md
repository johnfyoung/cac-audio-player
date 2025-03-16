# cac-audio-player

A lightweight, mobile-friendly audio player that can be hosted entirely on an S3 bucket without requiring any backend services. This web application provides a responsive interface for playing audio files organized into playlists, with support for PWA (Progressive Web App) functionality to enable offline use and mobile installation.

## Key Features

- **Responsive Design**: Works on both desktop and mobile devices
- **Playlist Support**: Organize your audio files into custom playlists
- **Audio Visualization**: Real-time waveform visualization during playback
- **No Backend Required**: Runs entirely from static files hosted on S3
- **Offline Support**: Built as a PWA for offline functionality
- **Media Session Integration**: Controls media playback from notification area
- **Background Playback**: Continues playing when screen is locked or app is in background

## Components

### Audio Player (index.html)

The main audio player interface provides:

- Track playback with play/pause, previous/next controls
- Progress bar with seeking capability
- Volume control
- Playlist selection and navigation
- Responsive design that adapts to mobile devices
- Real-time audio waveform visualization
- PWA support for offline functionality and home screen installation

The player reads from a `playlists.json` file that defines available playlists and their tracks. Each track references an audio file in the `/audio` directory.

### Playlist Creator (playlist-creator.html)

A separate tool for creating and managing playlists:

- Create, edit, and delete playlists
- Add tracks from your audio collection to playlists
- Reorder tracks within playlists using drag and drop
- Preview tracks before adding them
- Export playlists as JSON files
- Import previously exported playlists
- Save playlists to local storage

The playlist creator reads from an `available_tracks.json` file that contains metadata about the available audio files. This file can be generated using the included `scan-audio-directory.sh` script.

### S3 Sync Script (s3-sync-script.sh)

A bash script that automates the deployment of the audio player to an Amazon S3 bucket:

- Uploads all necessary HTML, JavaScript, and asset files
- Sets appropriate content types for files
- Syncs the audio directory to the S3 bucket
- Configurable via command-line arguments or environment variables
- Supports custom directory structures and file names

## Getting Started

1. Clone this repository
2. Place your audio files in the `audio` directory
3. Run `./scan-audio-directory.sh` to generate metadata for your audio files
4. Use `playlist-creator.html` to create and organize your playlists
5. Configure your S3 bucket name in `.env` (use `.env_sample` as a template)
6. Run `./s3-sync-script.sh` to deploy the player to your S3 bucket

## S3 Configuration Requirements

To host this application on S3:

1. Create an S3 bucket with Static Website Hosting enabled
2. Configure appropriate CORS settings to allow audio file access
3. Set up public read access for the bucket contents
4. Configure the bucket policy to allow public access to the files

## Additional Scripts

- `create-symlinks.sh`: Creates symbolic links to audio files, useful for organizing audio without duplicating files
- `scan-audio-directory.sh`: Scans an audio directory and generates a JSON manifest of available tracks with metadata

## PWA Support

The application includes:

- Service worker for offline caching (`service-worker.js`)
- Web app manifest for installation on mobile devices (`manifest.json`)
- Icons for various device sizes
- iOS-specific meta tags for home screen installation

## Browser Compatibility

The audio player is designed to work on modern browsers, with special consideration for iOS Safari to ensure audio playback works correctly on Apple devices, including background playback and lock screen controls.

## License

This project is provided as-is for personal use.

## Note

This application is designed to be simple, lightweight, and completely serverless. It relies entirely on client-side JavaScript and files hosted on S3, making it an ideal solution for hosting a personal audio collection without managing a web server.
