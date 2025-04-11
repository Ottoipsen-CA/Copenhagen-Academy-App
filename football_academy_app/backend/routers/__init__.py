# This file makes the routers directory a Python package 
from . import auth
from . import skill_tests
from . import challenges
from . import league_table
from . import development_plans

# Export routers
__all__ = [
    'auth',
    'skill_tests',
    'challenges',
    'league_table',
    'development_plans'
] 