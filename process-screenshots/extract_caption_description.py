import re

# NOTE: This did't work well until I changed the prompt to get just two lines back in the response
# See the other file for proper implementation

def extract_caption_and_description(response_text):
    # Debug: Print the input text
    print("Response Text:\n", response_text)

    # Extract caption using regex
    caption_match = re.search(r'\*\*Caption:\*\*\s*"(.*?)"', response_text, re.DOTALL)
    caption = caption_match.group(1).strip() if caption_match else "Caption not found"

    # Extract description using regex
    description_match = re.search(r'\*\*Description:\*\*\s*(.*)', response_text, re.DOTALL)
    description = description_match.group(1).strip() if description_match else "Description not found"

    return caption, description

# Sample response text
response_text = '''
**Caption:**
"A Serene Walk Through Nature"

**Description:**
The image showcases a picturesque wooden boardwalk meandering through a lush, green meadow under a vast, blue sky adorned with wispy clouds. The landscape exudes tranquility and invites the viewer for a peaceful walk, surrounded by the gentle beauty of nature. With trees dotting the horizon and vibrant wild grasses swaying in the breeze, this scene captures the essence of a perfect day in the countryside, where one can breathe in the fresh air and escape the hustle and bustle of everyday life.
'''

# Extract caption and description
caption, description = extract_caption_and_description(response_text)

# Print results
print(f"Caption: {caption}")
print(f"Description: {description}")