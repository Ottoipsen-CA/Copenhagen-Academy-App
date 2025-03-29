# Register completed challenge and reward XP
@router.post("/complete/{challenge_id}", response_model=schemas.UserChallengeResponse)
async def complete_challenge(
    challenge_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # 1. Find challenge
    challenge = db.query(models.Challenge).filter(models.Challenge.id == challenge_id).first()
    
    if not challenge:
        raise HTTPException(status_code=404, detail="Challenge not found")

    # 2. Check if already completed
    existing = db.query(models.UserChallenge).filter_by(
        user_id=current_user.id,
        challenge_id=challenge_id
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="Challenge already completed")

    # 3. Register challenge completion
    user_challenge = models.UserChallenge(
        user_id=current_user.id,
        challenge_id=challenge_id,
        completed=True,
        completed_at=datetime.utcnow()
    )
    db.add(user_challenge)

    # 4. Update XP (player stats)
    stats = db.query(models.PlayerStats).filter_by(player_id=current_user.id).first()

    if stats:
        stats.overall_rating += challenge.xp_reward
    else:
        stats = models.PlayerStats(
            player_id=current_user.id,
            overall_rating=challenge.xp_reward
        )
        db.add(stats)

    db.commit()
    db.refresh(user_challenge)
    return user_challenge

