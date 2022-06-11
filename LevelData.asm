;-------------------------------------------------------------------------------------
; Level Data - Defines tilemaps and enemy types for each level
LevelTotal:     db      10              ; Number of levels
LevelData:
Level1Data      S_LEVEL_TYPE {
                $$TileMapLevel1,        ; Memory bank hosting level data
                TileMapLevel1,          ; Link to TileMap data
                0,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                0*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song3DataMapping,       ; Link to NextDAW song
                EnemyDataLevel1}        ; Link to EnemyType data
Level2Data      S_LEVEL_TYPE {
                $$TileMapLevel2,        ; Memory bank hosting level data
                TileMapLevel2,          ; Link to TileMap data
                1,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                1*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song2DataMapping,       ; Link to NextDAW song
                EnemyDataLevel2}        ; Link to EnemyType data
Level3Data      S_LEVEL_TYPE {
                $$TileMapLevel3,        ; Memory bank hosting level data
                TileMapLevel3,          ; Link to TileMap data
                2,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                2*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song3DataMapping,       ; Link to NextDAW song
                EnemyDataLevel3}        ; Link to EnemyType data
Level4Data      S_LEVEL_TYPE {
                $$TileMapLevel4,        ; Memory bank hosting level data
                TileMapLevel4,          ; Link to TileMap data
                3,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                3*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song2DataMapping,       ; Link to NextDAW song
                EnemyDataLevel4}        ; Link to EnemyType data
Level5Data      S_LEVEL_TYPE {
                $$TileMapLevel5,        ; Memory bank hosting level data
                TileMapLevel5,          ; Link to TileMap data
                0,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                0*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song3DataMapping,       ; Link to NextDAW song
                EnemyDataLevel5}        ; Link to EnemyType data
Level6Data      S_LEVEL_TYPE {
                $$TileMapLevel6,        ; Memory bank hosting level data
                TileMapLevel6,          ; Link to TileMap data
                1,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                1*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song2DataMapping,       ; Link to NextDAW song
                EnemyDataLevel6}        ; Link to EnemyType data
Level7Data      S_LEVEL_TYPE {
                $$TileMapLevel7,        ; Memory bank hosting level data
                TileMapLevel7,          ; Link to TileMap data
                2,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                2*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song3DataMapping,       ; Link to NextDAW song
                EnemyDataLevel7}        ; Link to EnemyType data
Level8Data      S_LEVEL_TYPE {
                $$TileMapLevel8,        ; Memory bank hosting level data
                TileMapLevel8,          ; Link to TileMap data
                3,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                3*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song2DataMapping,       ; Link to NextDAW song
                EnemyDataLevel8}        ; Link to EnemyType data
Level9Data      S_LEVEL_TYPE {
                $$TileMapLevel9,        ; Memory bank hosting level data
                TileMapLevel9,          ; Link to TileMap data
                0,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                0*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song3DataMapping,       ; Link to NextDAW song
                EnemyDataLevel9}        ; Link to EnemyType data
Level10Data     S_LEVEL_TYPE {
                $$TileMapLevel10,        ; Memory bank hosting level data
                TileMapLevel10,         ; Link to TileMap data
                1,                      ; Link to 16-colour palette offset within tile palette (starts at 0)
                1*16,                   ; Link to definition offset within tilemap (starts at 0)
                Song2DataMapping,       ; Link to NextDAW song
                EnemyDataLevel10}        ; Link to EnemyType data

;-------------------------------------------------------------------------------------
; Enemy type Data - Used to populate listed Enemy Types
EnemyDataLevel1:        db      2              ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      6              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      150              ; Interval between enemies spawning
                        dw      150              ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      96              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      30            ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Static
                        dw      EnemyType4      ; Used to link to enemy Type
                        db      2              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      10              ; Interval between enemies spawning
                        dw      10               ; Interval between spawned enemies counter
                        dw      0             ; Spawn X position - Divsable by 16
                        db      0              ; Spawn Y position - Divsable by 16
                        dw      0             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      0               ; Number of frames enemy permitted to move before delay - higher value faster enemy
EnemyDataLevel2:        db      2               ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      6              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      150              ; Interval between enemies spawning
                        dw      150               ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      144              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      30            ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Static
                        dw      EnemyType4      ; Used to link to enemy Type
                        db      4              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      10              ; Interval between enemies spawning
                        dw      10               ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      96              ; Spawn Y position - Divsable by 16
                        dw      0             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      0               ; Number of frames enemy permitted to move before delay - higher value faster enemy
EnemyDataLevel3:        db      3               ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      3              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      150              ; Interval between enemies spawning
                        dw      150               ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      96              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      30            ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Static
                        dw      EnemyType4      ; Used to link to enemy Type
                        db      5              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      10              ; Interval between enemies spawning
                        dw      10               ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      96              ; Spawn Y position - Divsable by 16
                        dw      0             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      0               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Digger
                        dw      EnemyType2      ; Used to link to enemy Type
                        db      2               ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      150             ; Interval between enemies spawning
                        dw      150             ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      208              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      15             ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
EnemyDataLevel4:        db      2               ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      6             ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      125              ; Interval between enemies spawning
                        dw      125               ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      112              ; Spawn Y position - Divsable by 16
                        dw      300             ; Duration for enemy find state
                        dw      30            ; Duration for enemy flee state
                        db      4               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Static
                        dw      EnemyType4      ; Used to link to enemy Type
                        db      4              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      10              ; Interval between enemies spawning
                        dw      10               ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      96              ; Spawn Y position - Divsable by 16
                        dw      0             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      0               ; Number of frames enemy permitted to move before delay - higher value faster enemy
EnemyDataLevel5:        db      4               ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      4              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      64              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      30            ; Duration for enemy flee state
                        db      4               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Static
                        dw      EnemyType4      ; Used to link to enemy Type
                        db      3              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      10              ; Interval between enemies spawning
                        dw      10               ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      96              ; Spawn Y position - Divsable by 16
                        dw      0             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      0               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Digger
                        dw      EnemyType2      ; Used to link to enemy Type
                        db      2               ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100             ; Interval between enemies spawning
                        dw      100             ; Interval between spawned enemies counter
                        dw      240             ; Spawn X position - Divsable by 16
                        db      16              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      15             ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Speedy
                        dw      EnemyType3      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      144              ; Spawn Y position - Divsable by 16
                        dw      150             ; Duration for enemy find state
                        dw      50            ; Duration for enemy flee state
                        db      99               ; Number of frames enemy permitted to move before delay - higher value faster enemy 
EnemyDataLevel6:        db      5               ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      4              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      80              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      25            ; Duration for enemy flee state
                        db      4               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Static
                        dw      EnemyType4      ; Used to link to enemy Type
                        db      3              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      10              ; Interval between enemies spawning
                        dw      10               ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      96              ; Spawn Y position - Divsable by 16
                        dw      0             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      0               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Speedy
                        dw      EnemyType3      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      240             ; Spawn X position - Divsable by 16
                        db      176              ; Spawn Y position - Divsable by 16
                        dw      150             ; Duration for enemy find state
                        dw      50            ; Duration for enemy flee state
                        db      99               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Reaper
                        dw      EnemyType5      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      80             ; Spawn X position - Divsable by 16
                        db      208              ; Spawn Y position - Divsable by 16
                        dw      1000             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Reaper
                        dw      EnemyType52      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      176             ; Spawn X position - Divsable by 16
                        db      208              ; Spawn Y position - Divsable by 16
                        dw      1000             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
EnemyDataLevel7:        db      4               ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      2              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      240             ; Spawn X position - Divsable by 16
                        db      16              ; Spawn Y position - Divsable by 16
                        dw      100             ; Duration for enemy find state
                        dw      75            ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Standard
                        dw      EnemyType12     ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      16             ; Spawn X position - Divsable by 16
                        db      208              ; Spawn Y position - Divsable by 16
                        dw      100             ; Duration for enemy find state
                        dw      75            ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Speedy
                        dw      EnemyType3      ; Used to link to enemy Type
                        db      1             ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      64              ; Spawn Y position - Divsable by 16
                        dw      150             ; Duration for enemy find state
                        dw      50            ; Duration for enemy flee state
                        db      99               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Reaper
                        dw      EnemyType5      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      240             ; Spawn X position - Divsable by 16
                        db      208              ; Spawn Y position - Divsable by 16
                        dw      1000             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
EnemyDataLevel8:        db      7               ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      3              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      16              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      75            ; Duration for enemy flee state
                        db      4               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Standard
                        dw      EnemyType12      ; Used to link to enemy Type
                        db      3              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      208              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      75            ; Duration for enemy flee state
                        db      4               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Digger
                        dw      EnemyType2      ; Used to link to enemy Type
                        db      0               ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100             ; Interval between enemies spawning
                        dw      100             ; Interval between spawned enemies counter
                        dw      144             ; Spawn X position - Divsable by 16
                        db      16              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      15             ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Speedy
                        dw      EnemyType3      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      176             ; Spawn X position - Divsable by 16
                        db      48              ; Spawn Y position - Divsable by 16
                        dw      150             ; Duration for enemy find state
                        dw      50            ; Duration for enemy flee state
                        db      99               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Speedy
                        dw      EnemyType32      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      80             ; Spawn X position - Divsable by 16
                        db      176              ; Spawn Y position - Divsable by 16
                        dw      150             ; Duration for enemy find state
                        dw      50            ; Duration for enemy flee state
                        db      99               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Reaper
                        dw      EnemyType5      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      80             ; Spawn X position - Divsable by 16
                        db      48              ; Spawn Y position - Divsable by 16
                        dw      1000             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Reaper
                        dw      EnemyType52      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      176             ; Spawn X position - Divsable by 16
                        db      176              ; Spawn Y position - Divsable by 16
                        dw      1000             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
EnemyDataLevel9:        db      5               ; Number of Enemy Types defined within level data
; Standard
                        dw      EnemyType1      ; Used to link to enemy Type
                        db      2              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      128             ; Spawn X position - Divsable by 16
                        db      112              ; Spawn Y position - Divsable by 16
                        dw      150             ; Duration for enemy find state
                        dw      50            ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Static
                        dw      EnemyType4      ; Used to link to enemy Type
                        db      4              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      10              ; Interval between enemies spawning
                        dw      10               ; Interval between spawned enemies counter
                        dw      112             ; Spawn X position - Divsable by 16
                        db      96              ; Spawn Y position - Divsable by 16
                        dw      0             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      0               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Digger
                        dw      EnemyType2      ; Used to link to enemy Type
                        db      2               ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100             ; Interval between enemies spawning
                        dw      100             ; Interval between spawned enemies counter
                        dw      144             ; Spawn X position - Divsable by 16
                        db      16              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      100             ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Speedy
                        dw      EnemyType3      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      64             ; Spawn X position - Divsable by 16
                        db      144              ; Spawn Y position - Divsable by 16
                        dw      100             ; Duration for enemy find state
                        dw      100            ; Duration for enemy flee state
                        db      99               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Reaper
                        dw      EnemyType5      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      192             ; Spawn X position - Divsable by 16
                        db      32              ; Spawn Y position - Divsable by 16
                        dw      100             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
EnemyDataLevel10:       db      6               ; Number of Enemy Types defined within level data
; Digger
                        dw      EnemyType2      ; Used to link to enemy Type
                        db      1               ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100             ; Interval between enemies spawning
                        dw      100             ; Interval between spawned enemies counter
                        dw      80             ; Spawn X position - Divsable by 16
                        db      16              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      15             ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Digger
                        dw      EnemyType22      ; Used to link to enemy Type
                        db      1               ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100             ; Interval between enemies spawning
                        dw      100             ; Interval between spawned enemies counter
                        dw      16             ; Spawn X position - Divsable by 16
                        db      208              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      15             ; Duration for enemy flee state
                        db      3               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Speedy
                        dw      EnemyType3      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      176             ; Spawn X position - Divsable by 16
                        db      32              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      30            ; Duration for enemy flee state
                        db      99               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Speedy
                        dw      EnemyType32      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      176             ; Spawn X position - Divsable by 16
                        db      192              ; Spawn Y position - Divsable by 16
                        dw      200             ; Duration for enemy find state
                        dw      30            ; Duration for enemy flee state
                        db      99               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Reaper
                        dw      EnemyType5      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      96             ; Spawn X position - Divsable by 16
                        db      32              ; Spawn Y position - Divsable by 16
                        dw      1000             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
; Reaper
                        dw      EnemyType52      ; Used to link to enemy Type
                        db      1              ; Maximum number of enemies to spawn (Static - Need to ensure same number of 'S' tiles placed in tilemap)
                        db      0               ; Maximum number of enemies spawned counter
                        dw      100              ; Interval between enemies spawning
                        dw      100               ; Interval between spawned enemies counter
                        dw      96             ; Spawn X position - Divsable by 16
                        db      192              ; Spawn Y position - Divsable by 16
                        dw      1000             ; Duration for enemy find state
                        dw      0            ; Duration for enemy flee state
                        db      2               ; Number of frames enemy permitted to move before delay - higher value faster enemy
