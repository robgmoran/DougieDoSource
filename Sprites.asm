;-------------------------------------------------------------------------------------
; Sprites - Upload Sprite Patterns
; Parameters:
; - d = Memory Bank1 containing  sprites 0 - 63
; - e = Memory Bank2 containing  sprites 64 - 127
; - hl = Address of first byte of sprite patterns
; - ixl = Number of sprite patterns to upload (max - 128 * 4-bit sprites or 64 * 8-bit sprites)
UploadSpritePatterns:
; *** Select starting sprite index/slot 0 ***
;  SPRITE STATUS/SLOT SELECT Register
        ld      bc,$303B
        xor     a
        out     (c),a       ; Select slot 0 for patterns/attributes

SpritesPatterns1:
; *** Map SpritePixelData memory bank 1/2 to slot 6 ($C000..$DFFF)
; MEMORY MANAGEMENT SLOT 6 BANK Register
        ld      a, d
        cp      0       ; Check whether sprite memory bank1 has been specified     
        ret     z
        nextreg $56, a

SpritePatterns2:
; *** Map SpritePixelData+1 memory bank 2/2 to slot 7 ($E000-$Ffff)
; MEMORY MANAGEMENT SLOT 7 BANK Register
        ld      a, e
        cp      0       ; Check whether sprite memory bank2 has been specified     
        jr      z, Upload
        nextreg $57, a

Upload:
; *** Upload sprite pattern data into sprite pattern memory from $C000 via otir opcode below - AUTO-INCREMENTS TO NEXT SPRITE PATTERN SLOT
; SPRITE PATTERN UPLOAD Register
; Note: While uploading sprite pixel data, after sending 256 bytes (1 x sprite pattern) worth of pixels the pattern
; upload slot will auto-increment to point to the next slot and after uploading final "slot 63" data the internal index will wrap around back to "slot 0",
; this will not affect the sprite attribute upload index
        ld      bc,$5B                  ; sprite pattern-upload I/O port, B=0 (inner loop counter), register c only used for import
; Loop for all required sprite patterns
        ld      a,ixl                     ; Number of patterns (outer loop counter), each pattern is 256 bytes long 
UploadSpritePatternsLoop:
        ; upload 256 bytes of pattern data (otir increments HL and decrements B until zero)
        otir                            ; B=0 ahead, so otir will repeat 256x ("dec b" wraps 0 to 255)
        dec     a
        jr      nz, UploadSpritePatternsLoop ; Loop around until all 64 sprite patterns have been uploaded
        ret

;-------------------------------------------------------------------------------------
; Sprites - Configure player sprite values
; Parameters:
; hl = x Position (9-bit)
; b = y Position (8-bit)
SetupPlayerSprite:
; (1) Configure Sprite Data using Sprite Type values
; Player Sprite - Populate Player Sprite Data from Player Sprite Type
        ld      iy, PlayerSprite
        ld      (iy+S_SPRITE_TYPE.active), 1
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), 0

        push    hl, bc

; Player Sprite - Copy remaining sprite type values
        ld      hl, PlayerSprType+S_SPRITE_TYPE.patternRange      ; Source starting with patternCurrent
        ld      de, PlayerSprite+S_SPRITE_TYPE.patternRange    ; Destination starting at patternCurrent
        ld      bc, S_SPRITE_TYPE - S_SPRITE_TYPE.patternRange ; Number of values
        ldir

        pop     bc, hl

        ld      (iy+S_SPRITE_TYPE.xPosition), hl

        ld      a, TileMapSpriteYOffset
        add     a, b
        ld      b, a
        ld      (iy+S_SPRITE_TYPE.yPosition), b                         ; Update sprite position to accomodate tilemap y offset

; (2) Configure Sprite Attributes
; Sprite Attributes - Populate Player Sprite Attributes
        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt
        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      (iy+S_SPRITE_ATTR.y), b                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        ld      a, %0000'0'0'0'0                        ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        or      h                                       ; MSB of the X Position
        ld      (iy+S_SPRITE_ATTR.mrx8), a  

        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

        inc     hl                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        ret

;-------------------------------------------------------------------------------------
; Sprites - Spawn New Sprites
; Parameters:
; ix = Sprite type
; iy = Sprite storage memory address offset
; a = Sprite attribute offset
; hl = x Position (9-bit)
; b = y Position (8-bit)
SpawnNewSprite:
        push    hl, bc
; (1) Find spare sprite slot
        ld      c, a                            ; Sprite count to identify sprite number (used for attributes); offset based on sprite type passed into routine (player sprite is 0)
        ld      b, 64                          ; Number of sprite entries to search through
.FindAvailableSpriteSlot:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .FoundSpriteSlot
        inc     c                               ; Increment sprite count for next sprite number (used for attributes)
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Not found so point to next sprite slot
        djnz    .FindAvailableSpriteSlot

        pop     bc, hl
        ret                                     ; No spare sprite slot found so return

; (2) Configure sprite values
.FoundSpriteSlot:
; Sprite - Populate Sprite Data from Sprite Type
        ld      (iy+S_SPRITE_TYPE.active), 1
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), c

; Sprite - Copy remaining sprite type values
        ld      a, S_SPRITE_TYPE.patternRange
        ld      hl, ix
        add     hl, a                                                   ; Source starting with patternCurrent
        ld      de, iy                                  
        add     de, a                                                   ; Destination starting at patternCurrent
        ld      bc, S_SPRITE_TYPE - S_SPRITE_TYPE.patternRange          ; Number of values
        
        ldir

        pop     bc, hl                                                  ; Restore X, Y coordinates
        ld      (iy+S_SPRITE_TYPE.xPosition), hl

        bit     7, (ix+S_SPRITE_TYPE.SpriteType2)
        jr      nz, .SetYPosition                                       ; Jump if sprite bomb i.e. Don't update y position with TileMap offset

        ld      a, TileMapSpriteYOffset
        add     a, b
        ld      b, a                                                    ; Update sprite y position

.SetYPosition:
        ld      (iy+S_SPRITE_TYPE.yPosition), b                         ; Update sprite position to accomodate tilemap y offset

; Sprite Attributes - Populate Sprite Attributes
        ld      ix, iy                                                  ; Source - Sprite data
        ld      d, S_SPRITE_ATTR
        ld      e, (ix+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                                    ; Calculate sprite attribute offset
        ld      iy, SpriteAtt
        add     iy, de                                                  ; Destination - Sprite Attributes

        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      (iy+S_SPRITE_ATTR.y), b                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        ld      a, %0000'0'0'0'0                        ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        or      h                                       ; MSB of the X Position
        ld      (iy+S_SPRITE_ATTR.mrx8), a  
        

        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

        inc     hl                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern
        
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        ret

;-------------------------------------------------------------------------------------
; Sprites - Upload Multiple Sprite Attributes
; Parameters:
; - a = Number of sprites to upload (max - 128 * 4-bit sprites or 64 * 8-bit sprites)
UploadSpriteAttributes:
        ld      d, a    ; Number of sprites
        ld      e, 5    ; Number of attributes within each sprite 
        mul     d, e    ; Total number of sprite attributes to upload
; Populate sprite attributes
        ld      bc, $303B
        xor     a
        out     (c),a           ; select slot 0 for sprite attributes

; First loop based on register e
        ld      b, e            ; Number of attributes to copy
        ld      hl,SpriteAtt    ; Location containing sprite attributes
        ld      c, $57          ; Sprite pattern-upload I/O port
        otir                    ; Out required number of sprite attributes
    
; Check/second loop based on register d
        ld      a, d
        cp      0
        ret     z               ; Return if no more than 255 attributes

        dec     a               ; Note: 0 will result in a loop of 256
        ld      b, a
        otir                    ; Out required number of sprite attributes
        
        ret

;-------------------------------------------------------------------------------------
; Reset Sprites
; Parameters:
; a = Number of sprites to reset (max - 128 * 4-bit sprites or 64 * 8-bit sprites)
ResetSprites:
; Release Sprite Data slots
        push    af
        ld      ix, Sprites

        ld      b, a
.DisableSpriteLoop:
        ld      (ix+S_SPRITE_TYPE.active), 0    ; Clear active flag
        ld      (ix+S_SPRITE_TYPE.SpriteNumber), 0
        
        ld      de, S_SPRITE_TYPE
        add     ix, de                           ; Point to next sprite

        djnz    .DisableSpriteLoop

; Disable sprite in sprite attribute table
        pop     af
        push    af

        ld      iy, SpriteAtt

        ld      b, a
.DisableAttributeLoop:
        ld      a, (iy+S_SPRITE_ATTR.vpat) 
        ld      a, 0                                    ; Hide sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        ld      de, S_SPRITE_ATTR
        add     iy, de                                  ; Point to next sprite

        djnz    .DisableAttributeLoop
        
; Upload sprite attributes
        pop     af

        call    UploadSpriteAttributes

        ret

;-------------------------------------------------------------------------------------
; Update Sprite Pattern Attribute
; Parameters:
; ix = Sprite Attribute Table Entry
; iy = Sprite Type Table Entry
; bc = Required PatternReference
UpdateSpritePattern:                
; Check whether we are changing the pattern reference
        xor     a
        ld      hl, (iy+S_SPRITE_TYPE.patternRange)
        sbc     hl, bc
        jr      z, .SamePatternReference                ; Jump if pattern same as current pattern 

        ld      (iy+S_SPRITE_TYPE.patternRange), bc     ; Otherwise change pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay
        inc     bc                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    
        
        jp      .UpdateSpriteAttributes

; Update pattern within existing animation pattern reference
.SamePatternReference
        ld      a, (iy+S_SPRITE_TYPE.animationDelay)
        cp      0                                       
        jr      z, .CheckPatternRange                   ; Jump if ready to change pattern

        dec     a                                       ; Otherwise decrement delay
        ld      (iy+S_SPRITE_TYPE.animationDelay), a    
        ret

.CheckPatternRange:
; Reset animation delay
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.animationDelay), a

        inc     bc                                      
        inc     bc                                      ; Point to end pattern in sprite animation pattern range
        
        ld      d, (iy+S_SPRITE_TYPE.patternCurrent)
        ld      a, (bc)
        cp      d
        jr      z, .ResetPattern                        ; Jump if current pattern matches end pattern

        inc     d
        ld      (iy+S_SPRITE_TYPE.patternCurrent), d    ; Otherwise point to next pattern
        ld      a, d
        jp      .UpdateSpriteAttributes

.ResetPattern
        bit     2, (iy+S_SPRITE_TYPE.SpriteType2)        ; Check whether enemy spawning - Ready to change to normal enemy
        jr      nz, .EnemySpawned                       ; Jump if enemy is spawning

        bit     0, (iy+S_SPRITE_TYPE.SpriteType2)        ; Check whether enemy death animation being played - Ready to change to delete sprite
        jr      nz, .EnemyDead                       ; Jump if enemy death animation playing

        bit     6, (iy+S_SPRITE_TYPE.SpriteType2)        ; Check whether bomb has been dropped - Ready to explode
        jr      nz, .BombDropped                         ; Jump if bomb has been dropped

        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)        ; Check whether sprite is a rock
        jp      z, .CheckPlayer                          ; Jump if not rock

        bit     4, (iy+S_SPRITE_TYPE.SpriteType1)        ; Check whether rock is moving
        jp      nz, .ContReset                          ; Jump if rock moving

        ld      a, (iy+S_SPRITE_TYPE.Counter)
        cp      0                                       ; Check whether rock timer has reached zero             
        jp      z, .RockMove                            ; Jump if rock timer is zero

        jr      .ResetStart

.CheckPlayer:
; Check for end of player death animation
        bit     3, (iy+S_SPRITE_TYPE.SpriteType1)        ; Check whether player
        jr      z, .ResetStart                           ; Jump if not player
        
.CheckPlayerDead:
        ld      a, (PlayerDead)
        cp      0
        jr      z, .ResetStart                          ; Jump if player not dead

        ld      a, 1
        ld      (DeathAnimFinished), a                  ; Set flag to indicate end of death animation

        ret

.ResetStart:
        dec      (iy+S_SPRITE_TYPE.Counter)               ; Otherwise decrement timer
        jp       .ContReset

.EnemySpawned:
        ld      a, (iy+S_SPRITE_TYPE.Counter)           
        cp      0
        jr      z, .ResetSpawned                        ; Jump is enemy should now be spawned

        dec     a
        ld      (iy+S_SPRITE_TYPE.Counter), a
        
        dec     bc                                      
        dec     bc                                      ; Point to animation delay
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay
        
        inc     bc                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        ret
        
.ResetSpawned:
        res     2, (iy+S_SPRITE_TYPE.SpriteType2)       ; Reset spawning flag to enable normal enemy

        bit     1, (iy+S_SPRITE_TYPE.SpriteType2)
        ret     z                                       ; Return if enemy not set to static

; Obtain sprite location within sprite attribute table
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Sprite Attribute table location
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)     ; Sprite pattern range

        call    UpdateSpritePattern

        ret

.EnemyDead:
        call    DeleteSprite                    ; Otherwise delete sprite

        ret

.BombDropped:
        bit     5, (iy+S_SPRITE_TYPE.SpriteType2)       ; Check whether bomb is already exploding i.e At end of explode animation
        jr      z, .BombNotExploding                    ; Jump if not already exploding

        res     7, (iy+S_SPRITE_TYPE.SpriteType1)       ; Otherwise stop bomb explosion animation ready for destroying sprite
        ret

.BombNotExploding:
        set     5, (iy+S_SPRITE_TYPE.SpriteType2)        ; Set bomb to exploding

        ld      bc, BombExplodingPatterns
        ld      (iy+S_SPRITE_TYPE.patternRange), bc     ; Configure bomb with new sprite pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.animationDelay), a    ; Configure bomb with new animation delay
        inc     bc                                      ; Point to first pattern in new sprite pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a   ; Configure bomb with new first sprite pattern

        push    af, bc, de, hl, ix
        ld      a, AyFXBombExplode
        call    AFXPlay       

        ld      a, AyFXBombExplode
        call    AFXPlay       
        pop     ix, hl, de, bc, af

        jr      .UpdateSpriteAttributes

.RockMove
; Configure rock to move and update with new sprite pattern range
        set     4, (iy+S_SPRITE_TYPE.SpriteType1)        ; Configure rock to move
        
        ld      a, 4
        ld      (iy+S_SPRITE_TYPE.Movement), a          ; Configure rock movement to down

        ld      bc, (iy+S_SPRITE_TYPE.animationVer)
        ld      (iy+S_SPRITE_TYPE.patternRange), bc     ; Configure rock with new sprite pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.animationDelay), a    ; Configure rock with new animation delay
        inc     bc                                      ; Point to first pattern in new sprite pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a   ; Configure rock with new first sprite pattern
        jr      .UpdateSpriteAttributes

.ContReset:
        dec     bc                                      ; Point to start pattern in sprite animation pattern range

        ld      a, (bc)                                 
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Reset to start pattern

.UpdateSpriteAttributes:
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (ix+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ret

;-------------------------------------------------------------------------------------
; Process non-player sprites
; Parameters:
; a = Number of non-player/non-diamond sprites to check/animate
ProcessOtherSprites:
        ld      iy, OtherSprites                        ; Point to sprite table

        ld      b, a                                    ; Number of sprites
.SpriteLoop:
; Check whether sprite is active
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .ContLoop                            ; Jump if sprite isn't active

; Clear movement restriction flag
        ld      a, 0
        ld      (iy+S_SPRITE_TYPE.SprContactSide), a

; Check whether sprite is a rock
        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .Rock                               ; Jump if sprite is a rock

; Check whether sprite is an enemy
        bit     2, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .Enemy                              ; Jump if sprite is an enemy

; Check whether sprite is an exploding bomb
        bit     5, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      nz, .BombExploding                      ; Jump if sprite is an exploding bomb

        jr      .CheckAnimate

.BombExploding:
        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .Animate                            ; Jump if bomb is still animating

        ld      a, 0
        ld      (BombDropped),a                         ; Clear flag
         
        call    DeleteSprite                            ; Otherwise delete sprite

        
        jp      .ContLoop

.Rock:
; Rock - Check whether rock moving
        bit     4, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .RockMoving                          ; Jump if rock moving

; Rock - Check whether rock sprite is still active as the sprite could have been destroyed
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .ContLoop                            ; Jump if sprite isn't active

; Rock - Check whether rock animating
        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      nz, .Animate                            ; Jump if rock animating

; Rock - Otherwise check tile below rock
        push    bc
        call    CheckTilesBelowRock
        pop     bc

        jr      .ContLoop

.RockMoving:
        push    bc
        call    MoveRock
        pop     bc
        
        jr      .ContLoop

.Enemy:        
; Check whether enemy is spawning 
        bit     2, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      nz, .Animate               ; Jump if enemy is spawning

; Check whether enemy death animation is playing
        bit     0, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      nz, .Animate               ; Jump if enemy death animation is playing

; Check whether reaper 
        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jr      nz, .ContEnemyCheck             ; Jump if reaper

; Check enemy for collision
        push    bc, iy
        ld      ix, iy
        call    CheckEnemyForCollision          ; Return - a
        pop     iy, bc

; Check whether enemy sprite was deleted
        cp      1
        jr      z, .ContLoop                    ; Jump if enemy deleted

; Check whether enemy death animation is to be played
        bit     0, (ix+S_SPRITE_TYPE.SpriteType2)
        jr      nz, .Animate                   ; Jump if enemy death animation flag set

; Check whether enemy is static
        bit     1, (iy+S_SPRITE_TYPE.SpriteType2)
        jr      nz, .Animate               ; Jump if enemy is static i.e. No movement

.ContEnemyCheck:
        push    bc

        bit     0, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      z, .NormalEnemy                 ; Jump if enemy not digger
        
; Digger Condition
; The digger will be set to flee if it's blocked. Then following the flee duration countdown the digger
; will be reset back to find and will follow the normal digger behaviour
        ;bit     1, (iy+S_SPRITE_TYPE.SpriteType1)
        ;jr      z, .NormalEnemy                 ; Jump if enemy set to flee i.e. Don't dig towards player

        call    EnemyDig                        ; Otherwise dig towards enemy
        jr      .MoveComplete

.NormalEnemy:
        call    MoveEnemy                      ; Otherwise move enemy

.MoveComplete:
        pop     bc

        jr      .Animate

.CheckAnimate:
; Check whether sprite is configured to animate
        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      z, .ContLoop                            ; Jump if sprite not configured to animate

.Animate:
        push    bc
        
; Obtain sprite location within sprite attribute table
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Sprite Attribute table location
        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range

        call    UpdateSpritePattern

        pop     bc

.ContLoop:
        ld      de, S_SPRITE_TYPE               
        add     iy, de                                  ; Point to next sprite

        dec     b
        jp      nz, .SpriteLoop

        ret
        
;-------------------------------------------------------------------------------------
; Process Diamonds
; Parameters:
; a = Number of diamond sprites to animate
ProcessDiamonds:
        ld      iy, DiamondSprites                      ; Point to sprite table

        ld      b, a                                    ; Number of sprites
.SpriteLoop:
; Check whether sprite is active
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .ContLoop                            ; Jump if sprite isn't active

.CheckAnimate:
; Check whether sprite is configured to animate
        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)
        jr      z, .ContLoop                            ; Jump if sprite not configured to animate

.Animate:
        push    bc
        
; Obtain sprite location within sprite attribute table
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Sprite Attribute table location
        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range

        call    UpdateSpritePattern

        pop     bc

.ContLoop:
        ld      de, S_SPRITE_TYPE               
        add     iy, de                                  ; Point to next sprite

        dec     b
        jp      nz, .SpriteLoop

        ret

;-------------------------------------------------------------------------------------
; Delete sprite
; Parameters:
; iy = Sprite data
DeleteSprite:
; Obtain location within sprite attribute table and hide sprite
        ld      d, S_SPRITE_ATTR
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      ix, SpriteAtt
        add     ix, de                                  ; Sprite Attribute table location

        ld      a, 0                                    ; Hide sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (ix+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

; Release Sprite Data slot
        ld      (iy+S_SPRITE_TYPE.active), 0            
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), 0

        bit     2, (iy+S_SPRITE_TYPE.SpriteType1)       ; Check whether enemy
        ret     z                                       ; Return if not enemy

        bit     0, (iy+S_SPRITE_TYPE.SpriteType2)       ; Check whether enemy was playing death animation
        jr      nz, .Cont                               ; Jump if enemy playing death animation

        ld      hl, (iy+S_SPRITE_TYPE.EnemyType)        ; Otherwise obtain enemy associated EnemyType
        ld      ix, hl
        ld      a, (ix+S_ENEMY_TYPE.EnemyMaxCounter)
        dec     a                                       ; Decrement counter to enable respawn of new enemy
        ld      (ix+S_ENEMY_TYPE.EnemyMaxCounter), a

.Cont:
        res     0, (iy+S_SPRITE_TYPE.SpriteType2)       ; Reset enemy death animation flag

        ret

;-------------------------------------------------------------------------------------
; Spawn diamond sprites
SpawnDiamonds:
        ld      ix, DiamondX
        ld      iy, DiamondY
        ld      a, (DiamondsInLevel)
        cp      0
        ret     z

        ld      b, a
.Loop
        push    bc, ix, iy

        ld      hl, (ix)                ; x Position (9-bit)
        ld      b, (iy)                 ; y Position (8-bit)
        ld      ix, DiamondSprType      ; Sprite to spawn
        ld      iy, DiamondSprites      ; Sprite storage
        ld      a, DiamondAttStart      ; Sprite attributes start offset 
        call    SpawnNewSprite
        
        pop     iy, ix, bc

        inc     ix
        inc     ix
        inc     iy
        djnz    .Loop

        ret

;-------------------------------------------------------------------------------------
; Spawn rock sprites
SpawnRocks:
        ld      ix, RockX
        ld      iy, RockY
        ld      a, (RocksInLevel)
        cp      0
        ret     z

        ld      b, a
.Loop
        push    bc, ix, iy

        ld      hl, (ix)                ; x Position (9-bit)
        ld      b, (iy)                 ; y Position (8-bit)
        ld      ix, RockSprType         ; Sprite to spawn
        ld      iy, RockSprites         ; Sprite storage
        ld      a, RockAttStart         ; Sprite attributes start offset 
        call    SpawnNewSprite
        
        pop     iy, ix, bc

        inc     ix
        inc     ix
        inc     iy
        djnz    .Loop

        ret

;-------------------------------------------------------------------------------------
; Spawn enemy sprite
; iy = Enemy type
SpawnEnemy:
        ld      a, (iy+S_ENEMY_TYPE.EnemyMaxNumber)
        ld      b, a
        ld      a, (iy+S_ENEMY_TYPE.EnemyMaxCounter)
        cp      b
        ret     z                                       ; Return if max enemies spawned

        ld      de, (iy+S_ENEMY_TYPE.SpriteType)        ; New sprite to spawn
        ld      ix, de

        bit     1, (ix+S_SPRITE_TYPE.SpriteType2)
        jr      z, .NonStatic                           ; Jump if non-static enemy

; Static Enemy - Get x, y spawn point
        push    ix, iy 
        ld      ix, EnemyStaticX                        ; Pointer to Enemy Static X table
        ld      iy, EnemyStaticY                        ; Pointer to Enemy Static Y table

        ld      d, 2
        ld      e, a                                    ; Number of static enemy being spawned
        mul     d, e
        add     ix, de                                  ; Add index to next static X spawn point (x = two bytes)

        ld      d, 0
        ld      e, a                                    ; Number of static enemy being spawned
        add     iy, de                                  ; Add inxex to next static Y spawn point (y - one byte)

        ld      hl, (ix)                                ; x Position (9-bit)
        ld      b, (iy)                                 ; y Position (8-bit)

        pop     iy, ix

        ld      a, b
        cp      0
        ret     z                                       ; Return if Y position 0 i.e. Don't spawn at this location

        ld      a, (iy+S_ENEMY_TYPE.EnemyMaxCounter)

        inc     a
        ld      (iy+S_ENEMY_TYPE.EnemyMaxCounter), a

        jp      .AllEnemies

; Non-Static Enemy - Get x, y spawn point
.NonStatic:
        inc     a
        ld      (iy+S_ENEMY_TYPE.EnemyMaxCounter), a

        ld      hl, (iy+S_ENEMY_TYPE.EnemySpawnX)       ; x Position (9-bit)
        ld      b, (iy+S_ENEMY_TYPE.EnemySpawnY)        ; y Position (8-bit)
        
.AllEnemies:
        push    iy

        ;ld      de, (iy+S_ENEMY_TYPE.SpriteType)        ; New sprite to spawn
        ;ld      ix, de

        ld      iy, EnemySpritesStart                        ; Sprite storage
        ld      a, EnemyAttStart                        ; Sprite attributes start offset 
        call    SpawnNewSprite                          ; Return - ix = New sprite, iy = New sprite attributes

; Configure new enemy sprite to spawning
        set     2, (ix+S_SPRITE_TYPE.SpriteType2)       ; Set spawning flag

        ld      a, (EnemySpawnCycles)
        ld      (ix+S_SPRITE_TYPE.Counter), a           ; Set number of times spawn patterns should be displayed before actually spawning enemy

        pop     iy

        ld      hl, (iy+S_ENEMY_TYPE.EnemyFindTimer)
        ld      (ix+S_SPRITE_TYPE.FindFleeDelay), hl    ; Set find/flee timer

        ld      a, (iy+S_ENEMY_TYPE.EnemySpeed)
        ld      (ix+S_SPRITE_TYPE.MovementDelay), a     ; Set movement delay timer

        push    af, bc, de, hl, ix
        ld      a, AyFXSpawnEnemy
        call    AFXPlay       
        pop     ix, hl, de, bc, af

        ret

;-------------------------------------------------------------------------------------
; Spawn bomb sprites
; iy = Player type
DropBomb:
        ld      a, 1
        ld      (BombDropped), a                        ; Set flag
        
        push    ix, iy

        ld      hl, (iy+S_SPRITE_TYPE.xPosition)        ; x Position (9-bit)

        ld      b, (iy+S_SPRITE_TYPE.yPosition)         ; y Position (8-bit)
        ld      ix, BombSprType                         ; New Sprite
        ld      iy, BombSprites                         ; Sprite storage
        ld      a, BombAttStart                         ; Sprite attributes start offset 
        call    SpawnNewSprite
        
        set     7, (ix+S_SPRITE_TYPE.SpriteType1)       ; Set bomb to animate
        set     6, (ix+S_SPRITE_TYPE.SpriteType2)       ; Set bomb to dropped

        pop     iy, ix

        ret