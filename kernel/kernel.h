#ifndef _KERNEL_H
#define _KERNEL_H

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_MEMORY ((volatile unsigned short*)0xB8000)

void kclear(void);
void kputs(const char* s);
void kernel_main(void);

#endif