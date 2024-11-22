"""
Main script for fetching Reddit posts and saving them as JSON files to a GCS bucket.
"""

import json
import os
import time
from typing import List
from google.cloud import storage
import praw
from rate_limiter import RedditRateLimiter


def get_subject() -> List[str]:
    """
    Reads a JSON file named 'output.json' and retrieves the list of all subreddits.

    Returns:
        List[str]: A list of subreddit names retrieved from the 'all_subreddits' key.

    Raises:
        FileNotFoundError: If the 'output.json' file is not found.
        KeyError: If the 'all_subreddits' key is missing.
        json.JSONDecodeError: If the JSON content is invalid.
        Exception: For any other unexpected errors.
    """
    try:
        with open("output.json", "r", encoding="utf-8") as file:
            output = json.load(file)
            return output["all_subreddits"]
    except FileNotFoundError as error:
        print("Error: File 'output.json' not found.")
        raise error
    except KeyError as error:
        print("Error: 'all_subreddits' key is missing in the JSON file.")
        raise error
    except json.JSONDecodeError as error:
        print("Error: Invalid JSON content in 'output.json'.")
        raise error
    except Exception as error:
        print(f"An unexpected error occurred: {error}")
        raise error


def get_credentials() -> praw.Reddit:
    """
    Reads Reddit API credentials from a JSON file and initializes a `praw.Reddit` instance.

    The credentials file path can be provided via the environment variable `REDDIT_CREDS_PATH`.
    If the environment variable is not set, it defaults to 'reddit_credentials.json'.

    Returns:
        praw.Reddit: An authenticated Reddit API client.

    Raises:
        FileNotFoundError: If the credentials file is not found.
        KeyError: If required keys are missing in the JSON file.
        json.JSONDecodeError: If the JSON content is invalid.
        Exception: For any other unexpected errors.
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
    except FileNotFoundError as error:
        print(f"Error: Credentials file '{creds_path}' not found.")
        raise error
    except KeyError as error:
        print(f"Error: Missing key in credentials: {error}")
        raise error
    except json.JSONDecodeError as error:
        print(f"Error: Invalid JSON format in credentials file '{creds_path}'.")
        raise error
    except Exception as error:
        print(f"An unexpected error occurred: {error}")
        raise error


def save_post_to_bucket(bucket_name: str, post_data: dict) -> None:
    """
    Saves a single post to a Google Cloud Storage bucket as a JSON file.

    Args:
        bucket_name (str): The name of the Google Cloud Storage bucket.
        post_data (dict): The post data to save as JSON.

    Raises:
        Exception: If the save operation fails.
    """
    try:
        client = storage.Client()
        bucket = client.bucket(bucket_name)
        file_name = f"{post_data['id']}.json"
        json_data = json.dumps(post_data, ensure_ascii=False, indent=4)

        blob = bucket.blob(file_name)
        blob.upload_from_string(json_data, content_type="application/json")

        print(f"Post {post_data['id']} saved to bucket {bucket_name} as {file_name}.")
    except Exception as error:
        print(f"Error saving post {post_data['id']} to bucket: {error}")
        raise error


def fetch_comments(post: praw.models.Submission, rate_limiter: RedditRateLimiter) -> List[dict]:
    """
    Fetches all comments for a given Reddit post with rate limiting.

    Args:
        post (praw.models.Submission): The Reddit post object.
        rate_limiter (RedditRateLimiter): Instance to manage Reddit API rate limits.

    Returns:
        List[dict]: A list of dictionaries containing comment details.
    """
    comments = []
    try:
        post.comments.replace_more(limit=None)
        rate_limiter.increment()

        for comment in post.comments.list():
            comments.append({
                "id": comment.id,
                "author": str(comment.author) if comment.author else "[deleted]",
                "body": comment.body,
                "score": comment.score,
                "created_utc": comment.created_utc,
                "parent_id": comment.parent_id,
                "is_submitter": comment.is_submitter,
            })
    except Exception as error:
        print(f"Error fetching comments for post {post.id}: {error}")
    return comments


def main() -> None:
    """
    Main function to fetch Reddit posts and save them as JSON files in a GCS bucket.
    """
    try:
        reddit = get_credentials()
        all_subreddits = get_subject()
        bucket_name = "reddit-feelings-pipeline-bucket"
        rate_limiter = RedditRateLimiter()

        for subreddit in all_subreddits:
            print(f"Fetching posts from subreddit: {subreddit}...")
            sub = reddit.subreddit(subreddit)
            posts = sub.new(limit=100)

            for post in posts:
                rate_limiter.increment()

                if post.id:
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
    except Exception as error:
        print(f"An error occurred: {error}")
        time.sleep(30)


if __name__ == "__main__":
    main()