
;-------------------------------------------------------------------------------------
; Layer 2 Palette Setup
; Parameters:
; - a = Memory Bank (8kb) containing layer 2 palette data
; - hl = Address of layer 2 palette data
SetupLayer2Pal:
; *** Map Layer 2 Palette Memory Bank ***
; MEMORY MANAGEMENT SLOT 7 BANK Register
; -  Map memory bank hosting Layer2Palette to slot 7 ($E000..$EFFF)
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank)
; This saves explicitly listing the bank, enabling the bank to be set once when uploading the palette data
        nextreg $57, a

; *** Select Layer 2 Palette and Palette Index ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43,%0'001'0'0'0'1  ; Layer 2 - First palette
; PALETTE INDEX REGISTER
        nextreg $40,0               ; Start with color index 0

; *** Copy Layer 2 Palette Data
; Note: GFX2NEXT -PAL-STD PARAMETER not used
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B
        ld      b,0                 ; 256 colors (loop counter)
.SetPaletteLoop:
        ld      a,(hl)
        inc     hl        
        nextreg $44,a
        ld      a,(hl)
        inc     hl
        nextreg $44,a
        djnz    .SetPaletteLoop

        ret

;-------------------------------------------------------------------------------------
; Sprite Palette Setup
; Parameters:
; - a = Memory Bank (8kb) containing sprite palette
; - hl = Address of sprite palette data
SetupSpritePalette:
; By default sprites will use the default palette: color[i] = convert8bitColorTo9bit(i)
; which is set by the NEX loader in the first sprite palette.
; This routine will change the sprite palette to the specified sprite palette

; *** Map Sprite Palette Memory Bank ***
; MEMORY MANAGEMENT SLOT 6 BANK Register
; -  Map memory bank hosting SpritePalette to slot 6 ($C000..$DFFF)
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank)
; This saves explicitly listing the bank, enabling the bank to be set once when uploading the palette data
        nextreg $56, a

; *** Select Sprite Palette and Palette Index ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43,%0'010'0'0'0'1  ; Sprites - First palette
; PALETTE INDEX REGISTER
        nextreg $40,0               ; Start with color index 0

; *** Copy Sprite Palette Data
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B
        ld      b,0                 ; 256 colors (loop counter)
.SetPaletteLoop:
        ld      a,(hl)
        inc     hl        
        nextreg $44,a
        ld      a,(hl)
        inc     hl
        nextreg $44,a
        djnz    .SetPaletteLoop

        ret

;-------------------------------------------------------------------------------------
; Tilemap Palette Setup
; Parameters:
; - a = Memory Bank (8kb) containing tilemap palette
; - hl = Address of tilemap palette data
; - b = Palette size
SetupTileMapPalette:
; By default tilemap will use the default palette: color[i] = convert8bitColorTo9bit(i)
; which is set by the NEX loader in the first tilemap palette.
; This routine will change the tilemap palette to the specified tilemap palette

; *** Map Tilemap Palette Memory Bank ***
; MEMORY MANAGEMENT SLOT 6 BANK Register
; -  Map memory bank hosting Tilemap palette to slot 6 ($C000..$DFFF)
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank)
; This saves explicitly listing the bank, enabling the bank to be set once when uploading the palette data
        nextreg $56, a

; *** Select Tilemap Palette and Palette Index ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43,%0'011'0'0'0'1  ; Tilemap - First palette
; PALETTE INDEX REGISTER
        nextreg $40,0               ; Start with color index 0

; *** Copy Tilemap Palette Data
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B

.SetPaletteLoop:
        ld      a,(hl)
        inc     hl        
        nextreg $44,a
        
        ld      a,(hl)
        nextreg $44,a
        inc     hl
        
        djnz    .SetPaletteLoop

; *** Configure Tilemap Transparency
; TILEMAP TRANSPARENCY INDEX Register
        nextreg $4c, $00

        ret

;-------------------------------------------------------------------------------------
; ULANext Palette Setup
; Parameters:
; - hl = Address of ULANext palette data
SetupULANExtPalette:
; By default ULANext will use the default palette: color[i] = convert8bitColorTo9bit(i)
; which is set by the NEX loader in the first ULANext palette.
; This routine will change the ULANext palette to the specified ULANext palette

; *** Enable ULANext Mode
; ENHANCED ULA CONTROL Register
        nextreg $43,%0'000'0'0'0'1      ; Enable ULANext - First palette

; *** Configure Ink/Colour Mask
; ENHANCED ULA INK COLOUR MASK
        nextreg $42, %0000'1111         ; 16 colours for foreground (ink) and 16 colours for background (paper)

; PALETTE INDEX REGISTER - Foreground (Ink)
        nextreg $40,0                   ; Foreground starts at color index 0

; *** Copy ULANext Palette Data
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B
        push    hl
        ld      b,16                    ; 16 colors (loop counter)
.SetForePaletteLoop:
        ld      a,(hl)
        inc     hl        
        nextreg $44,a
        ld      a,(hl)
        inc     hl
        nextreg $44,a
        djnz    .SetForePaletteLoop

; PALETTE INDEX REGISTER - Background (Paper)
        nextreg $40,128                 ; Background Starts with color index 128

; *** Copy ULANext Palette Data
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B
        pop     hl
        ld      b,16                    ; 16 colors (loop counter)
.SetBackPaletteLoop:
        ld      a,(hl)
        inc     hl        
        nextreg $44,a
        ld      a,(hl)
        inc     hl
        nextreg $44,a
        djnz    .SetBackPaletteLoop

        ret

;-------------------------------------------------------------------------------------
; Cycle Layer 2 Colour Palette; only cycles once
; Parameters:
; - a = End colour offset within palette
CycleL2Palette:

; *** Select Layer 2 Palette ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43,%1'001'0'0'0'1  ; Layer 2 - First palette



        ld      c, a                    ; Backup original palette element
.CycleLoop:
        ld      a, c                    ; Restore original palette element
        nextreg $40, a                  ; Select palette element

        ld      a, $41        
        call    ReadNextReg             ; Read palette element

        ld      (BackupDataByte), a     ; Backup palette element to copy later
        
        ld      a, c                    ; Restore original palette element
        dec     a
        ld      d, a                    ; Destination palette element (end colour-1)

        ld      b, a                    ; Number of palette entries to copy/cycle (end colour-2 i.e. Not first colour which is transparent, and not end colour which is copied later)
.CopyColours:
        ld      a, d
        nextreg $40, a                  ; Select source palette element

        ld      a, $41        
        call    ReadNextReg             ; Read source palette element
        push    af                      ; Backup source value

        inc     d                       ; Point to destination palette element (source+1)
        ld      a, d
        nextreg $40, a                  ; Select destination palette element

        pop     af                      ; Restore source value
        nextreg $44, a                  ; Write destination palette element
        nextreg $44, 0                  ; Write destination palette element

        dec     d                       ; Point to next source palette element
        dec     d
        djnz    .CopyColours

; Copy last colour
        inc     d                       ; Point to final colour element
        ld      a, d
        nextreg $40, a                  ; Select palette element

        ld      a, (BackupDataByte)     ; Restore last colour to first colour
        nextreg $44, a                  ; Write destination palette element
        nextreg $44, 0                  ; Write destination palette element

        ret

;-------------------------------------------------------------------------------------
; Cycle TileMap Colour Palette; only cycles once
; Parameters:
; - a = End colour offset within palette - 0 - 255 - not offset within current tilemap palette
; - b = Number of palette entries to copy/cycle; does not include End colour (a) or first colour where end colour is copied too
CycleTileMapPalette:
        ld      c, a                    ; Backup original palette element

; *** Select TileMap Palette ***
; ENHANCED ULA CONTROL REGISTER
        ld      a, %1'011'0'0'0'1       ; Select TileMap - First palette
        nextreg $43, a

.CycleLoop:
        ld      a, c                    ; Restore original palette element
        nextreg $40, a                  ; Select palette element

        ld      a, $41        
        call    ReadNextReg             ; Read palette element

        ld      (BackupDataByte), a     ; Backup palette element to copy later
        
        ld      a, c                    ; Restore original palette element
        dec     a
        ld      d, a                    ; Destination palette element (end colour-1)

.CopyColours:
        ld      a, d
        nextreg $40, a                  ; Select source palette element

        ld      a, $41        
        call    ReadNextReg             ; Read source palette element
        push    af                      ; Backup source value

        inc     d                       ; Point to destination palette element (source+1)
        ld      a, d
        nextreg $40, a                  ; Select destination palette element

        pop     af                      ; Restore source value
        nextreg $44, a                  ; Write destination palette element
        nextreg $44, 0                  ; Write destination palette element

        dec     d                       ; Point to next source palette element
        dec     d
        djnz    .CopyColours

; Copy last colour
        inc     d                       ; Point to final colour element
        ld      a, d
        nextreg $40, a                  ; Select palette element

        ld      a, (BackupDataByte)     ; Restore last colour to first colour
        nextreg $44, a                  ; Write destination palette element
        nextreg $44, 0                  ; Write destination palette element

        ret
        