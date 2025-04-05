from enum import Enum
from typing import Dict

class Position(str, Enum):
    GOALKEEPER = "goalkeeper"
    DEFENDER = "defender"
    MIDFIELDER = "midfielder"
    STRIKER = "striker"

# Weight configuration for each position
# Weights should sum to 1.0 for each position
POSITION_WEIGHTS: Dict[Position, Dict[str, float]] = {
    Position.GOALKEEPER: {
        "pace": 0.15,
        "shooting": 0.10,
        "passing": 0.20,
        "dribbling": 0.10,
        "juggles": 0.15,
        "first_touch": 0.30
    },
    Position.DEFENDER: {
        "pace": 0.20,
        "shooting": 0.10,
        "passing": 0.20,
        "dribbling": 0.15,
        "juggles": 0.15,
        "first_touch": 0.20
    },
    Position.MIDFIELDER: {
        "pace": 0.15,
        "shooting": 0.15,
        "passing": 0.25,
        "dribbling": 0.15,
        "juggles": 0.15,
        "first_touch": 0.15
    },
    Position.STRIKER: {
        "pace": 0.25,
        "shooting": 0.25,
        "passing": 0.10,
        "dribbling": 0.15,
        "juggles": 0.10,
        "first_touch": 0.15
    }
} 