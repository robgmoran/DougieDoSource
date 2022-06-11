;-------------------------------------------------------------------------------------
; Assembler and CSpect Setup code
;
; Allow the Next paging and instructions
        DEVICE ZXSPECTRUMNEXT
        SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
        
; Generate a map file (debugging) for use with Cspect
        CSPECTMAP "DougieDo/output/DougieDo.map"

; include symbolic names for "magic numbers" like NextRegisters and I/O ports
        INCLUDE "constants.i.asm"

; Memory Map
; ----------
; The default mapping of memory is 16k banks: 7, 5, 2, 0 (8k pages: 14,15,10,11,4,5,0,1)
; This is the default mapping of assembler at assemble time, but at runtime the NEXLOAD
; will set the default mapping the same way, but first 16k is ROM, not bank 7.
; $0000-$1fff - ROM
; $2000-$3fff
; -Assembly Time
;	Data (40)       
; -Runtime
;	Data (40)       
; $4000-$5fff - 5  (10) - ULA, attributes
; -Assembly Time
;	Data (41)       
; -Runtime
; 	NextDAW (32/35) - Temp
;	Data (41)       
; $6000-$7fff -    (11) - Tilemap (1,280 bytes) - (11) - Tile Definitions
; -Runtime
; 	NextDAW (32/35) - Temp
; $8000-$9fff - 2  (4)  - Code (8,192 bytes)
; $a000-$bfff -    (5)  - $B800 - Stack (2,048 bytes)
; $c000-$dfff
; -Assembly Time
;       Sprites (25/26) - Wrap around bank
;       Sprite palette (27)
;       TileMap definitions (28)
;       TileMap palette (28)
;       TileMap (29/30) - Wrap around bank
; 	NextDAW (32/35)
; -Runtime
;       Sprite palette - Temp
;       Sprites 1/2 - Temp
;       TileMap palette - Temp
;       TileMap definitions - Temp
;       TileMap (29/30) --> Permanent - Dynamically Mapped based on bank hosting level data
; $e000-$ffff
; - Assembly Time
;       xFonts (1)
;       Layer2 (18-23) - Wrap around bank
;       Layer2 palette (24)
;       NextDAW Player (31) - Temp
; - Runtime
;       Layer2 palette - Temp
;       Sprites 2/2 - Temp
;       NextDAW Player (31) - Permanent
; Layer 2 Memory Banks - 9 (18, 19), 10 (20, 21), 11 (22, 23)

; Display
; -------
; SUL - Sprites - Enhanced ULA/Tilemap (ULA over Tilemap), Layer 2
; - xEnhanced ULA - Could be used to display text or extra graphics
; - Tilemap - Use to display foreground levelp
; - Layer 2 - Use to display background image

; Audio
; -----
; AY Chip-1 - 3 x Channels - NextDAW - Music
; AY Chip-2 - 3 x Channels - NextDAW - Music
; AY Chip-3 - 3 x CBhannels - AYFX - Sound Effects
; Memory Banks - 32, 33, 34, 35, 36, 37

;-------------------------------------------------------------------------------------
; Code Area
        org  $8000 

Start:
        di       

;-------------------------------------------------------------------------------------
; Setup Common Settings - Common - Run Once
;
        nextreg $07, %000000'11                ; Switch to 28Mhz
        call    SetCommonLayerSettings

;-------------------------------------------------------------------------------------
; Mount data memory bank - Part 1/2
;
; MEMORY MANAGEMENT SLOT 1 BANK Register
; -  Map memory bank hosting Data to slot 1 ($2000..$3FFF)
        ld      a, 40
        nextreg $51, a

;-------------------------------------------------------------------------------------
; Setup ULANext - Common - Run Once - Clear ULA screen before mapping new memory bank
        ld      hl, ULANextPal
        call    SetupULANExtPalette

        call    ClearULAScreen

;-------------------------------------------------------------------------------------
; Mount data memory bank - Part 2/2
;
; MEMORY MANAGEMENT SLOT 2 BANK Register
; -  Map memory bank hosting Data to slot 1 ($4000..$5FFF)
        ld      a, 41
        nextreg $52, a

;-------------------------------------------------------------------------------------
; Setup Layer 2 - Common - Run Once
;
        ld      a, $$Layer2Picture1/2   ; Memory bank (convert 8kb to 16kb) containing layer 2 pixel data
        call    SetupLayer2

; Layer 2 Palette
        ld      a, $$Layer2Palette1     ; Memory bank (8kb) containing layer 2 palette data
        ld      hl, Layer2Palette1      ; Address of first byte of layer 2 palette data
        call    SetupLayer2Pal

;-------------------------------------------------------------------------------------
; Setup Sprites - Common - Run Once
;
; Sprite Palette
        ld      a, $$SpritePaletteSet1  ; Memory bank (8kb) containing sprite palette data        
        ld      hl, SpritePaletteSet1   ; Address of first byte of sprite palette data
        call    SetupSpritePalette
        
; Upload Sprite Patterns
        ld      d, $$SpriteSet1         ; Memory bank (8kb) containing sprite data 0-63   - 8kb
        ld      e, $$SpriteSet1+1       ; Memory bank (8kb) containing sprite data 64-127 - 8kb
        ld      hl, SpriteSet1          ; Address of first byte of sprite patterns
        ld      ixl, 64                 ; Number of sprite patterns to upload
        call    UploadSpritePatterns
        
;-------------------------------------------------------------------------------------
; Setup Tilemap - Common - Run Once
        call    SetupTileMap

; Tilemap Palette
        ld      a, $$TileMapDef1PalStart                        ; Memory bank (8kb) containing tilemap palette data        
        ld      hl, TileMapDef1PalStart                         ; Address of first byte of layer 2 palette data
        ld      b, TileMapDef1PalEnd-TileMapDef1PalStart        ; Number of colours in palette
        call    SetupTileMapPalette

; Upload Tilemap definition data
        ld      a, $$TileMapDef1Start                           ; Memory bank (8kb) containing tilemap definition data
        call    UploadTileMapDefData               

;-------------------------------------------------------------------------------------
; Setup Audio
        call    SetupAYFX               ; Setup and initialise AYFX sound bank

;-------------------------------------------------------------------------------------
; Game Loop
Intro:
; Display Intro Screen
        call    IntroScreen

; Start new level
        call    StartNewGame

GameLoop:
        ;ld a,1
        ;out (#fe),a   ; set the border color

        call    ReadPlayerInput

; Check whether game paused
        ld      a, (Paused)
        cp      1
        jr      z, .Audio              ; Jump if game not paused i.e. Play game loop

.GameNotPaused:
        call    CheckPlayerInput

        call    FillFlood

        ld      a, MaxEnemy+MaxRocks+MaxBombs   ; Number of non-player/non-diamond sprites to check/animate
        call    ProcessOtherSprites

        ld      a, MaxDiamonds                  ; Number of diamond sprites to check/animate
        call    ProcessDiamonds                 ; Animate diamonds

        ld      a, 64                           ; Number of sprites to upload
        call    UploadSpriteAttributes

        call    CheckForEndOfLevel

        call    CheckSpritesForCollision        ; Player to sprite collisions

        call    EnemySpawner

.Audio
        call    NextDAW_UpdateSong              ; Keep NextDAW song playing
        ld      a, %1'11'111'01                 ; AYFX - Change selected chip to AY-3
        ld      bc, $fffd
        out     (c), a
        call    AFXFrame                       ; Keep AYFX sound effect playing
	
        ;ld a,0
	;out (#fe),a   ; set the border color

        call    WaitForScanlineUnderUla

        jr      GameLoop

        include "DougieDo/setup.asm"
        include "DougieDo/palettes.asm"
        include "DougieDo/sprites.asm"
        include "DougieDo/tilemaps.asm"
        include "DougieDo/routines.asm"
        include "DougieDo/collision.asm"
        include "DougieDo/input.asm"
        include "DougieDo/rock.asm"
        include "DougieDo/FillFlood.asm"
        include "DougieDo/enemy.asm"
        include "DougieDo/hud.asm"
        include "DougieDo/LevelManager.asm"
        include "DougieDo/audio.asm"

;-------------------------------------------------------------------------------------
; Data Area
        org     $2000

        include "DougieDo/data.asm"

;-------------------------------------------------------------------------------------
; Stack Location
; Required to aid Dezog debugging and label (stack_top) added to launch.json
; Reserve area for stack at $B800..$BFFF region
        ORG     $B800
stack_bottom:
        DS      $0800-2

stack_top:
        dw 0

;-------------------------------------------------------------------------------------
; Nex File Export

; This sets the name of the project, the start address, 
; and the initial stack pointer.
        SAVENEX OPEN "DougieDo/output/DougieDo.nex", Start, stack_top, 0, 2 ; V1.2 enforced
        SAVENEX CORE 3,0,0      ; core 3.0.0 required
; This sets the border colour while loading,
; what to do with the file handle of the nex file when starting (0 = 
; close file handle as we're not going to access the project.nex 
; file after starting.  See sjasmplus documentation), whether
; we preserve the next registers (0 = no, we set to default), and 
; whether we require the full 2MB expansion (0 = no we don't).
        SAVENEX CFG 0,0,0,0     ; Set colour to 0 - transparent
; Generate the Nex file by scanning all device memory for any non-zero values,
; and then dump every relevent 16ki bank to the NEX file based on these values
        SAVENEX AUTO 
        SAVENEX CLOSE