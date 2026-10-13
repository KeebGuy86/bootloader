[org 0x7C00]                     ; BIOS loads up at this address
[bits 16]                        ; The CPU starts in 16-bit real mode

start:
    cli    ; pause all interups during setup
    xor ax, ax    ; ax = 0
    mov ds, ax    ; data segment = 0
    mov es, ax    ; extra segment = 0
    mov ss, ax    ; stack segment = 0
    mov sp, 0x7C00    ; the stack will grow down
    sti    ; interupts are turned back on

    mov si, message    ; si points at the first letter

print_loop:
    lodsb    ; al = byte at [si], then si++
    cmp al, 0    ; the zero marks the end of the text
    je hang
    mov ah, 0x0E    ; BIOS function: prints one character
    int 0x10    ; calls the BIOS video service
    jmp print_loop

hang:
    hlt    ; sleeps the CPU
    jmp hang    ; and keeps it sleeping, until otherwise

message db "Hello World from my bootlaoder!", 0

times 510 - ($ - $$) db 0    ; fill the rest of the 512 bytes with zeros
dw 0xAA55     ; boot signature