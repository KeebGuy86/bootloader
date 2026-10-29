[org 0x7C00]
[bits 16]

start:
    mov [boot_drive], dl        ; BIOS puts the boot drive number in dl, save it

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov si, msg_loading
    call print_string

    ; read sector 2 into memory at 0x7E00
    mov ah, 0x02                ; BIOS function: read sectors
    mov al, 1                   ; how many sectors to read
    mov ch, 0                   ; cylinder 0
    mov cl, 2                   ; sector 2 (numbering starts at 1)
    mov dh, 0                   ; head 0
    mov dl, [boot_drive]        ; which drive to read from
    mov bx, 0x7E00              ; es:bx = where the data goes
    int 0x13
    jc disk_error               ; carry flag set = the read failed

    mov si, 0x7E00              ; point at the data we just loaded
    call print_string
    jmp switch_to_pm

disk_error:
    mov si, msg_error
    call print_string

hang:
    hlt
    jmp hang

print_string:                   ; prints the zero-ended text si points to
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    mov bh, 0                   ; display page 0
    int 0x10
    jmp print_string
.done:
    ret

; ---------- the GDT ----------
gdt_start:
    dq 0x0                      ; null descriptor (the CPU requires one)
gdt_code:
    dw 0xFFFF                   ; limit, low 16 bits
    dw 0x0000                   ; base, low 16 bits
    db 0x00                     ; base, middle 8 bits
    db 10011010b                ; access: present, ring 0, code, readable
    db 11001111b                ; flags: 4K pages, 32-bit; limit, high 4 bits
    db 0x00                     ; base, high 8 bits
gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b                ; access: present, ring 0, data, writable
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; size of the GDT, minus 1
    dd gdt_start                ; where the GDT lives in memory

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

switch_to_pm:
    cli                         ; no interrupts during the switch
    lgdt [gdt_descriptor]       ; tell the CPU where the GDT is
    mov eax, cr0
    or eax, 1                   ; set the protected-mode bit
    mov cr0, eax
    jmp CODE_SEG:pm_start       ; far jump: loads the new code segment

[bits 32]
pm_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000            ; a fresh stack

    cld                         ; make string instructions count upward
    mov edi, 0xB8000            ; start of video memory
    mov ecx, 80 * 25            ; 80 columns by 25 rows
    mov ax, 0x0720              ; space character, light grey on black
    rep stosw                   ; fill the whole screen with it

    mov esi, pm_message
    mov edi, 0xB8000            ; top-left corner of the screen
.print:
    lodsb                       ; al = next character
    cmp al, 0
    je .halt
    mov ah, 0x0F                ; white on black
    mov [edi], ax               ; write character + colour into video memory
    add edi, 2
    jmp .print
.halt:
    hlt
    jmp .halt

boot_drive  db 0
msg_loading db "Loading sector 2...", 13, 10, 0
msg_error   db "Disk read failed!", 0
pm_message  db "Now running in 32-bit protected mode!", 0

times 510 - ($ - $$) db 0
dw 0xAA55

; ---- sector 2 starts here ----
db "Hello from sector 2!", 0
times 1024 - ($ - $$) db 0