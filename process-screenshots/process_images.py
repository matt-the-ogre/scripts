import os
import glob
from PIL import Image, PngImagePlugin, JpegImagePlugin
# import openai
from openai import OpenAI
import time
import re
import base64
import requests
import logging

logging.basicConfig(level=logging.INFO)

# Set up OpenAI API key
client = OpenAI(api_key=os.environ['OPENAI_API_KEY'])
api_key = os.environ['OPENAI_API_KEY']

# Folder to monitor
# Note folder path must be absolute not relative
folder_path = '/Users/mattman//Pictures/CleanShots'
# File to track the last processed file timestamp
last_processed_file = '/Users/mattman/Pictures/CleanShots/last_processed.txt'

# Function to get the last processed timestamp
def get_last_processed_time():
    logging.debug(f"last_processed_file {last_processed_file}")
    if os.path.exists(last_processed_file):
        with open(last_processed_file, 'r') as file:
            return float(file.read().strip())
    return 0

# Function to update the last processed timestamp
def update_last_processed_time(timestamp):
    logging.debug(f"Updating last processed time to {timestamp}")
    logging.debug(f"last_processed_file {last_processed_file}")
    with open(last_processed_file, 'w') as file:
        file.write(str(timestamp))

def extract_caption_and_description_lines(response_text):
    # put the first line of the response_text into caption and the second line into the description
    lines = response_text.split("\n")
    logging.debug("\n\nlines", lines)
    # print the length of lines
    num_lines = len(lines)
    logging.debug(f"Number of lines: {num_lines}")
    
    # if num_lines == 2:
    caption = lines[0]
    description = lines[-1]
    # else:
    #     caption = "Caption not found"
    #     description = "Description not found"
    # #
    return caption, description

def extract_caption_and_description(response_text):
    # Debug: Print the input text
    # print("Response Text:\n", response_text)

    # Extract caption using regex
    caption_match = re.search(r'Caption:"(.*?)"', response_text, re.DOTALL)
    caption = caption_match.group(1).strip() if caption_match else "Caption not found"

    # Extract description using regex
    description_match = re.search(r'\*\*Description:\*\*\s*(.*)', response_text, re.DOTALL)
    description = description_match.group(1).strip() if description_match else "Description not found"

    return caption, description

# Function to encode the image
def encode_image(image_path):
  with open(image_path, "rb") as image_file:
    return base64.b64encode(image_file.read()).decode('utf-8')

# Function to generate caption and description using OpenAI
def generate_caption_and_description(image_path):
    # Load and process the image if needed
    # with open(image_path, 'rb') as image_file:
    #     image_bytes = image_file.read()
    
    # Getting the base64 string
    base64_image = encode_image(image_path)

    headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {api_key}"
    }

    payload = {
    "model": "gpt-4o",
    "messages": [
        {
        "role": "user",
        "content": [
            {
            "type": "text",
            "text": "Please generate a caption and short description for this image. Please return in the format of the caption on the first line and the description on the second line. Do not add anything else to your response. respond with only two lines of text. Do not add any extra characters to the response. Do not include the heading caption nor description in your response."
            },
            {
            "type": "image_url",
            "image_url": {
                "url": f"data:image/jpeg;base64,{base64_image}"
            }
            }
        ]
        }
    ],
    "max_tokens": 300
    }

    response = requests.post("https://api.openai.com/v1/chat/completions", headers=headers, json=payload)

    logging.debug(response.json())

    # Call the OpenAI API to generate caption and description
    # response = client.image_captioning(image_bytes=image_bytes)
    # response = client.chat.completions.create(
    #     model="gpt-4o",
    #     messages=[
    #         {
    #         "role": "user",
    #         "content": [
    #             {"type": "text", "text": "Please generate a caption and short description for this image."},
    #             {
    #             "type": "image_url",
    #             "image_url": {
    #                 "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg",
    #             },
    #             },
    #         ],
    #         }
    #     ],
    #     max_tokens=300,
    # )

    # Sample response text
    # response_text = '''
    # **Caption:**
    # "A Serene Walk Through Nature"

    # **Description:**
    # The image showcases a picturesque wooden boardwalk meandering through a lush, green meadow under a vast, blue sky adorned with wispy clouds. The landscape exudes tranquility and invites the viewer for a peaceful walk, surrounded by the gentle beauty of nature. With trees dotting the horizon and vibrant wild grasses swaying in the breeze, this scene captures the essence of a perfect day in the countryside, where one can breathe in the fresh air and escape the hustle and bustle of everyday life.
    # '''

    response_text = response.json()['choices'][0]['message']['content']
    # print(response.choices[0])
    # print(response.choices[0].message.content)
    # Extract caption and description
    # caption, description = extract_caption_and_description(response.choices[0].message.content)
    caption, description = extract_caption_and_description_lines(response_text)
    # caption, description = extract_caption_and_description(response_text)
    logging.debug("\n\ncaption", caption)
    logging.debug("\n\ndescription", description)
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
    # name contains the date and time in the format "CleanShot YYYY-MM-DD at HH.MM.SS"
    # extract the date from the filename in format YYYY-MM-DD

    date = name[10:20]
    # print("\ndate", date)
    # extract the time from the filename in format HH.MM.SS
    time = name[24:32]
    # print("\ntime", time)

    # clean description of any unsafe characters for a filename and replace spaces with underscores
    description = re.sub(r'[\.<>:"/\\|?*]', '', description)
    description = description.replace("!", "")
    description = description.replace(",", "_")
    description = description.replace(" ", "_")

    # add the description, limited to 64 characters, to the new filename
    new_name = f"{date}_{time}_{description[:64]}{ext}"

    logging.debug(f"\nnew_name", new_name)
    new_path = os.path.join(directory, new_name)
    os.rename(image_path, new_path)

# Main function to process new images
def process_new_images():
    last_processed_time = get_last_processed_time()
    logging.debug(f"Last processed time: {last_processed_time}")
    logging.debug(f"Monitoring folder: {folder_path}")
    # new_images = [f for f in glob.glob(f"{folder_path}/*") if os.path.getmtime(f) > last_processed_time]
    # make a list of all the images in the folder `folder_path`
    new_images = [f for f in glob.glob(f"{folder_path}/CleanShot 2023-1*.png")]

    # new_images = [f for f in glob.glob(f"{folder_path}/*")]
    # print the length of new_images
    logging.info(f"Number of new images: {len(new_images)}")
    
    for image_path in new_images:
        logging.info(f"Processing image: {image_path}")
        caption, description = generate_caption_and_description(image_path)
        # print(f"Caption: {caption}")
        # print(f"Description: {description}")
        add_metadata(image_path, description)
        rename_image(image_path, caption)
    
    if new_images:
        update_last_processed_time(time.time())

# Run the script
if __name__ == "__main__":
    process_new_images()