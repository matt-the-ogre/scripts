# Process screenshots for captions and filenames

> I have a folder of images (PNGs, JPEGs) on my Mac. They have a generic name that includes the date and time of the screenshot capture. I want your help to write a program that will look in the folder for any new files (since the last time the program was run), run an AI algorithm on the image to generate a text caption and a very short image description. I want the caption to be added to the image meta data and I want the file to be renamed with the short description, while still keeping the date and time in the filename. Can you help with this?

Sure, Matt! Here's a step-by-step guide and a Python script to achieve your goal. This script will:

1. Monitor the folder for new images.
2. Use an AI model to generate a caption and description.
3. Add the caption to the image metadata.
4. Rename the file with the description while keeping the date and time.

You will need to install the necessary libraries. You can use OpenAI's GPT model for generating the captions and descriptions.

## Prerequisites

1. **Install Python libraries**:
   `pip install pillow openai`

2. **Set up OpenAI API**:
   Ensure you have an OpenAI API key. You can get one from [OpenAI](https://www.openai.com/).

## Python Script

```python
import os
import glob
from PIL import Image, PngImagePlugin, JpegImagePlugin
import openai

# Set up OpenAI API key
openai.api_key = 'YOUR_OPENAI_API_KEY'

# Folder to monitor
folder_path = '/path/to/your/folder'
# File to track the last processed file timestamp
last_processed_file = '/path/to/last_processed.txt'

# Function to get the last processed timestamp
def get_last_processed_time():
    if os.path.exists(last_processed_file):
        with open(last_processed_file, 'r') as file:
            return float(file.read().strip())
    return 0

# Function to update the last processed timestamp
def update_last_processed_time(timestamp):
    with open(last_processed_file, 'w') as file:
        file.write(str(timestamp))

# Function to generate caption and description using OpenAI
def generate_caption_and_description(image_path):
    # Load and process the image if needed
    with open(image_path, 'rb') as image_file:
        image_bytes = image_file.read()
    
    # Generate caption and description
    response = openai.Image.create(
        prompt="Generate a caption and a short description for this image",
        images=[image_bytes]
    )
    caption = response['data'][0]['caption']
    description = response['data'][0]['description']
    return caption, description

# Function to update image metadata
def add_metadata(image_path, caption):
    image = Image.open(image_path)
    if isinstance(image, PngImagePlugin.PngImageFile):
        info = PngImagePlugin.PngInfo()
        info.add_text("Caption", caption)
        image.save(image_path, pnginfo=info)
    elif isinstance(image, JpegImagePlugin.JpegImageFile):
        info = image.info
        info["Caption"] = caption
        image.save(image_path, "JPEG", **info)

# Function to rename the image file
def rename_image(image_path, description):
    directory, filename = os.path.split(image_path)
    name, ext = os.path.splitext(filename)
    new_name = f"{name}_{description}{ext}"
    new_path = os.path.join(directory, new_name)
    os.rename(image_path, new_path)

# Main function to process new images
def process_new_images():
    last_processed_time = get_last_processed_time()
    new_images = [f for f in glob.glob(f"{folder_path}/*") if os.path.getmtime(f) > last_processed_time]
    
    for image_path in new_images:
        caption, description = generate_caption_and_description(image_path)
        add_metadata(image_path, caption)
        rename_image(image_path, description)
    
    if new_images:
        update_last_processed_time(max(os.path.getmtime(f) for f in new_images))

# Run the script
if __name__ == "__main__":
    process_new_images()
```

## Steps to Run

1. **Replace placeholder values**:
   - Replace `YOUR_OPENAI_API_KEY` with your actual OpenAI API key.
   - Set the `folder_path` to the path of your image folder.
   - Set the `last_processed_file` to the path where you want to save the timestamp of the last processed image.

2. **Save and run the script**:
   - Save the script as `process_images.py`.
   - Run the script using the command:
     `python process_images.py`

This script will monitor the specified folder for new images, generate captions and descriptions using OpenAI, update the metadata, and rename the files accordingly. Make sure to run the script periodically or set it up as a scheduled task to automate the process.