from sqlalchemy.ext.declarative import DeclarativeMeta
from sqlalchemy.orm import Session
from typing import Generic, TypeVar, Type, List, Optional, Dict, Any, Union
from pydantic import BaseModel
from fastapi import HTTPException, status

ModelType = TypeVar("ModelType", bound=DeclarativeMeta)
CreateSchemaType = TypeVar("CreateSchemaType", bound=BaseModel)
UpdateSchemaType = TypeVar("UpdateSchemaType", bound=BaseModel)
ResponseSchemaType = TypeVar("ResponseSchemaType", bound=BaseModel)

class BaseService(Generic[ModelType, CreateSchemaType, UpdateSchemaType, ResponseSchemaType]):
    def __init__(self, model: Type[ModelType], db: Session):
        self.model = model
        self.db = db

    def get_all(self, skip: int = 0, limit: int = 100, **filters) -> List[ModelType]:
        query = self.db.query(self.model)
        
        for key, value in filters.items():
            if hasattr(self.model, key) and value is not None:
                query = query.filter(getattr(self.model, key) == value)
                
        return query.offset(skip).limit(limit).all()

    def get_by_id(self, id: int) -> Optional[ModelType]:
        return self.db.query(self.model).filter(self.model.id == id).first()

    def create(self, obj_in: CreateSchemaType) -> ModelType:
        obj_data = obj_in.dict()
        db_obj = self.model(**obj_data)
        self.db.add(db_obj)
        try:
            self.db.flush() # Flush to get the ID assigned
            new_id = db_obj.id
            if new_id is None:
                 # This should not happen if flush worked for an autoincrement ID
                 raise RuntimeError(f"Flush did not populate ID for {self.model.__name__}")
                 
            self.db.commit() # Commit the transaction
            
            # Immediately fetch the object using the ID obtained after flush
            # Use self.get_by_id which queries the DB
            fetched_obj = self.get_by_id(new_id)
            if fetched_obj is None:
                 # If commit worked, this should find the object
                 raise RuntimeError(f"Failed to fetch {self.model.__name__} with ID {new_id} immediately after commit")
            
            return fetched_obj
            
        except Exception as e:
            print(f"ERROR during create/commit/fetch for {self.model.__name__}: {e}") # Log error
            self.db.rollback() # Rollback on any error during the process
            raise e # Re-raise the exception

    def update(self, id: int, obj_in: Union[UpdateSchemaType, Dict[str, Any]]) -> ModelType:
        db_obj = self.get_by_id(id)
        if not db_obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"{self.model.__name__} with id {id} not found"
            )
            
        if isinstance(obj_in, dict):
            update_data = obj_in
        else:
            update_data = obj_in.dict(exclude_unset=True)
            
        for field in update_data:
            if hasattr(db_obj, field):
                setattr(db_obj, field, update_data[field])
                
        self.db.add(db_obj)
        self.db.commit()
        self.db.refresh(db_obj)
        return db_obj

    def delete(self, id: int) -> bool:
        db_obj = self.get_by_id(id)
        if not db_obj:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"{self.model.__name__} with id {id} not found"
            )
            
        self.db.delete(db_obj)
        self.db.commit()
        return True 