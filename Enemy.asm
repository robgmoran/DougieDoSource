;-------------------------------------------------------------------------------------
; Setup EnemyType in preparation for spawning
; Parameters:
SetupEnemyTypes:
        ld      ix, (LevelEnemyTypeData); Source - Point to Level EnemyData

        ld      b, (ix)                 ; Source - Obtain number of EnemyTypes within level
        inc     ix                      ; Source - Increment to destination EnemyType

.LoopEnemyTypes:        
        ld      hl, (ix)                ; Source - Obtain destination EnemyType

        push    hl                      ; Save EnemyType reference - Start location

        ld      iy, hl
        inc     ix
        inc     ix                      ; Source - Increment to Start of EnemyType data
        inc     iy
        inc     iy                      ; Destination - Increment to start of EnemyType

        push    bc
        
        ld      b, S_ENEMY_TYPE-2      ; Obtain number of values to copy minus intial word

.LoopEnemyData:
        ld      a, (ix)
        ld      (iy), a
        
        inc     ix
        inc     iy
        
        djnz    .LoopEnemyData

        pop     bc

; Update enemy speed based on number of game loops completed i.e. Increase enemy movement speed by 1 per game loop
        pop     hl                      ; Restore EnemyType reference - Start location

        push    iy                      ; Save EnemyType reference - Current location

        ld      iy, hl

        ld      a, (GameLoops)
        ld      d, a

        ld      a, (iy+S_ENEMY_TYPE.EnemySpeed)
        cp      99
        jr      nz, .IncreaseSpeed              ; Jump if default enemy is not 99 i.e. Increase speed per game loop

        ld      a, 1                            ; Otherwise just set enemy speed to 1 i.e. Don't increase per game loop
        ld      (iy+S_ENEMY_TYPE.EnemySpeed), a
        jr      .Continue

.IncreaseSpeed:
        add     d                       ; Add game loops to enemy speed 
        ld      (iy+S_ENEMY_TYPE.EnemySpeed), a
        
.Continue:
        pop     iy                      ; Restore EnemyType refernce - Current location
        djnz    .LoopEnemyTypes

        ret

;-------------------------------------------------------------------------------------
; Enemy Spawner
; Parameters:
EnemySpawner:
        ld      ix, (LevelEnemyTypeData);EnemyDataLevel1     ; Point to Level EnemyData

        ld      b, (ix)                 ; Source - Obtain number of EnemyTypes within level
        inc     ix                      ; Source - Increment to destination EnemyType

.LoopEnemyTypes:        
        ld      hl, (ix)                ; Source - Obtain destination EnemyType
        ld      iy, hl
        
        push    bc, ix

        ld      hl, (iy+S_ENEMY_TYPE.EnemySpawnCounter)
        ld      de, 0
        xor     a
        sbc     hl, de
        jr      z, .SpawnEnemy          ; Call routine if counter at zero

        dec     hl                      ; Otherwise decrement counter
        ld      (iy+S_ENEMY_TYPE.EnemySpawnCounter), hl
        
        jr      .Continue

.SpawnEnemy:
        call    SpawnEnemy

        ld      hl, (iy+S_ENEMY_TYPE.EnemySpawnInterval)
        ld      (iy+S_ENEMY_TYPE.EnemySpawnCounter), hl

.Continue:
        pop     ix, bc

        ld      hl, ix
        ld      a, S_ENEMY_TYPE
        add     hl, a
        ld      ix, hl                  ; Source - Point to next EnemyType
        
        djnz    .LoopEnemyTypes

        ret

;-------------------------------------------------------------------------------------
; Enemy Movement
; Parameters:
; iy = Enemy sprite
MoveEnemy:
; Obtain EnemyType associated with sprite
        ld      hl, (iy+S_SPRITE_TYPE.EnemyType)
        ld      ix, hl                                  

; Check/Update enemy state
        call    UpdateEnemyState

; Check whether enemy can be moved based on movement delay
        ld      a, (iy+S_SPRITE_TYPE.MovementDelay)
        cp      0
        jr      nz, .ContinueMove                        ; Jump if movement counter is not zero and allow enemy to be moved

        ld      a, (ix+S_ENEMY_TYPE.EnemySpeed)
        ld      (iy+S_SPRITE_TYPE.MovementDelay), a     ; Otherwise reset enemy movement delay counter and don't move

        ret

.ContinueMove:
        dec     a
        ld      (iy+S_SPRITE_TYPE.MovementDelay), a     ; Decrement move counter and continue to move

; Check whether enemy at tile start and obtain tilemap position
        call    GetEnemyTilexy                  
        cp      0
        jp      z, .Move                                ; Jump if enemy not at tile start

; Enemy at tile start - Get valid junctions
        call    GetEnemyTileMapPosition                 
        call    GetEnemyJunctionOptions

; Check enemy state
        bit     1, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      z, .NonFFMovement               ; Jump if enemy set to flee i.e. Don't perform FF movement

; Check whether enemy within FF range of player
        ld      a, (EnemyTileColumn)
        ld      d, a
        ld      a, (EnemyTileRow)
        ld      e, a
        call    GetFFPosition                   

        ld      ix, FFStorage
        add     ix, de
        ld      a, (ix)                 ; Get current FF tile value

        cp      99                       
        jr      z, .NonFFMovement       ; Jump if not within FF player range i.e. FF tile returned is 99

; Enemy within FF player range - Check junctions
        ld      b, a                    ; Save current FF tile value
        ld      c, 0                    ; By default set movement value to 0 

.CheckFFUp:
        ld      a, (EnemyTileJunctions)
        bit     3, a                    ; Test up junction
        jr      z, .CheckFFRight        ; Jump if no up junction

        ld      a, (ix-TileMapWidth/2)
        cp      b
        jr      nc, .CheckFFRight       ; Jump if current FF tile <= new FF tile value

        ld      b, a                    ; Otherwise update current FF tile value
        ld      c, 8                    ; Store new movement value

.CheckFFRight:
        ld      a, (EnemyTileJunctions)
        bit     0, a                    ; Test right junction
        jr      z, .CheckFFDown         ; Jump if no right junction

        ld      a, (ix+1)
        cp      b
        jr      nc, .CheckFFDown        ; Jump if current FF tile <= new FF tile value

        ld      b, a                    ; Otherwise update current FF tile value
        ld      c, 1                    ; Store new movement value

.CheckFFDown:
        ld      a, (EnemyTileJunctions)
        bit     2, a                    ; Test down junction
        jr      z, .CheckFFLeft         ; Jump if no down junction

        ld      a, (ix+TileMapWidth/2)
        cp      b
        jr      nc, .CheckFFLeft        ; Jump if current FF tile <= new FF tile value

        ld      b, a                    ; Otherwise update current FF tile value
        ld      c, 4                    ; Store new movement value

.CheckFFLeft:
        ld      a, (EnemyTileJunctions)
        bit     1, a                    ; Test left junction
        jr      z, .UpdateMovement      ; Jump if no left junction

        ld      a, (ix-1)
        cp      b
        jr      nc, .UpdateMovement     ; Jump if current FF tile <= new FF tile value

        ld      c, 2                    ; Store new movement value

.UpdateMovement:
        ld      a, c
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Store updated movement value

        jr      .Move
        
.NonFFMovement:
; Calculate enemy movement based on player and enemy positions
        ld      ix, PlayerSprite
        call    Movement

.CheckDirection:
; Check whether enemy can continue to move in current direction
        ld      a, (iy+S_SPRITE_TYPE.Movement)          ; Get current direction (UDLR)
        ld      hl, EnemyTileJunctions                  ; Get possible junctions (UDLR)
        and     (hl)                                    ; Determine whether enemy can continue to move in current direction

        cp      0
        jr      z, .ReverseDirection                    ; Jump if enemy needs to reverse direction

.Move:
; Point to enemy sprite attribute data
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Destination - Sprite Attributes

; Move enemy in current direction
        bit     3, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .MoveUp

        bit     2, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .MoveDown

        bit     1, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .MoveLeft

        bit     0, (iy+S_SPRITE_TYPE.Movement)
        jp      nz, .MoveRight

        ret

.ReverseDirection
        ld      a, (iy+S_SPRITE_TYPE.Movement)          ; Get current direction (UDLR)

        ld      hl, EnemyReverseJunction                ; Get junction table
        add     hl, a
        
        ld      a, (hl)         
        ld      (iy+S_SPRITE_TYPE.Movement), a         ; Store new direction

        ret

.MoveUp:
; Update y value and sprite attributes
        ld      a, (ix+S_SPRITE_ATTR.y)

        bit     4, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .StdUpSpeed                    ; Jump if not set to double speed
        dec     a
.StdUpSpeed:
        dec     a				; Decrease y position
        ld      (ix+S_SPRITE_ATTR.y), a
        ld      (iy+S_SPRITE_TYPE.yPosition), a ; Store 8-bit value

; Change animation
        ld      bc, (iy+S_SPRITE_TYPE.animationVer)
        call    UpdateSpritePattern             ; Update animation

        ret

.MoveDown:
; Condition 1 - Check whether enemy is permitted to move down
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     2, a
        jr      z, .ContDown                    ; Jump if we're not restricted

; Rock below, so reverse enemy
        ld      hl, 0
        ld      (iy+S_SPRITE_TYPE.FindFleeDelay), hl

        ld      hl, (iy+S_SPRITE_TYPE.EnemyType)
        ld      ix, hl

        call    .ReverseDirection

        jp      UpdateEnemyState

.ContDown:
; Update y value and sprite attributes
        ld      a, (ix+S_SPRITE_ATTR.y)

        bit     4, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .StdDownSpeed                    ; Jump if not set to double speed
        inc     a
.StdDownSpeed:
        inc     a				; Increase y position
        ld      (ix+S_SPRITE_ATTR.y), a
        ld      (iy+S_SPRITE_TYPE.yPosition), a ; Store 8-bit value

; Change animation
        ld      bc, (iy+S_SPRITE_TYPE.animationVer)
        call    UpdateSpritePattern             ; Update animation

        ret

.MoveLeft:
; Choose new direction
        set     3, (ix+S_SPRITE_ATTR.mrx8)      ; Left - Horizontally mirror sprite

; Change animation
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern             ; Update animation

; Obtain 9-bit x value
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        and     %00000001
        ld      h, a
        ld      l, (ix+S_SPRITE_ATTR.x)         ; hl = 9-bit x value
        
; Condition 1 - Check whether enemy is permitted to move left
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     1, a
        jr      z, .ContLeft                    ; Jump if we're not restricted

; Rock hit - Check whether the rock and thus the enemy can move to the Left
        push    hl, ix, iy
        
        ld      hl, (iy+S_SPRITE_TYPE.SprCollision)     ; Obtain rock sprite location
        ld      iy, hl
        
        ;bit     4, (iy+S_SPRITE_TYPE.SpriteType1)
        ;call    z, MoveRockLeft                ; Call if rock not moving; Return - a
        call    MoveRockLeft

        pop     iy, ix, hl

        cp      1
        jr      z, .ContLeft                    ; Jump if rock can be moved

; Rock cannot be moved, so reverse enemy
        ld      hl, 0
        ld      (iy+S_SPRITE_TYPE.FindFleeDelay), hl

        ld      hl, (iy+S_SPRITE_TYPE.EnemyType)
        ld      ix, hl

        call    .ReverseDirection

        jp      UpdateEnemyState

.ContLeft:
; Update x value
        ;ld      hl, bc 				; Restore x position
        bit     4, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .StdLeftSpeed                    ; Jump if not set to double speed
        dec     hl
.StdLeftSpeed:
        dec     hl				; Decrease x position

        ld      (ix+S_SPRITE_ATTR.x), l         ; Store bits 0-8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl; Store 9-bit value

        or      a                               ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .LeftSetmrx8                ; Setmrx8 if hl >=256

; Update sprite attributes
        res     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9

	ret

.LeftSetmrx8
; Update sprite attributes
        set     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9

        ret

.MoveRight:
; Choose new direction
        res     3, (ix+S_SPRITE_ATTR.mrx8)      ; Right - Don't horizontally mirror sprite

; Change animation
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern             ; Update animation

; Obtain 9-bit x value
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        and     %00000001
        ld      h, a
        ld      l, (ix+S_SPRITE_ATTR.x)         ; hl = 9-bit x value
       
; Condition 1 - Check whether the enemy is permitted to move right
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     0, a
        jr      z, .ContRight                   ; Jump if we're not restricted

; Rock hit - Check whether the rock can move to the right
        push    hl, ix, iy
        ld      hl, (iy+S_SPRITE_TYPE.SprCollision); Obtain rock sprite location
        ld      iy, hl
        
        ;bit     4, (iy+S_SPRITE_TYPE.SpriteType1)
        ;call    z, MoveRockRight                ; Call if rock not moving; Return - a
        call    MoveRockRight

        pop     iy, ix, hl

        cp      1
        jp      z, .ContRight                    ; Jump if rock can be moved

; Rock cannot be moved, so reverse enemy
        ld      hl, 0
        ld      (iy+S_SPRITE_TYPE.FindFleeDelay), hl

        ld      hl, (iy+S_SPRITE_TYPE.EnemyType)
        ld      ix, hl

        call    .ReverseDirection

        jp      UpdateEnemyState

.ContRight:
; Update x value
        bit     4, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .StdRightSpeed                    ; Jump if not set to double speed
        inc     hl
.StdRightSpeed:
        inc     hl				; Increase x position

        ld      (ix+S_SPRITE_ATTR.x), l         ; Store bits 0-8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl; Store 9-bit value

        or      a                               ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .RightSetmrx8               ; Setmrx8 if hl >=256

; Update sprite attributes
        res     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9

	ret

.RightSetmrx8
; Update sprite attributes
        set     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9

        ret

;-------------------------------------------------------------------------------------
; Move Enemy AI
; Parameters:
; iy = Enemy sprite
; ix = Player sprite
Movement:
        xor     a
        ld      hl, (ix+S_SPRITE_TYPE.xPosition)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        sbc     hl, de
        jr      nc, .TryMoveRight               ; Jump if Player x position(hl) > Enemy x position (bc)

; Player to left of enemy - Check junctions
.TryMoveLeft:
; Check FindFlee flag and override movement as appropriate i.e. reverse
        bit     1, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      z, .RightOverride

.LeftOverride:
        ld      a, (iy+S_SPRITE_TYPE.Movement)
        bit     0, a
        jr      nz, .MoveBasedOnY             ; Jump if moving right i.e. Don't want enemy to reverse direction

        ld      a, (EnemyTileJunctions)
        bit     1, a
        jr      nz, .UseLeftJunction          ; Jump if enemy can use left junction - Left junction

        ld      a, (iy+S_SPRITE_TYPE.Movement)
        bit     1, a
        jr      nz, .MoveBasedOnY             ; Jump if moving left, but no left junction i.e. Don't want enemy to reverse direction

        jr      .MoveBasedOnY

.UseLeftJunction:
        ld      (iy+S_SPRITE_TYPE.Movement), 2  ; Otherwise change direction to left
        ret                          

; Player to right of enemy - Check junctions
.TryMoveRight:
; Check FindFlee flag and override movement as appropriate i.e. reverse
        bit     1, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      z, .LeftOverride

.RightOverride:
        ld      a, (iy+S_SPRITE_TYPE.Movement)
        bit     1, a
        jr      nz, .MoveBasedOnY             ; Jump if moving left i.e. Don't want enemy to reverse direction

        ld      a, (EnemyTileJunctions)
        bit     0, a
        jr      nz, .UseRightJunction                ; Jump if enemy can use right junction - Right junction

        ld      a, (iy+S_SPRITE_TYPE.Movement)
        bit     0, a
        jr      nz, .MoveBasedOnY             ; Jump if moving right, but no right junction i.e. Don't want enemy to reverse direction

        jr      .MoveBasedOnY

.UseRightJunction:
        ld      (iy+S_SPRITE_TYPE.Movement), 1  ; Otherwise change direction to right
        ret                           

; Compare player and enemy y positions
.MoveBasedOnY:
        ld      a, (iy+S_SPRITE_TYPE.yPosition)
        ld      b, (ix+S_SPRITE_TYPE.yPosition)
        cp      b
        jr      c, .TryMoveDown                 ; Jump if player is below enemy 

; Player above enemy - Check junctions
.TryMoveUp:
; Check FindFlee flag and override movement as appropriate i.e. reverse
        bit     1, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      z, .DownOverride

.UpOverride:
        ld      a, (iy+S_SPRITE_TYPE.Movement)
        bit     2, a
        ret     nz             ; Jump if moving down i.e. Don't want enemy to reverse direction

        ld      a, (EnemyTileJunctions)
        bit     3, a
        jr      nz, .UseUpJunction              ; Jump if enemy can use up junction - Up junction

        ld      a, (iy+S_SPRITE_TYPE.Movement)
        bit     3, a
        ret      nz             ; Jump if moving up, but no up junction i.e. Don't want enemy to reverse direction

        ret

.UseUpJunction:
        ld      (iy+S_SPRITE_TYPE.Movement), 8  ; Otherwise change direction to up
        ret                           

; Player below enemy - Check junctions
.TryMoveDown:
; Check FindFlee flag and override movement as appropriate i.e. reverse
        bit     1, (iy+S_SPRITE_TYPE.SpriteType1)

        jr      z, .UpOverride

.DownOverride:
        ld      a, (iy+S_SPRITE_TYPE.Movement)
        bit     3, a
        ret     nz             ; Jump if moving up i.e. Don't want enemy to reverse direction

        ld      a, (EnemyTileJunctions)
        bit     2, a
        jr      nz, .UseDownJunction              ; Jump if enemy can use down junction - Down junction

        ld      a, (iy+S_SPRITE_TYPE.Movement)
        bit     2, a
        ret      nz             ; Jump if moving down, but no dowm junction i.e. Don't want enemy to reverse direction

        ret

.UseDownJunction:
        ld      (iy+S_SPRITE_TYPE.Movement), 4  ; Otherwise change direction to down
        ret                           

        ret

;-------------------------------------------------------------------------------------
; Get Enemy x, y tilemap coordinates
; Enemy needs to be at both x and y tilemap coordinates divisable by 2 i.e. start of tile
; Parameters:
; iy = Enemy sprite
; Return Values:
; a = 0 - Enemy not at start of tile, 1 - Enemy at start of tile
; de = Enemy tile column (d), tile row (e)
GetEnemyTilexy:
; 1. Check whether enemy x position is divisable by 16
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        ld      a, e
        and     %00001111                       ; Check lower 4 bits 
        cp      0
        jr      nz, .PositionNotDivisable       ; Jump if x position not divisable by 16

; 2. Calculate Tile Column (using x position)
        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

        ld      a, e
        ld      (EnemyTileColumn), a            ; Store valid x coordinate

; 3. Check whether enemy y position is divisable by 16
        ld      a, (TileMapOffsetY)
        ld      b, a
        ld      a, (iy+S_SPRITE_TYPE.yPosition)
        add     a, b

        ld      d, 0
        ld      e, a

        and     %00001111                       ; Check lower 4 bits 
        cp      0
        jr      nz, .PositionNotDivisable       ; Jump if y position not divisable by 16

        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right
        
        ld      a, e
        ld      (EnemyTileRow), a               ; Store valid y coordinate

        ld      a, 1                            ; Indicate enemy at tile start

        ld      de, (EnemyTileRow)
        
        ret

.PositionNotDivisable:
        ld      a, 0                            ; Indicate enemy not at tile start

        ret

;-------------------------------------------------------------------------------------
; Get tilemap position based on tilemap coordinates; top left tile beneath enemy
; Parameters:
; de = x, y tilemap coordinates; not sprite x, y coordinates
; Return Values:
; hl = Enemy TilePosition
GetEnemyTileMapPosition:
        ld      c, d            ; Obtain column (x)
        
        ld      d, TileMapWidth ; Tilemap width 
        mul     d, e            ; Calculate tile row offset = Tilemap width (d)  * Number of Rows (e)

        ld      a, c            ; Restore tile column
        add     de, a           ; Add tile column to tile row offset 

        ld      hl, TileMapLocation
        add     hl, de
        ld      (EnemyTileOffset), hl

        ret

;-------------------------------------------------------------------------------------
; Get enemy junction options 
; Parameters:
GetEnemyJunctionOptions:
        ld      a, 0
        ld      (EnemyTileJunctions), a ; Assume no junctions
        
; Check Up direction        
        ld      ix, (EnemyTileOffset)
        ld      de, FFUPL
        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            
        ld      a, (ix)                 ; Get tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        cp      1
        jr      nz, .CheckRight          ; Jump if doesn't permit Up direction

; Node Above - Is it valid i.e. Is it a full tile that has been entered or a invalid half tile?
        ld      hl, ix
        ld      de, TileMapWidth        
        sub     hl, de                  ; Move up two lines
        ld      ix, hl

        ld      de, FFUPL
        ld      a, (ix)                 ; Get left source tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference
        ld      c, a
                
        ld      de, FFUPR
        ld      a, (ix+1)               ; Get right source tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        and     c
        cp      1
        jr      nz, .CheckRight          ; Jump if doesn't permit Up direction

        ld      a, (EnemyTileJunctions)
        set     3, a                    ; Otherwise enable Up direction
        ld      (EnemyTileJunctions), a

.CheckRight:
        ld      ix, (EnemyTileOffset)
        inc     ix                      ; Move right one column

        ld      de, FFRPT
        ld      a, (ix)                 ; Get tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        cp      1
        jr      nz, .CheckDown          ; Jump if doesn't permit Right Direction

; Node to Right - Is it valid i.e. Is it a full tile that has been entered or a invalid half tile?
        inc     ix                      ; Move right one column

        ld      de, FFRPT
        ld      a, (ix)                 ; Get top source tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference
        ld      c, a
                
        ld      hl, ix
        ld      de, TileMapWidth
        add     hl, de                  ; Move down one line
        ld      ix, hl

        ld      de, FFRPB
        ld      a, (ix)                 ; Get bottom source tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        and     c
        cp      1
        jr      nz, .CheckDown         ; Jump if doesn't permit Right direction

        ld      a, (EnemyTileJunctions)
        set     0, a                    ; Otherwise enable Right direction
        ld      (EnemyTileJunctions), a

.CheckDown:
        ld      hl, (EnemyTileOffset)
        ld      de, TileMapWidth        
        add     hl, de                  ; Move down one line
        ld      ix, hl
        
        ld      de, FFDPL
        ld      a, (ix)                 ; Get tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        cp      1
        jr     nz, .CheckLeft           ; Jump if doesn't permit Down direction

; Node Below - Is it valid i.e. Is it a full tile that has been entered or a invalid half tile?
        ld      hl, ix
        ld      de, TileMapWidth        
        add     hl, de                  ; Source - Move down one line
        ld      ix, hl

        ld      de, FFDPL
        ld      a, (ix)                 ; Get left source tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference
        ld      c, a
                
        ld      de, FFDPR
        ld      a, (ix+1)               ; Get right source tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        and     c
        cp      1
        jr      nz, .CheckLeft          ; Jump if doesn't permit Up direction

        ld      a, (EnemyTileJunctions)
        set     2, a                    ; Otherwise enable Down direction
        ld      (EnemyTileJunctions), a

.CheckLeft:
        ld      ix, (EnemyTileOffset)

        ld      de, FFLPT
        ld      a, (ix)                 ; Get tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        cp      1
        ret     nz                      ; Return if doesn't permit Left Direction

; Node to Left - Is it valid i.e. Is it a full tile that has been entered or a invalid half tile?
        dec     ix                      ; Move left one byte

        ld      de, FFLPT
        ld      a, (ix)                 ; Get top source tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference
        ld      c, a
                
        ld      hl, ix
        ld      de, TileMapWidth
        add     hl, de                  ; Move down one line
        ld      ix, hl

        ld      de, FFLPB
        ld      a, (ix)                 ; Get bottom source tile
        sub     b                       ; Subtract levels tile defintion offset

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        and     c
        cp      1
        ret     nz                      ; Return if doesn't permit Left direction

        ld      a, (EnemyTileJunctions)
        set     1, a                    ; Otherwise enable Left direction
        ld      (EnemyTileJunctions), a

        ret

;-------------------------------------------------------------------------------------
; Update enemy state 
; Parameters:
; ix = Enemy Sprite
; iy = EnemyType
UpdateEnemyState:
        ld      hl, (iy+S_SPRITE_TYPE.FindFleeDelay)
        ld      de, 0
        xor     a
        sbc     hl, de
        jr      z, .ToggleState                         ; Jump if enemy counter is 0 and change enemy state

        ld      hl, (iy+S_SPRITE_TYPE.FindFleeDelay)
        dec     hl                                      ; Otherwise decrement counter and don't change enemy state
        ld      (iy+S_SPRITE_TYPE.FindFleeDelay), hl
        
        ret

.ToggleState:        
        bit     1, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .ChangeToFlee

        ld      hl, (ix+S_ENEMY_TYPE.EnemyFindTimer);(EnemyFindTimer)
        ld      (iy+S_SPRITE_TYPE.FindFleeDelay), hl    ; Reset enemy counter to find time
        
        set     1, (iy+S_SPRITE_TYPE.SpriteType1)        ; Change enemy state to find

        ret

.ChangeToFlee:
        ld      hl, (ix+S_ENEMY_TYPE.EnemyFleeTimer) ;(EnemyFleeTimer)
        ld      (iy+S_SPRITE_TYPE.FindFleeDelay), hl    ; Reset enemy counter to flee time
        
        res     1, (iy+S_SPRITE_TYPE.SpriteType1)        ; Change enemy state to flee

        ret

;-------------------------------------------------------------------------------------
; Check Enemy to Rock/Bomb Collision
; ix - Sprite data
; Return Values:
; a = 0 - Don't delete source sprite, 1 - Delete source sprite
CheckEnemyForCollision:
; Clear movement restriction flag
        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.SprContactSide), a

        ld      iy, RockSprites                 ; Start at RockSprites and run through BombSprites
        ld      a, DiamondAttStart-RockAttStart;64-RockAttStart              ; Number of sprite entries to search through
        ld      b, a
.FindActiveSprite:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .NextSprite                  ; Jump if sprite not active

        push    bc, ix, iy
        call    CheckCollision                  ; Check collision between sprites; return - a
        pop     iy, ix, bc

        cp      0
        jr      z, .NextSprite                  ; Jump if not deleting enemy

        ld      iy, ix
        call    DeleteSprite                    ; Otherwise delete sprite

        push    af, bc, de, hl, ix
        ld      a, AyFXEnemyDead
        call    AFXPlay       
        pop     ix, hl, de, bc, af

        ld      a, 1                            ; Return with a = 1 i.e. Enemy deleted
        ret

.NextSprite:
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Point to next sprite
        djnz    .FindActiveSprite

        ld      a, 0                            ; Don't delete source sprite

        ret

;-------------------------------------------------------------------------------------
; Enemy digs toward player
; Parameters:
; iy = Enemy sprite
EnemyDig:
; Obtain EnemyType associated with sprite
        ld      hl, (iy+S_SPRITE_TYPE.EnemyType)
        ld      ix, hl                                  

; Check whether enemy can be moved based on movement delay
        ld      a, (iy+S_SPRITE_TYPE.MovementDelay)
        cp      0
        jr      nz, .CheckFlee                          ; Jump if movement counter is not zero and allow enemy to be moved

        ld      a, (ix+S_ENEMY_TYPE.EnemySpeed)
        ld      (iy+S_SPRITE_TYPE.MovementDelay), a     ; Otherwise reset enemy movement delay counter and don't move

        ret

.CheckFlee:
        dec     a
        ld      (iy+S_SPRITE_TYPE.MovementDelay), a     ; Decrement move counter and continue to move

; Following the flee duration countdown the digger will be reset back to track the player        
        bit     1, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .TrackPlayer                        ; Jump if enemy not set to flee - Track player

; Update/re-check flee status
        ld      hl, (iy+S_SPRITE_TYPE.EnemyType)
        ld      ix, hl
        call    UpdateEnemyState

        bit     1, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .TrackPlayer                        ; Jump if enemy now not set to flee - Track player

; Enemy not tracking player
; Move enemy in current direction
        ; Point to enemy sprite attribute data
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Destination - Sprite Attributes
        
        bit     3, (iy+S_SPRITE_TYPE.Movement)
        jp      nz, .CheckEnemyUp

        bit     2, (iy+S_SPRITE_TYPE.Movement)
        jp      nz, .CheckEnemyDown

        bit     1, (iy+S_SPRITE_TYPE.Movement)
        jp      nz, .CheckEnemyLeft

        bit     0, (iy+S_SPRITE_TYPE.Movement)
        jp      nz, .CheckEnemyRight

        ret

; Enemy tracking player
.TrackPlayer:
        bit     3, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .CheckYPosition                      ; Jump if enemy should be tracking via y

.CheckXPosition:
; Check enemy/player x position
        ld      ix, PlayerSprite

        xor     a
        ld      hl, (ix+S_SPRITE_TYPE.xPosition)        ; Get playerx position
        ld      a, l
        and     %11110000                               ; Ensure playerx is always divisable/16
        ld      l, a

        ; Point to enemy sprite attribute data
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Destination - Sprite Attributes

        ld      de, (iy+S_SPRITE_TYPE.xPosition)        ; Get enemyx position

        sbc     hl, de
        jp      z, DiggerChangeDirection                ; Jump if Player x position(hl) = Enemy x position (bc)
        jr      nc, .CheckEnemyRight                    ; Jump if Player x position(hl) > Enemy x position (bc)

        jp      .CheckEnemyLeft                         ; Otherwise try and move left

.CheckYPosition:        
        ld      ix, PlayerSprite
        
        ld      b, (ix+S_SPRITE_TYPE.yPosition)         ; Get playery position
        ld      a, b
        and     %11110000                               ; Ensure playery is always divisable/16
        ld      b, a

        ; Point to enemy sprite attribute data
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Destination - Sprite Attributes

        ld      a, (iy+S_SPRITE_TYPE.yPosition)         ; Get enemyy position

        cp      b
        jp      z, DiggerChangeDirection
        jp      c, .CheckEnemyDown                      ; Jump if player is below enemy 
        jp      .CheckEnemyUp

.CheckEnemyRight:
; If already travelling left/right - Permit right travel
        ld      a, %00000011
        cp      (iy+S_SPRITE_TYPE.Movement)
        jr      nc, .ContinueRight

; Not travelling left/right, so check whether we can now move right 
        ld      de, (iy+S_SPRITE_TYPE.yPosition)
        call    CheckDivisableBy16

        cp      1
        jr      z, .ContinueRight                       ; Jump if divisable

; Not at correct position, so continue travelling in current direction
        ld      a, 8
        cp      (iy+S_SPRITE_TYPE.Movement)
        jp      z, .ContinueUp

        jp      .ContinueDown

.ContinueRight:
; Obtain 9-bit x value
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        and     %00000001
        ld      h, a
        ld      l, (ix+S_SPRITE_ATTR.x)                 ; hl = 9-bit x value
        ld      de, hl
        
; Condition 1 - Check whether the enemy hit a rock and is restricted from moving right
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     0, a
        jr      z, .ContRight                           ; Jump if we're not restricted

; Rock hit - Check whether the rock and thus the enemy can move to the right
        push    ix, iy, hl
        ld      hl, (iy+S_SPRITE_TYPE.SprCollision)     ; Obtain rock sprite location
        ld      iy, hl
        
        ld      a, 0                                    ; Reset register in case MoveRockRight not called
        bit     4, (iy+S_SPRITE_TYPE.SpriteType1)
        call    z, MoveRockRight                        ; Call if rock not moving

        pop     hl, iy, ix                              
        ld      de, hl                                  ; Save position

        cp      1
        jr      z, .ContRight                           ; Jump if rock moved and enemy can also move

        call    DiggerPickNewXDirection
        call    DiggerFlee
        call    DiggerChangeDirection

        ret

.ContRight:
; Condition 2 - Check whether right screen limit reached
        or      a                                       ; Clear carry flag
        ld      bc, (SpriteMaxRight)
        sbc     hl, bc
        jp      nc, DiggerPickNewXDirection             ; Jump if hl >= SpriteMaxRight

; Condition 3 - Check tile collision
        push    de
        call    CheckTilesToRight                       ; Output - a=0 Don't move, a=1 Move
        pop     de

        cp      1
        jp      z, .TileRightPassed                     ; Jump if tile passed
        
        ld      a, (EnemyDiggerChangeDir)
        cp      0
        ret     z                                       ; Return if enemy needs to wait

        call    DiggerPickNewXDirection
        call    DiggerFlee
        call    DiggerChangeDirection

        ret

.TileRightPassed:
; OK to move - Update x value and sprite attributes
        ld      (iy+S_SPRITE_TYPE.Movement), 1          ; Set player movement flag to right

        ex      hl, de

        bit     4, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .StdRightSpeed                       ; Jump if not set to double speed

        inc     hl
.StdRightSpeed:
        inc     hl				        ; Increase x position

        ld      (ix+S_SPRITE_ATTR.x), l                 ; Store bits 0-8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl        ; Store 9-bit value

        or      a                                       ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .RightSetmrx8                       ; Setmrx8 if hl >=256

        ; Update sprite attributes
        res     0, (ix+S_SPRITE_ATTR.mrx8)              ; Store bit 9
        res     3, (ix+S_SPRITE_ATTR.mrx8)              ; Don't horizontally mirror sprite
        
.RightUpdateAnimation:
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern                     ; Update animation
        
        ret

.RightSetmrx8
        ; Update sprite attributes
        set     0, (ix+S_SPRITE_ATTR.mrx8)              ; Store bit 9
        res     3, (ix+S_SPRITE_ATTR.mrx8)              ; Don't horizontally mirror sprite

        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern                     ; Update animation

        ret

.CheckEnemyLeft:
; If already travelling left/right - Permit left travel
        ld      a, %00000011
        cp      (iy+S_SPRITE_TYPE.Movement)
        jr      nc, .ContinueLeft

; Not travelling left/right, so check whether we can now move left 
        ld      de, (iy+S_SPRITE_TYPE.yPosition)
        call    CheckDivisableBy16

        cp      1
        jr      z, .ContinueLeft                        ; Jump if divisable

; Not at correct position, so continue travelling in current direction
        ld      a, 8
        cp      (iy+S_SPRITE_TYPE.Movement)
        jp      z, .ContinueUp

        jp      .ContinueDown

.ContinueLeft
; Obtain 9-bit x value
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        and     %00000001
        ld      h, a
        ld      l, (ix+S_SPRITE_ATTR.x)                 ; hl = 9-bit x value
        
; Condition 1 - Check whether the enemy hit a rock and is restricted from moving left
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     1, a
        jr      z, .ContLeft                            ; Jump if we're not restricted

; Rock hit - Check whether the rock and thus the enemy can move to the Left
        push    ix, iy, hl
        
        ld      hl, (iy+S_SPRITE_TYPE.SprCollision)     ; Obtain rock sprite location
        ld      iy, hl
        
        ld      a, 0                                    ; Reset register in case MoveRockLeft not called
        bit     4, (iy+S_SPRITE_TYPE.SpriteType1)
        call    z, MoveRockLeft                         ; Call if rock not moving

        pop     hl, iy, ix
        
        cp      1
        jr      z, .ContLeft                            ; Jump if rock moved and enemy can also move

        call    DiggerPickNewXDirection
        call    DiggerFlee
        call    DiggerChangeDirection

        ret

.ContLeft:
; Condition 2 - Check whether left screen limit reached
        or      a                                       ; Clear carry flag
        ld      de, (SpriteMaxLeft)
        ex      hl, de
        sbc     hl, de
        jp      nc, DiggerPickNewXDirection             ; Jump if SpriteMaxLeft >= de

; Condition 3 - Check tile collision
        push    de
        call    CheckTilesToLeft                        ; Output - a=0 Don't move, a=1 Move
        pop     de
        
        cp      1
        jp      z, .TileLeftPassed                      ; Jump if tile passed

        ld      a, (EnemyDiggerChangeDir)
        cp      0
        ret     z                                       ; Jump if enemy needs to wait

        call    DiggerPickNewXDirection
        call    DiggerFlee
        call    DiggerChangeDirection

        ret

.TileLeftPassed:
; OK to move - Update x value and sprite attributes
        ld      (iy+S_SPRITE_TYPE.Movement), 2          ; Set player movement flag to left

        ex      hl, de
        
        bit     4, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .StdLeftSpeed                       ; Jump if not set to double speed

        dec     hl
.StdLeftSpeed:
        dec     hl				        ; Decrease x position

        ld      (ix+S_SPRITE_ATTR.x), l                 ; Store bits 0-8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl        ; Store 9-bit value

        or      a                                       ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .LeftSetmrx8                        ; Setmrx8 if hl >=256

        ; Update sprite attributes
        res     0, (ix+S_SPRITE_ATTR.mrx8)              ; Store bit 9
        set     3, (ix+S_SPRITE_ATTR.mrx8)              ; Horizontally mirror sprite
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern                     ; Update animation

        ret

.LeftSetmrx8
        ; Update sprite attributes
        set     0, (ix+S_SPRITE_ATTR.mrx8)              ; Store bit 9
        set     3, (ix+S_SPRITE_ATTR.mrx8)              ; Horizontally mirror sprite
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern                     ; Update animation

        ret

.CheckEnemyDown:
; If already travelling up/down - Permit down travel
        bit     2, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .ContinueDown 

        bit     3, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .ContinueDown 

; Not travelling up/down, so check whether we can now move down 
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        call    CheckDivisableBy16

        cp      1
        jr      z, .ContinueDown                        ; Jump if divisable

; Not at correct position, so travel in current direction
        ld      a, 1
        cp      (iy+S_SPRITE_TYPE.Movement)
        jp      z, .ContinueRight

        jp      .ContinueLeft

.ContinueDown
; Condition 1 - Check whether enemy is permitted to move down
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     2, a
        jr      z, .ContDown                            ; Jump if we're not restricted

        call    DiggerPickNewYDirection
        call    DiggerFlee
        call    DiggerChangeDirection
        
        ret

.ContDown:
; Condition 2 - Check whether bottom of screen limit reached
        or      a                                       ; Clear carry flag
        ld      a, (SpriteMaxDown)
        ld      b, a
        ld      a, (ix+S_SPRITE_ATTR.y)

        sbc     a, b
        jp      nc, DiggerPickNewYDirection             ; Jump if a >= SpriteMaxDown

; Condition 3 - Check tile collision
        call    CheckTilesBelow                         ; Output - a=0 Don't move, a=1 Move

        cp      1
        jp      z, .TileBelowPassed                     ; Jump if tile passed

        ld      a, (EnemyDiggerChangeDir)
        cp      0
        ret     z                                       ; Jump if enemy needs to wait

        call    DiggerPickNewYDirection
        call    DiggerFlee
        call    DiggerChangeDirection
        
        ret

.TileBelowPassed:
; OK to move - Update x value and sprite attributes
        ld      (iy+S_SPRITE_TYPE.Movement), 4          ; Set player movement flag to down

        ld      a, (ix+S_SPRITE_ATTR.y)

        bit     4, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .StdDownSpeed                        ; Jump if not set to double speed

        inc     a
.StdDownSpeed:
        inc     a				        ; Increase y position

        ld      (ix+S_SPRITE_ATTR.y), a
        ld      (iy+S_SPRITE_TYPE.yPosition), a         ; Store 8-bit value

.DownUpdateAnimation
        ld      bc, (iy+S_SPRITE_TYPE.animationVer)
        call    UpdateSpritePattern                     ; Update animation

        ret

.CheckEnemyUp:
; If already travelling up/down - Permit up travel
        bit     2, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .ContinueUp 

        bit     3, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .ContinueUp

; Not travelling up/down, so check whether we can now move up
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        call    CheckDivisableBy16

        cp      1
        jr      z, .ContinueUp                          ; Jump if divisable

; Otherwise check movement and jump to appropriate routine
        ld      a, 1
        cp      (iy+S_SPRITE_TYPE.Movement)
        jp      z, .ContinueRight

        jp      .ContinueLeft

.ContinueUp
; Condition 1 - Check whether enemy is permitted to move up
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     3, a
        jr      z, .ContUp                              ; Jump if we're not restricted

        call    DiggerPickNewYDirection
        call    DiggerFlee
        call    DiggerChangeDirection
        
        ret

.ContUp:
; Condition 2 - Check whether top of screen limit reached
        or      a                                       ; Clear carry flag
        ld      a, (SpriteMaxUp)
        ld      b, (ix+S_SPRITE_ATTR.y)

        sbc     a, b
        jp      nc, DiggerPickNewYDirection             ; Jump if SpriteMaxUp >= b

; Condition 3 - Check tile collision
        call    CheckTilesAbove                         ; Output - a=0 Don't move, a=1 Move

        cp      1
        jp      z, .TileAbovePassed                     ; Jump if tile passed

        ld      a, (EnemyDiggerChangeDir)
        cp      0
        ret     z                                       ; Jump if enemy needs to wait

        call    DiggerPickNewYDirection
        call    DiggerFlee
        call    DiggerChangeDirection

        ret

.TileAbovePassed:
; OK to move - Update x value and sprite attributes
        ld      (iy+S_SPRITE_TYPE.Movement), 8          ; Set player movement flag to up

        ld      a, (ix+S_SPRITE_ATTR.y)

        bit     4, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      z, .StdUpSpeed                        ; Jump if not set to double speed

        dec     a
.StdUpSpeed:
        dec     a				        ; Decrease x position

        ld      (ix+S_SPRITE_ATTR.y), a
        ld      (iy+S_SPRITE_TYPE.yPosition), a         ; Store 8-bit value

.UpUpdateAnimation:
        ld      bc, (iy+S_SPRITE_TYPE.animationVer)
        call    UpdateSpritePattern                     ; Update animation

        ret

;-------------------------------------------------------------------------------------
; Change digger axis to track player
; Parameters:
DiggerChangeDirection:
        bit     3, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      nz, .SetToY

        set     3, (iy+S_SPRITE_TYPE.SpriteType2)       ; Set to ensure enemy tries x direction first next time
        ret

.SetToY
        res     3, (iy+S_SPRITE_TYPE.SpriteType2)       ; Set to ensure enemy tries y direction first next time
        ret

;-------------------------------------------------------------------------------------
; Set digger to flee
; Parameters:
DiggerFlee:
; Set enemy to temporarily flee
        ld      hl, (iy+S_SPRITE_TYPE.EnemyType)
        ld      ix, hl
        ld      hl, (ix+S_ENEMY_TYPE.EnemyFleeTimer)
        ld      (iy+S_SPRITE_TYPE.FindFleeDelay), hl    ; Reset enemy counter to flee time
        
        res     1, (iy+S_SPRITE_TYPE.SpriteType1)       ; Set to temporarily flee

        ret


;-------------------------------------------------------------------------------------
; Set new digger x direction 
; Parameters:
DiggerPickNewXDirection:
; Check whether right screen limit reached and set direction as appropriate
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        and     %00000001
        ld      h, a
        ld      l, (ix+S_SPRITE_ATTR.x)         ; hl = 9-bit x value

        or      a                               ; Clear carry flag
        ld      bc, (SpriteMaxRight)
        sbc     hl, bc
        jp      nc, .TurnLeft                   ; Jump if hl >= SpriteMaxRight

        bit     0, (iy+S_SPRITE_TYPE.Movement)  ; Jump if enemy travelling right
        jp      nz, .TurnLeft

        ld      a, 1
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Otherwise switch to right

        ret

.TurnLeft:
        ld      a, 2
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Switch to left

        ret

;-------------------------------------------------------------------------------------
; Set new digger y direction
; Parameters:
DiggerPickNewYDirection:
; Check whether bottom of screen limit reached
        or      a                               ; Clear carry flag
        ld      a, (SpriteMaxDown)
        ld      b, a
        ld      a, (ix+S_SPRITE_ATTR.y)

        sbc     a, b
        jp      nc, .TurnUp        ; Jump if a >= SpriteMaxDown

        bit     2, (iy+S_SPRITE_TYPE.Movement)
        jp      nz, .TurnUp                     ; Jump if enemy travelling down

        ld      a, 4
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Otherwise switch to down

        ret

.TurnUp:
        ld      a, 8
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Switch to up

        ret

;-------------------------------------------------------------------------------------
; Find Maximum number of enemies for level
; Parameters:
; ix - LevelEnemyData
FindEnemyCount:
        ld      b, (ix)                 ; Obtain number of EnemyTypes within level
        inc     ix                      ; Increment to destination EnemyType

        ld      a, 0
        ld      (EnemiesTotal), a       ; Reset enemies total
.LoopEnemyTypes:        
; Check whwether enemy type is static or reaper
        ld      hl, (ix)
        ld      iy, hl
        ld      hl, (iy+S_ENEMY_TYPE.SpriteType)
        ld      iy, hl
        bit     1, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      nz, .NextEnemyType      ; Jump if static enemy type i.e. Don't count in enemy total

        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jr      nz, .NextEnemyType      ; Jump if reaper enemy type i.e. Don't count in enemy total

        ld      a, (EnemiesTotal)

        ld      d, (ix+S_ENEMY_TYPE.EnemyMaxNumber)
        add     d

        ld      (EnemiesTotal), a

.NextEnemyType:
        ld      hl, ix
        ld      a, S_ENEMY_TYPE
        add     hl, a
        ld      ix, hl                  ; Point to next EnemyType
        
        djnz    .LoopEnemyTypes

        ret

