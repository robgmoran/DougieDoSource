;-------------------------------------------------------------------------------------
; Storage of Data --> Memory Banks - Memory Banks Mapped to appropriate MMU at runtime
;-------------------------------------------------------------------------------------
; The bulk of the data will be stored in bank 40
; - Map bank 40/41 into slot 1/2 using sjasmplus MMU directive and 8kb references
        MMU     1 2, 40           
        ; Slot 1 = $2000..$3FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
        ; Slot 2 = $4000..$5FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 1 memory address
        ORG     $2000

;-------------------------------------------------------------------------------------
; Structures
; Structure for sprite attributes
        STRUCT S_SPRITE_ATTR
x               BYTE    0       ; X0:7
y               BYTE    0       ; Y0:7
mrx8            BYTE    0       ; PPPP Mx My Rt X8 (pal offset, mirrors, rotation, X8)
vpat            BYTE    0       ; V 0 NNNNNN (visible, 5B type=off, pattern number 0..63)
Attribute4      BYTE    0
        ENDS

; Structure for sprite type
        STRUCT S_SPRITE_TYPE
active          BYTE    0       ; Indicates whether sprite slot available (auto-populated)
SpriteNumber    BYTE    0       ; Sprite slot (also SpriteAtt ref) allocated to sprite (auto-populated)
patternRange    WORD    0       ; Sprite animation pattern range (patternRef); Also start pattern pattern range
patternCurrent  BYTE    0       ; Current Pattern for sprite (auto set as first pattern within patternRef)
animationDelay  BYTE    0       ; Animation - Speed (Set within routine parameters)
animationHor    WORD    0       ; Animation - Horizontal pattern range
animationVer    WORD    0       ; Animation - Vertical pattern range
Counter         BYTE    0       ; Counter used for sprite changes e.g. Delay before dropping rock
xPosition       WORD    0       ; X Position (update inline with sprite attr)
yPosition       BYTE    0       ; Y Position (update inline with sprite attr)
SpriteType1      BYTE    0       ; Sprite type - Used for processing within code
                                ; %ADRMPEFI
                                ; A - Animate (toggled in code), D - Diamond, R - Rock, M - Move rock (toggled in code),
                                ; P - Player, E -Enemy, F - Enemy Find/Flee (toggled on code), I - Digger (if set also set Enemy Find/Flee and appropriate duration for enemy flee state)
SpriteType2      BYTE    0      ; Sprite type - Used for processing within code
                                ; %BDEXISMA
                                ; B - Bomb, D - Bomb Dropped (toggled in code) , E- Bomb Exploding (toggled in code)
                                ; X - Double-Speed (Enemy), I - Toggle Dig x/y (1=x; enemy - toggled in code), S - Enemy Spawning (toggled in code), M - Static no movement, A - Death animation (toggled in code)
SpriteType3      BYTE    0      ; Sprite type - Used for processing within code
                                ; %R------
                                ; R - Reaper
Width           BYTE    0       ; Sprite width
Height          BYTE    0       ; Sprite height
BoundaryX       BYTE    0       ; Collision Boundary Box - x offset
BoundaryY       BYTE    0       ; Collision Boundary Box - y offset
BoundaryWidth   BYTE    0       ; Collision Boundary Box - Width
BoundaryHeight  BYTE    0       ; Collision Boundary Box - Height
Movement        BYTE    %00000000       ; Current movement - ---UDLR (UP, DOWN, LEFT, RIGHT)
SprCollision    WORD    0       ; Location of target sprite in collision - Set in code
SprContactSide  BYTE    0       ; Side of sprite hit by target sprite %----UDLR - Set in code
MovementDelay   BYTE    0       ; Used to delay enemy - Set in code
FindFleeDelay   WORD    0       ; Used to switch enemy states - Set in code
EnemyType       WORD    0       ; Used to link enemy to enemytype i.e. Manage re-spawning
DelayCounter    BYTE    0       ; Counter to delay player/enemy when moving through earth - Updated in code
        ENDS

; Structure for enemy types
        STRUCT S_ENEMY_TYPE
SpriteType              WORD
EnemyMaxNumber          BYTE     0                      ; Maximum number of enemies to spawn
EnemyMaxCounter         BYTE     0                      ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
EnemySpawnInterval      WORD     0                      ; Interval between enemies spawning
EnemySpawnCounter       WORD     0                      ; Interval between spawned enemies counter - Updated in code
EnemySpawnX             WORD     0                      ; Spawn X position - Divsable by 16
EnemySpawnY             BYTE     0                      ; Spawn Y position - Divsable by 16
EnemyFindTimer          WORD     0                      ; Duration for enemy find state
EnemyFleeTimer          WORD     0                      ; Duration for enemy flee state
EnemySpeed              BYTE     0                      ; Number of frames enemy permitted to move before delay - higher value faster enemy (99 = Code sets to 1 and never increases at each subsequent game loop)
        ENDS

; Structure for level data
        STRUCT S_LEVEL_TYPE
TileMapMemBank          BYTE    0                       ; Memory bank hosting level data
TileMap                 WORD    0                       ; TileMap location
TileMapPalOffset        BYTE    0                       ; Offset to required 16-colour palette within tile palette
TileMapDefOffset        BYTE    0                       ; Start offset of required tiles within tile defintion
SongMapping:            WORD    0                       ; NextDAW Song location
EnemyTypes              WORD    0                       ; EnemyType location
        ENDS

;-------------------------------------------------------------------------------------
; Sprite Data
SpriteMaxRight:
                DW      (TileMapMemWidth*8)-16          ; Ensures sprites keep within actual tilemap
                ;DW      320-16          ; 16 denotes sprite width
SpriteMaxLeft:
                DW      0               
SpriteMaxUp:
                DB      0               
SpriteMaxDown:
                DB      (TileMapHeight*8)-16;(TileMapMemHeight*8)-16         ; Ensures sprites keep within actual tilemap
                ;DB      256-16          ; 16 denotes sprite width

; Spawned Sprites Table
; - Used to store instantiated sprites - non-sprite attribute data

MaxDiamonds:            EQU     46
MaxEnemy:               EQU     10
MaxRocks:               EQU     6
MaxBombs:               EQU     1
Sprites:
                        DS      64 * S_SPRITE_TYPE
EnemyAttStart:          EQU     1                               ; Enemy Sprites start at this Sprite offset
RockAttStart:           EQU     EnemyAttStart+MaxEnemy          ; Rock Sprites start at this Sprite offset
BombAttStart:           EQU     RockAttStart+MaxRocks           ; Bomb Sprites start at this sprite offset
DiamondAttStart:        EQU     BombAttStart+MaxBombs           ; Diamond Sprites start at this Sprites offset

PlayerSprite:           EQU     Sprites + 0*S_SPRITE_TYPE                       ; Player sprite data
OtherSprites:           EQU     Sprites + 1*S_SPRITE_TYPE                       ; ALL other sprite data
EnemySpritesStart:           EQU     Sprites + EnemyAttStart*S_SPRITE_TYPE      
RockSprites:            EQU     Sprites + RockAttStart*S_SPRITE_TYPE      
BombSprites:            EQU     Sprites + BombAttStart*S_SPRITE_TYPE      
DiamondSprites:         EQU     Sprites + DiamondAttStart*S_SPRITE_TYPE       

; Spawned Sprites Attribute Table
; - Used to store instantiated sprites - sprite attribute data
SpriteAtt:
                DS      64 * S_SPRITE_ATTR, 0          ; Storage for 128 * 4-bit sprites or 64 * 8-bit sprites
PlayerSprAtt:   EQU     SpriteAtt + 0*S_SPRITE_ATTR     ; Player sprite at this address
OtherSprAtt:    EQU     SpriteAtt + 1*S_SPRITE_ATTR     ; ALL other sprites start at this address

; Sprite Types Table
; - Used to populate instantiated sprite settings
PlayerSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                PlayerIdlePatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                PlayerHorPatterns,      ; Animation - Horizontal pattern range
                PlayerVerPatterns,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00001000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                %00000001,;Current Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 
DiamondSprType  S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                DiamondPatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                0,      ; Animation - Horizontal pattern range
                0,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %11000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                %00000000,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                0,      ; Used to link enemy to enemy type - Set in code 
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 

RockSprType     S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                RockWaitPatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                0,      ; Animation - Horizontal pattern range
                RockMovePatterns,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00100000,      ; Sprite type - Used for processing within code e.g. Movement SDRMPE00
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                0,      ; Collision Boundary Box - x offset 
                0,      ; Collision Boundary Box - y offset
                16,      ; Collision Boundary Box - Width
                16,      ; Collision Boundary Box - Height
                %00000000,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 

; Standard Enemy - Performs find/flee
EnemySprType1   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                EnemySpawning,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                Enemy1HorPatterns,      ; Animation - Horizontal pattern range
                Enemy1VerPatterns,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00000100,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                %00000100,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                EnemyType1,      ; Used to link to enemy type - Set in code
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 
; Digger Enemy - Performs find/flee + Digs towards enemy
EnemySprType2   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                EnemySpawning,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                Enemy2HorPatterns,      ; Animation - Horizontal pattern range
                Enemy2VerPatterns,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00000111,      ; Sprite type - Used for processing within code e.g. Movement
                %00001000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                %00000100,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                EnemyType2,      ; Used to link to enemy type - Set in code
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 
; Speedy Enemy - Performs find/flee + Faster than player
EnemySprType3   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                EnemySpawning,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                Enemy3HorPatterns,      ; Animation - Horizontal pattern range
                Enemy3VerPatterns,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00000100,      ; Sprite type - Used for processing within code e.g. Movement
                %00010000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                %00000100,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                EnemyType3,      ; Used to link to enemy type - Set in code
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 
; Static Enemy - No movement + Can only be destroyed by rocks
EnemySprType4   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                EnemySpawning,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                Enemy4HorPatterns,      ; Animation - Horizontal pattern range
                Enemy4HorPatterns,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00000100,      ; Sprite type - Used for processing within code e.g. Movement
                %00000010,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                %00000010,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                EnemyType4,      ; Used to link to enemy type - Set in code
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 
; Reaper Enemy - Always finding enemy + Can move through rocks - Cannot be killed
EnemySprType5   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                EnemySpawning,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                Enemy5HorPatterns,      ; Animation - Horizontal pattern range
                Enemy5VerPatterns,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00000110,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %10000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                %00000010,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                EnemyType5,      ; Used to link to enemy type - Set in code
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 
BombSprType     S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                BombDroppedPatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                0,      ; Animation - Horizontal pattern range
                0,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00000000,      ; Sprite type - Used for processing within code e.g. Movement
                %10000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                %00000100,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                0,      ; Used to link to enemy type - Set in code 
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 

GOSprType       S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot allocated to sprite (auto-populated)
                GOPatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                0,      ; Animation - Horizontal pattern range
                0,      ; Animation - Vertical pattern range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                %00000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                16,     ; Sprite width
                16,     ; Sprite height
                4,      ; Collision Boundary Box - x offset 
                4,      ; Collision Boundary Box - y offset
                8,      ; Collision Boundary Box - Width
                8,      ; Collision Boundary Box - Height
                %00000000,      ; Current movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy - Set in code
                0,      ; Used to switch enemy states - Set in code
                0,      ; Used to link enemy to enemy type - Set in code 
                0}      ; Counter to delay player/enemy when moving through earth - Set in code 

; Sprite Animation Pattern Ranges
PlayerHorPatterns:      db      2, 0, 2         ; Animation delay, First pattern, Last pattern
PlayerVerPatterns:      db      2, 3, 5         ; Animation delay, First pattern, Last pattern
PlayerIdlePatterns:     db      10, 6, 7      ; Animation delay, First pattern, Last pattern
DeathPatterns:          db      8, 58, 63;60, 63      ; Animation delay, First pattern, Last pattern
DiamondPatterns:        db      13, 35, 38      ; Animation delay, First pattern, Last pattern
RockWaitPatterns:       db      3, 39, 41      ; Animation delay, First pattern, Last pattern
RockMovePatterns:       db      20, 40, 40      ; Animation delay, First pattern, Last pattern
BombDroppedPatterns:    db      20, 42, 44      ; Animation delay, First pattern, Last pattern
BombExplodingPatterns:  db      10, 45, 47      ; Animation delay, First pattern, Last pattern
EnemySpawning:          db      3, 48, 50      ; Animation delay, First pattern, Last pattern
GOPatterns:             db      0, 52, 58       ; Placeholder, only used to enable instantiation of GAMEOVER sprites
Enemy1HorPatterns:      db      3, 14, 16      ; Green monster - Standard
Enemy1VerPatterns:      db      3, 17, 19      ; Green monster - Standard
Enemy2HorPatterns:      db      3, 26, 28      ; Green Helmet monster - Digger
Enemy2VerPatterns:      db      3, 29, 31      ; Green Helmet monster - Digger
Enemy3HorPatterns:      db      3, 20, 22      ; Pink monster - Fast
Enemy3VerPatterns:      db      3, 23, 25      ; Pink monster - Fast
Enemy4HorPatterns:      db      20, 32, 34      ; Skeleton monster - Static
Enemy5HorPatterns:      db      20, 8, 10      ; Reaper monster
Enemy5VerPatterns:      db      20, 11, 13      ; Reaper monster

;-------------------------------------------------------------------------------------
; Other Data
TotalFrames:
                        dd      0       ; Use for counting frames

; Level Variables
PlayerStartX:           dw      16      ; Player start X position for each level
PlayerStartY:           db      16      ; Player start Y position for each level
PlayerDead:             db      0       ; Updated in code
DeathAnimFinished:      db      0       ; Updated in code
LevelComplete:          db      0       ; Updated in code
LevelNumber:            db      0       ; Managed as integer and converted to string for display; starts at 1
GameLoops:              db      0       ; Indicates how many times the game has looped - Updated in code
LevelTileMapData:       dw      0       ; Points to active level tilemap data - Set in code
LevelTileMapPalOffset:  db      0       ; Points to active level tilemap palette offset - Set in code
LevelTileMapDefOffset:  db      0       ; Points to active level tilemap definition offset - Set in code
LevelSongData:          dw      0       ; Point to active level NextDAW song - Set in code
LevelEnemyTypeData:     dw      0       ; Points to active level enemy type  data - Set in code
Lives:                  db      0       ; Managed as integer and converted to string for display
LivesStart:             equ     3       ; Number of lives at start of game
Bombs:                  db      0       ; Managed as integer and converted to string for display
DiamondsCollected:      db      0       ; Number of diamonds collected
DiamondsTotal:          db      0       ; Number of diamonds within level
EnemiesDestroyed:       db      0       ; Number of enemies killed by player
EnemiesTotal:           db      0       ; Number of enemies within level
LevelStartFramePause:   equ     110     ; Number of frames to wait when starting, restarting a level
LevelCompFramePause:    equ     130     ; Number of frames to wait when level completed
DeathFramePause:        equ     25     ; Number of frames to wait when dead
GameOverFramePause:     equ     100     ; Number of frames to wait at gameover

; Paused Variables
Paused:                 db      0       ; Indicates whether game is paused - set in code
PausedFrames:           db      10      ; Number of frames passed before processing another pause input
PausedCounter:          db      0       ; Used to add delay to pressing pause twice - set in code
PausedTextOn:           defb    "GAME PAUSED  ", 0
PausedTextOff:          defb    "             ", 0        ; Text to ensure Level message displayed correctly
PausedTextX:            equ     LevelHUDX-1
PausedFlashInt:         equ     25      ; Number of frames to toggle flashing of paused text
PausedFlashCt:          db      0       ; Set in code
PausedFlashSt:          db      0       ; Set in code - 0 = Text off, 1 = Text on

; Score Variables
Score:                  defb    "000000", 0     ; Managed as string due to required value greater than word
ScoreLength:            equ     6
TopScore:               defb    "005000", 0     ; Managed as string due to required value greater than word
TileTemp:               defb    "00", 0         ; Used to temporarily hold converted integer to string e.g. LevelNumber
ExtraLifeCounter:       dw      0               ; Incremental counter used to award extra life - Updated in code

; Score - Points
ScoreExtraLife:         equ     6000            ; Points when extra life is awarded
ScoreDiamondStr:        defb    "50"            ; Managed as a string to enable addition to Score; match to ScoreDiamond and if changing length update routine call
ScoreDiamond:           equ     50              ; Managed as integer to enable addition to ScoreExtraLife; match to ScoreDiamondStr
ScoreBombEnemyStr:      defb    "25"            ; Managed as a string to enable addition to Score; match to ScoreBombEnemy and if changing length update routine call
ScoreBombEnemy:         equ     25              ; Managed as integer to enable addition to ScoreExtraLife; match to ScoreBombEnemyStr
ScoreRockEnemyStr:      defb    "100"            ; Managed as a string to enable addition to Score; match to ScoreRockEnemy and if changing length update routine call
ScoreRockEnemy:         equ     100              ; Managed as integer to enable addition to ScoreExtraLife; match to ScoreRockEnemyStr
ScoreRockStaticStr:     defb    "100"           ; Managed as a string to enable addition to Score; match to ScoreRockEnemy and if changing length update routine call
ScoreRockStatic:        equ     100             ; Managed as integer to enable addition to ScoreExtraLife; match to ScoreRockEnemyStr
ScoreLevelCompleteStr:  defb    "500"
ScoreLevelComplete:     equ     500

; Player Variables
DelayCounter:           db      0       ; Counter to delay player when moving through earth - Updated in code
DelayCounterMax:        equ     2       ; Max player movement delay

; Idle Animation Variables
NotIdle:                db      0    ; 0 = Idle, 1 = Not Idle 
IdleFrameCount:         dw      0       ; Number of frames since player input
IdleFrameStart          equ     150     ; Number of frames before player idle animation starts

PlayerInput:            db      0       ; ---FUDLR (FIRE, UP, DOWN, LEFT, RIGHT)
PlayerMoved:            db      0       ; Used to indicate player has moved - Updated in code
WaitForScanLine:        DB      192     ; Scanline to wait for
PlayerDivisable:        db      0       ; Set in code to indicate whether player exactly within tile

; Layer 2 Scrolling Values
L2Width:                equ     256
L2Height:               equ     192
L2OffsetY               db      0
L2OffsetX               db      0

; Backup Memory
BackupData:             DW      1                       ; Used as memory backup
BackupDataByte:         db      0                       ; Use as register backup

;-------------------------------------------------------------------------------------
; Tilemap Memory Locations, Size and Scroll Parameters
TileMapLocation:        equ     $6000
TileMapDefLocation:     EQU     $6000+TileMapWidth*TileMapHeight ; Assumes tilemap of 40 x 32
TileMapWidth:           EQU     40      ; Tilemap - Value written to port
TileMapHeight:          EQU     32      ; Tilemap - Value written to port
TileMapMemWidth:        EQU     33      ; Tilemap - Value used to copy tilemap data
                                        ; i.e. Size of imported (downloaded) tilemap data to be displayed on screen
TileMapMemHeight:       EQU     29      ; Tilemap - Value used to copy tilemap data
                                        ; i.e. Size of imported (download) tilemap data to be displayed on screen
TileMapXOffset:         EQU     0       ; Column offset when copying tilemap to memory
TileMapYOffset:         EQU     2       ; Row offset when copying tilemap to memory - Divisable by 2
TileMapSpriteYOffset:   EQU     TileMapYOffset*8
TileMapOffsetX:         dw      0
TileMapOffsetY:         db      0
TileMapSourceOffset:    dw      0       ; Offset for tilemap data to be displayed i.e. Scrolling
TileMapScrollDir:       db      1       ; 1 = Up, 2 = Down
TileMapScrollMiddle:    equ     128-8   ; Indicates player Y position where player will remaining when scrolling 
TileMapScroll:          db      0       ; 0 = Scroll not permitted, 1 = Scroll permitted
TileTextStart:          equ     64;23      ; Position in TileMap definition where text characters start i.e Space
TileTextDelta:          equ     TileTextStart-32;32 - TileTextStart      ; Delta to subtract from character to be printed to enable mapping to TileMap text characters
; Tilemap lookup table for changing tiles
; - Column number represents source tile in screen tile map, data within each row represents tile that should be used to replace the source tile 
                               ;0,1,2,3,4,5,6,7,8,9,A ,B ,C ,D  - Current Source Tile
TileUTL:                db      9,1,2,3,4,5,$C,2,4,9,$A,$B,$C,$D     ; Up Direction - Tile Above - Left Tile
TileUTR:                db      8,1,2,3,4,5,3,$D,8,4,$A,$B,$C,$D     ; Up Direction - Tile Above - Right Tile
TileUPL:                db      2,1,2,3,$A,$C,$C,2,4,2,$A,$B,$C,$D     ; Up Direction - Tile on Player - Left Tile
TileUPR:                db      3,1,2,3,$B,$D,3,$D,3,4,$A,$B,$C,$D     ; Up Direction - Tile on Player - Right Tile
TileDTL:                db      7,1,2,3,4,5,5,7,$A,2,$A,$B,$C,$D     ; Down Direction - Tile Below - Left Tile
TileDTR:                db      6,1,2,3,4,5,6,5,3,$B,$A,$B,$C,$D     ; Down Direction - Tile Below - Right Tile
TileDPL:                db      2,1,2,3,$A,$C,$C,2,$A,2,$A,$B,$C,$D     ; Down Direction - Tile on Player - Left Tile
TileDPR:                db      3,1,2,3,$B,$D,3,$D,3,$B,$A,$B,$C,$D     ; Down Direction - Tile on Player - Right Tile
TileLTT:                db      9,1,2,3,4,5,$B,2,4,9,$A,$B,$C,$D     ; Left Direction - Tile to Left - Top Tile
TileLTB:                db      7,1,2,3,4,5,5,7,$D,2,$A,$B,$C,$D     ; Left Direction - Tile to Left - Bottom Tile
TileLPT:                db      4,1,$A,$B,4,5,$B,2,4,4,$A,$B,$C,$D     ; Left Direction - Tile on Player - Top Tile
TileLPB:                db      5,1,$C,$D,4,5,5,5,$D,2,$A,$B,$C,$D     ; Left Direction - Tile on Player - Bottom Tile
TileRTT:                db      8,1,2,3,4,5,3,$A,8,4,$A,$B,$C,$D     ; Right Direction - Tile to Right - Top Tile
TileRTB:                db      6,1,2,3,4,5,6,5,3,$C,$A,$B,$C,$D     ; Right Direction - Tile to Right - Bottom Tile
TileRPT:                db      4,1,$A,$B,4,5,3,$A,4,4,$A,$B,$C,$D     ; Right Direction - Tile on Player - Top Tile
TileRPB:                db      5,1,$C,$D,4,5,5,5,3,$C,$A,$B,$C,$D     ; Right Direction - Tile on Player - Bottom Tile
TileStones:             equ     14      ; Tile representing stones
TileEarth:              equ     0       ; Tile representing solid earth
TileEmpty:              equ     1       ; Tile representing empty space
TileLeft:               equ     2       ; Tile representing left tile
TileEnemyStatic:        equ     128      ; Tile representing enemy static, used to place static enemy sprites
TileDiamond:            equ     129      ; Tile representing diamond, used to place diamond sprites
TileRock:               equ     130      ; Tile representing rock, used to place rock sprites

;-------------------------------------------------------------------------------------
; Diamond Data
DiamondsInLevel:        db      0       ; Populated in code
; Divisable by 16
; Always place diamonds over solid earth
DiamondX:               ds      MaxDiamonds*2    ; Space for 46 x diamonds (word per diamond)
DiamondY:               ds      MaxDiamonds      ; Space for 46 x diamonds (byte per diamond)

;-------------------------------------------------------------------------------------
; Rock Data
; Divisable by 16
; Always place rocks over solid earth
RocksInLevel:           db      0                       ; Populated in code
RockX:                  ds      MaxRocks*2              ; Space for rocks (word per rock)
RockY:                  ds      MaxRocks                ; Space for rocks (byte per rock)
RockDelayBeforeDrop:    db      3                       ; Number of animation cycles (full range) before rock is allowed to move
RocksDropRows:          equ     99*2                    ; Number of rows rock permitted to drop before before destroyed (times by 2 to convert to 2 bytes)

;-------------------------------------------------------------------------------------
; Bomb Data
BombStart:              equ     5                      ; Number of bombs player starts with
BombDropped:            db      0                       ; Updated in code
BombExtra:              equ     30                      ; Number of diamonds to collect for new bomb
BombExtraCounter:       db      0                       ; Updated in code

;-------------------------------------------------------------------------------------
; Ememy Data - Commmon to all levels
;
; Static Enemy * 3 positions - x, y coordinates
EnemyStaticNumber:      equ     8
EnemyStaticX:           ds      EnemyStaticNumber*2             ; Auto-populated via tilemap (word per enemy static)
EnemyStaticY:           ds      EnemyStaticNumber               ; Auto-populated via tilemap (word per enemy static)
EnemySpawnCycles:       db      5                              ; How many times the spawn sprite should be looped before spawning enemy

; Enemy Types - 1 x per Enemy Sprite Type - Populated from Level Enemy Data
EnemyType1      S_ENEMY_TYPE {
                EnemySprType1,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code

EnemyType12     S_ENEMY_TYPE {
                EnemySprType1,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code
EnemyType2      S_ENEMY_TYPE {
                EnemySprType2,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code
EnemyType22     S_ENEMY_TYPE {
                EnemySprType2,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code
EnemyType3      S_ENEMY_TYPE {
                EnemySprType3,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code
EnemyType32     S_ENEMY_TYPE {
                EnemySprType3,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code
EnemyType4      S_ENEMY_TYPE {
                EnemySprType4,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code
EnemyType5      S_ENEMY_TYPE {
                EnemySprType5,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code
EnemyType52     S_ENEMY_TYPE {
                EnemySprType5,                  ; Used to link to enemy Sprite Type
                0,                              ; Maximum number of enemies to spawn - Updated in code
                0,                              ; Maximum number of enemies spawed counter - Updated in code
                0,                              ; Interval between enemies spawning - Updated in code
                0,                              ; Interval between spawned enemies counter - Updated in code
                0,                              ; Spawn X position - Divsable by 16 - Updated in code
                0,                              ; Spawn Y position - Divsable by 16 - Updated in code
                0,                              ; Duration for enemy find state - Updated in code
                0,                              ; Duration for enemy flee state - Updated in code
                0}                              ; Number of frames enemy permitted to move before delay - higher value faster enemy - Updated in code

EnemyTileRow:           db      0                       ; Points to tilemap row - Auto configured at runtime - COMMON
EnemyTileColumn:        db      0                       ; Points to tilemap column - Auto configured at runtime - COMMON
EnemyTileOffset:        dw      0                       ; Points to tilemap - Auto configured at runtime - COMMON
EnemyTileJunctions:     db      0                       ; Directions available to enemy (UDLR) - Auto configured at runtime - COMMON

                               ;   R  L     D           U - Direction last travelled, data indicates new direction
EnemyReverseJunction:   db      0, 2, 1, 0, 8, 0, 0, 0, 4       ; Table to reverse enemy direction when only single junction - COMMON
EnemyDiggerChangeDir:   db      0                       ; Used by digger enemy to request change in direction - Updated in code
;-------------------------------------------------------------------------------------
; Flood Fill Data
FFSize:                 equ     5                                       ; Number of lines above/below and columns to left/right of player
FFPlayerOffset          equ     FFSize*2                                ; Used to limit flood fill around player (x*2)
FFStartxPos             db      0                                       ; Used to hold player x value when starting flood fill
FFStartyPos             db      0                                       ; Used to hold player y value when starting flood fill
FFyPos:                 db      0                                       ; Used to hold working y value when performing flood fill
FFxPos:                 db      0                                       ; Used to hold working x value when performing flood fill
FFStorage:              ds      (TileMapWidth/2)*(TileMapHeight/2)      ; Used to hold Flood file node values - Populated at runtime
FFSourceOffset:         dw      0                                       ; Points to tilemap - Auto configured at runtime
FFTargetOffset:         dw      0                                       ; Points to FFStorage - Auto configured at runtime
; FF Tilemap lookup table for placing node values
; - Column number represents source tile in source screen tile map, data within each row indicates whether direction possible 
                             ;0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A ,B ,C ,D  - Current Source Tile
FFUPL:                db      0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1     ; Up Direction - Tile on Player - Left Tile
FFUPR:                db      0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1     ; Up Direction - Tile on Player - Right Tile
FFDPL:                db      0, 1, 1 ,0 ,0 ,0 ,0 ,0 ,0 ,0, 1, 1, 1, 1     ; Down Direction - Tile on Player - Left Tile
FFDPR:                db      0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1     ; Down Direction - Tile on Player - Right Tile
FFLPT:                db      0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1 ,1     ; Left Direction - Tile on Player - Top Tile
FFLPB:                db      0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1     ; Left Direction - Tile on Player - Bottom Tile
FFRPT:                db      0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1 ,1     ; Right Direction - Tile on Player - Top Tile
FFRPB:                db      0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1     ; Right Direction - Tile on Player - Bottom Tile
; Queue Variables used by FF
QueueStart:             dw      0
QueueEnd:               dw      0
Queue:                  DS      300;FFSize*FFSize

;-------------------------------------------------------------------------------------
; ULANext Palette
ULANextPal:
        INCLUDE  "DougieDo/assets/ulanext.pal"         ; INCLUDE file used as it allows a smaller exported file 

;-------------------------------------------------------------------------------------
; HUD Tile Text - CAPITAL LETTERS ONLY; terminate with 0
LevelHUD:       defb    "LEVEL", 0
LevelHUDX:      equ     12
LevelHUDY:      equ     0
LevelX:         equ     18
LevelY:         equ     0
TopScoreHUD:    defb    "TOP", 0
TopScoreHUDX:   equ     35
TopScoreHUDY:   equ     1
TopScoreX:      equ     34
TopScoreY:      equ     2
ScoreHUD:       defb    "SCORE", 0
ScoreHUDX:      equ     34
ScoreHUDY:      equ     7
ScoreX:         equ     34
ScoreY:         equ     8
LivesHUD:       defb    "LIVES",0
LivesHUDX:      equ     34
LivesHUDY:      equ     13
LivesX:         equ     35
LivesY:         equ     14
BombHUD:        defb    "BOMBS",0
BombHUDX:       equ     34
BombHUDY:       equ     19
BombsX:         equ     35
BombsY:         equ     20
;BombPos:        equ     $5800+(BombHUDY * 32 + BombHUDX)        ; Used to change text colour
GameOverHUD:    defb    51, 52, 53, 54, 0, 55, 56, 54, 57, 99   ; Sprites - 0 = Space, 99 = End of text

;-------------------------------------------------------------------------------------
; Intro Screen Text- CAPITAL LETTERS ONLY; terminate with 0
;
IntroStatus:    db      0       ; Set in code - 0 = Start Game, 1 = Credits, 2 = Instructions
; --- Instructions
InstrLineWidth: equ     31
InstrX:         equ     0
InstrY:         equ     2
InstPara0:      defb    "INSTRUCTIONS", 0
InstPara1:      defb    "AFTER HIS BROTHER RAN AWAY TO  "
                defb    "THE CIRCUS TO COLLECT CHERRIES,"
                defb    "DOUGIE DO DECIDED ON A MORE "
                defb    "   PROFITABLE CAREER ..DIAMONDS..",0
InstPara2:      defb    "USE DOUGIE TO COLLECT DIAMONDS WHILST AVOIDING ENEMIES.", 0
InstPara3:      defb    "TO COMBAT ENEMIES, DOUGIE CAN  "
                defb    "DROP BOMBS & ROCKS. BE CAREFUL "
                defb    "THOUGH, THESE CAN ALSO KILL    "
                defb    "DOUGIE. FINALLY BE AWARE THAT  "
                defb    "NOT ALL ENEMIES ARE THE SAME.  ", 0
InstPara31:     defb    "TIP: AN ENEMY WILL NOT RESPAWN "
                defb    "IF KILLED WITH A ROCK", 0
InstPara4:      defb    "CONTROLS:",0
InstPara5:      defb    "Q - UP,   A - DOWN,            "
                defb    "O - LEFT, P - RIGHT,           "
                defb    "SPACE - BOMB, ENTER - PAUSE    "
                defb    "KEMPSTON COMPATIBLE JOYSTICK", 0
InstPara6:      defb    "PRESS C FOR CREDITS", 0
; --- Credits
CredLineWidth:  equ     40
CredX:          equ     0
CredY:          equ     2
CredPara1:      defb    "CODING", 0
CredPara2:      defb    "-ROB MORAN-", 0
CredPara4:      defb    "MUSIC", 0
CredPara5:      defb    "-A MAN IN HIS-", 0
CredPara51:     defb    "-TECHNO SHED-", 0
CredPara6:      defb    "SPRITES", 0
CredPara7:      defb    "-EMCEE FLESHER-", 0
CredPara9:      defb    "SOUND FX", 0
CredPara10:      defb    "-NZ STORY-", 0
CredPara11:      defb    "-ELIMINATOR-", 0
CredPara12:      defb    "-AMAUROTE-", 0
CredPara13:      defb    "-ARKANOID-", 0

CredPara14:      defb    "PRESS I FOR INSTRUCTIONS", 0
; --- Start Game Line
StartLineWidth: equ     30
StartX:         equ     1
StartY:         equ     30
StartParaOn:    defb    "PRESS SPACE OR FIRE TO START", 0
StartParaOff:   defb    "                            ", 0
StartFlashInt:  equ     25      ; Number of frames to toggle flashing of start text
StartFlashCt:   db      0       ; Set in code
StartFlashSt:   db      0       ; Set in code - 0 = Text off, 1 = Text on
; --- Sprites
IntroSprTextX:          equ     32     ; X position to display text
IntroSprTextY:          equ     6      ; Y position to display text
IntroSprTextYOff:       equ     4      ; Y position offset for next text
IntroSprTextE1:         defb    "GRUNT", 0
IntroSprTextE2:         defb    "DIGGER", 0
IntroSprTextE3:         defb    "SPEEDY", 0
IntroSprTextE4:         defb    "SPAWN", 0
IntroSprTextE5:         defb    "REAPER", 0
IntroPlayerSprX:        equ     88      ; X position to display player sprite
IntroPlayerSprY:        equ     90-TileMapSpriteYOffset      ; Y position to display player sprite
IntroSprX:              equ     272     ; X position to display enemy sprite
IntroSprY:              equ     32      ; Y position to display enemy sprite
IntroSprYOff:           equ     32      ; Y position offset for next sprite
IntroSprPat:            db      0       ; Sprite pattern range to be used - Set in code - 0 = Horizontal Right, 1 = Vertical, 2 = Horizontal Left, 3 = Vertical
IntroSprPatInt:         equ     100     ; Number of frames to toggle sprite patterns
IntroSprPatCt:          db      0       ; Set in code
; Palette Cycle
IntroTMCycleFrames:     db     9
IntroTMCycleFramesCT:   db      0

;-------------------------------------------------------------------------------------
; Level-Specific Data - Defines tilemaps and enemy types for each level
;-------------------------------------------------------------------------------------
        include "DougieDo/LevelData.asm"

;-------------------------------------------------------------------------------------
; Audio
;-------------------------------------------------------------------------------------
;
; AYFX
AyFXBank:       incbin  "DougieDo/assets/audio/DougieDo.afb"
; Effects map to AY Sound FX Editor (Effect-1)
AyFXBombExplode:        equ     0
AyFXDiamond:            equ     1
AyFXDropRock:           equ     2
AyFXDropBomb:           equ     3
AyFXEnemyDead:          equ     4
AyFXSpawnEnemy:         equ     5
AyFXExtraBomb1:          equ    6
AyFXExtraBomb2:          equ    7
AyFXExtraLife1:          equ    8
AyFXExtraLife2:          equ    9
AyFXExtraLife3:          equ    10
AyFXStartLevel1:         equ    11
AyFXStartLevel2:         equ    12
AyFXStartLevel3:         equ    13
AyFXGameOver1:           equ    14 
AyFXGameOver2:           equ    15
AyFXGameOver3:           equ    16
AyFXPlayerDead1:         equ    17 
AyFXPlayerDead2:         equ    18
AyFXPlayerDead3:         equ    19
AyFXLevelComplete1:      equ    20
AyFXLevelComplete2:      equ    21
AyFXLevelComplete3:      equ    22
; NextDAW
NextDAWMMUSlots:        defb    3, 6    ; Temporary MMU slots to be used for initialisation
SongIntroDataMapping:	defb	32, 33  ; Memory banks containing music data - Defned/Populated below 
Song2DataMapping:	defb	34, 35  ; Memory banks containing music data - Defned/Populated below 
Song3DataMapping:	defb	36, 37  ; Memory banks containing music data - Defned/Populated below 
NextDAW:		equ     $E000
NextDAW_InitSong:	equ     NextDAW + $00
NextDAW_UpdateSong:	equ     NextDAW + $03
NextDAW_PlaySong:	equ     NextDAW + $06
NextDAW_StopSong:       equ     NextDAW + $09
NextDAW_StopSongHard:	equ     NextDAW + $0C

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data and Palettes
; ***Layer 2 Screen Data ***
; 48kb - Store in 8k banks: 18, 19, 20, 21, 22, 23 (16k banks 9, 10, 11) - As defined within layer 2 setup
; - Map bank 18 into slot 7 using sjasmplus MMU directive and 8kb references; banks 19… will follow in memory
        MMU     7 n, 9*2    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2Picture1:
        INCBIN  "DougieDo/assets/Intro.nxi", 0, 256*192
; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)

; ***Screen Palette Data***
; After pre-loading the image pixel data, bank 24 should now automatically start at $E000
; The background palette will be stored in bank 24
; - Verify this assumption using the sjasmplus ASSERT directive, failure will cause sjasmplus to issue an 'assertion failed' error
        ASSERT  $ == $E000 && $$ == 24
Layer2Palette1:
        INCBIN  "DougieDo/assets/Intro.nxp", 0, 512

;-------------------------------------------------------------------------------------
; Sprite Data and Palettes
; ***Sprite Data***
; The sprite data will be stored in banks 25/26 i.e. Next 8kb bank after background palette of Bank 24
; - Map bank 25 into slot 6 using sjasmplus MMU directive and 8kb references; bank 26 will follow in memory
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     6 n, 25;$$Layer2Palette1 + 1    ; Slot 6 = $C000..$DFFF, "n" option to wrap (around slot 6) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 6 memory address and include sprite data
        ORG     $C000
SpriteSet1:
        INCBIN  "DougieDo/assets/sprites.spr"

; ***Sprite Palette Data***
; After pre-loading the sprite data, bank 27 should now automatically start at $C000
; The sprite palette will be stored in bank 27
; - Verify this assumption using the sjasmplus ASSERT directive, failure will cause sjasmplus to issue an 'assertion failed' error
        ASSERT  $ == $C000 && $$ == 27
SpritePaletteSet1:
        INCBIN  "DougieDo/assets/sprites.pal"

;-------------------------------------------------------------------------------------
; Tilemap Definitions and Palette; Tilemap in different memory bank
; The tilemap data will be stored in bank 28 i.e. Next 8kb bank after SpritePalette of Bank 27
; - Map bank 28 into slot 6 using sjasmplus MMU directive and 8kb references
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     6 n, $$SpritePaletteSet1 + 1    ; Slot 6 = $C000..$DFFF, "n" option to wrap (around slot 6) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 6 memory address and include tilemap definition data
        ORG     $C000
TileMapDef1Start:
        INCLUDE "DougieDo/assets/TileGroundDef.til"   ; INCLUDE file used as it allows a smaller exported file 
TileMapDef1End:
TileMapDef1PalStart:
        INCLUDE "DougieDo/assets/TileGroundPal.til"   ; INCLUDE file used as it allows a smaller exported file 
TileMapDef1PalEnd:

;-------------------------------------------------------------------------------------
; Tilemap Data; Tilemap def & palette in different memory bank
; The tilemap data will be stored in banks 29/30 i.e. Next 8kb bank after TileMap palette of Bank 28
; - Map bank 29 into slot 6 using sjasmplus MMU directive and 8kb references
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     6, $$TileMapDef1PalStart + 1    ; Slot 6 = $C000..$DFFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 6 memory address and include tilemap data
        ORG     $C000
TileMapStart:
; Note: When scrolling don't place anything on the top line of the top screen
; and the bottom line of the bottom screen, as these won't be displayed when scrolling
TileMapLevel1:  INCBIN  "DougieDo/assets/TileGroundMap1-0.til"
TileMapLevel2:  INCBIN  "DougieDo/assets/TileGroundMap2-1.til"
TileMapLevel3:  INCBIN  "DougieDo/assets/TileGroundMap3-2.til"
TileMapLevel4:  INCBIN  "DougieDo/assets/TileGroundMap4-3.til"
TileMapLevel5:  INCBIN  "DougieDo/assets/TileGroundMap5-0.til"
TileMapLevel6:  INCBIN  "DougieDo/assets/TileGroundMap6-1.til"
TileMapLevel7:  INCBIN  "DougieDo/assets/TileGroundMap7-2.til"
TileMapLevel8:  INCBIN  "DougieDo/assets/TileGroundMap8-3.til"

; - Map bank 30 into slot 6 using sjasmplus MMU directive and 8kb references
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     6, $$TileMapStart + 1    ; Slot 6 = $C000..$DFFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 6 memory address and include tilemap data
        ORG     $C000
TileMapStart2:
TileMapLevel9:  INCBIN  "DougieDo/assets/TileGroundMap9-0.til"
TileMapLevel10: INCBIN  "DougieDo/assets/TileGroundMap10-1.til"

;-------------------------------------------------------------------------------------
; NextDAW Player and Music
;
; The NextDAW Player will be stored in bank 31 i.e. Next 8kb bank after Level Data in bank Bank 30
; - Map bank 31 into slot 6 using sjasmplus MMU directive and 8kb references
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     7, 31;$$TileMapStart2 + 1    ; Slot 6 = $C000..$DFFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 6 memory address and include NextDaw Player
        ORG     $E000

NextDAWPlayer:  INCBIN  "DougieDo/New-NextDAW_RuntimePlayer_E000.bin";NextDAW_RuntimePlayer_E000.bin"

; NextDAW Music Data
; The NextDAW Music will be stored in bank 32/33, 34/35 i.e. Next 8kb bank after Level Data in bank Bank 30
; - Map bank 32 into slot 6 using sjasmplus MMU directive and 8kb references
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     6 n, 32    ; Slot 6 = $C000..$DFFF, "n" option to wrap (around slot 6) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 6 memory address and include NextDaw Player
        ORG     $C000
Song1:
        INCBIN "DougieDo/assets/audio/tracks/Intro.ndr"
        
        MMU     6 n, 34    ; Slot 6 = $C000..$DFFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
        ORG     $C000
Song2:
        INCBIN "DougieDo/assets/audio/tracks/LevelEven.ndr"

        MMU     6 n, 36    ; Slot 6 = $C000..$DFFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
        ORG     $C000
Song3:
        INCBIN "DougieDo/assets/audio/tracks/LevelOdd.ndr"
