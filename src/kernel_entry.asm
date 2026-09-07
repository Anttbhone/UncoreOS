; Entry point: start of the flat kernel binary at KERNEL_BASE.
; Sets up a stack and calls the C entry point. Remains ASM (boot-side).
bits 32
section .text
global _start
extern kernel_main

_start:
    mov esp, 0x90000
    call kernel_main
    cli
.halt:
    hlt
    jmp .halt