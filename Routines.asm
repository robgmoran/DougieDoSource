;-------------------------------------------------------------------------------------
; Clear Screen and Screen Attributes
ClearULAScreen:
; Clear screen memory - $4000 -> 6,144 bytes
        ld hl, $4000
        ld de, $4000+1
        ld bc, 6144-1
        ld (hl),0
        ldir

/* Optional code to write to different banks
        ld hl, $4000
        ld de, $4000+1
        ld      bc, 2047
        ld (hl),$21
        ldir

        ld      bc, 2047
        ld (hl),$31
        ldir

        ld      bc, 2047
        ld (hl),$41
        ldir
*/
        
; Clean screen attribute memory - $5800 -> 768 bytes
        ld hl, $5800
        ld de, $5800+1
        ld bc, 768-1
        ld (hl), %0000'1111     ; Background colour'Foreground colour
        ldir

        ret

;-------------------------------------------------------------------------------------
; Wait for ULA Scan Line
WaitForScanlineUnderUla:
; Sync the main game loop by waiting for particular scanline under the ULA paper area, i.e. scanline 192
/*
; Update the IdleFrameCount if necessary
        ld      bc, (IdleFrameCount)
        ld      hl, 0
        sbc     hl, bc        
        jr      z, .UpdateTotalFrames   ; Jump if IdleFrameCount (hl) = 0

        inc     bc                            
        ld      (IdleFrameCount), bc    ; Otherwise increment IdleFrameCount
*/        
; Update the TotalFrames counter by +1
.UpdateTotalFrames:
        ld      hl,(TotalFrames)
        inc     hl
        ld      (TotalFrames),hl

; if HL=0, increment upper 16bit too
; Cannot compare a word (hl) therefore need to compare both h & l together
        ld      a,h
        or      l
        jr      nz,.totalFramesUpdated
        ld      hl,(TotalFrames+2)
        inc     hl
        ld      (TotalFrames+2),hl
.totalFramesUpdated:
; read NextReg $1F - LSB of current raster line
        ld      bc,$243B        ; TBBlue Register Select
        ld      a,$1F           ; Port to access - Active Video Line LSB Register
        out     (c),a           ; Select NextReg $1F
        inc     b               ; TBBlue Register Access
; If already at scanline 192, then wait extra whole frame (for super-fast game loops)
.cantStartAtScanLine:
        ld      a, (WaitForScanLine)
        ld      d,a
        in      a,(c)       ; read the raster line LSB
        cp      d
        jr      z,.cantStartAtScanLine
; If not yet at scanline, wait for it ... wait for it ...
.waitLoop:
        in      a,(c)       ; read the raster line LSB
        cp      d
        jr      nz,.waitLoop
; and because the max scanline number is between 260..319 (depends on video mode),
; I don't need to read MSB. 256+192 = 448 -> such scanline is not part of any mode.

        ret

;-------------------------------------------------------------------------------------
; Check for end of level
CheckForEndOfLevel:
        ld      a, (PlayerDead)
        cp      1
        jr      z, .PlayerDead

; Check diamonds collected
        ld      a, (DiamondsCollected)
        ld      hl, DiamondsTotal
        cp      (hl)
        jr      z, .LevelComplete

; Check enemies destroyed
        ld      a, (EnemiesDestroyed)
        ld      hl, EnemiesTotal
        cp      (hl)
        jr      z, .LevelComplete

        ret

.PlayerDead:
; Check player lives
        ld      a, (Lives)
        dec     a
        ld      (Lives), a

        call    DisplayHUDLivesValue

; Player Death animation
.DeathLoop:
        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite
        ld      bc, DeathPatterns

        call    UpdateSpritePattern             ; Update to death animation

        ld      a, 1                            ; Number of sprites to upload
        call    UploadSpriteAttributes

        call    NextDAW_UpdateSong              ; Keep NextDAW song playing
        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a
        call    AFXFrame                       ; Keep AYFX sound effect playing

        call    WaitForScanlineUnderUla

        ld      a, (DeathAnimFinished)
        cp      1
        jr      nz, .DeathLoop

; Pause before continuing
        ld      b, DeathFramePause
.PauseLoop:        
        push    bc

        call    NextDAW_UpdateSong              ; Keep NextDAW song playing
        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a
        call    AFXFrame                       ; Keep AYFX sound effect playing
 
        call    WaitForScanlineUnderUla
        pop     bc

        djnz    .PauseLoop

        ld      a, (Lives)
        cp      0
        jp      z, GameOver    ; Jump if the player has no lives left

        call    RestartLevel    ; Otherwise restart level

        ret

.LevelComplete:
        ld      a, 1
        ld      (LevelComplete), a      ; Used to suppress extra life sound effects
        
; Update score
        ld      iy, ScoreLevelCompleteStr
        ld      b, 3
        call    UpdateScore

        ld      de, ScoreLevelComplete
        call    CheckExtraLife
        call    DisplayHUDScoreValues

; Stop song
        call    NextDAW_StopSong      

        ld      a, AyFXLevelComplete1
        call    AFXPlay       
        ld      a, AyFXLevelComplete2
        call    AFXPlay       
        ld      a, AyFXLevelComplete3
        call    AFXPlay       

; Pause after completing level and play idle animation
        ld      b, LevelCompFramePause

.CompleteLoop:
        push    bc

        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite
        ld      bc, PlayerIdlePatterns

        call    UpdateSpritePattern             ; Update to death animation

        ld      a, 1                            ; Number of sprites to upload
        call    UploadSpriteAttributes

        call    NextDAW_UpdateSong
        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a
        call    AFXFrame                       ; Keep AYFX sound effect playing
        
        call    WaitForScanlineUnderUla

        pop     bc
        djnz    .CompleteLoop

        ld      a, 0
        ld      (LevelComplete), a      ; Used to allow extra life sound effects

        call    StartNewLevel

        ret


;-------------------------------------------------------------------------------------
; Read NextReg

; Params:
; A = nextreg to read
; Output:
; A = value in nextreg
ReadNextReg:
        push    bc
        ld      bc, $243B   ; TBBLUE_REGISTER_SELECT_P_243B
        out     (c),a
        inc     b       ; bc = TBBLUE_REGISTER_ACCESS_P_253B
        in      a,(c)   ; read desired NextReg state
        pop     bc
        
        ret
