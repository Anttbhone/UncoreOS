ASM = nasm
CC  = i686-elf-gcc
LD  = i686-elf-ld

SRC_DIR   = src
BUILD_DIR = build
KERNEL_BASE = 0x1000

KERNEL_SECTORS = $(shell [ -f $(BUILD_DIR)/kernel.bin ] && echo $$(( ($$(stat -f%z $(BUILD_DIR)/kernel.bin) + 511) / 512 )) || echo 1)

.PHONY: all clean run

all: $(BUILD_DIR)/main.floppy.img

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/boot.bin: $(SRC_DIR)/boot.asm $(BUILD_DIR)/kernel.bin | $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/boot.asm -f bin -dKERNEL_SECTORS=$(KERNEL_SECTORS) -o $@

$(BUILD_DIR)/kernel_entry.o: $(SRC_DIR)/kernel_entry.asm | $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/kernel_entry.asm -f elf32 -o $@

$(BUILD_DIR)/kernel.o: $(SRC_DIR)/kernel.c $(SRC_DIR)/kernel.h | $(BUILD_DIR)
	$(CC) -ffreestanding -nostdlib -fno-builtin -fno-stack-protector -Wall -Wextra -O2 -m32 -c $< -o $@

$(BUILD_DIR)/kernel.bin: $(BUILD_DIR)/kernel_entry.o $(BUILD_DIR)/kernel.o
	$(LD) -Ttext $(KERNEL_BASE) --oformat=binary -m elf_i386 $^ -o $@

$(BUILD_DIR)/main.floppy.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/kernel.bin
	cat $^ > $@
	truncate -s 1440k $@

# quick check that the kernel fits in the sectors the bootloader reads
check: $(BUILD_DIR)/kernel.bin
	@test $$(stat -f%z $(BUILD_DIR)/kernel.bin) -le 9216 || (echo "kernel too big (>9KB)"; exit 1)

run: all
	qemu-system-i386 -drive format=raw,file=$(BUILD_DIR)/main.floppy.img -monitor none -display curses

clean:
	rm -rf $(BUILD_DIR)