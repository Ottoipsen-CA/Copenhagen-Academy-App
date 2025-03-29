from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
import models, schemas

router = APIRouter(
    prefix="/test-stats",
    tags=["TEST — Player Stats"],
)

@router.post("/", response_model=schemas.SimplePlayerStat)
def create_simple_stats(
    stat_data: schemas.SimplePlayerStatCreate,
    db: Session = Depends(get_db)
):
    db_stat = models.PlayerStats(
        player_id=stat_data.player_id,
        pace=stat_data.pace,
        shooting=stat_data.shooting,
        passing=stat_data.passing,
        dribbling=0,
        defense=0,
        physical=0,
        overall_rating=0
    )
    db.add(db_stat)
    db.commit()
    db.refresh(db_stat)
    return db_stat
