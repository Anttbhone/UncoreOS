org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

; KERNEL_SECTORS is defined by the build (make passes -dKERNEL_SECTORS=n).
%ifndef KERNEL_SECTORS
%define KERNEL_SECTORS 16
%endif

; KERNEL_BASE is where the bootloader loads the kernel (flat address).
KERNEL_BASE equ 0x1000

start:
    jmp main

; BIOS teletype print. si -> null-terminated string.
puts:
    push si
    push ax
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .loop
.done:
    pop ax
    pop si
    ret

disk_error:
    mov si, msg_err
    call puts
.halt:
    jmp .halt

main:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x7C00

    mov [boot_drive], dl

    mov si, msg_loading
    call puts

    ; Read the kernel from the floppy into KERNEL_BASE.
    ; CHS: cylinder 0, head 0, sectors 2..(1+KERNEL_SECTORS).
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0
    mov cl, 0x02
    mov dh, 0
    mov dl, [boot_drive]
    mov bx, KERNEL_BASE      ; es already 0 => flat address KERNEL_BASE
    int 0x13
    jc disk_error

    mov si, msg_loaded
    call puts

    cli

    ; Load the Global Descriptor Table.
    lgdt [gdt_desc]

    ; Enable the A20 line via the fast A20 gate (purpose: wrap-free memory).
    in al, 0x92
    or al, 0x02
    out 0x92, al

    ; Switch to 32-bit protected mode.
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:pm_entry

bits 32
pm_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x90000

    jmp KERNEL_BASE

msg_loading: db 'UncoreOS: loading kernel from disk...', ENDL, 0
msg_loaded:  db 'kernel loaded. entering protected mode.', ENDL, 0
msg_err:     db 'FATAL: disk read error.', ENDL, 0
boot_drive:  db 0

align 8
gdt_start:
    dq 0                                  ; null descriptor
.code:                                    ; 0x08 32-bit code, flat
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00
.data:                                    ; 0x10 32-bit data, flat
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:
gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510 - ($ - $$) db 0
dw 0xAA55