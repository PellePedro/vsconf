from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field, validator, ValidationError, field_validator
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

from pydantic import BaseModel

from enum import Enum
from typing import Dict, Optional

app = FastAPI()

# Define a config variable holding the expected config data
config = {
    "apiVersion": "infra.k8smgmt.io/v3",
    "kind": "Credentials",
    "metadata": {
        "name": "skyrampdemocloudcreds-004",
        "project": "skyramp-project"
    },
    "spec": {
        "sharing": {
            "enabled": False,
        },
        "type": "ClusterProvisioning",
        "provider": "aws",
        "credentials": {
            "type": "AccessKey",
            "accessId": "aaaaaaaa",
            "secretKey": "gggggggggg"
        }
    }
}

class Credentials(BaseModel):
    type: str
    accessId: str
    secretKey: str

    @validator('type')
    def validate_type(cls, value):
        expected = config["spec"]["credentials"]["type"] 
        if value != expected:
            raise ValueError(f"type must be {expected}")
        return value

    @validator('secretKey')
    def validate_secret_key(cls, value):
        expected = config["spec"]["credentials"]["secretKey"]
        if value != expected:
            raise ValueError(f"secretKey must be {expected}")
        return value
    
    @validator('accessId')
    def validate_access_id(cls, value):
        expected = config["spec"]["credentials"]["accessId"]
        if value != expected:
            raise ValueError(f"accessId must be {expected}")
        return value

class Spec(BaseModel):
    sharing: Dict[str, bool]
    type: str
    provider: str
    credentials: Credentials

    @validator('sharing')
    def validate_sharing(cls, value):
        expected = config["spec"]["sharing"]
        if value != expected:
            raise ValueError(f"sharing must be {expected}")
        return value

    @validator('type')
    def validate_type(cls, value):
        expected = config["spec"]["type"]
        if value != expected:
            raise ValueError(f"type must be {expected}")
        return value

    @validator('provider')
    def validate_provider(cls, value):
        expected = config["spec"]["provider"]
        if value != expected:
            raise ValueError(f"provider must be {expected}")
        return value

class Metadata(BaseModel):
    name: str
    project: str

    @validator('name')
    def validate_name(cls, value):
        expected = config["metadata"]["name"]
        if value != expected:
            raise ValueError(f"name must be {expected}")
        return value
    
    @validator('project')
    def validate_project(cls, value):
        expected = config["metadata"]["project"]
        if value != expected:
            raise ValueError(f"project must be {expected}")
        return value

class CredentialsResource(BaseModel):
    apiVersion: str = Field(alias="apiVersion")
    kind: str
    metadata: Metadata
    spec: Spec

    @validator('apiVersion')
    def validate_api_version(cls, value):
        expected = config["apiVersion"]
        if value != expected:
            raise ValueError(f"apiVersion must be {expected}")
        return value

    @validator('kind')
    def validate_kind(cls, value):
        expected = config["kind"]
        if value != expected:
            raise ValueError(f"kind must be {expected}")
        return value

    class Config:
        allow_population_by_field_name = True

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # Format exception details in a serializable format
    errors = [{"location": e["loc"], "msg": e["msg"], "type": e["type"]} for e in exc.errors()]
    error_response = {
        "detail": "Validation error",
        "errors": errors,
        # Convert exception message to string if required
        # "message": str(exc)
    }
    return JSONResponse(
        status_code=400,
        content=error_response,
    )

# In-memory storage for demonstration purposes
credentials_store = {}

@app.get("/apis/infra.k8smgmt.io/v3/projects/{project}/credentials")
async def get_credentials(project: str, offset: int = 0, selector: Optional[str] = None, limit: int = 0):
    if offset < 0:
        raise HTTPException(status_code=400, detail="Offset must be a positive number")
    if selector and not selector.isidentifier():
        raise HTTPException(status_code=400, detail="Selector must be a valid identifier")
    if limit < 0:
        raise HTTPException(status_code=400, detail="Limit must be a positive number")
    # Check if the project exists in the store
    if project in credentials_store:
        # Return the stored credentials
        return credentials_store[project]
    else:
        # If the project is not found, return a 404 error
        raise HTTPException(status_code=404, detail="Project not found")

@app.post("/apis/infra.k8smgmt.io/v3/projects/{project}/credentials")
async def post_credentials(project: str, credentials_resource: CredentialsResource):
    # Store the validated credentials in the in-memory store
    credentials_store[project] = credentials_resource.dict(by_alias=True)
    # Confirm successful storage
    return {"message": "Credentials stored successfully", "project": project}
