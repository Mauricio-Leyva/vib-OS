/*
 * Vib-OS Kernel Linker Script for Limine bootloader
 * Higher-half kernel for x86_64
 */

/* Virtual base at -2GB (canonical higher half) */
KERNEL_VIRT = 0xFFFFFFFF80000000;
KERNEL_PHYS = 0x100000;  /* 1MB physical load address */

ENTRY(_start)

PHDRS {
    limine   PT_LOAD FLAGS(4);  /* r-- (read-only requests) */
    text     PT_LOAD FLAGS(5);  /* r-x (code) */
    rodata   PT_LOAD FLAGS(4);  /* r-- (read-only data) */
    data     PT_LOAD FLAGS(6);  /* rw- (read-write data) */
}

SECTIONS {
    . = KERNEL_VIRT;
    __kernel_start = .;

    .limine_requests : AT(KERNEL_PHYS) {
        KEEP(*(.limine_requests))
    } :limine

    . = ALIGN(4K);

    .text : AT(KERNEL_PHYS + (. - KERNEL_VIRT)) {
        __text_start = .;
        *(.text .text.*)
        __text_end = .;
    } :text

    . = ALIGN(4K);

    .rodata : AT(KERNEL_PHYS + (. - KERNEL_VIRT)) {
        __rodata_start = .;
        *(.rodata .rodata.*)
        __rodata_end = .;
    } :rodata

    . = ALIGN(4K);

    .data : AT(KERNEL_PHYS + (. - KERNEL_VIRT)) {
        __data_start = .;
        *(.data .data.*)
        __data_end = .;
    } :data

    . = ALIGN(4K);

    .bss : AT(KERNEL_PHYS + (. - KERNEL_VIRT)) {
        __bss_start = .;
        *(.bss .bss.*)
        *(COMMON)
        __bss_end = .;
    } :data

    /* Stack */
    . = ALIGN(16);
    __stack_bottom = .;
    . += 64K;  /* 64KB kernel stack */
    __stack_top = .;

    . = ALIGN(4K);
    __kernel_end = .;

    /* Discard unwanted sections */
    /DISCARD/ : {
        *(.comment)
        *(.note*)
        *(.eh_frame*)
    }
}
