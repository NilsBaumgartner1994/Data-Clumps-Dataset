import os
import argparse
import zipfile

def unzip_files_in_folder(folder_path):
    # Find all ZIP files in the folder
    zip_files = [
        os.path.join(folder_path, f) for f in os.listdir(folder_path)
        if f.endswith('.zip')
    ]

    if not zip_files:
        print(f"No ZIP files found in {folder_path}. Skipping...")
        return

    for zip_file in zip_files:
        try:
            # Attempt to open and extract the ZIP file
            with zipfile.ZipFile(zip_file, 'r') as zipf:
                extract_path = folder_path
                zipf.extractall(extract_path)
                print(f"Extracted {zip_file} to {extract_path}")
        except zipfile.BadZipFile:
            print(f"Skipping invalid ZIP file: {zip_file}")
            continue  # Skip to the next file

        try:
            # Delete the ZIP file after successful extraction
            os.remove(zip_file)
            print(f"Deleted {zip_file}")
        except Exception as e:
            print(f"Failed to delete {zip_file}: {e}")

def process_root_folder(root_folder):
    # Walk through all subdirectories in the root folder
    for folder_name, _, _ in os.walk(root_folder):
        print(f"Processing folder: {folder_name}")
        unzip_files_in_folder(folder_name)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Unzip all valid ZIP files in a folder and its subfolders, then delete them.")
    parser.add_argument('root_folder', type=str, help="The root folder to process.")

    args = parser.parse_args()

    process_root_folder(args.root_folder)
