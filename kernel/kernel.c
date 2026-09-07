#include "kernel.h"

static unsigned int kcol = 0;
static unsigned int krow = 0;
static unsigned char kcolor = 0x0F;

static inline unsigned short vga_entry(unsigned char c) {
    return (unsigned short)c | ((unsigned short)kcolor << 8);
}

static void kputc(char c) {
    if (c == '\n') {
        kcol = 0;
        krow++;
    } else {
        VGA_MEMORY[krow * VGA_WIDTH + kcol] = vga_entry(c);
        kcol++;
    }
    if (kcol >= VGA_WIDTH) {
        kcol = 0;
        krow++;
    }
    if (krow >= VGA_HEIGHT) {
        krow = 0;
    }
}

void kclear(void) {
    for (unsigned int y = 0; y < VGA_HEIGHT; y++) {
        for (unsigned int x = 0; x < VGA_WIDTH; x++) {
            VGA_MEMORY[y * VGA_WIDTH + x] = vga_entry(' ');
        }
    }
    kcol = 0;
    krow = 0;
}

void kputs(const char* s) {
    for (; *s; s++) {
        kputc(*s);
    }
}

void kernel_main(void) {
    kclear();
    kputs("WELCOME FROM UNCORE OS!");
    kputs("\nKernel: C   |   Bootloader: ASM");
    for (;;) {
        __asm__ __volatile__("hlt");
    }
}