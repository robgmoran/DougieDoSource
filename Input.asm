;-------------------------------------------------------------------------------------
; Read Input Devices - Intro Screen
; Return Values:
; a = Intro Screen Status - 0 = No change, 1 = Change
ReadIntroInput:
        ld      bc, $7ffe               ; Reference for keys Space, Sym, M, N, B
	in      a, (c)     
        bit     0, a                    ; Bit 0 = Space
        jr      z, .StartGame           ; Jump if Space pressed

        in      a, (KEMPSTON_JOY1_P_1F)
        ld      e, a                    ; E = the Kempston/MD joystick inputs (---FUDLR)
        bit     4, e
        jr      nz, .StartGame          ; Jump if fire pressed

        ld      bc, $fefe               ; Reference for keys Shift, Z, X, C, V
	in      a, (c)     
        bit     3, a                    ; Bit 3 = C
        jr      z, .DisplayCredits      ; Jump if C pressed

        ld      bc, $dffe               ; Reference for keys P, O, I, Y
	in      a, (c)     
        bit     2, a                    ; Bit 2 = I
        jr      z, .DisplayInstr        ; Jump if I pressed

        jr      .NoChange
        
.StartGame:
        ld      a, 0
        ld      (IntroStatus), a
        jr      .Change
        
.DisplayCredits:
        ld      a, (IntroStatus)
        cp      1
        jr      z, .NoChange

        ld      a, 1
        ld      (IntroStatus), a
        jr      .Change

.DisplayInstr:
        ld      a, (IntroStatus)
        cp      2
        jr      z, .NoChange

        ld      a, 2
        ld      (IntroStatus), a

.Change:
        ld      a, 1
        ret

.NoChange:
        ld      a, 0
        ret

;-------------------------------------------------------------------------------------
; Flash Paused Text 
; Params:
FlashPausedText:
        ld      a, (PausedFlashCt)
        cp      0
        jr      nz, .DisplayPauseText   ; Jump if pause text counter not zero i.e. Don't change pause text status

        ld      a, (PausedFlashSt)
        cp      0
        jr      z, .SetPauseFlashSt     ; Jump if need to display Pause text

        ; Remove Pause text
        dec     a
        ld      (PausedFlashSt), a

        ld      a, PausedFlashInt
        ld      (PausedFlashCt), a      ; Reset Pause flash counter

        ld      ix, PausedTextOff       ; Text to display suffixed by 255
        jr      .Display

        ; Display Pause text
.SetPauseFlashSt:
        inc     a
        ld      (PausedFlashSt), a        

        ld      a, PausedFlashInt
        ld      (PausedFlashCt), a      ; Reset Pause flash counter

        ld      ix, PausedTextOn        ; Text to display suffixed by 255
        jr      .Display

; Display Pause Text
.DisplayPauseText:
        ; Check status of Pause text
        ld      a, (PausedFlashSt)
        cp      0
        jr      nz, .PausedTextOn       ; Jump if Pause text should be displayed

        ld      ix, PausedTextOff       ; Text to display suffixed by 255
        jr      .Display

.PausedTextOn:
        ld      ix, PausedTextOn        ; Text to display suffixed by 255

.Display:
        ld      e, PausedTextX          ; x = 0-31
        ld      d, LevelHUDY            ; y = 0-23
        call    PrintTileString

; Decrement Start Text Flash
        ld      a, (PausedFlashCt)
        dec     a
        ld      (PausedFlashCt), a

        ret

;-------------------------------------------------------------------------------------
; Read Input Devices - Game
ReadPlayerInput:
; Check delay before pause can be pressed
        ld      a, (PausedCounter)
        cp      0
        jr      nz, .Decrement

; Check whether pause key pressed
        ld      bc, $bffe               ; Reference for keys Enter, L, K, J, H
	in      a, (c)     
        bit     0, a                    ; Bit 0 = Enter
        jr      nz, .CheckPaused        ; Jump if enter not pressed

        ld      a, (PausedFrames)
        ld      (PausedCounter), a      ; Reset pause counter

; Toggle pause status
        ld      a, (Paused)
        cp      1
        jr      z, .Unpause             ; Jump if game already pause i.e. Unpause game

        ld      a, 1
        ld      (Paused), a             ; Pause game

; Display Pause Text
        ld      a, 0
        ld      (PausedFlashCt), a      ; Reset pause flash counter to enable flash to start

        ret

.Unpause:
        ld      a, 0
        ld      (Paused), a             ; Unpause game

; Redisplay Level Number
        ld      ix, PausedTextOff       ; Text to display suffixed by 255
        ld      e, PausedTextX          ; x = 0-31
        ld      d, LevelHUDY            ; y = 0-23
        call    PrintTileString

        ld      ix, LevelHUD            ; Text to display suffixed by 255
        ld      e, LevelHUDX            ; x = 0-31
        ld      d, LevelHUDY            ; y = 0-23
        call    PrintTileString
        call    DisplayHUDLevelValue
        
        jr      .BypassCheck

.Decrement:
        dec     a
        ld      (PausedCounter), a

.CheckPaused:
        ld      a, (Paused)
        cp      1
        jp      z,  FlashPausedText     ; Jump if game paused

.BypassCheck:
; Read Kempston port first, will also clear the inputs
        in      a,(KEMPSTON_JOY1_P_1F)
        ld      e,a             ; E = the Kempston/MD joystick inputs (---FUDLR)

; Mix the joystick inputs with OPQA<space>
        ld      d,$FF           ; keyboard reading bits are 1=released, 0=pressed -> $FF = no key
; Check eighth row of matrix (<space><symbol shift>MNB) - FIRE
        ld      a,~(1<<7)       ; Rotate 1 to the left 7 times and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (space) into Fcarry
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (space) into d (bit 0)
; Check third row of matrix (QWERT) - UP
        ld      a,~(1<<2)       ; Rotate 1 to the left 2 times and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (q) into Fcarry
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (q) into d (bit 0)
; Check second row of matrix (ASDFG) - DOWN
        ld      a,~(1<<1)       ; Rotate 1 to the left 1 time and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (a) into Fcarry
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (a) into d (bit 0)
; Check sixth row of matrix (POIUY) - LEFT
        ld      a,~(1<<5)       ; Rotate 1 to the left 5 times and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rra                     ; Rotate bit 0 (p) into Fcarry
        rra                     ; Rotate bit 0 (o) into Fcarry and Fcarry (p) into bit 7
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (o) into d (bit 0)
        rla                     ; Rotate bit 7 (p) into Fcarry

        ld      a,d
        rla                     ; Store result - Rotate a left including rotation of Fcarry (p) into a (bit 0) - Now a = ---FUDLR

; Combine keyboard and joystick input
        cpl                     ; a is inverted i.e If key pressed, bit stored as 0; now invert the readings, now 1 = pressed, 0 = no key
        or      e               ; mix the keyboard and joystick readings together i.e. Keyboard (---FUDLR) and joystick (---FUDLR)
        ld      (PlayerInput),a ; store the combined player input
        
        ret

;-------------------------------------------------------------------------------------
; Update Player Based on Input
CheckPlayerInput:
        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite

        ld      a, 0
        ld      (PlayerMoved), a                ; Reset flag - Used to ensure player only moves once during routine

; If no player input then check idle animation
        ld      a, (PlayerInput)
        ld      (NotIdle), a
        cp      0
        jp      z, .EndOfInput

; Otherwise process player input
.CheckPlayerRight:
        ld      a, (PlayerInput)
        and     %00000001               
        jp      z, .CheckPlayerLeft

; If already travelling left/right - Permit right travel
        ld      a, %00000011
        cp      (iy+S_SPRITE_TYPE.Movement)
        jr      nc, .ContinueRight

; Not travelling left/right, so check whether we can now move right 
        ld      de, (iy+S_SPRITE_TYPE.yPosition)
        call    CheckDivisableBy16

        cp      1
        jr      z, .ContinueRight               ; Jump if divisable

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
        ld      l, (ix+S_SPRITE_ATTR.x)         ; hl = 9-bit x value
        ld      de, hl
        
; Condition 1 - Check whether the player hit a rock and is restricted from moving right
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     0, a
        jr      z, .ContRight                   ; Jump if we're not restricted

; Rock hit - Check whether the rock can move to the right
        push    ix, iy
        ld      hl, (iy+S_SPRITE_TYPE.SprCollision); Obtain rock sprite location
        ld      iy, hl
        
        bit     4, (iy+S_SPRITE_TYPE.SpriteType1)
        call    z, MoveRockRight                ; Call if rock not moving

        pop     iy, ix

        ld      a, 2
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Switch player to left
        jp      .CheckPlayerDown

.ContRight:
; Condition 2 - Check whether right screen limit reached
        or      a                               ; Clear carry flag
        ld      bc, (SpriteMaxRight)
        sbc     hl, bc
        jp      nc, .CheckPlayerDown            ; Jump if hl >= SpriteMaxRight

; Condition 3 - Check tile collision
        push    de
        call    CheckTilesToRight               ; Output - a=0 Don't move, a=1 Move
        pop     de
        cp      a, 0
        jp      z, .CheckPlayerFire             ; Jump if cannot move

; OK to move - Update x value and sprite attributes
        ld      (iy+S_SPRITE_TYPE.Movement), 1  ; Set player movement flag to right

        ld      a, 1
        ld      (PlayerMoved), a                ; Set movement flag to ensure player only moved once

        ex      hl, de
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
        
.RightUpdateAnimation:
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern             ; Update animation
        
        jp      .CheckPlayerFire

.RightSetmrx8
        ; Update sprite attributes
        set     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9
        res     3, (ix+S_SPRITE_ATTR.mrx8)      ; Don't horizontally mirror sprite

        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern             ; Update animation

        jp      .CheckPlayerDown

.CheckPlayerLeft
        ld      a, (PlayerInput)
        and     %00000010
        jp      z, .CheckPlayerDown

; If already travelling left/right - Permit left travel
        ld      a, %00000011
        cp      (iy+S_SPRITE_TYPE.Movement)
        jr      nc, .ContinueLeft

; Not travelling left/right, so check whether we can now move left 
        ld      de, (iy+S_SPRITE_TYPE.yPosition)
        call    CheckDivisableBy16

        cp      1
        jr      z, .ContinueLeft                ; Jump if divisable

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
        ld      l, (ix+S_SPRITE_ATTR.x)         ; hl = 9-bit x value
        ld      bc, hl
        
; Condition 1 - Check whether player is permitted to move left
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     1, a
        jr      z, .ContLeft                    ; Jump if we're not restricted

; Rock hit - Check whether the rock and thus the player can move to the Left
        push    ix, iy
        
        ld      hl, (iy+S_SPRITE_TYPE.SprCollision); Obtain rock sprite location
        ld      iy, hl
        
        bit     4, (iy+S_SPRITE_TYPE.SpriteType1)
        call    z, MoveRockLeft                ; Call if rock not moving

        pop     iy, ix

        ld      a, 1
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Otherwise switch to right
        jp      .CheckPlayerDown

.ContLeft:
; Condition 2 - Check whether left screen limit reached
        or      a                               ; Clear carry flag
        ld      de, (SpriteMaxLeft)
        ex      hl, de
        sbc     hl, de
        jr      nc, .CheckPlayerDown            ; Jump if SpriteMaxLeft >= de

; Condition 3 - Check tile collision
        push    bc
        call    CheckTilesToLeft               ; Output - a=0 Don't move, a=1 Move
        pop     bc
        cp      a, 0
        jp      z, .CheckPlayerFire            ; Jump if cannot move

; OK to move - Update x value and sprite attributes
        ld      (iy+S_SPRITE_TYPE.Movement), 2  ; Set player movement flag to left

        ld      a, 1
        ld      (PlayerMoved), a                ; Set movement flag to ensure player only moved once

        ld      hl, bc 
        dec     hl
        
        ld      (ix+S_SPRITE_ATTR.x), l         ; Store bits 0-8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl; Store 9-bit value

        or      a                               ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .LeftSetmrx8                ; Setmrx8 if hl >=256

        ; Update sprite attributes
        res     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9
        set     3, (ix+S_SPRITE_ATTR.mrx8)      ; Horizontally mirror sprite
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern             ; Update animation

        jp      .CheckPlayerFire

.LeftSetmrx8
        ; Update sprite attributes
        set     0, (ix+S_SPRITE_ATTR.mrx8)      ; Store bit 9
        set     3, (ix+S_SPRITE_ATTR.mrx8)      ; Horizontally mirror sprite
        ld      bc, (iy+S_SPRITE_TYPE.animationHor)
        call    UpdateSpritePattern             ; Update animation

.CheckPlayerDown
        ld      a, (PlayerInput)
        and     %00000100
        jp      z, .CheckPlayerUp

; If already travelling up/down - Permit down travel
        bit     2, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .ContinueDown 

        bit     3, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .ContinueDown 

; Not travelling up/down, so check whether we can now move down 
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        call    CheckDivisableBy16
        cp      1
        jr      z, .ContinueDown                ; Jump if divisable

; Not at correct position, so continue travelling in current direction
        ld      a, (PlayerMoved)
        cp      1
        jp      z, .CheckPlayerFire             ; Jump if the player has already moved

; Check for situation where player could be surrounded by rocks i.e. Collision left+Right
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        cp      3
        jp      z, .CheckPlayerFire

; Otherwise check movement and jump to appropriate routine
        ld      a, 1
        cp      (iy+S_SPRITE_TYPE.Movement)
        jp      z, .ContinueRight

        jp      .ContinueLeft

.ContinueDown
; Condition 1 - Check whether player is permitted to move down
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     2, a
        jr      z, .ContDown                    ; Jump if we're not restricted

        ld      a, 8
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Otherwise switch to up
        jp      .CheckPlayerFire

.ContDown:
; Condition 2 - Check whether bottom of screen limit reached
        or      a                               ; Clear carry flag
        ld      a, (SpriteMaxDown)
        ld      b, a
        ld      a, (ix+S_SPRITE_ATTR.y)

        sbc     a, b
        jp      nc, .CheckPlayerFire            ; Jump if a >= SpriteMaxDown

; Condition 3 - Check tile collision
        call    CheckTilesBelow                 ; Output - a=0 Don't move, a=1 Move
        cp      a, 0
        jp      z, .CheckPlayerFire             ; Jump if cannot move

; OK to move - Update x value and sprite attributes
        ld      (iy+S_SPRITE_TYPE.Movement), 4  ; Set player movement flag to down

        ld      a, (PlayerSprAtt+S_SPRITE_ATTR.y)
        inc     a
        ld      (PlayerSprAtt+S_SPRITE_ATTR.y), a
        ld      (iy+S_SPRITE_TYPE.yPosition), a ; Store 8-bit value

.DownUpdateAnimation
        ld      bc, (iy+S_SPRITE_TYPE.animationVer)
        call    UpdateSpritePattern             ; Update animation

        jr      .CheckPlayerFire

.CheckPlayerUp
        ld      a, (PlayerInput)
        and     %00001000               
        jp      z, .CheckPlayerFire

; If already travelling up/down - Permit up travel
        bit     2, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .ContinueUp 

        bit     3, (iy+S_SPRITE_TYPE.Movement)
        jr      nz, .ContinueUp

; Not travelling up/down, so check whether we can now move up
        ld      de, (iy+S_SPRITE_TYPE.xPosition)
        call    CheckDivisableBy16

        cp      1
        jr      z, .ContinueUp                  ; Jump if divisable

; Not at correct position, so continue travelling in current direction
        ld      a, (PlayerMoved)
        cp      1
        jp      z, .CheckPlayerFire             ; Jump if the player has already moved

; Check for situation where player could be surrounded by rocks i.e. Collision left+Right
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        cp      3
        jr      z, .CheckPlayerFire

; Otherwise check movement and jump to appropriate routine
        ld      a, 1
        cp      (iy+S_SPRITE_TYPE.Movement)
        jp      z, .ContinueRight

        jp      .ContinueLeft

.ContinueUp
; Condition 1 - Check whether player is permitted to move up
        ld      a, (iy+S_SPRITE_TYPE.SprContactSide)
        bit     3, a
        jr      z, .ContUp                      ; Jump if we're not restricted

        ld      a, 4
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Otherwise switch to down
        jr      .CheckPlayerFire

.ContUp:
; Condition 2 - Check whether top of screen limit reached
        or      a                               ; Clear carry flag
        ld      a, (SpriteMaxUp)
        ld      b, (ix+S_SPRITE_ATTR.y)

        sbc     a, b
        jr      nc, .CheckPlayerFire            ; Jump if SpriteMaxUp >= b

; Condition 3 - Check tile collision
        call    CheckTilesAbove                 ; Output - a=0 Don't move, a=1 Move
        cp      a, 0
        jr      z, .CheckPlayerFire             ; Jump if cannot move

; OK to move - Update x value and sprite attributes
        ld      (iy+S_SPRITE_TYPE.Movement), 8  ; Set player movement flag to up

        ld      a, (PlayerSprAtt+S_SPRITE_ATTR.y)
        dec     a
        ld      (PlayerSprAtt+S_SPRITE_ATTR.y), a
        ld      (iy+S_SPRITE_TYPE.yPosition), a ; Store 8-bit value

.UpUpdateAnimation:
        ld      bc, (iy+S_SPRITE_TYPE.animationVer)
        call    UpdateSpritePattern             ; Update animation

.CheckPlayerFire
        ld      a, (PlayerInput)
        and     %00010000               
        jp      z, .EndOfInput

; Bomb Check 1 - Check whether a bomb has already been dropped
        ld      a, (BombDropped)
        cp      1
        jr      z, .EndOfInput                  ; Jump if bomb already dropped

 ; Bomb Check 2 - Check whether player has any bombs
        ld      a, (Bombs)
        cp      0
        jr      z, .EndOfInput                  ; Jump if player has no bombs

        ld      a, (Bombs)
        dec     a       
        ld      (Bombs), a             ; Decrement number of bombs
        
        push    af, bc, de, hl, ix
        ld      a, AyFXDropBomb
        call    AFXPlay 
        pop     ix, hl, de, bc, af


        call    DisplayHUDBombValue
        
        ;ld      a, %0000'1010                   ; Background colour'Foreground colour
        ;call    ChangeBombHUDColour

        call    DropBomb

.EndOfInput
; Check whether idle animation should be played
.ContAnimate:   ; Disabled idle animation check
        ;;ld      a, (NotIdle)
        ;;cp      0
        ;;jr      z, .StartIdleCheck              ; Jump if no player input processed

        ;;ld      bc, 0
        ;;ld      (IdleFrameCount), bc            ; Otherwise reset idle frame counter
        ret

/*
.StartIdleCheck:
        ld      bc, (IdleFrameCount)
        ld      hl, 0
        sbc     hl, bc                          ; Check idle frame counter
        jr      nz, .CheckIdleAnimation         ; Jump if IdleFrameCount (hl) > 0

        ld      bc, 1
        ld      (IdleFrameCount), bc            ; Otherwise start idle frame counter
        ret

.CheckIdleAnimation
        or      a                               ; Clear carry flag
        ld      hl, (IdleFrameCount)
        ld      bc, IdleFrameStart
        sbc     hl, bc        
        jr      nc, .StartIdleAnimation         ; Jump if IdleFrameCount (hl) >= IdleFrameStart

        ret                                     ; Otherwise return; IdleFrameCount updated in WaitForScanlineUnderUla 

.StartIdleAnimation
        ld      bc, PlayerIdlePatterns
        call    UpdateSpritePattern             ; Update animation

        ret
*/