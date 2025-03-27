# This file makes the routers directory a Python package 

# Import routers so they can be imported from the routers package
import os
import sys

# Add parent directory to path
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if parent_dir not in sys.path:
    sys.path.append(parent_dir) 