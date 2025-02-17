bits 16

; We are loaded at 0x9000 (0x900:0)

org 0x9000

jmp	main	

%include "gdt.asm"	
%include "a20.asm"	
%include "boot/fat12.asm" 
%include "defs.asm"
%include "ram.asm"
%include "vga.asm"
;%include "vga2.asm"
%include "stdio16.asm"


bits 16		


%define IMAGE_RMODE_BASE 0xD000
%define IMAGE_PMODE_BASE 0x200000
%define USB_BASE 0x30000
%define USBFS_BASE 0x40000

; the same as in loader.asm, hdloader.asm, hdfsloader.asm, forth/hd.asm, ram.asm, kernel.asm (and MemMap in forth/common.asm)
;%define	RAM_MAP_ENT_LOC	0x6FFE
;%define	RAM_MAP_LOC		0x7000
%define RAM_SIZE_LO_LOC	0x8FF4
%define RAM_SIZE_HI_LOC	0x8FF8
%define KERNEL_SIZE_LOC	0x8FFC
%define USB_SIZE_LOC	0x8FEC
%define USBFS_SIZE_LOC	0x8FE8

; kernel name (Must be 11 bytes)
ImageName	db "KRNL    SYS"
USBName		db "USB     TXT"
USBFSName	db "USBFS   TXT"

LoadingMsg db 0x0D, 0x0A, "Searching for Operating System...", 0x00
%ifdef NORMALRES_DEF
	GUINotAvail db 0x0D, 0x0A, "1024*768*16 with linear framebuffer not available", 0x00
%else
	GUINotAvail db 0x0D, 0x0A, "640*480*16 with linear framebuffer not available", 0x00
%endif
msgFailure db 0x0D, 0x0A, "*** FATAL: MISSING OR CORRUPT KRNL.SYS. Press Any Key to Reboot", 0x0D, 0x0A, 0x0A, 0x00
msgUSBFailure db 0x0D, 0x0A, "*** FATAL: MISSING OR CORRUPT USB.TXT. Press Any Key to Reboot", 0x0D, 0x0A, 0x0A, 0x00
msgUSBFSFailure db 0x0D, 0x0A, "*** FATAL: MISSING OR CORRUPT USBFS.TXT. Press Any Key to Reboot", 0x0D, 0x0A, 0x0A, 0x00
;PressSpace db "Press SPACE To Continue", 0x0D, 0x0A, 0


main:
			cli	
			xor	ax, ax	
			mov	ds, ax
			mov	es, ax
			mov	ax, 0x0700
			mov	ss, ax
			mov	sp, 0x1000
			sti	

			call gdt_init 

			call a20_enable_kybrd_out

			call ram_get
			call ram_copy_memmap
;			call ram_show				; will show it in protected mode
;.WaitForKey	mov ax, 0x100	
;			int 0x16
;			jz .WaitForKey
			mov eax, [ram_size_hi]
			mov	[RAM_SIZE_HI_LOC], eax	
			mov eax, [ram_size_lo]
			mov	[RAM_SIZE_LO_LOC], eax
			mov ax, [ram_map_ent]
			mov	[RAM_MAP_ENT_LOC], ax	

;			call vga2_info
;			call vga2_modes
;			mov	si, PressSpace
;			call stdio16_puts
;.WaitForKey	mov ax, 0x100	
;			int 0x16
;			jz .WaitForKey

;			xor	ax, ax	
;			int 0x16 
;			cmp ah, 0x39 
;			jnz .WaitForKey

			call vga_get_framebuff
			cmp eax, 0
			jnz	.Msg
			mov	si, GUINotAvail
			call stdio16_puts
			jmp $			

.Msg		mov	si, LoadingMsg
			call stdio16_puts

			call LoadRoot	

			mov	ebx, IMAGE_RMODE_BASE 
			shr ebx, 4
		    mov	bp, 0 
			mov	si, ImageName	
			call LoadFile	
			shl ecx, 9	
			mov	[KERNEL_SIZE_LOC], ecx	
			cmp	ax, 0	
			je	.USB	
			mov	si, msgFailure	
			call stdio16_puts
			mov	ah, 0
			int 0x16	
			int 0x19	
			cli	
			hlt

.USB:
			xor eax, eax
			mov	ds, ax
			mov	es, ax

			mov	ebx, USB_BASE 
			shr ebx, 4
		    mov	bp, 0 
			mov	si, USBName	
			call LoadFile
			shl ecx, 9	
			mov	[USB_SIZE_LOC], ecx	
			cmp	ax, 0
			je	.USBFS
			mov	si, msgUSBFailure
			call stdio16_puts
			mov	ah, 0
			int 0x16
			int 0x19
			cli	
			hlt

.USBFS:
			xor eax, eax
			mov	ds, ax
			mov	es, ax

			mov	ebx, USBFS_BASE	
			shr ebx, 4
		    mov	bp, 0 
			mov	si, USBFSName
			call LoadFile
			shl ecx, 9
			mov	[USBFS_SIZE_LOC], ecx
			cmp	ax, 0
			je	.EnterStage3	
			mov	si, msgUSBFSFailure	
			call stdio16_puts
			mov	ah, 0
			int 0x16
			int 0x19
			cli	
			hlt

.EnterStage3:
%ifdef NORMALRES_DEF
			; switch to 1024*768*16
			mov bx, VGA_NORMALRES
%else
			; switch to 640*480*16
			mov bx, VGA_SMALLRES
%endif
			call vga_switch_to_mode

			cli	
			mov	eax, cr0
			or eax, 1
			mov	cr0, eax

			jmp	GDT_CODE_DESC:Stage3

bits 32

Stage3:
			mov	ax, GDT_DATA_DESC	
			mov	ds, ax
			mov	ss, ax
			mov	es, ax
			mov	esp, 90000h	

CopyImage:
			mov ecx, [KERNEL_SIZE_LOC]
			shr ecx, 2	
			inc	ecx	
			cld
			mov esi, IMAGE_RMODE_BASE
			mov edi, IMAGE_PMODE_BASE
			rep movsd

			jmp	GDT_CODE_DESC:IMAGE_PMODE_BASE

			cli
			hlt





