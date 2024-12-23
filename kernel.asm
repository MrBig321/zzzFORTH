;*******************************************************
;
;	kernel.asm (Stage3)
;		A basic 32 bit binary kernel running
;
;	OS Development Series
;*******************************************************

%ifndef __KERNEL__
%define __KERNEL__


org	0x200000			; Kernel starts at 2 MB

bits 32					; 32 bit code

jmp	Stage3				; jump to entry point

%include "defs.asm"
%include "cpu.asm"
%include "idt.asm"
%include "pic.asm"
%include "pit.asm"
%include "kybrd.asm"
%include "pci.asm"
%include "gstdio.asm"
%include "forth/core.asm"


; several are the same as in loader.asm, hdloader.asm, hdfsloader.asm, forth/hd.asm, ram.asm, kernel.asm (and MemMap in forth/common.asm)
%define	RAM_MAP_ENT_LOC		0x6FFE
%define	RAM_MAP_LOC			0x7000
%define FRAMEBUFF			0x8FF0	; from vga.asm
%define RAM_SIZE_LO_LOC		0x8FF4
%define RAM_SIZE_HI_LOC		0x8FF8
%define KERNEL_SIZE_LOC		0x8FFC


Stage3:
			;-------------------------------;
			;   Set registers				;
			;-------------------------------;
			mov	ax, 0x10		; set data segments to data selector (0x10)
			mov	ds, ax
			mov	ss, ax
			mov	es, ax
			mov	esp, STACKBUFF+STACKLEN		; stack begins from here (intel first decrements ESP, only then does it store value)

			mov ebx, [FRAMEBUFF]
			mov [gstdio_framebuff], ebx

			; set MTRR
			mov ebp, [gstdio_framebuff]
			mov esi, GSTDIO_SCREEN_BYTES
			mov edi, CPU_MEM_TYPE_WC
			call cpu_set_mtrr
			; end of MTRR

			call pci_init

			;-------------------------------;
			; set IDT
			;-------------------------------;
			call idt_init
			call idt_load_isrs

			call pic_init
			call pit_init
			call pit_start_counter

			call kybrd_init

			; enable interrupts after installing timer and keyboard
			sti

			;---------------------------------------;
			;   Clear screen and print success		;
			;---------------------------------------;

			mov ebx, 1
			call gstdio_clrscr
			mov	ebx, msg
			call gstdio_draw_text

			; CPU
			call cpu_get_info
			call cpu_show_info

			; RAM  (calculated in Real Mode)
			mov ebx, RAMTxt
			call gstdio_draw_text
			mov eax, DWORD [RAM_SIZE_LO_LOC]
			mov edx, DWORD [RAM_SIZE_HI_LOC]
			shr eax, 20						; get Mb (/(1024*1024))
			cmp edx, 0
			jz	.DrawRAM
			shl	edx, 12
			or eax, edx
.DrawRAM	call gstdio_draw_dec
			mov ebx, MiBTxt
			call gstdio_draw_text
			call gstdio_new_line

			; Hard Disk
.HD			mov ebx, HDTxt
			call gstdio_draw_text
			cmp BYTE [pci_ide_det], 1
			jz	.IDE
			cmp BYTE [pci_sata_det], 1
			jz	.SATA
			mov ebx, CouldntDetectTxt
			call gstdio_draw_text
			call gstdio_new_line
			jmp .Audio
.IDE		mov ebx, IDETxt
			call gstdio_draw_text
			jmp .Audio
.SATA		mov ebx, SATATxt
			call gstdio_draw_text

			; Audio
.Audio 		mov ebx, AudioTxt
			call gstdio_draw_text
			cmp BYTE [pci_hdaudio_det], 1
			jz	.HDAudio
			mov ebx, CouldntDetectTxt
			call gstdio_draw_text
			call gstdio_new_line
			jmp .USB
.HDAudio 	mov ebx, HDAudioTxt
			call gstdio_draw_text

			; USB
.USB 		mov ebx, USBTxt
			call gstdio_draw_text
			cmp BYTE [pci_usb_uhci_det], 1
			jnz	.OHCI
			mov ebx, UHCITxt
			call gstdio_draw_text
.OHCI		cmp BYTE [pci_usb_ohci_det], 1
			jnz	.EHCI
			mov ebx, OHCITxt
			call gstdio_draw_text
.EHCI		cmp BYTE [pci_usb_ehci_det], 1
			jnz	.XHCI
			mov ebx, EHCITxt
			call gstdio_draw_text
.XHCI		cmp BYTE [pci_usb_xhci_det], 1
			jnz	.NL
			mov ebx, XHCITxt
			call gstdio_draw_text

.NL			call gstdio_new_line

			; Kernel
.Kern		mov ebx, KernelTxt
			call gstdio_draw_text
			mov eax, DWORD [KERNEL_SIZE_LOC]	; in bytes
			shr eax, 10						; /1024
			call gstdio_draw_dec
			mov ebx, KiBTxt
			call gstdio_draw_text
			call gstdio_new_line
			call gstdio_new_line

;cmp BYTE [cpu_mtrr], 1
;jne	ColdStart
;mov ebx, MTRRTxt
;call gstdio_draw_text

;FORTH
ColdStart:	call forth_init
WarmStart:	call _quit

			;---------------------------------------;
			;   Stop execution						;
			;---------------------------------------;

			cli
			hlt					; How to shutdown the CPU!? (ACPI)


section .data

msg db  0x0A, 0x0A, "                Welcome to zzzFORTH 20241222 ", 0x0A, 0x0A, 0

RAMTxt		db "RAM: ", 0
HDTxt		db "HD: ", 0
AudioTxt	db "Audio: ", 0
USBTxt		db "USB: ", 0
MiBTxt		db " MiB", 0
CouldntDetectTxt	db "Couldn't detect", 0
KernelTxt	db "Kernel: ", 0
KiBTxt		db " KiB", 0
HDAudioTxt	db "HD Audio", 0x0A, 0
IDETxt		db "IDE", 0x0A, 0
SATATxt		db "SATA", 0x0A, 0
UHCITxt		db "UCHI ", 0
OHCITxt		db "OCHI ", 0
EHCITxt		db "ECHI ", 0
XHCITxt		db "XCHI ", 0

;MTRRTxt		db "MTRR supported", 0x0A, 0


%endif

