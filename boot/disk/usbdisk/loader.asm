bits 16


org  0x9000	; Entering PMode (jump to Stage3) reboots with "org 0" (because boot.asm loads it to 0x9000, and base in GDT-table is zero)

jmp	main		

%include "gdt.asm"	
%include "a20.asm"	
%include "boot/fat32.asm"
%include "defs.asm"
%include "ram.asm"
%include "vga.asm"
;%include "vga2.asm"
%include "stdio16.asm"

bits 16


main:
			cli				
			xor	ax, ax	
			mov	ds, ax
			mov	es, ax
			mov	ax, 0x0700	
			mov	ss, ax
			mov	sp, 0x1000	
			sti				

			mov [drivenum], dl
			mov [partition_lba_begin], ebx
mov [0x1FF7], dl
mov [0x1FF8], ebx

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

			;-------------------------------;
			; VGAInfo
			;-------------------------------;
;			call vga2_info
;			call vga2_modes
;			mov	si, msgPressSpace
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
			mov	si, msgGUINotAvail
			call stdio16_puts
			jmp $			

.Msg		mov	si, msgLoading
			call stdio16_puts

			mov dl, [drivenum]
			mov eax, [partition_lba_begin]
			call fat32_init

			mov eax, IMAGE_RMODE_BASE
			shr eax, 4
			mov es, ax
			mov di, 0
			mov	bx, filename	
			call fat32_readfile		
			mov	[KERNEL_SIZE_LOC], ecx	
			cmp	ecx, 0			
			jne	.USB	
			mov	si, msgFailure		
			call stdio16_puts
			mov	ah, 0
			int 0x16				
			int 0x19			
			cli					
			hlt

.USB:
			mov eax, USB_BASE
			shr eax, 4
			mov es, ax
			mov di, 0
			mov	bx, filenameUSB		
			call fat32_readfile		
			mov	[USB_SIZE_LOC], ecx	
			cmp	ecx, 0				
			jne	.USBFS
			mov	si, msgFailureUSB	
			call stdio16_puts
			mov	ah, 0
			int 0x16				
			int 0x19				
			cli					
			hlt

.USBFS:
			mov eax, USBFS_BASE
			shr eax, 4
			mov es, ax
			mov di, 0
			mov	bx, filenameUSBFS		
			call fat32_readfile		
			mov	[USBFS_SIZE_LOC], ecx	
			cmp	ecx, 0				
			jne	.EnterStage3			
			mov	si, msgFailureUSBFS	
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
			mov	ax, GDT_DATA_DESC		; set data segments to data selector (0x10)
			mov	ds, ax
			mov	ss, ax
			mov	es, ax
			mov	esp, 90000h	

CopyImage:
			mov ecx, [KERNEL_SIZE_LOC]
			shr ecx, 2		
			inc ecx		
			cld
			mov esi, IMAGE_RMODE_BASE
			mov edi, IMAGE_PMODE_BASE
			rep movsd		

			jmp	GDT_CODE_DESC:IMAGE_PMODE_BASE	

			cli
			hlt


drivenum			db 0		; the drive we booted from
partition_lba_begin	dd 0

IMAGE_RMODE_BASE 	equ		0xD000
IMAGE_PMODE_BASE 	equ		0x200000
USB_BASE 			equ 	0x30000
USBFS_BASE 			equ 	0x40000

; the same as in hdloader.asm, ram.asm, kernel.asm and forth/core.asm
;RAM_MAP_ENT_LOC		equ	0x6FFE
;RAM_MAP_LOC			equ	0x7000
RAM_SIZE_LO_LOC		equ	0x8FF4
RAM_SIZE_HI_LOC		equ	0x8FF8
KERNEL_SIZE_LOC		equ	0x8FFC
USB_SIZE_LOC		equ 0x8FEC
USBFS_SIZE_LOC		equ	0x8FE8

; kernel name (Must be 11 bytes)
filename		db "KRNL    SYS"
filenameUSB		db "USB     TXT"
filenameUSBFS	db "USBFS   TXT"

msgLoading		db 0x0D, 0x0A, "Searching for Operating System...", 0
%ifdef NORMALRES_DEF
	msgGUINotAvail	db 0x0D, 0x0A, "1024*768*16 with linear framebuffer not available", 0
%else
	msgGUINotAvail	db 0x0D, 0x0A, "640*480*16 with linear framebuffer not available", 0
%endif
msgFailure		db 0x0D, 0x0A, "*** FATAL: MISSING OR CORRUPT KRNL.SYS. Press Any Key to Reboot", 0x0D, 0x0A, 0x0A, 0
msgFailureUSB	db 0x0D, 0x0A, "*** FATAL: MISSING OR CORRUPT USB.TXT. Press Any Key to Reboot", 0x0D, 0x0A, 0x0A, 0
msgFailureUSBFS	db 0x0D, 0x0A, "*** FATAL: MISSING OR CORRUPT USBFS.TXT. Press Any Key to Reboot", 0x0D, 0x0A, 0x0A, 0
;msgPressSpace	db "Press SPACE To Continue", 0x0D, 0x0A, 0



