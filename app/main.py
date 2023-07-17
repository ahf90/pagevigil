import base64
from datetime import datetime
import os
from urllib.parse import urlparse
import boto3
from botocore.exceptions import NoCredentialsError
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from tempfile import mkdtemp
import yaml

CONFIG = os.environ.get("CONFIG")
BUCKET_ID = os.environ.get("BUCKET_ID")
SNS_TOPIC_ARN = os.environ.get("BUCKET_ID")
REGION = os.environ.get("REGION")

s3 = boto3.client("s3")
sns = boto3.client("sns", region_name=REGION)


def handler(event, context):
    if not CONFIG or not BUCKET_ID or not SNS_TOPIC_ARN or not REGION:
        print("Environment variables not set")
        sns.publish(TopicArn=SNS_TOPIC_ARN,
                    Message="Environment variables not set",
                    Subject="PageVigil Error: Environment variables not set")
        raise

    options = webdriver.ChromeOptions()
    options.binary_location = "/opt/chrome/chrome"
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1280x1696")
    options.add_argument("--single-process")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-dev-tools")
    options.add_argument("--no-zygote")
    options.add_argument(f"--user-data-dir={mkdtemp()}")
    options.add_argument(f"--data-path={mkdtemp()}")
    options.add_argument(f"--disk-cache-dir={mkdtemp()}")
    options.add_argument("--remote-debugging-port=9222")
    service = Service(executable_path="/opt/chromedriver")
    chrome = webdriver.Chrome(service=service, options=options)

    decoded_config = parse_config()
    for page in decoded_config["chrome_urls"]:
        chrome.get(page["url"])
        chrome.get_screenshot_as_file("/tmp/temp_screenshot.png")
        store_in_s3(page["url"], "chrome")

    chrome.close()
    chrome.quit()

    response = {
        "statusCode": 200,
        "body": "Selenium Headless Chrome Initialized"
    }

    return response


def store_in_s3(url: str, browser: str):
    """
    Stores a screenshot in S3
    :param url: URL of the page that was screenshotted
    :param browser: which browser the screenshot was taken from
    """
    try:
        s3.upload_file("/tmp/temp_screenshot.png", BUCKET_ID, find_object_path(url, browser))
        print("Upload Successful", url)
        return url
    except FileNotFoundError:
        print("File not found")
        sns.publish(TopicArn=SNS_TOPIC_ARN,
                    Message="File not found",
                    Subject="PageVigil Error: File not found")
        return None
    except NoCredentialsError:
        print("Credentials")
        sns.publish(TopicArn=SNS_TOPIC_ARN,
                    Message="Insufficient credentials to write to S3",
                    Subject="PageVigil Error: NoCredentialsError")
        return None
    except Exception:
        print("Unknown exception")
        sns.publish(TopicArn=SNS_TOPIC_ARN,
                    Message="PageVigil Error: Unknown exception",
                    Subject="PageVigil Error: Unknown exception")
        return None


def find_object_path(url: str, browser: str):
    """
    Converts a URL to a path that can be stored in S3
    :param url: URL of the page that was screenshotted
    :param browser: which browser the screenshot was taken from
    :return: string path to use for S3 upload
    """
    now = datetime.utcnow()
    parsed_url = urlparse(url)
    return f"{browser}/{parsed_url.netloc}{parsed_url.path}/{now.year}/{now.month}/{now.day}/{now.hour}/{now.minute}"


def parse_config():
    """
    Decodes, loads, and parses the config file into a dict
    :return: Python dict containing config
    """
    decoded_config = yaml.safe_load(base64.b64decode(CONFIG))
    decoded_config["chrome_urls"] = []
    decoded_config["firefox_urls"] = []
    for page in decoded_config["pages"]:
        if page["browser"] == "chrome":
            decoded_config["chrome_urls"].append(page["url"])
        elif page["browser"] == "firefox":
            decoded_config["firefox_urls"].append(page["url"])
    return decoded_config
