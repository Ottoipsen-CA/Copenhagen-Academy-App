#!/usr/bin/env python
"""
Script to run all API tests for the Football Academy App.
"""
import os
import sys
import pytest

# Add the parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

if __name__ == "__main__":
    # Run all tests in verbose mode
    exit_code = pytest.main([
        "-v",                          # Verbose output
        os.path.dirname(__file__),     # Run tests in the current directory
    ])
    
    sys.exit(exit_code) 