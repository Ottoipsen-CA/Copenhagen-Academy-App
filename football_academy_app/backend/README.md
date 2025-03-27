# Football Academy API

This is the backend API for the Football Academy application. It provides endpoints for managing users, training plans, exercises, achievements, and player statistics.

## Features

- User authentication and authorization
- Training plan management
- Exercise management with video uploads
- Achievement tracking
- Player statistics tracking
- Role-based access control (players and coaches)

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set up environment variables:
- Copy `.env.example` to `.env`
- Update the values in `.env` with your configuration

4. Run the application:
```bash
uvicorn main:app --reload
```

The API will be available at `http://localhost:8000`

## API Documentation

Once the application is running, you can access:
- Interactive API docs (Swagger UI): `http://localhost:8000/docs`
- Alternative API docs (ReDoc): `http://localhost:8000/redoc`

## Project Structure

```
backend/
├── main.py              # FastAPI application entry point
├── database.py          # Database configuration
├── models.py            # SQLAlchemy models
├── schemas.py           # Pydantic schemas
├── auth.py             # Authentication utilities
├── routers/            # API route handlers
│   ├── users.py
│   ├── training_plans.py
│   ├── exercises.py
│   ├── achievements.py
│   └── player_stats.py
├── requirements.txt    # Python dependencies
└── .env               # Environment variables
```

## Development

To run tests:
```bash
pytest
```

## License

This project is licensed under the MIT License - see the LICENSE file for details. 