# Football Academy API Documentation

## Swagger UI Documentation

The Football Academy API is fully documented using Swagger UI, which provides an interactive API documentation interface.

### Accessing the Documentation

When the server is running, you can access the Swagger UI documentation at:

```
http://localhost:8000/docs
```

This will display a comprehensive, interactive documentation of all API endpoints, including:

- Request parameters
- Response models
- Authentication requirements
- Example requests and responses

### Alternative Documentation (ReDoc)

You can also access the documentation in ReDoc format, which offers a different UI:

```
http://localhost:8000/redoc
```

## OpenAPI Schema

The API schema is available in OpenAPI format, which can be used with various tools:

1. The schema is automatically accessible at: `http://localhost:8000/openapi.json`
2. We've also generated a static copy in the `openapi_schema.json` file

### Using the OpenAPI Schema

You can use the OpenAPI schema with various tools:

1. **Importing to Postman**: Import the OpenAPI schema into Postman to create a collection of API requests.
2. **Code Generation**: Use tools like OpenAPI Generator to create client libraries in various programming languages.
3. **Testing Tools**: Use tools like Dredd for API testing based on the schema.

## API Authentication

Most endpoints require JWT authentication. To authenticate:

1. Use the `/token` endpoint with email and password to obtain an access token
2. Include the token in the Authorization header of subsequent requests:
   ```
   Authorization: Bearer your_access_token
   ```

## Challenge Progression System 

The Football Academy API includes a challenge progression system that automatically unlocks new challenges as players complete the current ones. This system ensures players progress through challenges in a structured way.

### Key Concepts

1. **Challenge Levels**: Challenges are organized by category (passing, shooting, etc.) and level (1, 2, 3, etc.)
2. **Challenge Status**: Each challenge can have one of three statuses:
   - `LOCKED`: Not yet available to the player
   - `AVAILABLE`: Ready to be attempted by the player
   - `COMPLETED`: Successfully completed by the player

3. **Automatic Progression**: When a player completes all challenges at a certain level within a category, the system automatically unlocks challenges at the next level.

### Relevant Endpoints

- `GET /challenges/with-status`: Retrieve all challenges with their current status for the logged-in user
- `POST /challenges/initialize-status`: Initialize challenge statuses for a new user
- `POST /challenges/complete/{challenge_id}`: Mark a challenge as completed and automatically unlock next challenges
- `GET /challenges/{challenge_id}`: Get details of a specific challenge with its status

## Making API Requests

The Swagger UI allows you to:

1. Try out API endpoints directly in the browser
2. See the expected parameters and response formats
3. Authenticate with the API using the "Authorize" button
4. Generate code snippets for various programming languages

## Exploring the API

The API is organized into several sections:

1. **Users**: User registration, profile management
2. **Training Plans**: Manage training plans and activities
3. **Exercises**: Browse and access exercise instructions
4. **Achievements**: View and manage player achievements and badges
5. **Player Stats**: Track player performance statistics
6. **Challenge Progress**: Record and view challenge completions
7. **Challenges**: Manage challenge progression and status

Each section contains multiple endpoints for different operations (GET, POST, PUT, DELETE). 