# This file makes the routers directory a Python package 
from . import auth
from . import skill_tests
from . import development_plan
from . import focus_area
from . import training_session

# Export routers
__all__ = [
    'auth',
    'skill_tests',
    'challenges',
    'league_table',
    'training',
    'exercise_library',
    'development_plan',
    'focus_area',
    'training_session',
] 