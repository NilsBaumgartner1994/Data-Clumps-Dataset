import os
import argparse
import zipfile

# Define the chunk size as a variable
CHUNK_SIZE = 500

def process_folder(folder_path):
    # Gather all JSON files in the folder
    json_files = [
        os.path.join(folder_path, f) for f in os.listdir(folder_path)
        if f.endswith('.json')
    ]

    if not json_files:
        print(f"No JSON files found in {folder_path}. Skipping...")
        return

    # Process the JSON files in chunks of CHUNK_SIZE
    for i in range(0, len(json_files), CHUNK_SIZE):
        chunk = json_files[i:i + CHUNK_SIZE]
        part_number = i // CHUNK_SIZE + 1
        zip_name = f"data_clumps_part_{part_number}.zip"
        zip_path = os.path.join(folder_path, zip_name)

        # Create a ZIP file for the current chunk
        with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for json_file in chunk:
                arcname = os.path.basename(json_file)
                zipf.write(json_file, arcname)
                print(f"Added {json_file} to {zip_path}")

        print(f"Created {zip_path}")

    # Delete all JSON files in the folder
    for json_file in json_files:
        os.remove(json_file)
        print(f"Deleted {json_file}")

def process_root_folder(root_folder):
    # Walk through all subdirectories in the root folder
    for folder_name, _, _ in os.walk(root_folder):
        print(f"Processing folder: {folder_name}")
        process_folder(folder_name)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Combine JSON files into ZIP files.")
    parser.add_argument('root_folder', type=str, help="The root folder to process.")

    args = parser.parse_args()

    process_root_folder(args.root_folder)
