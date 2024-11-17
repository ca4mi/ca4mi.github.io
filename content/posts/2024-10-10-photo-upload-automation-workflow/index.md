---
author: "ca4mi"
title: "Automating upload workflow using Selenium"
date: "2024-10-10"
description: "Automating upload workflow using Selenium"
categories: ["Photography"]
ShowToc: true
TocOpen: false
---

Often need to efficiently share large photo sets with clients. This post outlines a workflow that utilizes automation tools for managing and organizing the process, specifically focusing on WeTransfer file sharing. 

WeTransfer's free tier offers up to 2GB of shared files for 7 days before they expire. For larger projects, it's necessary to split photos into manageable chunks (around 1.8GB each) before uploading.

**Step 1: Initial Photo Selection and Ranking**

After shooting a session, photographers should carefully select the best images. Software like Darktable or Lightroom can be used to identify poorly exposed or blurry photos and discard them. The remaining photos are then ranked, and low-resolution copies are exported to a designated folder. This bash script can further filter photo filenames and save them as a text file for easy reference.

```bash
ls | grep -oP '\d+' > filenames.txt
```

**Step 2: Handling Client Requests for All Photos**

Occasionally, clients may request all high-quality images, regardless of initial ranking or non-selected photos that not edited or non-post-production versions. In these cases, can simply gather the full set of JPEGs and organize them according to the filenames listed in the `filenames.txt`. This is bash script:

```bash
#!/bin/bash

# Define variables
numbers_file="/path/to/Photos/filenames.txt" # Path to your text file containing the numbers
source_dir="/path/to/Photos/raw/jpg" # Directory where the files are located
destination_dir="/path/to/Photos/new_photo_folder" # Directory to copy the matching files

# Read each number from the text file
while IFS= read -r number; do
    # Find and copy files starting with the number
    find "$source_dir" -type f -name "*$number*" -exec cp {} "$destination_dir" \;
done < "$numbers_file"

echo "Photos copied successfully!"
```

**Step 3: Splitting Photos into WeTransfer-Friendly Chunks**

A custom bash script (`wt_split.sh`) split the photos into chunks of approximately 1.8GB each. This ensures that stay within WeTransfer's file size limits.

```bash
#!/bin/bash

# Usage: ./split_dir.sh /path/to/large_directory
# Check if directory is provided
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/directory"
  exit 1
fi

# Variables
DIR_PATH=$1
PART_SIZE=$((1800 * 1024 * 1024))  # 1.8GB in bytes
OUTPUT_DIR="upload_to_wt"
COUNTER=1
CURRENT_SIZE=0

# Create output directory
mkdir -p $OUTPUT_DIR

# Create first part directory
PART_DIR="$OUTPUT_DIR/part_$COUNTER"
mkdir -p "$PART_DIR"

# Loop through files in the directory
find "$DIR_PATH" -type f | while read FILE; do
  FILE_SIZE=$(stat --printf="%s" "$FILE")

  # Check if adding this file exceeds the part size limit
  if (( CURRENT_SIZE + FILE_SIZE > PART_SIZE )); then
    # Create new part directory and reset size
    ((COUNTER++))
    PART_DIR="$OUTPUT_DIR/part_$COUNTER"
    mkdir -p "$PART_DIR"
    CURRENT_SIZE=0
  fi

  # Move file to current part directory
  mv "$FILE" "$PART_DIR/"
  CURRENT_SIZE=$((CURRENT_SIZE + FILE_SIZE))
done

echo "Directory $DIR_PATH has been split into directories of up to 1.8GB in $OUTPUT_DIR/."
```

**Step 4: Uploading with Python and Selenium**

Finally, a Python code (`wetransfer_selenium.py`) leverages the Selenium library to automate the WeTransfer upload process. This script handles selecting photos, uploading files, and generating a shareable link for clients.

```python
import sys
import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

# Check if the user provided a file or directory to upload
if len(sys.argv) != 2:
    print("Usage: python3 wetransfer_selenium.py <path_to_file_or_directory>")
    sys.exit(1)

# Get the file or directory path from the command-line argument
file_or_dir_path = sys.argv[1]

# Check if the path exists
if not os.path.exists(file_or_dir_path):
    print(f"Error: The path {file_or_dir_path} does not exist.")
    sys.exit(1)

# Set up the browser (use Chrome or Firefox)
driver = webdriver.Chrome()  # Or webdriver.Firefox()
wait = WebDriverWait(driver, 20)  # Add an explicit wait

# Open WeTransfer website
driver.get("https://wetransfer.com/")

# Wait for the page to load fully
time.sleep(5)  # Optional: increase the sleep time if necessary

# Wait for the "Accept All Cookies" button to appear and click it
try:
    accept_cookies_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Accept All')]")))
    accept_cookies_button.click()
    print("Accepted cookies.")
except Exception as e:
    print("Error locating or clicking the Accept All button:", e)
    driver.quit()
    sys.exit(1)

# Wait for the "I Agree" button to appear and click it
try:
    agree_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'I agree')]")))
    agree_button.click()
    print("Agreed to the terms.")
except Exception as e:
    print("Error locating or clicking the I Agree button:", e)
    driver.quit()
    sys.exit(1)

# Click the three-dot button to open more options
try:
    print("Clicking the three-dot button for more options...")
    three_dot_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//span[@data-testid='iconbar-icon']")))
    three_dot_button.click()
except Exception as e:
    print("Error clicking the three-dot button:", e)
    driver.quit()
    sys.exit(1)

# Select the "Create link" boolean option
try:
    print("Selecting 'Create link' boolean option...")
    create_link_radio = wait.until(EC.element_to_be_clickable((By.XPATH, "//input[@id='transfer__type-link']")))
    if not create_link_radio.is_selected():
        driver.execute_script("arguments[0].click();", create_link_radio)
        print("'Create link' option selected.")
    else:
        print("'Create link' option is already selected.")
except Exception as e:
    print("Error selecting 'Create link' option:", e)
    driver.quit()
    sys.exit(1)

# Proceed to set the expiry options
try:
    print("Opening expiry dropdown...")
    expiry_dropdown = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(@class, 'TransferWindowSetExpiry_input')]")))
    driver.execute_script("arguments[0].click();", expiry_dropdown)
    print("Expiry dropdown opened.")

    # Wait for the dropdown options to be visible
    seven_days_option = wait.until(EC.element_to_be_clickable((By.XPATH, "//li[contains(text(), '7 days')]")))

    # Click the '7 days' option
    driver.execute_script("arguments[0].click();", seven_days_option)
    print("Expiry set to 7 days.")

except Exception as e:
    print("Error selecting '7 days' option:", e)
    driver.quit()
    sys.exit(1)

# Wait for the uploader form to appear
try:
    print("Waiting for the uploader form...")
    wait.until(EC.visibility_of_element_located((By.CLASS_NAME, "uploader--form")))
    print("Uploader form is now visible.")
except Exception as e:
    print("Error locating the uploader form:", e)
    driver.quit()
    sys.exit(1)

# Wait for the file input element to appear
try:
    print("Waiting for the file input element...")
    file_input = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, 'input[data-testid="file-input"]')))
    print("File input element located successfully.")
except Exception as e:
    print("Error locating the file input element:", e)
    driver.quit()
    sys.exit(1)

# Upload file(s)
time.sleep(3)

# If it's a directory, get all files inside the directory
if os.path.isdir(file_or_dir_path):
    files = [os.path.join(file_or_dir_path, file) for file in os.listdir(file_or_dir_path)]
else:
    files = [file_or_dir_path]

# Upload each file
for file_path in files:
    print(f"Fetch: {file_path}")
    file_input.send_keys(file_path)  # Upload the file(s)

# Click the 'Get a link' button
try:
    print("Clicking the 'Get a link' button...")
    get_link_button = WebDriverWait(driver, 30).until(EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Get a link')]")))
    get_link_button.click()
    print("'Get a link' button clicked.")

except Exception as e:
    print(f"Error clicking the 'Get a link' button: {e}")
    driver.quit()
    sys.exit(1)

# Waiting for Transferring.. text will shown in page
time.sleep(3)

try:
    print("'Transferring...'")
    WebDriverWait(driver, 7200).until(EC.invisibility_of_element_located((By.XPATH, "//div[contains(@class, 'transfer__window uploader--progress')]//h2[text()='Transferring...']")))
    print("Upload complete.")
except Exception as e:
    print(f"Error waiting for the upload to complete: {e}")
    driver.quit()
    sys.exit(1)

time.sleep(10)

# Get the download link
try:
    link = WebDriverWait(driver, 60).until(EC.presence_of_element_located((By.CSS_SELECTOR, ".TransferDetails__link.link input.link__url")))
    link = WebDriverWait(driver, 30).until(EC.visibility_of_element_located((By.CSS_SELECTOR, ".TransferDetails__link.link input.link__url")))
    # Retrieve the link
    download_link = link.get_attribute("value")
    print(f"Download link: {download_link}")

except Exception as e:
    print("Error retrieving the download link:", e)
    driver.quit()
    sys.exit(1)

# Close the browser
driver.quit()
```