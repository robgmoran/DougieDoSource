;-------------------------------------------------------------------------------------
; Display Intro Screen
; Params:
IntroScreen:        
; Reset sprites
        ld      a, 64
        call    ResetSprites

; *** Setup Layer-2 ***
; DISPLAY CONTROL 1 REGISTER
; - Enable Layer 2, ULA remaining at bank 5, Timex mode 0
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %1'0'000000      ; (bit 7)

; Clear intro screen tilemap
        ld      d, 0                    ; Starting row
        ld      a, TileMapHeight        ; Number of rows to clear
        ld      b, TileMapWidth
        call    ClearIntroTileMap

; Setup Sprites
        call    SetupIntroSprites

        ld      a, 0                    ; 0 = Horizontal Right, 1 = Vertical, 2 = Horizontal Left 
        ld      (IntroSprPat), a
        
        ld      a, IntroSprPatInt
        ld      (IntroSprPatCt), a

; Set/display default Intro Screen Display Status
        ld      a, 1
        ld      (IntroStatus), a        ; 0 = Start Game, 1 = Credits, 2 = Instructions
        call    DisplayCredits

; Reset Start Text flash variables
        ld      a, StartFlashInt
        ld      (StartFlashCt), a

        ld      a, 1                    ; 0 = Don't display text, 1 = Display text
        ld      (StartFlashSt), a       

; Reset TileMap Palette Cycle
        ld      a, (IntroTMCycleFrames)
        ld      (IntroTMCycleFramesCT), a

; Configure tilemap palette offset for colour cycling
; TILEMAP ATTRIBUTE Register
        ld      a, %0101'0'0'0'0        ; Pal offset 0, no mirrorx, no mirrory, no rotate, tilemap over ULA (also needs to be set on register $6b)
        nextreg $6c, a

; Play song
        ld      de, SongIntroDataMapping    ; Intro music
        call    PlayNextDAWSong        

        call    SetAY3ToMono           

.IntroLoop:
        ld      a, 6
        call    AnimateIntroSprites

        call    FlashStartText

        call    NextDAW_UpdateSong              ; Keep NextDAW song playing

        call    ReadIntroInput          ; Return value a = 0 - No change, 1 - Change

        cp      0
        jr      z, .NoChange            ; Jump if no change from user
        
; Change intro screen
        ld      a, (IntroStatus)
        cp      0
        ret     z                       ; Return if selected - Start Game

        cp      1
        call    z, DisplayCredits       ; Jump if selected - Credits

        cp      2
        call    z, DisplayInstructions  ; Jump if selected - Instructions

.NoChange:
        ld      a, $70                  ; End colour to cycle from
        call    CycleL2Palette          ; Colour cycle L2 colours

        ld      a, (IntroTMCycleFramesCT)
        cp      0
        jr      nz, .PostTMCycle        ; Jump if not ready to cycle tilemap palette colours

        ld      a, $56                  ; End colour to cycle from
        ld      b, 4                    ; Number of colours to cycle
        call    CycleTileMapPalette

        ld      a, (IntroTMCycleFrames)
        ld      (IntroTMCycleFramesCT), a

.PostTMCycle:
        ld      a, (IntroTMCycleFramesCT)
        dec     a
        ld      (IntroTMCycleFramesCT), a
        
        call    WaitForScanlineUnderUla

        jr      .IntroLoop

;-------------------------------------------------------------------------------------
; Clear Intro TileMap 
; Params:
; d = Starting row - Starting at 0; column always starts at 0
; a = Number of rows
; b = Number of columns
ClearIntroTileMap:
; Calculate Destination
        ld      e, TileMapWidth
        mul     d, e                    ; Calculate starting offset

        add     de, TileMapLocation     

; Calculate Source
        push    de
        pop     hl                      ; Set destination

        push    af                      ; Save row count

        ld      a, b
        ld      (BackupDataByte), a     ; Save number of columns

        pop     af                      ; Restore row count

        ld      b, a                    ; Number of rows
.RowLoop:
        push    bc                      ; Save row count

        ld      a, (BackupDataByte)     ; Restore number of columns
        ld      b, a                    
.ColumnLoop:
        ld      (hl), TileEmpty         ; Write to tile

        inc     hl                      ; Point to next destination tile

        djnz    .ColumnLoop

        ld      a, (BackupDataByte)
        ld      b, a
        ld      a, TileMapWidth
        sub     b                       ; Calculate offset to point to next line

        add     hl, a                   ; Point destination to next line

        pop     bc                      ; Restore row count

        djnz    .RowLoop

        ret

;-------------------------------------------------------------------------------------
; Display Instructions
; Params:
DisplayInstructions:
        push    af

; *** Setup Layer-2 ***
; DISPLAY CONTROL 1 REGISTER
; - Disable Layer 2, ULA remaining at bank 5, Timex mode 0
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %0'0'000000      ; (bit 7)

; Clear intro screen tilemap
        ld      d, CredY                ; Starting row - Clear previous credit screen
        ld      a, 27                   ; Number of rows to clear
        ld      b, 40                   ; Number of columns to clear - Clear previous credit screen
        call    ClearIntroTileMap

; Display Instructions
        ld      ix, InstPara0           ; Text to display suffixed by 255
        ld      c, InstrLineWidth
        ld      e, InstrX+9               ; x = 0-31
        ld      d, InstrY               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, InstPara1           ; Text to display suffixed by 255
        ld      c, InstrLineWidth
        ld      e, InstrX               ; x = 0-31
        ld      d, InstrY+2               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, InstPara2           ; Text to display suffixed by 255
        ld      c, InstrLineWidth
        ld      e, InstrX               ; x = 0-31
        ld      d, InstrY+7               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, InstPara3           ; Text to display suffixed by 255
        ld      c, InstrLineWidth
        ld      e, InstrX               ; x = 0-31
        ld      d, InstrY+10               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, InstPara31           ; Text to display suffixed by 255
        ld      c, InstrLineWidth
        ld      e, InstrX               ; x = 0-31
        ld      d, InstrY+16               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, InstPara4           ; Text to display suffixed by 255
        ld      c, InstrLineWidth
        ld      e, InstrX               ; x = 0-31
        ld      d, InstrY+19               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, InstPara5           ; Text to display suffixed by 255
        ld      c, InstrLineWidth
        ld      e, InstrX               ; x = 0-31
        ld      d, InstrY+20               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, InstPara6           ; Text to display suffixed by 255
        ld      c, InstrLineWidth
        ld      e, InstrX+5               ; x = 0-31
        ld      d, InstrY+26               ; y = 0-23
        call    PrintTileStringLines

; Disable Player Sprite
        ld      iy, PlayerSprAtt
        res     7, (iy+S_SPRITE_ATTR.vpat)      ; Disable Sprite

; Display Enemy Sprites
; Enemy 1 - Side of Screen
        ld      ix, IntroSprTextE1          ; Text to display suffixed by 255
        ld      e, IntroSprTextX          ; x = 0-39
        ld      d, IntroSprTextY+(IntroSprTextYOff*0)          ; y = 0-31
        call    PrintTileString

        ld      iy, OtherSprAtt
        set     7, (iy+S_SPRITE_ATTR.vpat)      ; Enable sprite

; Enemy 2 - Side of Screen
        ld      ix, IntroSprTextE2          ; Text to display suffixed by 255
        ld      e, IntroSprTextX          ; x = 0-39
        ld      d, IntroSprTextY+(IntroSprTextYOff*1)          ; y = 0-31
        call    PrintTileString

        ld      de, S_SPRITE_ATTR
        add     iy, de
        set     7, (iy+S_SPRITE_ATTR.vpat)      ; Enable sprite

; Enemy 3 - Side of Screen
        ld      ix, IntroSprTextE3          ; Text to display suffixed by 255
        ld      e, IntroSprTextX          ; x = 0-39
        ld      d, IntroSprTextY+(IntroSprTextYOff*2)          ; y = 0-31
        call    PrintTileString

        ld      de, S_SPRITE_ATTR
        add     iy, de
        set     7, (iy+S_SPRITE_ATTR.vpat)      ; Enable sprite

; Enemy 4 - Side of Screen
        ld      ix, IntroSprTextE4          ; Text to display suffixed by 255
        ld      e, IntroSprTextX          ; x = 0-39
        ld      d, IntroSprTextY+(IntroSprTextYOff*3)          ; y = 0-31
        call    PrintTileString

        ld      de, S_SPRITE_ATTR
        add     iy, de
        set     7, (iy+S_SPRITE_ATTR.vpat)      ; Enable sprite

; Enemy 5 - Side of Screen
        ld      ix, IntroSprTextE5          ; Text to display suffixed by 255
        ld      e, IntroSprTextX          ; x = 0-39
        ld      d, IntroSprTextY+(IntroSprTextYOff*4)          ; y = 0-31
        call    PrintTileString

        ld      de, S_SPRITE_ATTR
        add     iy, de
        set     7, (iy+S_SPRITE_ATTR.vpat)      ; Enable sprite

        ld      a, 6
        call    UploadSpriteAttributes

        pop     af

        ret

;-------------------------------------------------------------------------------------
; Display Credits
; Params:
DisplayCredits:
        push    af

; *** Setup Layer-2 ***
; DISPLAY CONTROL 1 REGISTER
; - Enable Layer 2, ULA remaining at bank 5, Timex mode 0
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %1'0'000000      ; (bit 7)

; Clear intro screen tilemap
        ld      d, InstrY               ; Starting row - Clear previous instructions screen
        ld      a, 27                   ; Number of rows to clear
        ld      b, 40       ; Number of columns to clear - Clear previous instructions screen
        call    ClearIntroTileMap

; Coding
        ld      ix, CredPara1           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+30               ; x = 0-31
        ld      d, CredY+2               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, CredPara2           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+28              ; x = 0-31
        ld      d, CredY+3               ; y = 0-23
        call    PrintTileStringLines

; Music
        ld      ix, CredPara4           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+30              ; x = 0-31
        ld      d, CredY+7               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, CredPara5           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+26              ; x = 0-31
        ld      d, CredY+8               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, CredPara51           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+27              ; x = 0-31
        ld      d, CredY+9               ; y = 0-23
        call    PrintTileStringLines

; Sound FX
        ld      ix, CredPara9           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+29              ; x = 0-31
        ld      d, CredY+13               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, CredPara10           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+28              ; x = 0-31
        ld      d, CredY+14               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, CredPara11           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+27              ; x = 0-31
        ld      d, CredY+15               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, CredPara12           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+28              ; x = 0-31
        ld      d, CredY+16               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, CredPara13           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+28              ; x = 0-31
        ld      d, CredY+17               ; y = 0-23
        call    PrintTileStringLines

; Sprites
        ld      ix, CredPara6           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+29               ; x = 0-31
        ld      d, CredY+21               ; y = 0-23
        call    PrintTileStringLines

        ld      ix, CredPara7           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+25               ; x = 0-31
        ld      d, CredY+22               ; y = 0-23
        call    PrintTileStringLines

; Keys Text
        ld      ix, CredPara14           ; Text to display suffixed by 255
        ld      c, CredLineWidth
        ld      e, CredX+3               ; x = 0-31
        ld      d, CredY+26               ; y = 0-23
        call    PrintTileStringLines

; Enable Player Sprite
        ld      iy, PlayerSprAtt
        set     7, (iy+S_SPRITE_ATTR.vpat)      ; Enable Sprite

; Disable Enemy Sprites
        ld      iy, OtherSprAtt
        ld      de, S_SPRITE_ATTR
        ld      b, 5
.DisableEnemySprites:
        res     7, (iy+S_SPRITE_ATTR.vpat)      ; Disable Sprite
        add     iy, de                          ; Point to next sprite attributes
        djnz    .DisableEnemySprites

        ld      a, 6
        call    UploadSpriteAttributes

        pop     af

        ret

;-------------------------------------------------------------------------------------
; Flash Start Text 
; Params:
FlashStartText:
        ld      a, (StartFlashCt)
        cp      0
        jr      nz, .DisplayStartText   ; Jump if Start text counter not zero i.e. Don't change Start text status

        ld      a, (StartFlashSt)
        cp      0
        jr      z, .SetStartFlashSt     ; Jump if need to display Start text

        ; Remove Start text
        dec     a
        ld      (StartFlashSt), a

        ld      a, StartFlashInt
        ld      (StartFlashCt), a       ; Reset Start flash counter

        ld      ix, StartParaOff        ; Text to display suffixed by 255
        jr      .Display

        ; Display Start text
.SetStartFlashSt:
        inc     a
        ld      (StartFlashSt), a        

        ld      a, StartFlashInt
        ld      (StartFlashCt), a       ; Reset Start flash counter

        ld      ix, StartParaOn        ; Text to display suffixed by 255
        jr      .Display

; Display Start Text
.DisplayStartText:
        ; Check status of Start text
        ld      a, (StartFlashSt)
        cp      0
        jr      nz, .StartTextOn        ; Jump if Start text should be displayed

        ld      ix, StartParaOff        ; Text to display suffixed by 255
        jr      .Display

.StartTextOn:
        ld      ix, StartParaOn        ; Text to display suffixed by 255

.Display:
        ld      c, StartLineWidth
        ld      e, StartX               ; x = 0-31
        ld      d, StartY               ; y = 0-23
        call    PrintTileStringLines

; Decrement Start Text Flash
        ld      a, (StartFlashCt)
        dec     a
        ld      (StartFlashCt), a

        ret

;-------------------------------------------------------------------------------------
; Setup Intro Sprites but don't enable
; Params:
SetupIntroSprites:
; Reset PlayerDead to ensure player sprite animation can be played
        ld      a, 0
        ld      (PlayerDead), a
        
; Player - Middle of Screen
        ld      hl, IntroPlayerSprX                ; x Position (9-bit)
        ld      b, IntroPlayerSprY                 ; y Position (8-bit)
        ld      ix, PlayerSprType      ; Sprite to spawn
        ld      iy, PlayerSprite      ; Sprite storage
        ld      a, 0      ; Sprite attributes start offset 
        call    SpawnNewSprite

; Increase size of player
        ld      a, (iy+S_SPRITE_ATTR.Attribute4)
        or      a, %0'0'0'10'10'0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a

        res     7, (iy+S_SPRITE_ATTR.vpat)      ; Disable sprite

; Enemy 1 - Side of Screen
        ld      hl, IntroSprX                ; x Position (9-bit)
        ld      b, IntroSprY+(IntroSprYOff*0)                 ; y Position (8-bit)
        ld      ix, EnemySprType1      ; Sprite to spawn
        ld      iy, EnemySpritesStart      ; Sprite storage
        ld      a, EnemyAttStart      ; Sprite attributes start offset 
        call    SpawnNewSprite

        res     7, (iy+S_SPRITE_ATTR.vpat)      ; Disable sprite

; Enemy 2 - Side of Screen
        ld      hl, IntroSprX                ; x Position (9-bit)
        ld      b, IntroSprY+(IntroSprYOff*1)                 ; y Position (8-bit)
        ld      ix, EnemySprType2      ; Sprite to spawn
        ld      iy, EnemySpritesStart      ; Sprite storage
        ld      a, EnemyAttStart      ; Sprite attributes start offset 
        call    SpawnNewSprite

        res     7, (iy+S_SPRITE_ATTR.vpat)      ; Disable sprite

; Enemy 3 - Side of Screen
        ld      hl, IntroSprX                ; x Position (9-bit)
        ld      b, IntroSprY+(IntroSprYOff*2)                 ; y Position (8-bit)
        ld      ix, EnemySprType3      ; Sprite to spawn
        ld      iy, EnemySpritesStart      ; Sprite storage
        ld      a, EnemyAttStart      ; Sprite attributes start offset 
        call    SpawnNewSprite

        res     7, (iy+S_SPRITE_ATTR.vpat)      ; Disable sprite

; Enemy 4 - Side of Screen
        ld      hl, IntroSprX                ; x Position (9-bit)
        ld      b, IntroSprY+(IntroSprYOff*3)                 ; y Position (8-bit)
        ld      ix, EnemySprType4      ; Sprite to spawn
        ld      iy, EnemySpritesStart      ; Sprite storage
        ld      a, EnemyAttStart      ; Sprite attributes start offset 
        call    SpawnNewSprite

        res     7, (iy+S_SPRITE_ATTR.vpat)      ; Disable sprite

; Enemy 5 - Side of Screen
        ld      hl, IntroSprX                ; x Position (9-bit)
        ld      b, IntroSprY+(IntroSprYOff*4)                 ; y Position (8-bit)
        ld      ix, EnemySprType5      ; Sprite to spawn
        ld      iy, EnemySpritesStart      ; Sprite storage
        ld      a, EnemyAttStart      ; Sprite attributes start offset 
        call    SpawnNewSprite

        res     7, (iy+S_SPRITE_ATTR.vpat)      ; Disable sprite

        ld      a, 6
        call    UploadSpriteAttributes

        ret

;-------------------------------------------------------------------------------------
; Animate Intro Sprites
; Params:
; a = Number of sprites to animate
AnimateIntroSprites:
        push    af

        ld      b, a                                    ; Number of sprite entries to search through
        ld      iy, PlayerSprite

; Sprite Pattern Check
        ld      a, (IntroSprPatCt)
        cp      0
        jr      nz, .Cont                               ; Jump if counter not zero - Don't need to change sprite pattern

        ld      a, (IntroSprPat)
        cp      3
        jr      nz, .NoReset                            ; Jump if pattern not at end - Only need to increment

        ld      a, 0
        ld      (IntroSprPat), a                        ; Otherwise reset pattern to 0

        ld      a, IntroSprPatInt
        jr      .Cont        

.NoReset:
        inc     a
        ld      (IntroSprPat), a

        ld      a, IntroSprPatInt

.Cont
        dec     a                                       ; Decrement counter
        ld      (IntroSprPatCt), a

.SpriteLoop:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .NextSprite

; Obtain sprite attribute reference
        ld      e, (iy+S_SPRITE_TYPE.SpriteNumber)
        ld      d, S_SPRITE_ATTR
        mul     d, e

        ld      ix, SpriteAtt
        add     ix, de

        bit     7, (ix+S_SPRITE_ATTR.vpat)              ; Check whether sprite is visible
        jr      z, .NextSprite                          ; Jump if sprite not visible

; Update Animation
; Check whether player sprite
        ld      a, (iy+S_SPRITE_TYPE.SpriteType1)
        bit     3, a
        jr      z, .NotPlayer                           ; Jump if sprite not player

        ld      bc, PlayerIdlePatterns                  ; Only play idle pattern for player sprite
        jr      .UpdatePattern

.NotPlayer:

        ld      a, (IntroSprPat)
        cp      0
        jr      z, .PatternRight                        ; Jump if change pattern to horizontal right

        cp      1
        jr      z, .Vertical                            ; Jump if change pattern to vertical

        cp      2
        jr      z, .PatternLeft                         ; Jump if change pattern to horizontal left

.Vertical:
        ld      bc, (iy+S_SPRITE_TYPE.animationVer)
        jr      .UpdatePattern

.PatternRight:
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        res     3, (ix+S_SPRITE_ATTR.mrx8)              ; Don't horizontally mirror sprite
        jr      .UpdatePattern

.PatternLeft:
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        set     3, (ix+S_SPRITE_ATTR.mrx8)              ; Horizontally mirror sprite

.UpdatePattern:
        call    UpdateSpritePattern             

.NextSprite:
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Point to next sprite slot

        djnz    .SpriteLoop

; Upload 
        pop     af
        call    UploadSpriteAttributes

        ret                                     

;-------------------------------------------------------------------------------------
; Setup Level Data - Run at start of new game
; Params:
StartNewGame:
; Reset counters
        call    ResetStartNewGameCounters

; Reset sprites
        ld      a, 64
        call    ResetSprites

; *** Setup Layer-2 ***
; DISPLAY CONTROL 1 REGISTER
; - Disable Layer 2, ULA remaining at bank 5, Timex mode 0
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %0'0'000000      ; (bit 7)

; Draw level
        call    DrawNewLevel
        call    DisplayHUDText

; Reset counters
        call    ResetNewLevelCounters

        call    NextDAW_StopSong                

        ld      a, AyFXStartLevel1
        call    AFXPlay
        ld      a, AyFXStartLevel1
        call    AFXPlay
        ld      a, AyFXStartLevel1
        call    AFXPlay

; Pause before starting level and play idle animation
        ld      b, LevelStartFramePause

.StartLoop:
        push    bc

        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite
        ld      bc, PlayerIdlePatterns

        call    UpdateSpritePattern             ; Update to death animation

        ld      a, 1                            ; Number of sprites to upload
        call    UploadSpriteAttributes

        call    NextDAW_UpdateSong              ; Keep NextDAW song playing
        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a
        call    AFXFrame                       ; Keep AYFX sound effect playing

        call    WaitForScanlineUnderUla

        pop     bc

        djnz    .StartLoop

; Play song                
        ld      de, (LevelSongData)
        call    PlayNextDAWSong                 

        call    SetAY3ToMono

        ret

;-------------------------------------------------------------------------------------
; Setup Level Data - Run at start of new level
; Params:
StartNewLevel:
; Reset sprites 
        ld      a, 1                    ; Clear all sprites
        call    ClearLevelSprites

; Check/Update level number
        ld      a, (LevelNumber)
        ld      hl, LevelTotal        
        cp      (hl)
        jr      nz, .ContinueLevelBuild ; Jump if not at last level

; Loop Game
        ld      a, (GameLoops)
        inc     a
        ld      (GameLoops), a          ; Increment game loops, used to increase enemy movement speed

        ld      a, 0                    ; Reset level number

.ContinueLevelBuild:
        inc     a                       ; Point to next level
        ld      (LevelNumber), a

; Draw level
        call    DrawNewLevel
        call    DisplayHUDText

; Reset counters
        call    ResetNewLevelCounters

        call    NextDAW_StopSong                

        ld      a, AyFXStartLevel1
        call    AFXPlay       
        ld      a, AyFXStartLevel2
        call    AFXPlay       
        ld      a, AyFXStartLevel3
        call    AFXPlay       

; Pause before starting level and play idle animation
        ld      b, LevelStartFramePause

.StartLoop:
        push    bc

        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite
        ld      bc, PlayerIdlePatterns

        call    UpdateSpritePattern             ; Update to death animation

        ld      a, 1                            ; Number of sprites to upload
        call    UploadSpriteAttributes

        call    NextDAW_UpdateSong              ; Keep NextDAW song playing
        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a
        call    AFXFrame                       ; Keep AYFX sound effect playing

        call    WaitForScanlineUnderUla

        pop     bc
        djnz    .StartLoop

; Play song
        ld      de, (LevelSongData)
        call    PlayNextDAWSong

        call    SetAY3ToMono

        ret

;-------------------------------------------------------------------------------------
; Setup Level Data - Run at restart of level
; Params:
RestartLevel:
; Reset counters
        call    ResetLevelCounters

; Reset sprites 
        ld      a, 0                    ; Clear limited sprites
        call    ClearLevelSprites

; Configure enemy values
        call    ConfigureEnemyValues

; Setup Player sprite
        ld      hl, (PlayerStartX)      ; Player Sprite - x Position (9-bit)
        ld      a, (PlayerStartY)       ; Player Sprite - y Position (8-bit)
        ld      b, a
        call    SetupPlayerSprite

; Upload Sprite Attributes
        ld      a, 64                   ; Number of sprites to upload
        call    UploadSpriteAttributes

        call    NextDAW_StopSong                

        ld      a, AyFXStartLevel1
        call    AFXPlay       
        ld      a, AyFXStartLevel2
        call    AFXPlay       
        ld      a, AyFXStartLevel3
        call    AFXPlay       

; Pause before re-starting level and play idle animation
        ld      b, LevelStartFramePause

.StartLoop:
        push    bc

        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite
        ld      bc, PlayerIdlePatterns

        call    UpdateSpritePattern             ; Update to death animation

        ld      a, 1                            ; Number of sprites to upload
        call    UploadSpriteAttributes

        call    NextDAW_UpdateSong              ; Keep NextDAW song playing
        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a
        call    AFXFrame                       ; Keep AYFX sound effect playing

        call    WaitForScanlineUnderUla

        pop     bc
        djnz    .StartLoop

; Play song
        ld      de, (LevelSongData)
        call    PlayNextDAWSong

        call    SetAY3ToMono

        ret

;-------------------------------------------------------------------------------------
; Clear level ready for start or restart; not start of new game
; Params:
; a = 0 - Clear enemies, bombs , a = 1 - Clear diamonds, rocks, enemies, bombs
ClearLevelSprites:
        cp      0
        jr      z, .ClearPart2           ; Jump if only enemies and bombs need to be cleared

; Delete diamonds
        ld      b, MaxDiamonds
        ld      iy, DiamondSprites
.DiamondLoop:
        call    DeleteSprite

        ld      de, S_SPRITE_TYPE
        add     iy, de                  ; Point to next diamond sprite
        djnz    .DiamondLoop

; Delete rocks
        ld      b, MaxRocks
        ld      iy, RockSprites
.RockLoop:
        call    DeleteSprite

        ld      de, S_SPRITE_TYPE
        add     iy, de                  ; Point to next rock sprite
        djnz    .RockLoop

.ClearPart2:
; Delete enemies
        ld      b, MaxEnemy
        ld      iy, EnemySpritesStart
.EnemyLoop:
        call    DeleteSprite

        ld      de, S_SPRITE_TYPE
        add     iy, de                  ; Point to next enemy sprite        
        djnz    .EnemyLoop

; Delete bombs
        ld      b, MaxBombs
        ld      iy, BombSprites
.BombLoop:
        call    DeleteSprite

        ld      de, S_SPRITE_TYPE
        add     iy, de                  ; Point to next enemy sprite        
        djnz    .BombLoop

        ret

;-------------------------------------------------------------------------------------
; Configure enemy types
; Params:
ConfigureEnemyValues:
        call    SetupEnemyTypes
        ld      ix, (LevelEnemyTypeData)        ; Point to Level EnemyData
        call    FindEnemyCount

        ret

;-------------------------------------------------------------------------------------
; Reset level counters
; Params:
ResetLevelCounters:
; Reset various counters
        ld      a, 0
        ld      (BombDropped), a
        ld      (EnemiesDestroyed), a
        ld      (PlayerDead), a
        ld      (DeathAnimFinished), a

        ret

;-------------------------------------------------------------------------------------
; Reset start of new level counters
; Params:
ResetNewLevelCounters:
; Reset diamonds
        ld      a, 0
        ld      (DiamondsCollected), a
        ld      a, (DiamondsInLevel)
        ld      (DiamondsTotal), a
        ld      (LevelComplete), a

        call    ResetLevelCounters

        ret

;-------------------------------------------------------------------------------------
; Reset start of game counters
; Params:
ResetStartNewGameCounters:
        
; Reset various counters
        ld      a, 0
        ld      (BombExtraCounter), a
        ld      (Paused), a

        ld      a, (PausedFrames)
        ld      (PausedCounter), a

        ld      hl, 0
        ld      (ExtraLifeCounter), hl

; Reset HUD Values
        ld      hl, LevelNumber
        ld      (hl), 1

        ld      a, 0
        ld      (GameLoops), a

        ld      hl, Lives
        ld      (hl), LivesStart

        ld      hl, Bombs
        ld      (hl), BombStart

        ld      ix, Score
        ld      b, ScoreLength
.ResetScore:
        ld      a, 48                   ; "0" value
        ld      (ix), a                 ; Set score digit to "0"
        
        inc     ix
        djnz    .ResetScore

        ret

;-------------------------------------------------------------------------------------
; Draw new level
; Params:
DrawNewLevel:
; Clear intro screen tilemap
        ld      d, 0                    ; Starting row
        ld      a, TileMapHeight        ; Number of rows to clear
        ld      b, TileMapWidth
        call    ClearIntroTileMap

; Point to level data and upload tilemap data
        call    PointToLevelData
        call    UploadLevelTileMapData       

; Configure tilemap palette offset for level
; TILEMAP ATTRIBUTE Register
        ld      a, (LevelTileMapPalOffset)
        ld      d, a
        ld      e, 16
        mul     d, e

        ld      a, %0000'0'0'0'0        ; Pal offset 0, no mirrorx, no mirrory, no rotate, tilemap ULA over (also needs to be set on register $6b)
        or      e                       ; Update pal offset
        nextreg $6c, a

; Configure enemy values
        call    ConfigureEnemyValues
        
; Setup/Spawn Player sprite
        ld      hl, (PlayerStartX)      ; Player Sprite - x Position (9-bit)
        ld      a, (PlayerStartY)       ; Player Sprite - y Position (8-bit)
        ld      b, a
        call    SetupPlayerSprite

; Spawn diamonds/rocks
        call    SpawnDiamonds
        call    SpawnRocks

; Upload Sprite Attributes
        ld      a, 64                   ; Number of sprites to upload
        call    UploadSpriteAttributes

        ret

;-------------------------------------------------------------------------------------
; Point to Level data and enemy type data for current level
; Params:
PointToLevelData:
        ld      a, (LevelNumber)
        dec     a                       ; Require levels to start at 0

        ld      d, a
        ld      e, S_LEVEL_TYPE
        mul     d, e                    ; Calculate level data offset

        ld      ix, LevelData
        add     ix, de                  ; Point to actual level data

        ld      bc, (ix+S_LEVEL_TYPE.TileMap)
        ld      (LevelTileMapData), bc

        ld      bc, (ix+S_LEVEL_TYPE.TileMapPalOffset)
        ld      (LevelTileMapPalOffset), bc

        ld      bc, (ix+S_LEVEL_TYPE.TileMapDefOffset)
        ld      (LevelTileMapDefOffset), bc

        ld      bc, (ix+S_LEVEL_TYPE.SongMapping)
        ld      (LevelSongData), bc

        ld      bc, (ix+S_LEVEL_TYPE.EnemyTypes)
        ld      (LevelEnemyTypeData), bc

; Map memory bank containing level tilemap data
        ld      b, (ix+S_LEVEL_TYPE.TileMapMemBank)             ; Memory bank (8kb) containing tilemap data
        call    MapTileMapBank

        ret        

;-------------------------------------------------------------------------------------
; Gameover routine
; Params:
GameOver:
; Reset sprites 
        ld      a, 0                    ; Clear limited sprites
        call    ClearLevelSprites

; Display GAME OVER message as sprites
        ld      ix, GameOverHUD

        ld      hl, 64                  ; x Position (9-bit)
        ld      b, 44                   ; y Position (8-bit)

.Loop:
        ld      a, (ix)
        ld      c, a                    ; Backup value

        cp      99
        jr      z, .Finished            ; Jump if end of text

        cp      0
        jr      z, .NextCharacter       ; Jump if space required
        
        push    hl, ix, iy
        push    bc

        ld      ix, GOSprType           ; Sprite to spawn
        ld      iy, EnemySpritesStart        ; Sprite storage
        ld      a, EnemyAttStart        ; Sprite attributes start offset 
        call    SpawnNewSprite
        
        pop     bc

        ld      a, c                                    ; Set required sprite pattern
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        pop     iy, ix, hl

.NextCharacter:
        inc     ix                      ; Point to next character

        ld      a, 16
        add     hl, a                   ; Point to next screen location

        jr      .Loop

.Finished:
; Upload Sprite Attributes
        ld      a, MaxEnemy+1                   ; Number of sprites to upload
        call    UploadSpriteAttributes

        ld      a, AyFXGameOver1
        call    AFXPlay       
        ld      a, AyFXGameOver2
        call    AFXPlay       
        ld      a, AyFXGameOver3
        call    AFXPlay       

; Rotate sprites down screen
.MoveSprites:
        ld      ix, EnemySpritesStart
        ld      a, 8                                    ; Number of "GAME OVER" sprites
        ld      (BackupDataByte), a                     ; Save value
.MoveGOLoop:
; Point to enemy sprite attribute data
        ld      d, S_SPRITE_ATTR
        ld      e, (ix+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                    ; Calculate sprite attribute offset
        ld      iy, SpriteAtt
        add     iy, de                                  ; Destination - Sprite Attributes

        ld      a, (iy+S_SPRITE_ATTR.y)
        cp      98+TileMapSpriteYOffset
        jr      z, .NextSprite                          ; Jump if sprite now at required y position

; Move sprite down 2 with no mirror/rotation
        ld      c, %0000'000'0
        call    RotateGO

; Move sprite down 2 with mirror/rotation
        ld      a, (iy+S_SPRITE_ATTR.y)
        inc     a
        inc     a
        ld      (iy+S_SPRITE_ATTR.y), a         ; Attribute 2 - Store updated y position

        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        or      %0000'111'0
        ld      (iy+S_SPRITE_ATTR.mrx8), a         ; Attribute 3 - Store updated rotation/mirror

        push    ix, iy, bc
        call    NextDAW_UpdateSong
        pop     bc, iy, ix
        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a

        push    bc, ix
        call    AFXFrame                       ; Keep AYFX sound effect playing
        pop     ix, bc
        
        call    WaitForScanlineUnderUla

; Upload Sprite Attributes
        ld      a, MaxEnemy+1                   ; Number of sprites to upload
        call    UploadSpriteAttributes

; Move sprite down 2 with no mirror/rotation
        ld      c, %0000'000'0
        call    RotateGO

; Move sprite down 2 with mirror/rotation
        ld      c, %0000'001'0
        call    RotateGO

; Move sprite down 2 with no mirror/rotation
        ld      c, %0000'000'0
        call    RotateGO

; Move sprite down 2 with mirror/rotation
        ld      c, %0000'111'0
        call    RotateGO

; Move sprite down 2 with no mirror/rotation
        ld      c, %0000'000'0
        call    RotateGO

; Move sprite down 2 with mirror/rotation
        ld      c, %0000'001'0
        call    RotateGO

; Move sprite down 2 with no mirror/rotation
        ld      c, %0000'000'0
        call    RotateGO

        jr      .MoveGOLoop

.NextSprite:
        ld      de, S_SPRITE_TYPE
        add     ix, de                          ; Point to next sprite

        ld      a, (BackupDataByte)             ; Restore value
        dec     a
        ld      (BackupDataByte), a
        cp      0
        jp      nz, .MoveGOLoop

; Pause before returning to intro screen
        ld      b, GameOverFramePause
.PauseLoop:
        push    bc
        call    WaitForScanlineUnderUla
        pop     bc

        djnz    .PauseLoop
        
; Reset sprites 
        ;ld      a, 1                            ; Clear all sprites
        ;call    ClearLevelSprites

        jp      Intro                           ; Jump back to intro

        ret

;-------------------------------------------------------------------------------------
; Rotate GAMEOVER text
; Parms:
; iy = GAMEOVER sprite attributes
; c = Rotation/Mirror value
RotateGO:
        ld      a, (iy+S_SPRITE_ATTR.y)
        inc     a
        inc     a
        ld      (iy+S_SPRITE_ATTR.y), a         ; Attribute 2 - Store updated y position

        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        xor     c
        ld      (iy+S_SPRITE_ATTR.mrx8), a      ; Attribute 3 - Store updated rotation/mirror

        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a

        push    bc, ix
        call    AFXFrame                       ; Keep AYFX sound effect playing
        pop     ix, bc

        call    WaitForScanlineUnderUla

; Upload Sprite Attributes
        ld      a, MaxEnemy+1                   ; Number of sprites to upload
        call    UploadSpriteAttributes

        ret