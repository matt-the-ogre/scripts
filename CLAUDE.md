# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of utility scripts for macOS, primarily shell scripts and Python scripts for system administration, disk testing, media processing, and hardware control.

## Script Categories

### Disk/System Testing
- `disk_speed_test.sh <size-in-mb>` - Manual disk speed test using dd (requires `brew install coreutils` for gdate)
- `sysbench_disk.sh <size-in-mb> <output-file>` - Comprehensive disk benchmarking using sysbench (random/sequential read/write tests)
- `dir_size.sh <directory>` - Show top 20 largest items in a directory

### Media Processing
- `pdf_to_png.sh <file.pdf>` - Convert PDF to PNG images at 300 DPI (requires ImageMagick)
- `batch_render.py` - Blender script to render STL files from multiple camera angles. Run via: `blender --background --python batch_render.py -- <input_dir> <output_dir>`

### Hardware Control
- `elgato_control.sh` - Control Elgato Ring Light via HTTP API. Options: `-o` (on/off), `-b` (brightness), `-t` (temperature)
- `ping_for_hostname.sh` - Scan local network (192.168.7.229-254) for Elgato devices

### Sync/Cleanup
- `sync-plex.sh` - Two-way rsync between ~/Plex and Synology Drive
- `clean-my-mac.sh` - Interactive cleanup of trash, logs, caches (runs with confirmations)

### Screenshot Processing (process-screenshots/)
- `process_images.py` - Uses OpenAI GPT-4o to generate captions for screenshots, updates metadata, and renames files
- Requires: `pip install pillow openai requests` and `OPENAI_API_KEY` environment variable

## Dependencies

Most scripts assume Homebrew is installed. Common dependencies:
- `coreutils` (for gdate with nanosecond precision)
- `imagemagick` (for PDF conversion)
- `sysbench` (for disk benchmarking)
