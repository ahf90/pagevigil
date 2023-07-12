from datetime import datetime
import os
from urllib.parse import urlparse
import boto3
from botocore.exceptions import NoCredentialsError
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import yaml

CONFIG = os.environ["CONFIG"]
BUCKET_ID = os.environ['BUCKET_ID']

s3 = boto3.client('s3')


def handler(event, context):
    options = Options()
    options.binary_location = '/opt/headless-chromium'
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--single-process')
    options.add_argument('--disable-dev-shm-usage')

    driver = webdriver.Chrome('/opt/chromedriver', options=options)

    pages = yaml.safe_load(CONFIG)
    for page in pages['pages']:
        driver.get(page['url'])
        driver.get_screenshot_as_file("temp_screenshot.png")
        store_in_s3(page['url'])

    driver.close()
    driver.quit()

    response = {
        "statusCode": 200,
        "body": "Selenium Headless Chrome Initialized"
    }

    return response


def store_in_s3(url):
    try:
        s3.upload_file(find_object_path(url), BUCKET_ID, "temp_screenshot.png")
        print("Upload Successful", url)
        return url
    except FileNotFoundError:
        # TODO: send to SNS
        print("File not found")
        return None
    except NoCredentialsError:
        # TODO: send to SNS
        print("Credentials")
        return None


def find_object_path(url):
    now = datetime.utcnow()
    parsed_url = urlparse(url)
    return f"{parsed_url.netloc}{parsed_url.path}/{now.year}/{now.month}/{now.day}/{now.hour}/{now.minute}"
