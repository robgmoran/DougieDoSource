;-------------------------------------------------------------------------------------
; Scroll Layer 2 - 256 x 192 Based on Player Input
ScrollL2:
; Scroll down based on player up
        ld      a, (PlayerInput)
        bit     3, a
        jr      z, .CheckDown

        ld      a, (L2OffsetY)
        dec     a
        cp      255
        jr      nz, .UpdateL2Y

        ld      a, (L2Height)-1
        jr      .UpdateL2Y

; Scroll up based on player down
.CheckDown
        ld      a, (PlayerInput)
        bit     2, a
        jr      z, .CheckLeft

        ld      a, (L2OffsetY)
        inc     a
        cp      L2Height
        jr      nz, .UpdateL2Y
        
        ld      a, 0

.UpdateL2Y
        nextreg $17,a
        ld      (L2OffsetY), a

; Scroll right based on player Left
.CheckLeft:
        ld      a, (PlayerInput)
        bit     1, a
        jr      z, .CheckRight

        ld      a, (L2OffsetX)
        dec     a
        jr      .UpdateL2X

; Scroll left based on player right
.CheckRight:
        ld      a, (PlayerInput)
        bit     0, a
        ret     z

        ld      a, (L2OffsetX)
        inc     a

.UpdateL2X
        nextreg $16, a
        ld      (L2OffsetX), a

        ret


; Configure Tile Offset
; TILEMAP OFFSET X MSB Register
        nextreg $2f,%000000'00          ; Offset 0 
; TILEMAP OFFSET X LSB Register
        nextreg $30,%00000000           ; Offset 0
; TILEMAP OFFSET Y Register
        nextreg $31,%00000000           ; Offset 0


;-------------------------------------------------------------------------------------
; Scroll Tilemap - 40 x 32 Based on Player Input
ScrollTileMap:
; Scroll down based on player up
        ld      a, (PlayerInput)
        bit     3, a
        jr      z, .CheckDown

        ld      ix, PlayerSprite
        ld      a, (ix+S_SPRITE_TYPE.Movement)
        bit     3, a
        jr      z, .CheckDown 

        ld      a, (TileMapOffsetY)
        dec     a
        jr      .UpdateTileMapY

; Scroll up based on player down
.CheckDown
        ld      a, (PlayerInput)
        bit     2, a
        jr      z, .CheckLeft

        ld      ix, PlayerSprite
        ld      a, (ix+S_SPRITE_TYPE.Movement)
        bit     2, a
        jr      z, .CheckLeft 

        ld      a, (TileMapOffsetY)
        inc     a

.UpdateTileMapY
        nextreg $31,a
        ld      (TileMapOffsetY), a

; Scroll right based on player Left
.CheckLeft:
/*        ld      a, (PlayerInput)
        bit     1, a
        jr      z, .CheckRight

        ld      a, (L2OffsetX)
        dec     a
        jr      .UpdateL2X

; Scroll left based on player right
.CheckRight:
        ld      a, (PlayerInput)
        bit     0, a
        ret     z

        ld      a, (L2OffsetX)
        inc     a

.UpdateL2X
        nextreg $16, a
        ld      (L2OffsetX), a
*/
        ret

ScrollTileMap2:
; First check whether we can scroll
        ld      a, (TileMapScroll)
        cp      1
        ret     nz                              ; Return if we can't scroll

; Check direction to scroll
        ld      a, (PlayerInput)
        bit     3, a
        jr      nz, .ScrollUp

        bit     2, a
        jr      nz, .ScrollDown

        ret

.ScrollUp
; Check whether the player is permitted to move up
        ld      iy, PlayerSprite
        bit     3, (iy+S_SPRITE_TYPE.Movement)
        ret     z

; Check whether we've reached the start of the tilemap data
        ld      hl, (TileMapSourceOffset)
        ld      bc, 0
        xor     a
        sbc     hl, bc                  
        ret     z                               ; Return if start reached

; Check whether we previously moved up
        ld      a, (TileMapScrollDir)
        cp      1
        jr      z, .ScrollUpCont                ; Jump if previously moved up

; Point to new Tilemap source
        ld      hl, (TileMapSourceOffset)
        ld      bc, TileMapWidth*TileMapHeight
        xor     a
        sbc     hl, bc                          ; Otherwise subtract tilemap data size to point to start of currently displayed tilemap screen data
        ld      (TileMapSourceOffset), hl

; Change direction
        ld      a, 1
        ld      (TileMapScrollDir), a

        jr      .ScrollUp

.ScrollUpCont:
; Check whether we should update the tilemap scroll offset
        ld      a, (TileMapOffsetY)
        cp      0-7
        jr      z, .CopyTileMapDown             ; Jump if we now need to copy the tilemap data

.ScrollUpCont2:
        dec     a
        ld      (TileMapOffsetY),a              ; Otherwise update the tilemap scroll offset

        nextreg $31, a                          ; TILEMAP OFFSET Y Register
        ret

.CopyTileMapDown:
; Reset Tilemap scroll offset
        ld      a, 0
        ld      (TileMapOffsetY), a             
        nextreg $31, a                          ; TILEMAP OFFSET Y Register

; Copy tilemap data down
        ld      hl, TileMapLocation+(TileMapWidth*(TileMapHeight-1))-1  ; Source line
        ld      de, TileMapLocation+(TileMapWidth*TileMapHeight)-1      ; Destination line
        ld      bc, TileMapWidth*(TileMapHeight-1)                      ; Copy all lines-1                                             
        lddr

; Copy new tilemap data to the top
        ld      hl, TileMapStart
        ld      bc, (TileMapSourceOffset)
        add     hl, bc                                  ; Source tilemap data
        dec     hl                                      ; Point to previous tile in tilemap data
        ld      de, TileMapLocation+TileMapWidth-1      ; Destination line
        ld      bc, TileMapWidth
        lddr

; Update tilemap source offset to point to next line of source data
        ld      hl, (TileMapSourceOffset)
        ld      de, TileMapWidth
        xor     a
        sbc     hl, de
        ld      (TileMapSourceOffset), hl

        ret

.ScrollDown
; Check whether the player is permitted to move down
        ld      iy, PlayerSprite
        bit     2, (iy+S_SPRITE_TYPE.Movement)
        ret     z

; Check whether we've reached the end of the tilemap data
        ld      hl, TileMapLevel1End-TileMapStart
        ld      bc, (TileMapSourceOffset)
        xor     a
        sbc     hl, bc                  
        ret     z                                       ; Return if end reached

; Check whether we previously moved down
        ld      a, (TileMapScrollDir)
        cp      2
        jr      z, .ScrollDownCont                      ; Jump if previously moved down

; Point to new Tilemap source
        ld      hl, (TileMapSourceOffset)
        ld      bc, TileMapWidth*TileMapHeight
        add     hl, bc
        ld      (TileMapSourceOffset), hl               ; Otherwise configure tilemap source to point to next tilemap screen data

; Change direction
        ld      a, 2
        ld      (TileMapScrollDir), a

        jr      .ScrollDown

.ScrollDownCont        
; Check whether we should update the tilemap scroll offset
        ld      a, (TileMapOffsetY)
        cp      7
        jr      z, .CopyTileMapUp                       ; Jump if we now need to copy the tilemap data

        inc     a
        ld      (TileMapOffsetY),a                      ; Otherwise update the tilemap scroll offset

        nextreg $31, a                                  ; TILEMAP OFFSET Y Register
        ret
        
.CopyTileMapUp:
; Reset Tilemap scroll offset
        ld      a, 0
        ld      (TileMapOffsetY), a             
        nextreg $31, a                                  ; TILEMAP OFFSET Y Register

; Copy tilemap data up
        ld      hl, TileMapLocation+40                  ; Source line
        ld      de, TileMapLocation                     ; Destination line
        ld      bc, TileMapWidth*(TileMapHeight-1)      ; Copy all lines-1                                             
        ldir
        
; Copy new tilemap data to the bottom
        ld      hl, TileMapStart                        
        ld      bc, (TileMapSourceOffset)
        add     hl, bc                                  ; Source tilemap data
        ld      bc, TileMapWidth
        ldir

; Update tilemap source offset to point to next line of source data
        ld      hl, (TileMapSourceOffset)
        add     hl, TileMapWidth
        ld      (TileMapSourceOffset), hl

        ret

