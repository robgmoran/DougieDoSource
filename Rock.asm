;-------------------------------------------------------------------------------------
; Move Rock
; Parameters:
; iy = Sprite data
MoveRock:
        ld      a, (iy+S_SPRITE_TYPE.Movement)
        cp      4
        jp      z, MoveRockDown                        ; Jump if rock moving down

        ld      a, (iy+S_SPRITE_TYPE.Movement)
        cp      2
        jp      z, MoveRockLeft                        ; Jump if rock moving left

        ld      a, (iy+S_SPRITE_TYPE.Movement)
        cp      1
        jp      z, MoveRockRight                       ; Jump if rock moving right

        ret

;-------------------------------------------------------------------------------------
; Move Rock Down
; Parameters:
; iy = Sprite data
MoveRockDown:
        push    bc

.ContDown:
; Obtain sprite location within sprite attribute table
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Sprite Attribute table location

; Condition 1 - Check tile collision
        call    CheckTilesBelowRock                     ; Output - a=0 Don't move, a=1 Move
        cp      a, 0
        jr      z, .DownEnd                             ; Jump if cannot move

; OK to move - Update y value and sprite attributes
        ;ld      (iy+S_SPRITE_TYPE.Movement), 4  ; Set player movement flag to down

        ld      a, (ix+S_SPRITE_ATTR.y)
        inc     a
        ld      (ix+S_SPRITE_ATTR.y), a
        ld      (iy+S_SPRITE_TYPE.yPosition), a         ; Store 8-bit value

.DownEnd:
        pop     bc
        
        ret

;-------------------------------------------------------------------------------------
; Check Tiles below Rock
; Parameters:
; iy = Sprite
; ix = Sprite Attributes
; Return Values:
; a=1 - Can move, a=0 - Cannot move
CheckTilesBelowRock:
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        call    CheckDivisableBy16
        cp      1                               ; Check whether rock in a position to move down
        jp      nz, .ContDown                   ; Jump if not divisable

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

        push    de                              ; Backup y position

        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

; 3. Calculate Tile Offset in Tilemap Memory 
        call    GetTilePosition                 ; Output - HL = Tile offset in tilemap memory 

; 4. Check sprite position
        pop     de                              ; Restore y position
        call    CheckDivisableBy8
        cp      1
        jr      z, .Divisable                   ; Jump if rock directly above tile

        ld      a, 1                            ; Otherwise continue moving rock
        ret

.Divisable:
        or      a                               ; Clear carry flag
        ld      a, (SpriteMaxDown)
        ld      b, a
        ld      a, (iy+S_SPRITE_TYPE.yPosition)

        sbc     a, b
        jp      nc, .CannotMoveBelow                    ; Jump if a >= SpriteMaxDown

; 5. Check for stones and earth - Directly in-front
        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            
        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileStones                      ; Check below-left tile
        jp      z, .CannotMoveBelow             ; Jump if rock hit stone

        cp      TileEarth                       ; Check below-left tile
        jp      z, .CannotMoveBelow             ; Jump if rock hit earth

        inc     hl                              ; Point to next right tile

        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileEarth                       ; Check below-right tile
        jr      z, .CannotMoveBelow             ; Jump if rock hit earth
        
; No stones or earth below rock
; Special Case Check - Check whether source rock directly above target rock; required to ensure rock doesn't drop down onto other rock
        push    ix, iy, hl
        
        push    iy
        pop     ix

        call    CheckRockForCollision

        pop     hl, iy, ix

        bit     2, (iy+S_SPRITE_TYPE.SprContactSide)
        jp      nz, .CannotMoveBelow
        ;ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        ;cp      4
        ;jp      z, .CannotMoveBelow             ; Jump if rock directly beneath

        bit     4, (iy+S_SPRITE_TYPE.SpriteType1); Check rock movement
        jr      z, .AnimateRock                 ; Jump if rock not moving

        inc     (iy+S_SPRITE_TYPE.Counter)      ; Increment drop counter

; Clear tiles
; In-front - Left Character        
        dec     hl

        ld      de, TileDTL     ; Get lookup table
        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

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

; Sprite - Left Character
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

; Sprite - Right Character
        inc     hl

        ld      de, TileDPR     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offse

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        ld      a, 1                            ; Permit rock to drop
        ret

.AnimateRock:
        set     7, (iy+S_SPRITE_TYPE.SpriteType1); Set rock to animate

        ld      a, (RockDelayBeforeDrop)
        ld      (iy+S_SPRITE_TYPE.Counter), a   ; Set rock drop timer
        
        push    af, bc, de, hl, ix
        ld      a, AyFXDropRock
        call    AFXPlay       
        pop     ix, hl, de, bc, af

        ld      a, 0                            ; Don't move rock yet
        ret

.CannotMoveBelow:
; Check for movement and drop count
        bit     4, (iy+S_SPRITE_TYPE.SpriteType1); Check rock movement
        jr      z, .ContDown                    ; Jump if rock not moving

        ld      a, RocksDropRows
        cp      (iy+S_SPRITE_TYPE.Counter)      ; Check whether we've dropped too many levels
        jr      c, .DestroyRock                 ; Jump if dropped too many levels 

; Reset rock back to normal static rock
        res     4, (iy+S_SPRITE_TYPE.SpriteType1)        ; Configure rock not to move
        
        ld      a, 0
        ld      (iy+S_SPRITE_TYPE.Movement), a          ; Reset rock movement flag

        res     7, (iy+S_SPRITE_TYPE.SpriteType1)        ; Configure rock not to animate
        ld      (iy+S_SPRITE_TYPE.Counter), 0           ; Reset rock level counter

        ld      bc, RockWaitPatterns
        ld      (iy+S_SPRITE_TYPE.patternRange), bc     ; Configure rock with new sprite pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.animationDelay), a    ; Configure rock with new animation delay
        inc     bc                                      ; Point to first pattern in new sprite pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a   ; Configure rock with new first sprite pattern

        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (ix+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        jr      .ContDown

.ContReset:
        dec     bc                                      ; Point to start pattern in sprite animation pattern range

        ld      a, (bc)                                 
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Reset to start pattern

.DestroyRock
        call    DeleteSprite                    ; Delete sprite if dropped down too far

.ContDown:
        ld      a, 0                            ; Return value - Don't permit rock to move
        ret

;-------------------------------------------------------------------------------------
; Move Rock Right
; Parameters:
; iy = Sprite data
; a = 0 - Don't allow player/enemy to move, 1 = Allow player/enemy to move
MoveRockRight:
; Check whether rock is in contact with another rock on right
        push    iy, iy

        pop     ix    

        call    CheckRockForCollision

        pop     iy
        
        bit     0, (iy+S_SPRITE_TYPE.SprContactSide)
        jr      z, .RightCont                           ; Jump if rock not on right

        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)        ; Check whether sprite animating
        jr      nz, .RightEnd                           ; Jump if animating

        bit     1, (iy+S_SPRITE_TYPE.SprContactSide)
        jr      nz, .RightEnd                            ; Jump if rock not on left

        ld      a, 2
        ld      (iy+S_SPRITE_TYPE.Movement), a          ; Otherwise move rock left
        jp      MoveRockLeft

        ret

.RightCont:
        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)        ; Check whether sprite animating
        jr      nz, .RightEnd                           ; Jump if animating

; Obtain sprite location within sprite attribute table
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Sprite Attribute table location

; Condition 1 - Check tile collision
        call    CheckTilesToRightRock                   ; Output - a=0 Don't move, a=1 Move
        cp      a, 0
        jr      z, .RightEnd                            ; Jump if cannot move

; OK to move - Update x value and sprite attributes
        ld      hl, (iy+S_SPRITE_TYPE.xPosition)

        inc     hl

        ld      (ix+S_SPRITE_ATTR.x), l         ; Store bits 0-8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl; Store 9-bit value

        or      a                               ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .RightSetmrx8               ; Setmrx8 if hl >=256

        ; Update sprite attributes
        res     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9
        res     3, (ix+S_SPRITE_ATTR.mrx8)      ; Don't horizontally mirror sprite
        
        ld      a, 1                            ; Allow player to move

        ret

;.RightUpdateAnimation:
;        ld      bc, PlayerHorPatterns
;        call    UpdateSpritePattern             ; Update animation
        
;        jp      .CheckPlayerFire

.RightSetmrx8
        ; Update sprite attributes
        set     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9
        res     3, (ix+S_SPRITE_ATTR.mrx8)      ; Don't horizontally mirror sprite

        ld      a, 1                            ; Allow player to move
        
        ret
        ;ld      bc, PlayerHorPatterns
        ;call    UpdateSpritePattern             ; Update animation

.RightEnd:
        ld      a, 0                            ; Don't allow player to move
        ;ld      a, (iy+S_SPRITE_TYPE.Movement)

        ret

;-------------------------------------------------------------------------------------
; Move Rock Left
; Parameters:
; iy = Sprite data
; Return Values:
; a = 0 - Don't allow player/enemy to move, 1 = Allow player/enemy to move
MoveRockLeft:
; Check whether rock is in contact with another rock on left
        push    iy, iy

        pop     ix    

        call    CheckRockForCollision

        pop     iy
        
        bit     1, (iy+S_SPRITE_TYPE.SprContactSide)
        jr      z, .LeftCont                            ; Jump if rock not on left

        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)        ; Check whether sprite animating
        jr      nz, .LeftEnd                            ; Jump if animating

        bit     0, (iy+S_SPRITE_TYPE.SprContactSide)
        jr      nz, .LeftEnd

        ld      a, 1
        ld      (iy+S_SPRITE_TYPE.Movement), a          ; Otherwise move rock right
        jp      MoveRockRight

        ret

.LeftCont:
        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)       ; Check whether sprite animating
        jr      nz, .LeftEnd                            ; Jump if animating

; Obtain sprite location within sprite attribute table
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Sprite Attribute table location

; Condition 1 - Check tile collision
        call    CheckTilesToLeftRock                    ; Output - a=0 Don't move, a=1 Move
        cp      a, 0
        jr      z, .LeftEnd                            ; Jump if cannot move

; OK to move - Update x value and sprite attributes
        ld      hl, (iy+S_SPRITE_TYPE.xPosition)

        dec     hl

        ld      (ix+S_SPRITE_ATTR.x), l         ; Store bits 0-8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl; Store 9-bit value

        or      a                               ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .LeftSetmrx8               ; Setmrx8 if hl >=256

        ; Update sprite attributes
        res     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9
        res     3, (ix+S_SPRITE_ATTR.mrx8)      ; Don't horizontally mirror sprite
        
        ld      a, 1                            ; Allow player to move

        ret

;.LeftUpdateAnimation:
;        ld      bc, PlayerHorPatterns
;        call    UpdateSpritePattern             ; Update animation
        
;        jp      .CheckPlayerFire

.LeftSetmrx8:
        ; Update sprite attributes
        set     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9
        res     3, (ix+S_SPRITE_ATTR.mrx8)      ; Don't horizontally mirror sprite

        ld      a, 1                            ; Allow player to move
        
        ret
        ;ld      bc, PlayerHorPatterns
        ;call    UpdateSpritePattern             ; Update animation

.LeftEnd:
        ld      a, 0                            ; Don't allow player to move

        ret

;-------------------------------------------------------------------------------------
; Check Tiles to right of rock
; Parameters:
; iy = Sprite
; ix = Sprite attributes
; Return Values:
; a=1 - Can move, a=0 - Cannot move
CheckTilesToRightRock:
; 1. Calculate Tile Column (using x position)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        ld      a, (iy+S_SPRITE_TYPE.Width)    ; Assumes full width player
        add     de, a                          ; Add width offset

        push    de                              ; Backup x position

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
        pop     de                              ; Restore x position

        call    CheckDivisableBy8
        
        cp      1
        jr      z, .Divisable                   ; Jump if rock directly to left of tile

        ld      a, 1                            ; Otherwise continue moving rock
        ret

.Divisable:
; Check whether we're at a divisable by 16 tile to either start moving or end moving 
        call    CheckDivisableBy16
        cp      0
        jr      z, .ContDivisable               ; Jump if not divisable by 16

        bit     4, (iy+S_SPRITE_TYPE.SpriteType1); Check whether rock is moving
        jp      nz, .CannotMoveRight            ; Jump if rock moving i.e. The rock is now at the end location

; Rock at start of move
        set     4, (iy+S_SPRITE_TYPE.SpriteType1); Set rock moving flag
        ld      a, 1
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Set rock movement to right

.ContDivisable:
        ld      de, hl                          ; Backup hl
        
        ld      hl, (iy+S_SPRITE_TYPE.xPosition)

        or      a                               ; Clear carry flag
        ld      bc, (SpriteMaxRight)
        sbc     hl, bc
        jp      nc, .CannotMoveRight            ; Jump if hl >= SpriteMaxRight

        ld      hl, de                          ; Restore hl
        
; 6. Check for stones/earth - Directly in-front        
        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            
        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileStones
        jr      z, .CannotMoveRight             ; Jump if player hit stone

        cp      TileEarth                       
        jr      z, .CannotMoveRight             ; Jump if player hit earth

        add     hl, TileMapWidth                ; Point to next tile down

        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileStones
        jr      z, .CannotMoveRight             ; Jump if player hit stone
        
        cp      TileEarth                       ; Jump if player hit earth
        jr      z, .CannotMoveRight

; Clear tiles
; In-front - Top Character
        ld      hl, de                          ; Restore hl

        push    hl
        
        ld      de, TileRTT     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a

; In-front - Bottom Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileRTB     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        pop     hl

; Player Right - Top Character        
        push    hl
        
        dec     hl

        ld      de, TileRPT     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; Player Right - Bottom Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileRPB     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        pop     hl

; Player Left - Top Character        
        dec     hl
        dec     hl

        ld      de, TileRPT     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; Player - Right Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileRPB     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        ld      a, 1            ; Return value - Permit rock to move

        ret

.CannotMoveRight:
        res     4, (iy+S_SPRITE_TYPE.SpriteType1); Reset rock moving flag
        ld      a, 0
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Reset rock movement flag

        ld      a, 0            ; Return value - Don't permit rock to move

        ret

;-------------------------------------------------------------------------------------
; Check Tiles to left of rock
; Parameters:
; iy = Sprite
; ix = Sprite attributes
; Return Values:
; a=1 - Can move, a=0 - Cannot move
CheckTilesToLeftRock:
; 1. Calculate Tile Column (using x position)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)

; 2. Check whether we are directly to the right of a new tile
        call    CheckDivisableBy8

        cp      a, 1
        jr      nz, .ContLeft                   ; Jump if player x not divisable

        add     de, -8                          ; Otherwise change starting position

.ContLeft
        push    de                              ; Backup x position

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

; 5. Check tiles to Left of sprite
        pop     de                              ; Restore x position

        call    CheckDivisableBy8
        
        cp      1
        jr      z, .Divisable                   ; Jump if rock directly to left of tile

        ld      a, 1                            ; Otherwise continue moving rock
        ret

.Divisable:
; Check whether we're at a divisable by 16 tile to either start moving or end moving         
        add     de, 8
        call    CheckDivisableBy16
        cp      0
        jr      z, .ContDivisable               ; Jump if not divisable by 16

        bit     4, (iy+S_SPRITE_TYPE.SpriteType1); Check whether rock is moving
        jp      nz, .CannotMoveLeft            ; Jump if rock moving i.e. The rock is now at the end location

; Rock at start of move
        set     4, (iy+S_SPRITE_TYPE.SpriteType1); Set rock moving flag
        ld      a, 2
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Set rock movement to left

.ContDivisable:
; Condition 2 - Check whether left screen limit reached
        ld      bc, hl                          ; Backup hl

        ld      hl, (iy+S_SPRITE_TYPE.xPosition)

        or      a                               ; Clear carry flag
        ld      de, (SpriteMaxLeft)
        ex      hl, de
        sbc     hl, de
        jr      nc, .CannotMoveLeft            ; Jump if SpriteMaxLeft >= de

        ld      hl, bc                          ; Restore hl

; 6. Check for stones/earth - Directly in-front        
        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            
        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileStones
        jr      z, .CannotMoveLeft             ; Jump if player hit stone

        cp      TileEarth                       
        jr      z, .CannotMoveLeft             ; Jump if player hit earth

        add     hl, TileMapWidth                ; Point to next tile down

        ld      a, (hl)
        sub     b                               ; Subtract levels tile defintion offset

        cp      TileStones
        jr      z, .CannotMoveLeft              ; Jump if player hit stone
        
        cp      TileEarth                       ; Jump if player hit earth
        jr      z, .CannotMoveLeft

; Clear tiles
; In-front - Top Character
        ld      hl, de                          ; Restore hl

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
        push    hl
        
; Player Left - Top Character        
        inc     hl

        ld      de, TileLPT     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
        ld      (hl), a         ; Place new tile

; Player Left - Bottom Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileLPB     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; Player Right - Top Character        
        pop     hl
        
        inc     hl
        inc     hl
        
        ld      de, TileLPT     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

; Player Right - Bottom Character
        add     hl, TileMapWidth; Point to next tile right

        ld      de, TileLPB     ; Get lookup table
        ld      a, (hl)         ; Get screen character
        sub     b               ; Subtract levels tile defintion offset

        add     de, a           ; Add to lookup table
        ld      a, (de)         ; Get lookup table reference
	add     b               ; Add levels tile defintion offset

        ld      (hl), a         ; Place new tile

        ld      a, 1            ; Return value - Permit rock to move

        ret

.CannotMoveLeft:
        res     4, (iy+S_SPRITE_TYPE.SpriteType1); Reset rock moving flag
        ld      a, 0
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Reset rock movement flag

        ld      a, 0            ; Return value - Don't permit rock to move

        ret

;-------------------------------------------------------------------------------------
; Check Rock Collision
; ix - Sprite data
CheckRockForCollision:
; Clear movement restriction flag
        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.SprContactSide), a

; Check rock to player
        ld      iy, PlayerSprite

        push    ix, iy
        call    CheckCollision                  ; Check collision between sprites
        pop     iy, ix

; Check rock to enemy/rocks
        ld      iy, EnemySpritesStart
        ld      a, BombAttStart-EnemyAttStart   ; Number of sprite entries to search through
        ld      b, a

.FindActiveRockSprite:
        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        cp      (iy+S_SPRITE_TYPE.SpriteNumber)
        jr      z, .NextSprite                  ; Jump if source and target are the same

        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .NextSprite                  ; Jump if sprite not active

        push    bc, ix, iy
        call    CheckCollision                  ; Check collision between sprites
        pop     iy, ix, bc

.NextSprite
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Point to next sprite
        djnz    .FindActiveRockSprite

        ret


