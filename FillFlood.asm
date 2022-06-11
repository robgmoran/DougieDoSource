;-------------------------------------------------------------------------------------
; Fill Flood counters adjacent to player
; 
; Source: TileMapScreen - Only checks top byte within each 4 byte tile i.e. Each tile is 16-pixels x 16-pixels
; Target: FFStorage - Based on source, only stores 1 byte per tile, so (TileMapHeight/2)*(TileMapWidth/2)
; Note: Ensure screen refresh doesn't conflict with routine at top of screen, otherwise incorrect end of line
;       values can be reported 
; Troubleshooting:
; 1. Run and create gaps in map and press F1
; 2. Within Debug Console, type -md FFStorage 320
; 3. Copy content of Debug Console into Notepad (wordwrap enabled)
; 4. Size Notepad to fit 20 pairs of digits onto line
; 5. Replace 99 (63) with --
FillFlood:
; First check whether player at valid position
        call    GetPlayerTilexy         ; Get/Check player tile position
        cp      0
        ret     z                       ; Return if position not valid i.e. Not divisable by 2

; Clear Flood Fill Storage
        ld hl, FFStorage
        ld de, FFStorage+1
        ld bc, (TileMapHeight/2)*(TileMapWidth/2)-1
        ld (hl), 99
        ldir

; Reset Queue
        call    ResetQueue

; Queue first x, y position - Coordinates start from 0, 0
        ld      a, (FFStartxPos)        ; Current player x position
        ld      (FFxPos), a
        ld      d, a
        ld      a, (FFStartyPos)        ; Current player y position
        ld      (FFyPos), a
        ld      e, a
        
        call    EnQueue                 ; Store first x, y position

; Set FF start content to 0
        call    PeekQueue               ; Return - d(x)e(y)
        call    GetFFPosition           ; Return - hl & de = Offset

        ld      iy, FFStorage
        add     iy, de
        ld      (iy), 0

; Process Nodes Loop
.NextNode:
        ld      hl, (QueueStart)
        ld      de, (QueueEnd)
        or      a
        sbc     hl, de
        ret     z                       ; Return if queue empty

; Process Node
        call    DeQueue                 ; Return - d(x)e(y)
        ld      (FFyPos), de

        call    GetFFPosition           ; Return - hl & de = Target Offset

        ld      iy, FFStorage
        add     iy, de
        ld      b, (iy)                 ; Obtain counter for node
        inc     b                       ; Increment counter

.CheckUp:
; Source Node - Does it support Up direction?
        ld      hl, TileMapLocation
        ld      de, (FFSourceOffset)        
        add     hl, de
        ld      ix, hl

        ld      de, FFUPL
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        cp      1
        jr      nz, .CheckRight          ; Jump if doesn't permit Up direction

; Check whether at top of screen
        ld      a, (FFyPos)
        cp      0                       ; Check whether at top
        jr      z, .CheckRight          ; Jump if at top

; Check whether within player offset
        ld      a, (FFStartyPos)
        sub     FFPlayerOffset          ; Subtract FF offset
        ld      c, a
        ld      a, (FFyPos)        
        cp      c
        jr      z, .CheckRight          ; Jump if FFStartyPos-offset (c) = FFyPos (a)

; Target Node Above - Does it already have a value?
        ld      hl, iy
        ld      de, TileMapWidth/2      
        sub     hl, de                  ; Target - Move up 1 x line        
        ld      iy, hl        

        ld      a, (iy)
        cp      99                      ; Target - Check whether a new value has already been stored
        jr      nz, .CheckRight         ; Jump if assigned

; Source Node Above - Is it valid i.e. Is it a full tile that has been entered or a invalid half tile?
        ld      hl, ix
        ld      de, TileMapWidth        
        sub     hl, de                  ; Source - Move up one line
        ld      ix, hl

        ld      de, FFUPL
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get left source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference
        ld      c, a
        push    bc
                
        ld      de, FFUPR
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix+1)               ; Get right source tile
        sub     c                       ; Subtract         
        
        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        pop     bc
        and     c
        cp      1
        jr      nz, .CheckRight          ; Jump if doesn't permit Up direction

; Store new node value
        ld      (iy), b                 ; Target - Store content value 

; Place node onto queue
        ld      a, (FFxPos)
        ld      d, a
        ld      a, (FFyPos)
        dec     a
        dec     a                       ; Move up extra line i.e. Next 16-pixel tile up
        ld      e, a
        call    EnQueue                 ; Store up x, y position

.CheckRight:
; Source Node - Does it support Right direction?
        ld      hl, TileMapLocation
        ld      de, (FFSourceOffset)        
        add     hl, de
        inc     hl                      ; Source - Move right one byte
        ld      ix, hl

        ld      de, FFRPT
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        cp      1
        jr      nz, .CheckDown         ; Jump if doesn't permit Right Direction

; Check whether at right of screen
        ld      a, (FFxPos)
        cp      TileMapMemWidth-2          ; Check whether at far right
        jr      z, .CheckDown

; Check whether within player offset
        ld      c, a
        ld      a, (FFStartxPos)
        add     FFPlayerOffset          ; Add FF offset
        cp      c
        jr      z, .CheckDown           ; Jump if FFxPos (c) = FFStartxPos+offset (a)

; Target Node Right - Does it already have a value?
        ld      iy, FFStorage
        ld      hl, (FFTargetOffset)    ; Restore hl
        inc     hl                      ; Target - Move right one byte
        ex      hl, de
        add     iy, de
        ld      a, (iy)
        cp      99                      ; Target - Check whether a new value has already been stored
        jr      nz, .CheckDown

; Source Node Right - Is it valid i.e. Is it a full tile that has been entered or a invalid half tile?
        inc     ix                      ; Source - Move right one byte

        ld      de, FFRPT
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get top source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference
        ld      c, a
        push    bc

        ld      hl, ix
        ld      de, TileMapWidth
        add     hl, de                  ; Source - Move down one line
        ld      ix, hl

        ld      de, FFRPB
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get bottom source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        pop     bc
        and     c
        cp      1
        jr      nz, .CheckDown         ; Jump if doesn't permit Right direction

; Store new node value
        ld      (iy), b                 ; Target - Store content value 
        
; Place node onto queue
        ld      a, (FFxPos)
        inc     a
        inc     a                       ; Move right extra byte i.e. Next 16-pixel tile right
        ld      d, a
        ld      a, (FFyPos)
        ld      e, a
        call    EnQueue                 ; Store up x, y position

.CheckDown:
; Source Node - Does it support Down direction?
        ld      hl, TileMapLocation
        ld      de, (FFSourceOffset)        
        add     hl, de
        ld      de, TileMapWidth        
        add     hl, de                  ; Source - Move down one line
        ld      ix, hl

        ld      de, FFDPL
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get left source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        cp      1
        jr      nz, .CheckLeft          ; Jump if doesn't permit Down direction

; Check whether at bottom of screen
        ld      a, (FFyPos)
        cp      TileMapMemHeight-2         ; Check whether at bottom
        jr      z, .CheckLeft           ; Jump if at bottom

; Check whether within player offset
        ld      c, a
        ld      a, (FFStartyPos)
        add     FFPlayerOffset          ; Add FF offset
        cp      c
        jr      z, .CheckLeft           ; Jump if FFyPos (c) = FFStartyPos+offset (a)

; Target Node Below - Does it already have a value?
        ld      hl, FFStorage
        ld      de, TileMapWidth/2      
        add     hl, de                  ; Target - Move down 1 x line        
        ld      de, (FFTargetOffset)
        add     hl, de
        ld      iy, hl        

        ld      a, (iy)
        cp      99                      ; Target - Check whether a new value has already been stored
        jr      nz, .CheckLeft         

; Source Node Below - Is it valid i.e. Is it a full tile that has been entered or a invalid half tile?
        ld      hl, ix
        ld      de, TileMapWidth        
        add     hl, de                  ; Source - Move down one line
        ld      ix, hl

        ld      de, FFDPL
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get left source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference
        ld      c, a
        push    bc

        ld      de, FFDPR
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix+1)               ; Get right source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        pop     bc
        and     c
        cp      1
        jr      nz, .CheckLeft          ; Jump if doesn't permit Up direction

; Store new node value
        ld      (iy), b                 ; Target - Store content value 

; Place node onto queue
        ld      a, (FFxPos)
        ld      d, a
        ld      a, (FFyPos)
        inc     a
        inc     a                       ; Move down extra line i.e. Next 16-pixel tile down
        ld      e, a
        call    EnQueue                 ; Store up x, y position

.CheckLeft:
; Source Node - Does it support Left direction?
        ld      hl, TileMapLocation
        ld      de, (FFSourceOffset)        
        add     hl, de
        ld      ix, hl

        ld      de, FFLPT
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        cp      1
        jr      nz, .EndOfCheck         ; Jump if doesn't permit Left Direction

; Check whether at left of screen
        ld      a, (FFxPos)
        cp      0                       ; Check whether at far left
        jr      z, .EndOfCheck

; Check whether within player offset
        ld      a, (FFStartxPos)
        sub     FFPlayerOffset          ; Subtract FF offset
        ld      c, a
        ld      a, (FFxPos)
        cp      c
        jr      z, .EndOfCheck          ; Jump if FFStartxPos-offset (c) = FFxPos (a)

; Target Node Left - Does it already have a value?
        ld      iy, FFStorage
        ld      hl, (FFTargetOffset)    ; Restore hl
        dec     hl                      ; Target - Move left one byte
        ex      hl, de
        add     iy, de
        ld      a, (iy)
        cp      99                      ; Target - Check whether a new value has already been stored
        jr      nz, .EndOfCheck

; Source Node Left - Is it valid i.e. Is it a full tile that has been entered or a invalid half tile?
        dec     ix                      ; Source - Nove left one byte

        ld      de, FFLPT
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get top source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference
        ld      c, a
        push    bc

        ld      hl, ix
        ld      de, TileMapWidth
        add     hl, de                  ; Source - Move down one line
        ld      ix, hl

        ld      de, FFLPB
        ld      a, (LevelTileMapDefOffset)
        ld      c, a                            
        ld      a, (ix)                 ; Get bottom source tile
        sub     c                       ; Subtract         

        add     de, a                   ; Add to FF lookup table
        ld      a, (de)                 ; Get FF lookup table reference

        pop     bc
        and     c
        cp      1
        jr      nz, .EndOfCheck         ; Jump if doesn't permit Left direction

; Store new node value
        ld      (iy), b                 ; Target - Store content value 
        
; Place node onto queue
        ld      a, (FFxPos)
        dec     a
        dec     a                       ; Move right extra byte i.e. Next 16-pixel tile right
        ld      d, a
        ld      a, (FFyPos)
        ld      e, a
        call    EnQueue                 ; Store up x, y position

.EndOfCheck:
        jp      .NextNode

;-------------------------------------------------------------------------------------
; Get/Check Player x, y tilemap coordinates
; Player needs to be at both x and y tilemap coordinates divisable by 2 i.e. start of tile
; Parameters:
; Return Values:
; a = 0 - Don't perform FF, 1 - Perform FF
GetPlayerTilexy:
        ld      iy, PlayerSprite

; 1. Calculate Tile Column (using x position)
        ld      de, (iy+S_SPRITE_TYPE.xPosition)

        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

; Check whether x coordinate divisable by 2 i.e. Valid for checking tile
        ld      a, e
        rra                                     ; Rotate to right through carry - Divide by 2
        jr      c, .NotAtDivisableBy2           ; If carry set then coordinate not directly divisable by 2

        ld      a, e
        ld      (FFStartxPos), a                ; Store valid x coordinate

; 2. Calculate Tile Row (using y Position and tilemap offset y)
        ld      a, (TileMapOffsetY)
        ld      b, a
        ld      a, (iy+S_SPRITE_TYPE.yPosition)
        add     a, b

        ld      d, 0
        ld      e, a

        ld      b, 3    
        bsrl    de, b                           ; Divide by 8 i.e. 3 shifts to the right

; Check whether y coordinate divisable by 2 i.e. Valid for checking tile for FF
        ld      a, e
        rra                                     ; Rotate to right through carry - Divide by 2
        jr      c, .NotAtDivisableBy2           ; If carry set then coordinate not directly divisable by 2
        
        ld      a, e
        ld      (FFStartyPos), a                ; Store valid y coordinate

        ld      a, 1

        ret

.NotAtDivisableBy2:
        ld      a, 0
        ret

GetFFPosition:
; Get FF positions based on tilemap coordinates
; Parameters:
; de = x, y tilemap coordinates; not sprite x, y coordinates
; Return Values:
; hl & de = Target TilePosition
; Calculate Tile Offsets in Memory
        push    de              ; Backup

; Calculate Source Offset
        ld      c, d            ; Obtain column (x)
        
        ld      d, TileMapWidth ; Tilemap width 
        mul     d, e            ; Calculate tile row offset = Tilemap width (d)  * Number of Rows (e)

        ld      a, c            ; Restore tile column
        add     de, a           ; Add tile column to tile row offset 

        ld      (FFSourceOffset), de

; Calculate Target Offset
        pop     de              ; Restore

        ld      c, d            ; Obtain column (x)

        sra     e               ; y / 2
        ld      d, (TileMapWidth)/2
        mul     d, e            ; y * (TileMapWidth/2)

        ld      a, c            ; Restore 
        sra     a               ; x / 2

        add     de, a           ; y + x

        ld      (FFTargetOffset), de

        ld      hl, de

        ret

;-------------------------------------------------------------------------------------
; Reset queue pointers
ResetQueue:
        ld      hl, Queue
        ld      (QueueStart), hl
        ld      (QueueEnd), hl

        ret

;-------------------------------------------------------------------------------------
; Add word to queue
; Parameters:
; - de = Word to store in queue
EnQueue:
        ld      ix, (QueueEnd)
        ld      (ix), de

        inc     ix
        inc     ix
        ld      (QueueEnd), ix

        ret

;-------------------------------------------------------------------------------------
; Remove word from queue
; Return Values:
; de = Word removed from Queue
DeQueue:
        ld      ix, (QueueStart)
        ld      de, (ix)
        ld      bc, $0000
        ld      (ix), bc

        inc     ix
        inc     ix

        ld      (QueueStart), ix

        ret

;-------------------------------------------------------------------------------------
; Peek next word in queue
; Return Values:
; de = Next word in Queue
PeekQueue:
        ld      ix, (QueueStart)
        ld      de, (ix)

        ret