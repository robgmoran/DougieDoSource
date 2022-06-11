SetupTileMap:
;-------------------------------------------------------------------------------------
; Setup Tilemap Configuration
; TILEMAP CONTROL Register
        ld      a, %1'0'1'0'0'0'0'1     ; Enable tilemap, 40x32, no attributes, primary pal, 256 mode, ULA over tilemap (can be overidden by tile attribute)
        nextreg $6b, a

;-------------------------------------------------------------------------------------
; Configure Memory Locations
; ULA screen and Tilemaps share 16KB Bank 5
; - $4000 - $5800 - ULA Bitmap Data
; - $5800 - $5b00 - ULA Colour Attribute Data
; - $5b00 - $6000 - Tilemap
; - $6000 - $7fff - Tile Descriptions (32 bytes/tile x 256 tiles)
; TILEMAP BASE ADDRESS Register
	ld hl, TileMapLocation 
	ld bc, hl
	ld a,b
        nextreg $6e, a

; TILEMAP DEFINITIONS BASE ADDRESS Register
	ld hl, TileMapDefLocation
	ld bc, hl
	ld a,b
        nextreg $6f, a

;-------------------------------------------------------------------------------------
; Configure Clip Window
; CLIP WINDOW TILEMAP Register
; The X coordinates are internally doubled (40x32 mode) or quadrupled (80x32 mode), and origin [0,0] is 32* pixels left and above the top-left ULA pixel
; i.e. Tilemap mode does use same coordinates as Sprites, reaching 32* pixels into "BORDER" on each side.
; It will extend from X1*2 to X2*2+1 horizontally and from Y1 to Y2 vertically.
        nextreg $1c, %0000'1000         ; Reset tilemap clip write index
        nextreg $1b, 0                  ; X1 Position
        nextreg $1b, 159                ; X2 Position
        nextreg $1b, 0                  ; Y1 Position
        nextreg $1b, 255              ; Y2 Position

;-------------------------------------------------------------------------------------
; Configure Tile Offset
; Note: Doesn't change the memory address of the tilemap, only where it's displayed on the screen
; Therefore the top tile of the tilemap will still be located at the start of the tilemap memory even though it might
; be displayed at a different offset on the screen 
; TILEMAP OFFSET X MSB Register
        nextreg $2f,%000000'00          ; Offset 0 
; TILEMAP OFFSET X LSB Register
        nextreg $30,%00000000           ; Offset 0
; TILEMAP OFFSET Y Register
        nextreg $31,%00000000           ; Offset 0

;-------------------------------------------------------------------------------------
; Configure Common Tile Attribute
; 1 x Byte per Tilemap Entry - Configure Common Tilemap Attributes
; TILEMAP ATTRIBUTE Register
        ld      a, %0000'0'0'0'0        ; Pal offset 0, no mirrorx, no mirrory, no rotate, tilemap over ULA (also needs to be set on register $6b)
        nextreg $6c, a
 
; ULA CONTROL Register
        ld      a, %0'00'0'0'0'0'0      ; enable ULA (tilemode), no stencil mode, other bits to default 0 configs
        nextreg $68, a

        ret

;-------------------------------------------------------------------------------------
; Copy Tilemap definition data - Run once and common for all levels
; Parameters:
; - a = Memory Bank containing tilemap definition data
UploadTileMapDefData:
; Map memory bank to slot 6 ($c000)
; MEMORY MANAGEMENT SLOT 6 BANK Register
; - Map tilemap definition memory bank to slot 6 ($C000..$DFFF)
        nextreg $56, a

; Copy Tilemap Definition Data
        ld      hl, TileMapDef1Start    ; Source ($C000)
        ld      de, TileMapDefLocation  ; Destination
        ld      bc, TileMapDef1End-TileMapDef1Start;  TilesEnd-Tiles
        ldir

; Clear TileMap
        ld hl, TileMapLocation
        ld de, TileMapLocation+1
        ld bc, (TileMapWidth*TileMapHeight)-1
        ld (hl), TileEmpty
        ldir

;-------------------------------------------------------------------------------------
; Map TileMap memory banks for later reference - Run once and common for all levels
; Parameters:
; - b = Memory Bank containing tilemap data
MapTileMapBank:
; Map memory bank to slot 6 ($c000)
; MEMORY MANAGEMENT SLOT 29 BANK Register
; -  Map 8kb memory bank 1 hosting tilemap to slot 6 ($C000..$DFFF)
        ld      a, b
        nextreg $56, a

        ret

;-------------------------------------------------------------------------------------
; Copy Tilemap level data - Required to be run for each level
; Parameters:
UploadLevelTileMapData:
; Process tilemap for diamonds, static spawn points and rocks
        call    GetDiamondInfo
        call    GetEnemyStaticInfo
        call    GetRockInfo

; Copy/Display Tilemap Data
/*
; Method 1 - Based on entire tilemap being displayed on screen
; Calculate the Tilemap starting offset and position

        ld      hl, TileMapLevel1-TileMapStart
        ld      (TileMapSourceOffset), hl
        
        ld      hl, TileMapLevel1        ; Source
	ld      de, TileMapLocation             ; Destination
        
        ld      bc, TileMapWidth*TileMapHeight
	ldir

*/

; Method 2 - Based on smaller tilemap being displayed on screen
        ;ld      hl, TileMapLevel1-TileMapStart
        ld      a, 0
        ld      (TileMapSourceOffset), a
        
        ld      hl, (LevelTileMapData)                  ; Source
	ld      de, TileMapLocation                     ; Destination

        ld      a, TileMapXOffset                       ; Destination x offset
        add     de, a

        push    hl
        ld      hl, TileMapYOffset*TileMapWidth        ; Destination y offset
        add     hl, de
        ex      de, hl
        pop     hl

        ld      a, TileMapWidth-TileMapMemWidth         ; Offset used to move to next line
        ld      b, TileMapMemHeight

.CopyRows:
        push    bc

        ;ld      bc, TileMapMemWidth
        ;ldir                                            ; Copy column

        ld      b, TileMapMemWidth
.CopyColumns:
        push    bc

        ld      a, (LevelTileMapDefOffset)
        ld      b, a                            

        ld      a, (hl)

        cp      TileDiamond
        jr      z, .UpdateTile                          ; Jump if tile diamond

        cp      TileRock
        jr      z, .UpdateTile                          ; Jump if tile enemy rock

        cp      TileEnemyStatic
        jr      nz, .DisplayTile                        ; Jump if tile not enemy static

        ld      a, TileLeft                             ; Change enemy static symbol
	add     b                                       ; Add levels tile defintion offset

        jr      .DisplayTile

.UpdateTile:
        ld      a, TileEarth                            ; Change diamond and rock symbols
	add     b                                       ; Add levels tile defintion offset

.DisplayTile
        ld      (de), a

        inc     hl                                      ; Point to next source
        inc     de                                      ; Point to next destination

        pop     bc

        djnz    .CopyColumns

        ld      a, TileMapWidth-TileMapMemWidth         ; Offset used to move to next line
        add     de, a                                   ; Destination - Increment to next line
        
        pop     bc
        djnz    .CopyRows

        ret

;-------------------------------------------------------------------------------------
; Get Diamond Information from TileMap - Used to populate diamond sprite info
; Params
GetDiamondInfo:
        ld      a, 0
        ld      (DiamondsInLevel), a            ; Reset level diamond count
        
        ld      hl, (LevelTileMapData);TileMapLevel1          ; Source tilemap

        ld      ix, DiamondX
        ld      iy, DiamondY

        ld      b, 0                            ; Row counter
.ProcessRows:
        ld      c, 0                            ; Column counter

.ProcessColumns:
        push    hl                              ; Save tileMap pointer

        ld      a, (hl)                         ; Get tile from tilemap

        cp      TileDiamond
        jp      nz, .ContinueLoop              ; Jump if tile not diamond

; Found diamond tile
        ;ld      (hl), TileEarth                 ; Replace diamond tile with earth tile

; Calculate/update diamond sprite details
        ld      d, c                            ; Obtain tile x position
        ld      e, 8                            
        mul     d, e                            ; Multiply by 8 to obtain sprite x position 
        ld      (ix), de                        ; Store sprite x position
        
        ld      d, b                            ; Obtain tile y position
        ld      e, 8
        mul     d, e                            ; Multiply by 8 to obtain sprite y position
        ld      (iy), e                        ; Store sprite y position

        inc     ix
        inc     ix                              ; Increment ix by a word
        inc     iy

        ld      hl, DiamondsInLevel
        inc     (hl)                            ; Increment level diamond count

.ContinueLoop:
        pop     hl                              ; Restore tilemap pointer
        inc     hl                              ; Point to next tile in tilemap

        inc     c                               ; Increment column counter
        ld      a, TileMapMemWidth
        cp      c
        jr      nz, .ProcessColumns             ; Jump if not at end of column

        inc     b                               ; Increment row counter
        ld      a, TileMapMemHeight
        cp      b
        jr      nz, .ProcessRows                ; Jump if not at end of rows

        ret

;-------------------------------------------------------------------------------------
; Get Enemy static Information from TileMap - Used to populate static enemy sprite info
;
GetEnemyStaticInfo:
        ld      hl, (LevelTileMapData);TileMapLevel1          ; Source tilemap

        ld      ix, EnemyStaticX
        ld      iy, EnemyStaticY

        ld      b, 0                            ; Row counter
.ProcessRows:
        ld      c, 0                            ; Column counter

.ProcessColumns:
        ld      a, (hl)                         ; Get tile from tilemap

        cp      TileEnemyStatic
        jp      nz, .ContinueLoop               ; Jump if tile not enemy static

; Found bomb tile
        ;ld      (hl), TileLeft                 ; Replace enemy static tile with left tile

; Calculate/update enemy static sprite details
        ld      d, c                            ; Obtain tile x position
        ld      e, 8                            
        mul     d, e                            ; Multiply by 8 to obtain sprite x position 
        ld      (ix), de                        ; Store sprite x position
        
        ld      d, b                            ; Obtain tile y position
        ld      e, 8
        mul     d, e                            ; Multiply by 8 to obtain sprite y position
        ld      (iy), e                         ; Store sprite y position

        inc     ix
        inc     ix                              ; Increment ix by a word
        inc     iy

.ContinueLoop:
        inc     hl                              ; Point to next tile in tilemap

        inc     c                               ; Increment column counter
        ld      a, TileMapMemWidth
        cp      c
        jr      nz, .ProcessColumns             ; Jump if not at end of column

        inc     b                               ; Increment row counter
        ld      a, TileMapMemHeight
        cp      b
        jr      nz, .ProcessRows                ; Jump if not at end of rows

        ret

;-------------------------------------------------------------------------------------
; Get Rock Information from TileMap - Used to populate rock sprite info
;
GetRockInfo:
        ld      a, 0
        ld      (RocksInLevel), a               ; Reset level rock count
        
        ld      hl, (LevelTileMapData);TileMapLevel1          ; Source tilemap

        ld      ix, RockX
        ld      iy, RockY

        ld      b, 0                            ; Row counter
.ProcessRows:
        ld      c, 0                            ; Column counter

.ProcessColumns:
        push    hl                              ; Save tileMap pointer

        ld      a, (hl)                         ; Get tile from tilemap

        cp      TileRock
        jp      nz, .ContinueLoop               ; Jump if tile not rock

; Found rock tile
        ;ld      (hl), TileEarth                 ; Replace rock tile with earth tile

; Calculate/update rock sprite details
        ld      d, c                            ; Obtain tile x position
        ld      e, 8                            
        mul     d, e                            ; Multiply by 8 to obtain sprite x position 
        ld      (ix), de                        ; Store sprite x position
        
        ld      d, b                            ; Obtain tile y position
        ld      e, 8
        mul     d, e                            ; Multiply by 8 to obtain sprite y position
        ld      (iy), e                        ; Store sprite y position

        inc     ix
        inc     ix                              ; Increment ix by a word
        inc     iy

        ld      hl, RocksInLevel
        inc     (hl)                            ; Increment level rock count

.ContinueLoop:
        pop     hl                              ; Restore tilemap pointer
        inc     hl                              ; Point to next tile in tilemap

        inc     c                               ; Increment column counter
        ld      a, TileMapMemWidth
        cp      c
        jr      nz, .ProcessColumns             ; Jump if not at end of column

        inc     b                               ; Increment row counter
        ld      a, TileMapMemHeight
        cp      b
        jr      nz, .ProcessRows                ; Jump if not at end of rows

        ret

;-------------------------------------------------------------------------------------
; Print String via Tiles
; Parameters
; ix = Text to display suffixed by 0
; e = x starting position - (0 to 39)
; d = y starting position - (0 to 31)
PrintTileString:
; Calculate starting location        
        ld      hl, TileMapLocation
        ld      a, e
        add     hl, a

        ld      a, TileMapYOffset
        add     a, d            ; Add tilemap y offset
        ld      d, a

        ld      e, TileMapWidth
        mul     d, e

        add     hl, de

.PrintTileLoop:
        ld      a, (ix)
        cp      0
        ret     z               ; Terminate when end character reached

        add     TileTextDelta   ; Calculate tile definition position

        ld      (hl), a         ; Write tile to tilemap
        
        inc     hl              ; Point to next tilemap location
        inc     ix              ; Point to next character in string
        jr      .PrintTileLoop

        ret

;-------------------------------------------------------------------------------------
; Print String via Tiles across multiple lines
; Parameters
; ix = Text to display suffixed by 0
; c = Line width
; e = x starting position - (0 to 39)
; d = y starting position - (0 to 31)
PrintTileStringLines:
; Calculate starting location        
        ld      hl, TileMapLocation
        ld      a, e
        add     hl, a

        ;ld      a, TileMapYOffset
        ;add     a, d                    ; Add tilemap y offset
        ;ld      d, a

        ld      b, e                    ; Set line character counter
        
        ld      e, TileMapWidth
        mul     d, e

        add     hl, de

.PrintTileLoop:
        ld      a, (ix)
        cp      0
        ret     z                       ; Terminate when end character reached

        add     TileTextDelta           ; Calculate tile definition position

        ld      (hl), a                 ; Write tile to tilemap
        
        inc     b                       ; Increment characters written to line
        inc     hl                      ; Point to next tilemap location

        ld      a, b                    ; Get number of characters written to line
        cp      c
        jr      nz, .NextTile           ; Jump if number of characters doesn't exceed line width

        ld      a, TileMapWidth
        sub     c
        add     hl, a                   ; Point to tilemap next line

        ld      b, 0                    ; Reset character line character counter

.NextTile:
        inc     ix                      ; Point to next character in string
        jr      .PrintTileLoop

        ret

