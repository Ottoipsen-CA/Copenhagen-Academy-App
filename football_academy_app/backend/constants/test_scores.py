"""
Constants defining the maximum scores for various skill tests.
These values are used to normalize test results and calculate player ratings.
"""

# Maximum scores for each test type
MAX_PACE_SCORE = 1.9  # seconds (lower is better)
MAX_SHOOTING_SCORE = 10.0  # points out of 10
MAX_PASSING_SCORE = 10.0  # points out of 10
MAX_DRIBBLING_SCORE = 2.0  # seconds (lower is better)
MAX_JUGGLES_SCORE = 100  # number of consecutive juggles
MAX_FIRST_TOUCH_SCORE = 10.0  # points out of 10

# Minimum scores that still yield a decent rating (50)
MIN_PACE_SCORE = 3.0  # seconds
MIN_SHOOTING_SCORE = 5.0  # points out of 10
MIN_PASSING_SCORE = 5.0  # points out of 10
MIN_DRIBBLING_SCORE = 4.0  # seconds
MIN_JUGGLES_SCORE = 10  # number of consecutive juggles
MIN_FIRST_TOUCH_SCORE = 5.0  # points out of 10

# Rating scale
MAX_RATING = 99.0
MIN_RATING = 1.0