[org 0x7C00]
[bits 16]

start:
    mov [boot_drive], dl    ;BIOS puts the boot_drive number in dl, saves it

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
    mov ah, 0x02            ; BIOS function: reads sectors
    mov al, 1               ; how many sectors to read
    mov ch, 0               ; cylinder 0
    mov cl, 2               ; sector 2 (sector numbers start at 1)
    mov dh, 0               ; head 0
    mov dl, [boot_drive]    ; which drive to read from
    mov bx, 0x7E00          ; es:bx = where to put the data
    int 0x13
    jc disk_error           ; carry flag set = the read failed

    mov si, 0x7E00
    call print_string
    jmp hang

disk_error:
    mov si, msg_error
    call print_string

hang:
    hlt
    jmp hang

print_string:               ; prints the zero-ended text that si points to 
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp print_string
.done:
    ret 


boot_drive db 0
msg_loading db "Loading sector 2...", 13, 10, 0
msg_error db "Disk Read Failed!", 0

times 510 - ($ - $$) db 0
dw 0xAA55

; ----- sector 2 start here -----
db "Hello from sector 2", 0
times 1024 - ($ - $$) db 0