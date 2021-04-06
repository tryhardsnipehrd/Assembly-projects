.segment "HEADER"
.byte "NES"
.byte $1a
.byte $02 ; 2 * 16KB PRG ROM
.byte $01 ; 1 * 8KB CHR ROM
.byte %00000000 ; mapper and mirroring
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00 ; filler bytes
.segment "ZEROPAGE" ; LSB 0 - FF
.segment "STARTUP"
Reset:
    SEI ; Disable all interrupts
    CLD ; Disable decimal mode

    ; Disable Sound IRQ
    LDX #$40 ; Store 40 into X
    STX $4017 ; Store the value of X into the address 4017

    ; Initialize the stack register
    LDX #$FF ; Load FF into X
    TXS ; Transfer X to the Stack Register

    INX ; #$FF + 1 => #$00

    ; Zero out the PPU registers
    STX $2000 ; Store X (0) to Memory address 2000
    STX $2001 ; Store X (0) to Memory address 2001

    ; Disable PPM
    STX $4010
; Wait for V-Blank
:
    BIT $2002
    BPL :- ; Go to the anonymous label above

    TXA ; Transfer X to A

CLEARMEM:
    STA $0000, X ; $0000 => $00FF
    STA $0100, X ; $0100 => $01FF 
    STA $0300, X
    STA $0400, X
    STA $0500, X
    STA $0600, X
    STA $0700, X
    LDA #$FF
    STA $0200, X ; This one is done later so that the Sprites appear properly
    LDA #$00
    INX ; Increment X
    BNE CLEARMEM ; Branch if not equal to CLEARMEM
    ; This works because the zero flag is set to 0 when using INX, except when it rolls over
; Wait for V-Blank
:
    BIT $2002
    BPL :- ; Go to the anonymous label above

    LDA #$02 ; Load A with value 2
    STA $4014
    NOP

    ;$3F00
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006

    LDX #$00

LoadPalettes:
    LDA PaletteData, X
    STA $2007
    INX
    CPX #$20
    BNE LoadPalettes
    
    LDX #$00

LoadSprites:
    LDA SpriteData, X ; Take the address at SpriteData at index X
    STA $0200, X
    INX
    CPX #$20
    BNE LoadSprites

    ; Enable interrupts
    CLI

    LDA #%10010000 ; enable NMI and background use seconds CHRest
    STA $2000
    ; Enabling sprites and background for left-most 8 pixels
    ; Enabling sprites and background 
    LDA #%00011110
    STA $2001


Loop:
    JMP Loop
    ; This just infinite loops

NMI:
    LDA #$02 ; Copy sprite data from $0200 => PPU for display
    STA $4014
    RTI

PaletteData:
    .byte $22,$29,$1A,$0F,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0f ; Background palette palette
    .byte $22,$16,$27,$18,$22,$1A,$30,$27,$22,$16,$30,$27,$22,$0F,$36,$17 ; Sprite palette data

SpriteData:
    .byte $20, $00, $00, $08
    .byte $20, $01, $00, $10
    .byte $28, $02, $00, $08
    .byte $28, $03, $00, $10
    .byte $30, $04, $00, $08
    .byte $30, $05, $00, $10
    .byte $38, $06, $00, $08
    .byte $38, $07, $00, $10

.segment "VECTORS"
    .word NMI
    .word Reset
    ;
.segment "CHARS"
    .incbin "Hellomario.chr"
