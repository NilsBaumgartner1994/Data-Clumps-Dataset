#!/bin/bash

# Function to format elapsed time
format_time() {
    local total_seconds=$1
    printf "%02d:%02d:%02d" $((total_seconds/3600)) $((total_seconds%3600/60)) $((total_seconds%60))
}

# Prompt user for the action: compress or decompress
read -p "Do you want to compress or decompress files? (c/d): " ACTION

# Prompt user for the directory to search
read -p "Enter the relative or absolute path to search for files: " SEARCH_DIR

# Check if the entered path is valid
if [ ! -d "$SEARCH_DIR" ]; then
    echo "The path provided is not a valid directory."
    exit 1
fi

# Start time
start_time=$(date +%s)

# Function to compress .json files
compress_files() {
    # Find .json files
    files=$(find "$SEARCH_DIR" -type f -name "*.json")
    total_files=$(echo "$files" | wc -l)
    
    if [ -z "$files" ]; then
        echo "No .json files found."
        exit 0
    fi

    echo "Found $total_files .json files to compress."

    progress=0
    # Create zip files and delete original files
    for file in $files; do
        zipfile="${file}.zip"
        zip -j "$zipfile" "$file"
        if [ $? -eq 0 ]; then
            rm -f "$file"
            echo "Compressed and deleted: $file"
        else
            echo "Failed to compress: $file"
        fi

        
        # Update progress counter
        progress=$((progress + 1))


        # Calculate elapsed time
        elapsed_time=$(( $(date +%s) - $start_time ))

        # Calculate estimated time to complete
        if [ $progress -gt 0 ]; then
            est_time=$(( (elapsed_time * total_files) / progress ))
        else
            est_time=0
        fi

        # Calculate remaining time
        remaining_time=$((est_time - elapsed_time))

        # Calculate estimated completion time
        estimated_finished_at=$((start_time + est_time))
        estimated_finished_time=$(date -d "@$estimated_finished_at" +"%d days %H:%M")

        # Display progress
        echo "Elapsed time: $(format_time $elapsed_time) | ($progress/$total_files) | Estimated finished at: $estimated_finished_time | Remaining time: $(format_time $remaining_time)"
    done

    echo "All .json files were successfully compressed and original files deleted."
}

# Function to decompress .zip files
decompress_files() {
    # Find .zip files
    zip_files=$(find "$SEARCH_DIR" -type f -name "*.zip")
    total_files=$(echo "$zip_files" | wc -l)

    if [ -z "$zip_files" ]; then
        echo "No .zip files found."
        exit 0
    fi

    echo "Found $total_files .zip files to decompress."

    progress=0
    # Decompress zip files
    for zipfile in $zip_files; do
        unzip -j "$zipfile" -d "$(dirname "$zipfile")"
        if [ $? -eq 0 ]; then
            rm -f "$zipfile"
            echo "Decompressed and deleted: $zipfile"
        else
            echo "Failed to decompress: $zipfile"
        fi

        # Update progress counter
        progress=$((progress + 1))


        # Calculate elapsed time
        elapsed_time=$(( $(date +%s) - $start_time ))

        # Calculate estimated time to complete
        if [ $progress -gt 0 ]; then
            est_time=$(( (elapsed_time * total_files) / progress ))
        else
            est_time=0
        fi

        # Calculate remaining time
        remaining_time=$((est_time - elapsed_time))

        # Calculate estimated completion time
        estimated_finished_at=$((start_time + est_time))
        estimated_finished_time=$(date -d "@$estimated_finished_at" +"%d days %H:%M")

        # Display progress
        echo "Elapsed time: $(format_time $elapsed_time) | ($progress/$total_files) | Estimated finished at: $estimated_finished_time | Remaining time: $(format_time $remaining_time)"
    done

    echo "All .zip files were successfully decompressed and original zip files deleted."
}

# Determine action based on user input
if [[ "$ACTION" == "c" ]]; then
    compress_files
elif [[ "$ACTION" == "d" ]]; then
    decompress_files
else
    echo "Invalid action. Please enter 'c' for compress or 'd' for decompress."
    exit 1
fi
