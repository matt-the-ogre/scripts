# Process screenshots for captions and filenames

> I have a folder of images (PNGs, JPEGs) on my Mac. They have a generic name that includes the date and time of the screenshot capture. I want your help to write a program that will look in the folder for any new files (since the last time the program was run), run an AI algorithm on the image to generate a text caption and a very short image description. I want the caption to be added to the image meta data and I want the file to be renamed with the short description, while still keeping the date and time in the filename. Can you help with this?

Here's a step-by-step guide and a Python script to achieve your goal. This script will:

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
