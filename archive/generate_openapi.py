import json
from main import app

if __name__ == "__main__":
    # Generate OpenAPI schema
    openapi_schema = app.openapi()
    
    # Save the schema to a file
    with open("openapi_schema.json", "w") as f:
        json.dump(openapi_schema, f, indent=2)
    
    print("OpenAPI schema has been generated and saved to openapi_schema.json")
    print("You can now use this file with other Swagger tools or import it into Swagger UI")
    print("To view the API documentation, open http://localhost:8000/docs in your browser while the server is running") 