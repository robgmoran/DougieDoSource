;-------------------------------------------------------------------------------------
; Setup Next Values and Display Layer 2 screen
; Parameters:
; - a = Memory Bank (8kb) containing layer 2 pixel data
SetupLayer2:
; *** Setup Layer-2 ***
; DISPLAY CONTROL 1 REGISTER
; - Enable Layer 2, ULA remaining at bank 5, Timex mode 0
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %1'0'000000      ; Disable by default and re-enable later (bit 7)

; *** Configure Layer 2 Memory Bank ***
;  LAYER 2 RAM PAGE REGISTER
; - References 16kb memory banks
; - Set Layer 2 to use banks 9, 10, 11 (Layer 2 - 256 x 192 occupies 48kb) 
; - Note: Avoid using banks 5 and 7 for Layer 2
        nextreg $12, a

; *** Setup Layer 2 Resolution
; LAYER 2 CONTROL REGISTER
; - Layer 2 screen resolution - 256 x 192 x8bpp - L2 palette offset +0
        nextreg $70, %00'00'0000        

; *** Reset Layer 2 Clip Window
; CLIP WINDOW LAYER 2 REGISTERS
; - $18 - Auto-Increment wrapping from 3 to 0
       nextreg $1c, %0000'0'0'0'1 ; Clip window to set - Reset Layer 2
       nextreg $18, 0             ; Wite to Index 0 - X1 Position
       nextreg $18, 255           ; Wite to Index 1 - X2 Position
       nextreg $18, 0             ; Wite to Index 2 - Y1 Position
       nextreg $18, 191           ; Wite to Index 3 - Y2 Position

; *** Reset Scrolling Offset Registers ***
; LAYER 2 X OFFSET REGISTER
        ld      a, (L2OffsetX)
        nextreg $16, a 
; LAYER 2 X OFFSET MSB REGISTER
        nextreg $71, %0000000'0
; LAYER 2 Y OFFSET REGISTER
        ld      a, (L2OffsetY)
        nextreg $17, a

        ret

SetCommonLayerSettings:
; *** Setup Sprite Behavior and Layer Priority ***
; SPRITE AND LAYERS SYSTEM REGISTER
; - LowRes off
; - Sprite rendering flipped i.e. Sprite 0 (Player) on top of other sprites
; - Layer Priority - SUL (Top - Sprites, Enhanced_ULA, Layer 2)
; - Sprites visible and displayed in border
        nextreg $15, %0'1'0'010'1'1

; *** Configure Layer 2 and ULA Transparency Colour
; GLOBAL TRANSPARENCY Register
        nextreg $14,$00         ; Transparency Colour - Ensure palettes are configured correctly

        ret
