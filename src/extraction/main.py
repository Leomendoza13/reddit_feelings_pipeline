"""
Main script for fetching Reddit posts and saving them as JSON files to a GCS bucket.
"""

import json
import os
import time
from typing import List
from google.cloud import storage
import praw
from praw.exceptions import APIException, ClientException, PRAWException
from requests.exceptions import RequestException
from rate_limiter import RedditRateLimiter


def get_subject() -> List[str]:
    """
    Retrieves subreddit names from a JSON file named 'output.json'.

    Returns:
        List[str]: A list of subreddit names.

    Raises:
        FileNotFoundError: If 'output.json' is missing.
        KeyError: If 'all_subreddits' key is not in the JSON file.
        json.JSONDecodeError: If the JSON file is malformed.
        Exception: For unexpected errors.
    """
    try:
        with open("output.json", "r", encoding="utf-8") as file:
            output = json.load(file)
            return output["all_subreddits"]
    except (FileNotFoundError, KeyError, json.JSONDecodeError) as error:
        print(f"Error reading 'output.json': {error}")
        raise
    except Exception as error:
        print(f"Unexpected error: {error}")
        raise


def get_credentials() -> praw.Reddit:
    """
    Reads Reddit API credentials from a JSON file and initializes a `praw.Reddit` instance.

    Returns:
        praw.Reddit: An authenticated Reddit client.

    Raises:
        FileNotFoundError: If the credentials file is not found.
        KeyError: If required keys are missing in the JSON file.
        json.JSONDecodeError: If the JSON file is invalid.
        Exception: For unexpected errors.
    """
    creds_path = os.getenv("REDDIT_CREDS_PATH", "reddit_credentials.json")
    try:
        with open(creds_path, "r", encoding="utf-8") as file:
            credentials = json.load(file)

        return praw.Reddit(
            client_id=credentials["client_id"],
            client_secret=credentials["client_secret"],
            username=credentials["username"],
            password=credentials["password"],
            user_agent=credentials["user_agent"],
        )
    except (FileNotFoundError, KeyError, json.JSONDecodeError) as error:
        print(f"Error reading credentials file '{creds_path}': {error}")
        raise
    except Exception as error:
        print(f"Unexpected error: {error}")
        raise


def save_post_to_bucket(bucket_name: str, post_data: dict) -> None:
    """
    Uploads a post's data as a JSON file to a Google Cloud Storage bucket.

    Args:
        bucket_name (str): The target GCS bucket name.
        post_data (dict): The post data to be saved.

    Raises:
        Exception: If the upload fails.
    """
    try:
        client = storage.Client()
        bucket = client.bucket(bucket_name)
        file_name = f"{post_data['id']}.json"
        json_data = json.dumps(post_data, ensure_ascii=False, indent=4)

        blob = bucket.blob(file_name)
        blob.upload_from_string(json_data, content_type="application/json")

        print(
            f"Post {post_data['id']} saved to bucket '{bucket_name}' as '{file_name}'."
        )
    except Exception as error:
        print(f"Error saving post {post_data['id']} to bucket: {error}")
        raise


def fetch_comments(
    post: praw.models.Submission, rate_limiter: RedditRateLimiter
) -> List[dict]:
    """
    Fetches all comments for a given Reddit post, respecting API rate limits.

    Args:
        post (praw.models.Submission): The Reddit post object.
        rate_limiter (RedditRateLimiter): The rate limiter instance.

    Returns:
        List[dict]: A list of dictionaries containing comment details.
    """
    comments = []
    try:
        post.comments.replace_more(limit=None)  # Load all comments
        rate_limiter.increment()

        for comment in post.comments.list():
            comments.append(
                {
                    "id": comment.id,
                    "author": str(comment.author) if comment.author else "[deleted]",
                    "body": comment.body,
                    "score": comment.score,
                    "created_utc": comment.created_utc,
                    "parent_id": comment.parent_id,
                    "is_submitter": comment.is_submitter,
                }
            )
    except (APIException, ClientException, RequestException) as error:
        print(f"Error fetching comments for post {post.id}: {error}")
    return comments


def main() -> None:
    """
    Main function to fetch posts from subreddits and save them as JSON files in a GCS bucket.
    """
    try:
        reddit = get_credentials()  # Initialize Reddit API client
        all_subreddits = get_subject()  # Load subreddits to process
        bucket_name = "reddit-feelings-pipeline-bucket"
        rate_limiter = RedditRateLimiter()

        for subreddit in all_subreddits:
            print(f"Fetching posts from subreddit: {subreddit}...")
            try:
                sub = reddit.subreddit(subreddit)
                posts = sub.new(limit=100)  # Fetch the latest 100 posts

                for post in posts:
                    rate_limiter.increment()

                    if post.id:  # Ensure the post is valid
                        comments = fetch_comments(post, rate_limiter)
                        post_data = {
                            "title": post.title,
                            "id": post.id,
                            "url": post.url,
                            "score": post.score,
                            "author": str(post.author),
                            "created_utc": post.created_utc,
                            "num_comments": post.num_comments,
                            "selftext": post.selftext,
                            "subreddit": str(post.subreddit),
                            "comments": comments,
                        }
                        save_post_to_bucket(bucket_name, post_data)
            except (PRAWException, RequestException) as error:
                print(f"Error processing subreddit '{subreddit}': {error}")
            except KeyboardInterrupt:
                print("Process interrupted by user.")
                return
    except (PRAWException, RequestException) as error:
        print(f"Critical error in main function: {error}")
        time.sleep(30)
    except KeyboardInterrupt:
        print("Process interrupted by user.")
        return


if __name__ == "__main__":
    main()
