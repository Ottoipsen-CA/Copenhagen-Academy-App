# This file makes the routers directory a Python package 
from . import auth
from . import skill_tests

# Export routers
__all__ = [
    'auth',
    'skill_tests',
    'challenges',
    'league_table',
    'training',
    'exercise_library'
] 