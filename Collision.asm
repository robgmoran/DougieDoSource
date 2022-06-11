;-------------------------------------------------------------------------------------
; Check Sprites for Collision
CheckSpritesForCollision:
        ld      ix, PlayerSprite

; Clear player movement restriction flag
        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.SprContactSide), a

        ld      iy, OtherSprites
        ld      b, 63                          ; Number of sprite entries to search through
.FindActiveSprite:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .NextSprite                  ; Jump if sprite not active

        push    bc, ix, iy
        call    CheckCollision                  ; Check collision between sprites
        pop     iy, ix, bc

.NextSprite
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Point to next sprite
        djnz    .FindActiveSprite

        ret
        
;-------------------------------------------------------------------------------------
; Check Collision
; Parameters:
; ix = Source sprite
; iy = Target sprite
; Return Values:
; a = 0 - Don't delete source sprite, 1 - Delete source sprite
CheckCollision:
; Special Case - Check rock to rock collision
; Check 1 - Check source and target are rocks
        bit     5, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      z, .BypassRockDownCheck                 ; If not continue to normal collision checks

        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)       ; If not continue to normal collision checks
        jp      z, .BypassRockDownCheck

; Check 2 - Check whether source is above target
; - Check source and target have the same x position
        xor     a
        ld      hl, (ix+S_SPRITE_TYPE.xPosition)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        sbc     hl, de
        jr      nz, .RockCheckLeft                      ; Jump if not to check left and right

; - Check target is directly beneath source
        ld      a, (ix+S_SPRITE_TYPE.yPosition)
        add     a, (ix+S_SPRITE_TYPE.Height)
        ld      b, (iy+S_SPRITE_TYPE.yPosition)
        cp      b
        ret     nz                                      ; Return if not

; - Store rock collision
        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.SprCollision), hl     ; Store target collided sprite location

        set     2, (ix+S_SPRITE_TYPE.SprContactSide)    ; Store side hit to restrict movement

        ld      a, 0                                    ; Return value
        ret

; Check 3 - Check whether source is to the left of target
.RockCheckLeft:
; - Check source and target have the same y position
        ld      a, (ix+S_SPRITE_TYPE.yPosition)
        ld      b, (iy+S_SPRITE_TYPE.yPosition)
        cp      b
        ret     nz                                      ; Return of not

; - Check source is to the left of target
        xor     a
        ld      hl, (ix+S_SPRITE_TYPE.xPosition)
        ld      b, 0
        ld      c, (ix+S_SPRITE_TYPE.Width)
        add     hl, bc
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        sbc     hl, de
        jr      nz, .RockCheckRight                     ; Jump if not

; Store rock collision
        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.SprCollision), hl     ; Store target collided sprite location

        set     0, (ix+S_SPRITE_TYPE.SprContactSide)    ; Store side hit to restrict movement

        ld      a, 0                                    ; Return value
        ret

; Check 4 - Check whether source is to the right of target
.RockCheckRight:
; - Check source is to the right of target
        xor     a
        ld      hl, (ix+S_SPRITE_TYPE.xPosition)
        ld      b, 0
        ld      c, (ix+S_SPRITE_TYPE.Width)
        sub     hl, bc
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        sbc     hl, de
        ret     nz                                      ; Jump if not

; Store rock collision
        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.SprCollision), hl     ; Store target collided sprite location

        set     1, (ix+S_SPRITE_TYPE.SprContactSide)    ; Store side hit to restrict movement

        ld      a, 0                                    ; Return value
        ret

; Not rock to rock collisions checks
.BypassRockDownCheck:
; Check whether target sprite is a spawning enemy
        bit     2, (iy+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .NotInRange                 ; Jump if target sprite is spawning

; Check whether target sprite is performing death animation
        bit     0, (iy+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .NotInRange                 ; Jump if target sprite is performing death animation

; Obtain source and target 9-bit x coordinates
        ld      hl, (ix+S_SPRITE_TYPE.xPosition)
        ld      a, (ix+S_SPRITE_TYPE.BoundaryX)
        add     hl, a                           ; Add boundary x offset to source.x
        ld      bc, hl                          ; Backup source.x value
        
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        ld      a, (iy+S_SPRITE_TYPE.BoundaryX)
        add     de, a                           ; Add boundary x offset to target.x
        ld      (BackupData), de                ; Backup target.x value

; Box Check 1 - source.x < target.x + width
        ld      a, (iy+S_SPRITE_TYPE.BoundaryWidth)
        add     de, a                           ; Add width to target.x value

        or      a
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if source.x (hl) >= target.x + width (de)

; Box Check 2 - source.x + width > target.x
        ld      hl, bc                          ; Restore source.x value
        ld      a, (ix+S_SPRITE_TYPE.BoundaryWidth)
        add     hl, a                           ; Add boundary width to source.x

        ld      de, (BackupData)                ; Restore target.x value

        or      a
        ex      hl, de                          ; Swap target.x and source.x
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if target.x (hl) >= source.x + width (de)

; Obtain source and target 8-bit y coordinates
        ld      hl, 0
        ld      l, (ix+S_SPRITE_TYPE.yPosition)
        ld      a, (ix+S_SPRITE_TYPE.BoundaryY)
        add     hl, a                           ; Add boundary y offset to source.y
        ld      bc, hl                          ; Backup source.x value

        ld      de, 0
        ld      e, (iy+S_SPRITE_TYPE.yPosition)
        ld      a, (iy+S_SPRITE_TYPE.BoundaryY)
        add     de, a                           ; Add boundary y offset to source.y
        ld      (BackupData), de                ; Backup target.x value
        
; Box Check 3 - source.y < target.y + height
        ld      a, (iy+S_SPRITE_TYPE.BoundaryHeight)
        add     de, a                           ; Add boundary height to target.y

        or      a
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if player.y (hl) >= enemy.y + height (de)

; Box Check 4 - source.y + height > target.y
        ld      hl, bc                          ; Restore source.y

        ld      a, (ix+S_SPRITE_TYPE.BoundaryHeight)
        add     hl, a                           ; Add boundary height to source.y
        
        ld      de, (BackupData)                ; Restore target.y

        or      a
        ex      hl, de                          ; Swap target.x and source.x
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if enemy.y (hl) >= player.y + height        

; Collision with sprite
        bit     2, (ix+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .EnemySource                ; Jump if source enemy 

        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .PlayerSource               ; Jump if source player 

        jp      .CheckSides                     ; Jump if not player or enemy

; Enemy hit sprite
.EnemySource:
        bit     5, (iy+S_SPRITE_TYPE.SpriteType2)       ; Check for collision with exploding bomb
        jr      nz, .HitExplodingBomb

        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)       ; Check for collision with rock
        jp      nz, .HitRock

        ld      a, 0                            ; Set enemy not to be destroyed
        ret

.HitExplodingBomb:
; Update score
        push    iy, ix
        ld      iy, ScoreBombEnemyStr
        ld      b, 2
        call    UpdateScore

        ld      de, ScoreBombEnemy
        call    CheckExtraLife
        call    DisplayHUDScoreValues
        pop     ix, iy

        ld      a, 1                            ; Set enemy to be destroyed
        ret

; Player hit sprite
.PlayerSource:
        bit     6, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .HitDiamond

        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .HitRock

        bit     2, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .HitEnemy

        bit     7, (iy+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .HitBomb

        ret

.HitDiamond:
        push    af, bc, de, hl, ix
        ld      a, AyFXDiamond
        call    AFXPlay       
        pop     ix, hl, de, bc, af

; Delete diamond sprite
        push    ix
        call    DeleteSprite
        pop     ix

; Update diamonds total
        ld      hl, DiamondsCollected
        inc     (hl)

; Update score
        push    iy, ix
        ld      iy, ScoreDiamondStr
        ld      b, 2
        call    UpdateScore

        ld      de, ScoreDiamond
        call    CheckExtraLife
        call    DisplayHUDScoreValues
        pop     ix, iy

; Check for extra bomb
        ld      a, (BombExtraCounter)
        inc     a
        ld      (BombExtraCounter), a
        cp      BombExtra
        ret     nz                      ; Return if not yet awarded extra bomb

        ld      a, 0
        ld      (BombExtraCounter), a   ; Reset bomb extra counter

        ld      a, (Bombs)
        inc     a
        ld      (Bombs), a              ; Add extra bomb
        
        push    af, bc, de, hl, ix
        ld      a, AyFXExtraBomb1
        call    AFXPlay
        ld      a, AyFXExtraBomb2
        call    AFXPlay
        pop     ix, hl, de, bc, af

        call    DisplayHUDBombValue

        ret

.HitEnemy:
; Stop song
        call    NextDAW_StopSong

        push    af, bc, de, hl, ix
        ld      a, AyFXPlayerDead1
        call    AFXPlay
        ld      a, AyFXPlayerDead2
        call    AFXPlay
        ld      a, AyFXPlayerDead3
        call    AFXPlay
        pop     ix, hl, de, bc, af

        ld      a, 1
        ld      (PlayerDead), a                 ; Player dead
        ret

.HitBomb:
        bit     5, (iy+S_SPRITE_TYPE.SpriteType2)
        ret     z                               ; Jump if player not hit exploding bomb
        ;jr      z, .BombCont                    ; Jump if player not hit exploding bomb

; Stop song
        call    NextDAW_StopSong

        push    af, bc, de, hl, ix
        ld      a, AyFXPlayerDead1
        call    AFXPlay       
        ld      a, AyFXPlayerDead2
        call    AFXPlay       
        ld      a, AyFXPlayerDead3
        call    AFXPlay       
        pop     ix, hl, de, bc, af

        ld      a, 1
        ld      (PlayerDead), a                 ; Otherwise player dead
        ret

;.BombCont:
        ;bit     6, (iy+S_SPRITE_TYPE.SpriteType2)
        ;ret     nz                              ; Return if bomb dropped i.e. We don't want to pickup

        ;ret

.HitRock:
.CheckSides:
; Check whether source below rock
        ld      a, (iy+S_SPRITE_TYPE.yPosition)
        ld      b, (ix+S_SPRITE_TYPE.yPosition)
        cp      b
        jr      c, .BelowRock                   ; Jump if Source.y (b) > Target.y (a)

; Check whether source above rock
        ld      c, a
        ld      a, b
        ld      b, c                            ; Swap source and target
        cp      b
        jp      c, .AboveRock                   ; Jump if Target.y (b) > Source.y (a)

; Check whether source to left of rock
        ld      hl, (ix+S_SPRITE_TYPE.xPosition)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        or      a
        sbc     hl, de
        jp      c, .LeftOfRock                 ; Jump if Source.x (hl) < Target.x (de)

; Check whether source to right of rock
        ld      hl, (iy+S_SPRITE_TYPE.xPosition)
        ld      de, (ix+S_SPRITE_TYPE.xPosition)
        or      a
        sbc     hl, de
        jp      c, .RightOfRock                 ; Jump if Target.x (hl) < Source.x (de)        

        ld      a, 0                            ; Return value

        ret

.BelowRock:
        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.SprCollision), hl     ; Store target collided sprite location

        set     3, (ix+S_SPRITE_TYPE.SprContactSide)    ; Store side hit to restrict movement

        ;bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        ;ret     z                                       ; Return if source not player 

; Check whether player/enemy dead i.e. Rock fallen on player/enemy
        ld      a, 0                                    ; Assume enemy will not be destroyed

        bit     4, (iy+S_SPRITE_TYPE.SpriteType1)       ; Check whether rock is moving
        ret     z                                       ; Return if rock not moving

        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .PlayerDead                         ; Jump if source player 

        bit     2, (ix+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .EnemyDead                          ; Jump if source enemy 

        ret

.PlayerDead:
; Stop song
        call    NextDAW_StopSong        

        push    af, bc, de, hl, ix
        ld      a, AyFXPlayerDead1
        call    AFXPlay       
        ld      a, AyFXPlayerDead2
        call    AFXPlay       
        ld      a, AyFXPlayerDead3
        call    AFXPlay       
        pop     ix, hl, de, bc, af

        ld      a, 1
        ld      (PlayerDead), a                         ; Otherwise rock hit player and player dead

        ret

.EnemyDead:
; Set dying animation
        push    iy, ix

        ld      iy, ix

        ; Point to enemy sprite attribute data
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Destination - Sprite Attributes

        ld      bc, DeathPatterns                       ; Sprite pattern range
        call    UpdateSpritePattern

        set     0, (iy+S_SPRITE_TYPE.SpriteType2)       ; Set death flag

        pop     ix, iy

; Enemy hit by rock so prevent enemy respawning
        ld      hl, (ix+S_SPRITE_TYPE.EnemyType)        ; Obtain enemy associated EnemyType
        ld      iy, hl
        ld      a, (iy+S_ENEMY_TYPE.EnemyMaxNumber)
        dec     a                                       ; Decrement counter to prevent enemy being respawned
        ld      (iy+S_ENEMY_TYPE.EnemyMaxNumber), a
        ld      a, (iy+S_ENEMY_TYPE.EnemyMaxCounter)
        dec     a                                       ; Decrement counter to prevent enemy being respawned
        ld      (iy+S_ENEMY_TYPE.EnemyMaxCounter), a

        push    af, bc, de, hl, ix
        ld      a, AyFXEnemyDead
        call    AFXPlay       
        pop     ix, hl, de, bc, af

; Update score
        push    iy, ix

        bit     1, (ix+S_SPRITE_TYPE.SpriteType2)
        jr      z, .NormalEnemy                         ; Jump if not static enemy

; Static Enemy
        ld      iy, ScoreRockStaticStr
        ld      b, 3
        call    UpdateScore

        ld      de, ScoreRockStatic

        jr      .CheckExtraLife

; Normal Enemy
.NormalEnemy:
        ld      a, (EnemiesDestroyed)
        inc     a
        ld      (EnemiesDestroyed), a

        ld      iy, ScoreRockEnemyStr
        ld      b, 3
        call    UpdateScore

        ld      de, ScoreRockEnemy

.CheckExtraLife:
        call    CheckExtraLife
        call    DisplayHUDScoreValues
        pop     ix, iy

        ld      a, 0                                    ; Return value

        ret

.AboveRock:
; If source rock - Don't set collision
; Note: Collision for source rock above is only checked for rock to rock at start of routine
        ld      a, 0                                    ; Assume return value

        bit     5, (ix+S_SPRITE_TYPE.SpriteType1)
        ret     nz                                      ; Return if source rock

        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.SprCollision), hl     ; Store target collided sprite location

        set     2, (ix+S_SPRITE_TYPE.SprContactSide)    ; Store side hit to restrict movement

        ld      a, 0                                    ; Return value

        ret

.LeftOfRock:
; Configure source
        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.SprCollision), hl     ; Store target collided sprite location

        set     0, (ix+S_SPRITE_TYPE.SprContactSide)    ; Store side hit to restrict movement

        ld      a, 0                                    ; Return value

        ret

.RightOfRock:
; Configure source
        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.SprCollision), hl     ; Store target collided sprite location

        set     1, (ix+S_SPRITE_TYPE.SprContactSide)    ; Store side hit to restrict movement

        ld      a, 0                                    ; Return value

        ret

.NotInRange:
        ld      a, 0                                    ; Set return value

        ret

;-------------------------------------------------------------------------------------
; Check Tiles above Sprite
; Parameters:
; iy = Sprite
CheckTilesAbove:
; 1. Calculate Tile Column (using x position)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)

        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

        ld      c, e                            ; Store tile column position

; 2. Calculate Tile Row (using y Position and tilemap offset y)
        ld      a, (TileMapOffsetY)
        ld      b, a
        ld      a, (iy+S_SPRITE_TYPE.yPosition)
        add     a, b
        ld      d, 0
        ld      e, a

; 3. Check whether we are directly below new tile
        call    CheckDivisableBy8
        ld      (PlayerDivisable), a
        cp      a, 1
        jr      nz, .ContUp                     ; Jump if player y divisable

        add     de, -8                          ; Otherwise change starting position

.ContUp:
        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

; 4. Calculate Tile Offset in Tilemap Memory 
        call    GetTilePosition                 ; Output - HL = Tile offset in tilemap memory 

; 5. Check tiles to right of sprite
        ;;set     0, (ix+S_SPRITE_TYPE.Movement) ; Default - Allow sprite to move right 
        ld      a, (PlayerDivisable)
        cp      1
        jr      z, .Divisable                   ; Jump if player directly below tile

        ld      a, 1
        ret
        ;;jr      z, .DigRight                    ; Jump if player not at left of tile i.e. Don't need to check for stones

.Divisable:
; 6. Check for stones - Directly in-front
        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            
        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileStones
        jr      z, .CannotDigAbove              ; Jump if player hit stone

        cp      TileEarth                       
        jr      z, .CheckDelay                  ; Jump if player hit earth

/*
        inc     hl
        ld      a, (hl)
        dec     hl
        cp      TileStones
        jr      z, .CannotDigAbove              ; Jump if player hit stone
*/

        jr      .DigAbove

.CannotDigAbove:
        ld      a, 1
        ld      (EnemyDiggerChangeDir), a       ; Return value - Request enemy to try different direction
        ld      a, 0                            ; Return value - Don't permit player to move
        ret

.CheckDelay:
        ld      a, (iy+S_SPRITE_TYPE.DelayCounter);(DelayCounter)
        cp      0
        jr      z, .DigAbove                    ; Jump if player delay counter is zero

        dec     a
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a               ; Otherwise decrement counter and don't move
        
        ld      a, 0
        ld      (EnemyDiggerChangeDir), a       ; Return value - Don't change enemy direction
        ld      a, 0                            ; Return value - Don't permit player to move
        ret

; 7. Check for remaining tiles
.DigAbove:
        ld      a, DelayCounterMax
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a               ; Reset player movement delay counter

; In-front - Left Character        
        ld      de, TileUTL     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; In-front - Right Character
        inc     hl

        ld      de, TileUTR     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        dec     hl

; Player - Left Character
        add     hl, TileMapWidth

        ld      de, TileUPL     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; Player - Right Character
        inc     hl

        ld      de, TileUPR     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        ld      a, 1            ; Return value - Permit player to move
        ret

;-------------------------------------------------------------------------------------
; Check Tiles below Sprite
; Parameters:
; iy = Sprite
CheckTilesBelow:
; 1. Calculate Tile Column (using x position)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

        ld      c, e                            ; Store tile column position

; 2. Calculate Tile Row (using y Position and tilemap offset y)
        ld      a, (TileMapOffsetY)
        ld      b, a
        ld      a, (iy+S_SPRITE_TYPE.yPosition)
        add     a, b
        ld      d, 0
        ld      e, a

        ld      a, (iy+S_SPRITE_TYPE.Height)
        add     de, a                           ; Add height offset

; 3. Check whether we are directly above new tile
        call    CheckDivisableBy8
        ld      (PlayerDivisable), a

        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

; 4. Calculate Tile Offset in Tilemap Memory 
        call    GetTilePosition                 ; Output - HL = Tile offset in tilemap memory 

; 5. Check tiles to right of sprite
        ;;set     0, (ix+S_SPRITE_TYPE.Movement) ; Default - Allow sprite to move right 
        ld      a, (PlayerDivisable)
        cp      1
        jr      z, .Divisable                   ; Jump if player directly above tile

        ld      a, 1
        ret
        ;;jr      z, .DigRight                    ; Jump if player not at left of tile i.e. Don't need to check for stones

.Divisable:
; 6. Check for stones - Directly in-front
        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            
        ld      a, (hl)
        sub     b

        cp      TileStones
        jr      z, .CannotDigBelow              ; Jump if player hit stone

        cp      TileEarth                       
        jr      z, .CheckDelay                  ; Jump if player hit earth

/*
        inc     hl
        ld      a, (hl)
        dec     hl
        cp      TileStones
        jr      z, .CannotDigBelow              ; Jump if player hit stone
*/      
        jr      .DigBelow

.CannotDigBelow:
        ld      a, 1
        ld      (EnemyDiggerChangeDir), a       ; Return value - Request enemy to try change direction
        ld      a, 0                            ; Return value - Don't permit player to move
        ret

.CheckDelay:
        ld      a, (iy+S_SPRITE_TYPE.DelayCounter) ;(DelayCounter)
        cp      0
        jr      z, .DigBelow                    ; Jump if player delay counter is zero

        dec     a
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a               ; Otherwise decrement counter and don't move
        
        ld      a, 0
        ld      (EnemyDiggerChangeDir), a       ; Return value - Don't change enemy direction
        ld      a, 0                            ; Return value - Don't permit player to move
        ret

; 7. Check for remaining tiles
.DigBelow:
        ld      a, DelayCounterMax
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a       ; Reset player movement delay counter

; In-front - Left Character        
        ld      de, TileDTL     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b
        ld      (hl), a         ; Place new tile

; In-front - Right Character
        inc     hl

        ld      de, TileDTR     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        dec     hl

; Player - Left Character
        xor     a
        ld      de, TileMapWidth
        sbc     hl, de

        ld      de, TileDPL     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; Player - Right Character
        inc     hl

        ld      de, TileDPR     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        ld      a, 1            ; Return value - Permit player to move
        ret

;-------------------------------------------------------------------------------------
; Check Tiles to left of Sprite
; Parameters:
; iy = Sprite
CheckTilesToLeft:
; 1. Calculate Tile Column (using x position)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)

; 2. Check whether we are directly to the right of a new tile
        call    CheckDivisableBy8
        ld      (PlayerDivisable), a

        cp      a, 1
        jr      nz, .ContLeft                   ; Jump if player x not divisable

        add     de, -8                          ; Otherwise change starting position

.ContLeft
        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

        ld      c, e                            ; Store tile column position

; 3. Calculate Tile Row (using y Position and tilemap offset y)
        ld      a, (TileMapOffsetY)
        ld      b, a
        ld      a, (iy+S_SPRITE_TYPE.yPosition)
        add     a, b
        ld      d, 0
        ld      e, a

        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

; 4. Calculate Tile Offset in Tilemap Memory 
        call    GetTilePosition                 ; Output - HL = Tile offset in tilemap memory 


; 5. Check tiles to left of sprite
        ;;set     0, (ix+S_SPRITE_TYPE.Movement) ; Default - Allow sprite to move right 
        ld      a, (PlayerDivisable)
        cp      1
        jr      z, .Divisable                   ; Jump if player directly to right of tile

        ld      a, 1
        ret
        ;;jr      z, .DigRight                    ; Jump if player not at left of tile i.e. Don't need to check for stones

.Divisable:
; 6. Check for stones - Directly in-front
        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            
        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileStones
        jr      z, .CannotDigLeft               ; Jump if player hit stone

        cp      TileEarth                       
        jr      z, .CheckDelay                  ; Jump if player hit earth

/*
        push    hl
        add     hl, TileMapWidth                ; Point to next tile down
        ld      a, (hl)
        pop     hl
        cp      TileStones
        jr      z, .CannotDigLeft               ; Jump if player hit stone
 */

        jr      .DigLeft

.CannotDigLeft:
        ld      a, 1
        ld      (EnemyDiggerChangeDir), a       ; Return value - Request enemy to try y direction
        ld      a, 0                            ; Return value - Don't permit player to move
        ret

.CheckDelay:
        ld      a, (iy+S_SPRITE_TYPE.DelayCounter) ;(DelayCounter)
        cp      0
        jr      z, .DigLeft                     ; Jump if player delay counter is zero

        dec     a
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a               ; Otherwise decrement counter and don't move
        
        ld      a, 0
        ld      (EnemyDiggerChangeDir), a       ; Return value - Don't change enemy direction
        ld      a, 0                            ; Return value - Don't permit player to move
        ret

; 7. Check for remaining tiles
.DigLeft:
        ld      a, DelayCounterMax
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a              ; Reset player movement delay counter

; In-front - Top Character
        push    hl
        
        ld      de, TileLTT     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; In-front - Bottom Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileLTB     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        pop     hl
        
; Player - Top Character        
        inc     hl

        ld      de, TileLPT     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; Player - Right Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileLPB     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        ld      a, 1            ; Return value - Permit player to move
        ret

;-------------------------------------------------------------------------------------
; Check Tiles to right of Sprite
; Parameters:
; iy = Sprite
CheckTilesToRight:
; 1. Calculate Tile Column (using x position)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        ld      a, (iy+S_SPRITE_TYPE.Width)    ; Assumes full width player
        add     de, a                           ; Add width offset

; 2. Check whether we are directly to the left of a new tile
        call    CheckDivisableBy8
        ld      (PlayerDivisable), a
        
        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

        ld      c, e                            ; Store tile column position

; 3. Calculate Tile Row (using y Position and tilemap offset y)
        ld      a, (TileMapOffsetY)
        ld      b, a
        ld      a, (iy+S_SPRITE_TYPE.yPosition)
        add     a, b
        ld      d, 0
        ld      e, a

        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

; 4. Calculate Tile Offset in Tilemap Memory 
        call    GetTilePosition                 ; Output - HL = Tile offset in tilemap memory 
        
; 5. Check tiles to right of sprite
        ;;set     0, (ix+S_SPRITE_TYPE.Movement) ; Default - Allow sprite to move right 
        ld      a, (PlayerDivisable)
        cp      1
        jr      z, .Divisable                   ; Jump if player directly to left of tile

        ld      a, 1
        ret
        ;;jr      z, .DigRight                    ; Jump if player not at left of tile i.e. Don't need to check for stones

.Divisable:
; 6. Check for stones/earth - Directly in-front
        ld      a, (LevelTileMapDefOffset)
        ld      b, a
        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileStones
        jr      z, .CannotDigRight              ; Jump if player hit stone
        cp      TileEarth                       
        jr      z, .CheckDelay                  ; Jump if player hit earth

/*
        push    hl
        add     hl, TileMapWidth                ; Point to next tile down
        ld      a, (hl)
        pop     hl
        cp      TileStones
        jr      z, .CannotDigRight              ; Jump if player hit stone
        
        cp      TileEarth                       ; Jump if player hit earth
        jr      z, .CheckDelay

*/

        jr      .DigRight

.CannotDigRight:
        ld      a, 1
        ld      (EnemyDiggerChangeDir), a       ; Return value - Request enemy to try y direction
        ld      a, 0                            ; Return value - Don't permit player to move
        ret

.CheckDelay:
        ld      a, (iy+S_SPRITE_TYPE.DelayCounter) ;(DelayCounter)
        cp      0
        jr      z, .DigRight                    ; Jump if player delay counter is zero

        dec     a
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a               ; Otherwise decrement counter and don't move
        
        ld      a, 0
        ld      (EnemyDiggerChangeDir), a       ; Return value - Don't change enemy direction
        ld      a, 0                            ; Return value - Don't permit player to move
        ret

; 7. Check for remaining tiles
.DigRight:
        ld      a, DelayCounterMax
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a       ; Reset player movement delay counter

; In-front - Top Character
        push    hl
        
        ld      de, TileRTT     ; Get lookup table

        ld      a, (LevelTileMapDefOffset)
        ld      b, a
        ld      a, (hl)                         ; Get screen character
        sub     b                               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a

; In-front - Bottom Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileRTB     ; Get lookup table

        ld      a, (LevelTileMapDefOffset)
        ld      b, a
        ld      a, (hl)                         ; Get screen character
        sub     b                               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        pop     hl

; Player - Top Character        
        dec     hl

        ld      de, TileRPT     ; Get lookup table

        ld      a, (LevelTileMapDefOffset)
        ld      b, a
        ld      a, (hl)                         ; Get screen character
        sub     b                               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; Player - Right Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileRPB     ; Get lookup table

        ld      a, (LevelTileMapDefOffset)
        ld      b, a
        ld      a, (hl)                         ; Get screen character
        sub     b                               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        ld      a, 1            ; Return value - Permit player to move
        ret
        
;-------------------------------------------------------------------------------------
; Get Tile Offset within Tile Map
; Parameters:
; de = Number of Rows
; c = Tile Column
; Return Values:
; hl = TilePosition
GetTilePosition:
; Calculate Tile Offset in Memory
        ld      d, TileMapWidth ; Tilemap width 
        mul     d, e            ; Calculate tile row offset = Tilemap width (d)  * Number of Rows (e)

        ld      a, c            ; Restore tile column
        add     de, a           ; Add tile column to tile row offset 

        ld      hl, TileMapLocation 
        add     hl, de          ; Add tile offset to tilemap memory location

        ret

;-------------------------------------------------------------------------------------
; Check whether position divisable by 8
; Parameters:
; de = Sprite Position either x or y
; Return Values:
; a = 0 - Not Divisable by 8, 1 - Divisable by 8
CheckDivisableBy8:
; Check whether value is divisable by 8
        ld      a, e            ; Store low byte
        ld      b, 1            ; Assume divisable by 8
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 8
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 8
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 8
        
        jp      .Continue       ; Number directly divisable by 8

.Remainder
        dec     b               ; Indicate position not divisable by 8
.Continue
        ld      a, b
        ret

;-------------------------------------------------------------------------------------
; Check whether position divisable by 16
; Parameters:
; de = Sprite Position either x or y
; Return Values:
; a = 0 - Not Divisable by 16, 1 - Divisable by 16
CheckDivisableBy16:
; Check whether value is divisable by 16
        ld      a, e            ; Store low byte
        ld      b, 1            ; Assume divisable by 16
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 16
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 16
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 16
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 16
        jp      .Continue       ; Number directly divisable by 16
.Remainder
        dec     b               ; Indicate position not divisable by 16
.Continue
        ld      a, b
        ret
