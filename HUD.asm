;-------------------------------------------------------------------------------------
; Update Score
; Params:
; iy = Points to add e.g. "100"
; b = Points length e.g. 3
UpdateScore:
        ld      a, ScoreLength
        sub     b
        ld      hl, Score
        add     hl, a           ; Score starting pointer offset
        
.ScoreLoop:
        ld      a, (iy)         ; Get points digit
        cp      48
        jr      z, .ContinueLoop        ; Jump if digit 0

        sub     48              ; Subtract "0" to convert to digit              
        ld      d, b            ; Save register
        ld      b, a            ; Value to add to score
        call    UpdateTileTextValue

        ld      b, d            ; Restore register

.ContinueLoop:
        inc     hl              ; Increment score pointer
        inc     iy              ; Increment points pointer
        djnz    UpdateScore

        call    CheckTopScore

        ret

UpdateTileTextValue:
        ld a,(hl)           ; current value of digit.

        add a,b             ; add points to this digit.
        ld (hl),a           ; place new digit back in string.
        cp 58               ; more than ASCII value '9'?
        ret c               ; no - relax.
        sub 10              ; subtract 10.
        ld (hl),a           ; put new character back in string.
uval0:
        dec hl              ; previous character in string.
        inc (hl)            ; up this by one.
        ld a,(hl)           ; what's the new value?

        cp 58               ; gone past ASCII nine?
        ret c               ; no, scoring done.
        sub 10              ; down by ten.
        ld (hl),a           ; put it back
        jp uval0           ; go round again.


;-------------------------------------------------------------------------------------
; Check for new top score
; Params:
CheckTopScore:
        ld      ix, Score
        ld      iy, TopScore

        ld      b, ScoreLength
.DigitLoop:
        ld      a, (ix)
        ld      b, (iy)
        cp      b
        ret     c                       ; Return if TopScore digit > Score digit

        jr      nz, .NewTopScore        ; Jump if TopScore digit != Score Digit

.NextDigit:
        inc     ix                      ; Point to next score digit
        inc     iy                      ; Point to next top score digit
        djnz    .DigitLoop

        ret

; Copy new score to top score
.NewTopScore
        ld      hl, Score
        ld      de, TopScore
        ld      b, 0
        ld      c, ScoreLength
        ldir

        ret


;-------------------------------------------------------------------------------------
; Check whether extra life should be awarded
; Params:
; de = Points awarded to player
CheckExtraLife:
        ld      hl, (ExtraLifeCounter)
        add     hl, de
        ld      (ExtraLifeCounter), hl    

        or      a
        ld      de, ScoreExtraLife
        sbc     hl, de
        ret     c                       ; Return if player has not got enough points

; Increase lives
        ld      (ExtraLifeCounter), hl  ; Store updated counter for next check

        ld      a, (LevelComplete)
        cp      1
        jr      z, .PostSoundEffect     ; Jump if level complete i.e. Don't play extra life sound effect

        push    af, bc, de, hl, ix
        ld      a, AyFXExtraLife1
        call    AFXPlay 
        ld      a, AyFXExtraLife2
        call    AFXPlay 
        ld      a, AyFXExtraLife3
        call    AFXPlay 
        pop     ix, hl, de, bc, af

.PostSoundEffect:
        ld      a, (Lives)
        inc     a
        ld      (Lives), a              ; Add extra life
        
        call    DisplayHUDLivesValue

        ret

/*
;-------------------------------------------------------------------------------------
; Increase Tile Text by 1 - Used to update 2 x digit text only
; Params:
; iy = Tile Text to update ( 2 x digits)
IncreaseTileText:
        ld      hl, iy
        inc     hl              ; Point to right-most digit

        ld      b, 1            ; Value to add to score (1)
        call    UpdateTileTextValue

        ret
*/

;-------------------------------------------------------------------------------------
; Convert integer to string - Used to update 2 x digit text only
; Ref: http://map.grauw.nl/sources/external/z80bits.html
; Params:
; a = Integer
; de = Memory to store string - 2 x digits followed by 0
ConvertIntToString:
        ld      h, 0
        ld      l, a
        ;ld      hl, 10
	;ld	bc,-10000
	;call	Num1
	;ld	bc,-1000
	;call	Num1
	;ld	bc,-100
	;call	Num1
        ld      b, $ff
        ld	c,-10
	call	Num1
	ld	c,b

Num1	ld	a,'0'-1
Num2	inc	a
	add	hl,bc
	jr	c,Num2
	sbc	hl,bc

	ld	(de),a
	inc	de
	ret

;-------------------------------------------------------------------------------------
; Display HUD Text
; Params:
DisplayHUDText:
; - Level Number
        ld      ix, LevelHUD                    ; Text to display suffixed by 255
        ld      e, LevelHUDX                    ; x = 0-31
        ld      d, LevelHUDY                         ; y = 0-23
        call    PrintTileString
        call    DisplayHUDLevelValue

; - Hi-Score
        ld      ix, TopScoreHUD                 ; Text to display suffixed by 255
        ld      e, TopScoreHUDX                 ; x = 0-31
        ld      d, TopScoreHUDY                 ; y = 0-23
        call    PrintTileString

; - Score
        ld      ix, ScoreHUD                    ; Text to display suffixed by 255
        ld      e, ScoreHUDX                    ; x = 0-31
        ld      d, ScoreHUDY                    ; y = 0-23
        call    PrintTileString
        call    DisplayHUDScoreValues

; - Lives
        ld      ix, LivesHUD                    ; Text to display suffixed by 255
        ld      e, LivesHUDX                    ; x = 0-31
        ld      d, LivesHUDY                    ; y = 0-23
        call    PrintTileString
        call    DisplayHUDLivesValue

; - Bombs
        ld      ix, BombHUD                     ; Text to display suffixed by 255
        ld      e, BombHUDX                     ; x = 0-31
        ld      d, BombHUDY                     ; y = 0-23
        call    PrintTileString
        call    DisplayHUDBombValue

        ret

;-------------------------------------------------------------------------------------
; Display HUD Level Value
; Params:
DisplayHUDLevelValue:
; Display Level Number
        ld      a, (LevelNumber)
        ld      de, TileTemp
        call    ConvertIntToString
        ld      ix, TileTemp                    ; Text to display suffixed by 255
        ld      e, LevelX                       ; x = 0-31
        ld      d, LevelY                       ; y = 0-23
        call    PrintTileString

        ret

;-------------------------------------------------------------------------------------
; Display HUD Score Values
; Params:
DisplayHUDScoreValues:
; Display Top Score
        ld      ix, TopScore                    ; Text to display suffixed by 255
        ld      e, TopScoreX                    ; x = 0-31
        ld      d, TopScoreY                    ; y = 0-23
        call    PrintTileString

; Display Score
        ld      ix, Score                       ; Text to display suffixed by 255
        ld      e, ScoreX                       ; x = 0-31
        ld      d, ScoreY                       ; y = 0-23
        call    PrintTileString

        ret

;-------------------------------------------------------------------------------------
; Display HUD Lives Value
; Params:
DisplayHUDLivesValue:
; Display Lives
        ld      a, (Lives)
        ld      de, TileTemp
        call    ConvertIntToString
        ld      ix, TileTemp                    ; Text to display suffixed by 255
        ld      e, LivesX                       ; x = 0-31
        ld      d, LivesY                       ; y = 0-23
        call    PrintTileString

;-------------------------------------------------------------------------------------
; Display HUD Bomb Values
; Params:
DisplayHUDBombValue:
; Display Bombs
        ld      a, (Bombs)
        ld      de, TileTemp
        call    ConvertIntToString
        ld      ix, TileTemp            ; Text to display suffixed by 255
        ld      e, BombsX               ; x = 0-31
        ld      d, BombsY               ; y = 0-23
        call    PrintTileString

        ret

/*
;-------------------------------------------------------------------------------------
; Uddate HUD Elements - Score, Bomb, Lives
UpdateHUD:

; Update Score

; Update Bomb
        xor     a
        ld      hl, (BombDropCounter)
        ld      de, 0
        sbc     hl, de
        jr      nz, .UpdateLives        ; Jump if bomb drop counter not 0

        ld      a, %0000'1100           ; Background colour'Foreground colour
        call    ChangeBombHUDColour

.UpdateLives:
; Update Lives

        ret
*/
/*
;-------------------------------------------------------------------------------------
; Change colour of Bomb HUD text
; Params:
; a = Colour - %bbbb'ffff - Background/Foregound
ChangeBombHUDColour:
        ld      hl, BombPos
        ld      b, 4
BombColorLoop:        
        ld      (hl), a         ; Background colour'Foreground colour
        inc     hl
        djnz    BombColorLoop

        ret
*/

