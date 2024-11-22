import time

class RedditRateLimiter:
    """
    A class to handle Reddit API rate limiting (100 requests per minute).
    """
    def __init__(self, max_requests_per_minute: int = 100):
        """
        Initializes the rate limiter.

        Args:
            max_requests_per_minute (int): Maximum number of requests allowed per minute.
        """
        self.max_requests = max_requests_per_minute
        self.request_count = 0
        self.start_time = time.time()

    def increment(self):
        """
        Increment the request counter and enforce the rate limit if necessary.

        Raises:
            Exception: If the rate limit logic encounters an error.
        """
        self.request_count += 1

        # If we've hit the limit, pause to respect the API restrictions
        if self.request_count >= self.max_requests:
            elapsed_time = time.time() - self.start_time
            if elapsed_time < 60:  # If less than a minute has passed
                wait_time = 60 - elapsed_time
                print(f"Rate limit reached. Waiting {wait_time:.2f} seconds...")
                time.sleep(wait_time)  # Pause for the remaining time
            self.reset()  # Reset the counter and timer

    def reset(self):
        """
        Reset the request counter and the timer.
        """
        self.request_count = 0
        self.start_time = time.time()