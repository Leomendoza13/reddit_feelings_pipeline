"""
Reddit Subreddit Analyzer
-------------------------
This module provides functionality to find, analyze and categorize relevant subreddits
based on a given topic using semantic similarity and various quality metrics.
"""

import json
import logging
import os
import sys
from datetime import datetime
from typing import Dict, List, Tuple, Optional


import praw
import prawcore
from sentence_transformers import SentenceTransformer, util


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def calculate_activity_score(subreddit: praw.models.Subreddit) -> float:
    """
    Calculate an activity score for a subreddit based on recent posts.

    Args:
        subreddit: A PRAW subreddit object to analyze

    Returns:
        float: Activity score between 0 and 1, where 1 indicates high activity

    Raises:
        prawcore.exceptions.RequestException: If Reddit API request fails
        prawcore.exceptions.Forbidden: If access to subreddit is forbidden
        prawcore.exceptions.NotFound: If subreddit is not found
        AttributeError: If subreddit object lacks required attributes
        TypeError: If data types are invalid
        ValueError: If calculation fails
        KeyError: If required data is missing

    The score is calculated using:
    - Recency of the latest post
    - Average frequency of posts between submissions
    """
    try:
        # Analyze last 10 posts
        recent_posts = list(subreddit.new(limit=10))
        if not recent_posts:
            return 0.0

        # Calculate latest post age in days
        latest_post_age = (
            datetime.now().timestamp() - recent_posts[0].created_utc
        ) / 86400

        # Calculate average post frequency
        if len(recent_posts) > 1:
            timestamps = [post.created_utc for post in recent_posts]
            time_diffs = [
                timestamps[i] - timestamps[i + 1] for i in range(len(timestamps) - 1)
            ]
            avg_time_between_posts = sum(time_diffs) / len(time_diffs) / 86400
        else:
            avg_time_between_posts = latest_post_age

        # Calculate scores based on recency and frequency
        recency_score = 1.0 / (1 + latest_post_age)
        frequency_score = 1.0 / (1 + avg_time_between_posts)

        return (recency_score + frequency_score) / 2

    except (
        prawcore.exceptions.RequestException,
        prawcore.exceptions.Forbidden,
        prawcore.exceptions.NotFound,
    ) as exception:
        logger.error(
            "Reddit API error while calculating activity score: %s", str(exception)
        )
        return 0.0
    except (AttributeError, TypeError, ValueError) as exception:
        logger.error(
            "Data processing error in activity score calculation: %s", str(exception)
        )
        return 0.0
    except KeyError as exception:
        logger.error("Missing required data in subreddit object: %s", str(exception))
        return 0.0


def is_quality_subreddit(subreddit: praw.models.Subreddit) -> bool:
    """
    Determine if a subreddit meets quality criteria.

    Args:
        subreddit: A PRAW subreddit object to evaluate

    Returns:
        bool: True if the subreddit meets quality criteria, False otherwise

    Raises:
        prawcore.exceptions.RequestException: If Reddit API request fails
        prawcore.exceptions.Forbidden: If access is forbidden
        prawcore.exceptions.NotFound: If subreddit not found
        AttributeError: If subreddit object lacks required attributes

    Quality criteria:
    - Has a substantial description (>50 chars)
    - Has sufficient subscribers (>5000)
    """
    try:
        has_description = len(subreddit.public_description) > 50
        has_enough_subscribers = subreddit.subscribers > 5000

        return has_description and has_enough_subscribers

    except (
        prawcore.exceptions.RequestException,
        prawcore.exceptions.Forbidden,
        prawcore.exceptions.NotFound,
    ) as exception:
        logger.error("Reddit API error checking subreddit quality: %s", str(exception))
        return False
    except AttributeError as exception:
        logger.error("Missing attribute in subreddit object: %s", str(exception))
        return False


def categorize_subreddit(name: str, description: Optional[str]) -> str:
    """
    Categorize a subreddit based on its name and description.

    Args:
        name: The name of the subreddit
        description: The subreddit's description (can be None)

    Returns:
        str: Category name from predefined categories or 'general' if no match

    Categories include:
    - memes: Humor and entertainment content
    - discussions: Theory and discussion forums
    - art: Creative and artistic content
    - news: Updates and official information
    - media: Visual and audio content
    - general: Default category for uncategorized content
    """
    name_lower = name.lower()
    desc_lower = description.lower() if description else ""

    categories: Dict[str, List[str]] = {
        "memes": ["meme", "funny", "humor", "circlejerk"],
        "discussions": ["discuss", "theory", "lore", "questions"],
        "art": ["art", "fanart", "creative", "drawings"],
        "news": ["news", "updates", "official", "leaks"],
        "media": ["clips", "videos", "screenshots", "photos"],
    }

    for category, keywords in categories.items():
        if any(keyword in name_lower for keyword in keywords):
            return category
        if any(keyword in desc_lower for keyword in keywords):
            return category

    return "general"


def process_subreddit(
    subreddit: praw.models.Subreddit, topic: str, model: SentenceTransformer
) -> Optional[Dict]:
    """
    Process a single subreddit and calculate its scores.

    Args:
        subreddit: The subreddit to process
        topic: The search topic
        model: The sentence transformer model

    Returns:
        Optional[Dict]: Subreddit data dictionary if successful, None if failed

    The returned dictionary contains:
        - score: Combined relevance score
        - similarity: Semantic similarity to topic
        - popularity: Score based on subscriber count
        - subscribers: Number of subscribers
        - description: Subreddit description
        - category: Assigned category

    Raises:
        TypeError: If data types are invalid
        ValueError: If calculations fail
    """
    try:
        # Create rich text for semantic analysis
        rich_text = (
            f"{subreddit.display_name} {subreddit.title} {subreddit.public_description}"
        )
        subreddit_embedding = model.encode(rich_text, convert_to_tensor=True)
        topic_embedding = model.encode(topic, convert_to_tensor=True)

        # Calculate scores
        similarity = util.pytorch_cos_sim(topic_embedding, subreddit_embedding).item()
        popularity_score = min(1.0, subreddit.subscribers / 1000000)

        # Combined score (70% similarity, 30% popularity)
        combined_score = similarity * 0.7 + popularity_score * 0.3

        # Categorize subreddit
        category = categorize_subreddit(
            subreddit.display_name, subreddit.public_description
        )

        return {
            "score": combined_score,
            "similarity": similarity,
            "popularity": popularity_score,
            "subscribers": subreddit.subscribers,
            "description": subreddit.public_description,
            "category": category,
        }

    except (TypeError, ValueError) as calc_error:
        logger.error(
            "Error calculating scores for subreddit %s: %s",
            subreddit.display_name,
            str(calc_error),
        )
        return None


def perform_subreddit_search(
    reddit: praw.Reddit,
    topic: str,
    model: SentenceTransformer,
    min_subscribers: int,
    search_method: str = "search_by_name",
) -> Dict[str, List[Tuple[str, Dict]]]:
    """
    Perform a subreddit search using specified method.

    Args:
        reddit: Reddit API instance
        topic: Search topic
        model: Transformer model
        min_subscribers: Minimum subscriber threshold
        search_method: Reddit search method to use ('search_by_name' or 'search')

    Returns:
        Dict[str, List[Tuple[str, Dict]]]: Categorized subreddit results

    Raises:
        prawcore.exceptions.RequestException: If Reddit API request fails
        prawcore.exceptions.Forbidden: If search access is forbidden
        prawcore.exceptions.NotFound: If search endpoint not found
        AttributeError: If response objects lack required attributes
        TypeError: If data structure is invalid
        ValueError: If search parameters are invalid
    """
    categories: Dict[str, List[Tuple[str, Dict]]] = {}
    search_func = (
        reddit.subreddits.search_by_name
        if search_method == "search_by_name"
        else reddit.subreddits.search
    )

    try:
        for subreddit in search_func(topic.lower()):
            if subreddit.subscribers < min_subscribers:
                continue

            subreddit_data = process_subreddit(subreddit, topic, model)
            if subreddit_data:
                category = subreddit_data["category"]
                if category not in categories:
                    categories[category] = []
                categories[category].append((subreddit.display_name, subreddit_data))

    except (
        prawcore.exceptions.RequestException,
        prawcore.exceptions.Forbidden,
        prawcore.exceptions.NotFound,
    ) as api_error:
        logger.error(
            "Reddit API error during %s search: %s", search_method, str(api_error)
        )
    except (AttributeError, TypeError) as attr_error:
        logger.error(
            "Data structure error during %s search: %s", search_method, str(attr_error)
        )
    except ValueError as val_error:
        logger.error(
            "Invalid value error during %s search: %s", search_method, str(val_error)
        )

    return categories


def find_subreddits(
    topic: str,
    reddit: praw.Reddit,
    model: SentenceTransformer,
    min_subscribers: int = 5000,
    max_results: int = 15,
) -> Dict[str, List[Tuple[str, Dict]]]:
    """
    Find and analyze relevant subreddits for a given topic.

    Args:
        topic: The topic to search for
        reddit: Authenticated PRAW Reddit instance
        model: SentenceTransformer model for semantic similarity
        min_subscribers: Minimum number of subscribers for a subreddit to be considered
        max_results: Maximum number of results to return per category

    Returns:
        Dict[str, List[Tuple[str, Dict]]]: Dict mapping categories to lists of
        (subreddit_name, metadata) tuples

    Raises:
        prawcore.PrawcoreException: If critical Reddit API error occurs
    """
    logger.info("Searching for topic: %s", topic)

    # Try primary search method
    try:
        categories = perform_subreddit_search(
            reddit, topic, model, min_subscribers, "search_by_name"
        )

        if not categories:
            logger.info("No results from primary search, attempting backup method...")
            # Try backup search method
            categories = perform_subreddit_search(
                reddit, topic, model, min_subscribers, "search"
            )

    except prawcore.exceptions.PrawcoreException as api_error:
        logger.error("Critical Reddit API error: %s", str(api_error))
        return {}

    # Sort results by category
    return {
        category: sorted(results, key=lambda x: x[1]["score"], reverse=True)[
            :max_results
        ]
        for category, results in categories.items()
    }


def get_subreddit_names(
    results_by_category: Dict[str, List[Tuple[str, Dict]]]
) -> Dict[str, List[str]]:
    """
    Extract just the subreddit names from the results, organized by category.

    Args:
        results_by_category: Dictionary mapping categories to lists of subreddit results

    Returns:
        Dict[str, List[str]]: Dict mapping categories to lists of subreddit names
    """
    return {
        category: [result[0] for result in results]
        for category, results in results_by_category.items()
    }


def print_simple_results(results_by_category: Dict[str, List[str]]) -> None:
    """
    Print just the subreddit names by category.

    Args:
        results_by_category: Dictionary mapping categories to lists of subreddit names

    Prints the results in a formatted structure:
    === CATEGORY ===
    r/subreddit1
    r/subreddit2
    """
    print("\nSubreddits found by category:")
    if not results_by_category:
        print("No subreddits found")
        return

    for category, subreddits in results_by_category.items():
        print(f"\n=== {category.upper()} ===")
        for subreddit in subreddits:
            print(f"r/{subreddit}")


def get_reddit_credentials(
    filename: str = "../../config/reddit_credentials.json",
) -> Dict[str, str]:
    """
    Read Reddit API credentials from a JSON file.

    Args:
        filename: Name of the JSON credentials file

    Returns:
        Dict[str, str]: Dict containing Reddit API credentials

    Raises:
        FileNotFoundError: If credentials file is not found
        json.JSONDecodeError: If credentials file is not valid JSON
        KeyError: If required credentials are missing
        IOError: If file cannot be read
        OSError: If file system error occurs

    Required credentials in JSON file:
        - client_id
        - client_secret
        - username
        - password
        - user_agent
    """
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(script_dir, filename)

        with open(json_path, "r", encoding="utf-8") as file:
            credentials = json.load(file)

        required_keys = [
            "client_id",
            "client_secret",
            "username",
            "password",
            "user_agent",
        ]
        for key in required_keys:
            if key not in credentials:
                raise KeyError(f"Missing required key '{key}' in credentials file")

        return credentials

    except FileNotFoundError:
        logger.error("Credentials file %s not found", filename)
        raise
    except json.JSONDecodeError:
        logger.error("Invalid JSON format in credentials file %s", filename)
        raise
    except KeyError as exception:
        logger.error("Missing required credential: %s", str(exception))
        raise
    except (IOError, OSError) as exception:
        logger.error("File system error reading credentials: %s", str(exception))
        raise


def write_results(subject: str, all_subreddits: List[str]) -> None:
    """
    Write the given subject and a list of subreddits to a JSON file.

    Args:
        subject (str): The topic or subject being analyzed.
        all_subreddits (List[str]): A list of subreddit names related to the subject.

    Raises:
        IOError: If there is an issue with writing to the JSON file.
    """
    object_json = {"subject": subject, "all_subreddits": all_subreddits}
    output_dir = os.path.join("config")
    output_path = os.path.join(output_dir, "output.json")
    try:
        with open(
            output_path, "w", encoding="utf-8"
        ) as json_file:  # Corrected to "w" mode to write the file
            json.dump(object_json, json_file, indent=4)
    except IOError as io_error:
        raise IOError(f"Error writing to the file: {io_error}") from io_error


def main() -> None:
    """
    Main function to run the subreddit analysis.

    Initializes the Reddit client and model, performs the subreddit search,
    and displays the results. Exits with status 1 if initialization fails.

    Raises:
        FileNotFoundError: If credentials file cannot be found
        json.JSONDecodeError: If credentials are invalid JSON
        prawcore.exceptions.OAuthException: If Reddit authentication fails
        prawcore.exceptions.ResponseException: If Reddit API responds with error
        ImportError: If required models cannot be loaded
        RuntimeError: If initialization fails for other reasons
    """
    try:
        # Initialize Reddit client
        credentials = get_reddit_credentials()
        reddit = praw.Reddit(**credentials)

        # Initialize sentence transformer model
        model = SentenceTransformer("all-mpnet-base-v2")

        subject = "guns"
        # Get results
        full_results = find_subreddits(subject, reddit, model)
        subreddit_names = get_subreddit_names(full_results)

        # Print results
        print_simple_results(subreddit_names)

        # Print flat array of all subreddits
        all_subreddits = [
            subreddit
            for subreddits in subreddit_names.values()
            for subreddit in subreddits
        ]
        write_results(subject, all_subreddits)
        print("\nAll subreddits:", all_subreddits)

    except (FileNotFoundError, json.JSONDecodeError) as file_error:
        logger.error("Credentials error: %s", str(file_error))
        sys.exit(1)
    except (
        prawcore.exceptions.OAuthException,
        prawcore.exceptions.ResponseException,
    ) as auth_error:
        logger.error("Reddit authentication error: %s", str(auth_error))
        sys.exit(1)
    except ImportError as import_error:
        logger.error("Failed to load required models: %s", str(import_error))
        sys.exit(1)
    except RuntimeError as runtime_error:
        logger.error("Runtime initialization error: %s", str(runtime_error))
        sys.exit(1)


if __name__ == "__main__":
    main()
