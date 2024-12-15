bits 16	

org	0

start:	jmp	main

;*********************************************
;	BIOS Parameter Block
;*********************************************

; BPB Begins 3 bytes from start. We do a far jump, which is 3 bytes in size.
; If you use a short jump, add a "nop" after it to offset the 3rd byte.

bpbOEM					db "My OS   "
bpbBytesPerSector:  	DW 512
bpbSectorsPerCluster: 	DB 1
bpbReservedSectors: 	DW 1
bpbNumberOfFATs:		DB 2
bpbRootEntries:			DW 224
bpbTotalSectors:		DW 2880
bpbMedia:				DB 0xF0	
bpbSectorsPerFAT:		DW 9
bpbSectorsPerTrack: 	DW 18
bpbHeadsPerCylinder: 	DW 2
bpbHiddenSectors:		DD 0
bpbTotalSectorsBig:     DD 0
bsDriveNumber: 	        DB 0 
bsUnused:				DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:	        DD 0xa0a1a2a3
bsVolumeLabel: 	        DB "MOS FLOPPY " 
bsFileSystem: 	        DB "FAT12   " 


;************************************************;
;	Prints a string
;	DS=>SI: 0 terminated string
;************************************************;
Print:		lodsb 
			or al, al	
			jz .PrintDone	
			mov	ah, 0eh	
			int	10h
			jmp	Print	
.PrintDone:	ret	


;************************************************;
; Reads a series of sectors
; CX=>Number of sectors to read
; AX=>Starting sector
; ES:BX=>Buffer to read to
;************************************************;
ReadSectors:
.MAIN		mov di, 0x0005	
.SECTORLOOP	push ax
			push bx
			push cx
			call LBACHS	
			mov ah, 0x02	
			mov al, 0x01	
			mov ch, BYTE [absoluteTrack]
			mov cl, BYTE [absoluteSector]
			mov dh, BYTE [absoluteHead]	
			mov dl, BYTE [bsDriveNumber]
			int 0x13	
			jnc .SUCCESS	
			xor ax, ax	
			int 0x13	
			dec di	
			pop cx
			pop bx
			pop ax
			jnz .SECTORLOOP	
			int 0x18
.SUCCESS	mov si, msgProgress
 			call Print
			pop cx
			pop bx
			pop ax
			add bx, WORD [bpbBytesPerSector]
			inc ax		
			loop .MAIN	
			ret


;************************************************;
; Convert CHS to LBA
; LBA = (cluster - 2) * sectors per cluster
;************************************************;
ClusterLBA:
			sub ax, 0x0002	
			xor cx, cx
			mov cl, BYTE [bpbSectorsPerCluster]	
			mul cx
			add ax, WORD [datasector]	
			ret
     

;************************************************;
; Convert LBA to CHS
; AX=>LBA Address to convert
;
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
;
;************************************************;
LBACHS:
			xor dx, dx	
			div WORD [bpbSectorsPerTrack]
			inc dl	
			mov BYTE [absoluteSector], dl
			xor dx, dx	
			div WORD [bpbHeadsPerCylinder]	
			mov BYTE [absoluteHead], dl
			mov BYTE [absoluteTrack], al
			ret


;*********************************************
;	Bootloader Entry Point
;*********************************************

main:
			cli			
			mov ax, 0x07C0	
			mov ds, ax
			mov es, ax	
			mov fs, ax
			mov gs, ax

			mov ax, 0x0000	
			mov ss, ax
			mov sp, 0xFFF0
			sti			

	; Ensure 80*25
			mov ax, 3  
			int 10h

			mov si, msgLoading
			call Print
          
LOAD_ROOT:
			xor cx, cx
			xor dx, dx
			mov ax, 0x0020		
			mul WORD [bpbRootEntries]	
			div WORD [bpbBytesPerSector]
			xchg ax, cx
          
			mov al, BYTE [bpbNumberOfFATs]	
			mul WORD [bpbSectorsPerFAT]	
			add ax, WORD [bpbReservedSectors]
			mov WORD [datasector], ax	
			add WORD [datasector], cx
          
			mov bx, 0x0200			
			call ReadSectors

			mov cx, WORD [bpbRootEntries]	
			mov di, 0x0200	
.LOOP:		push cx
			mov cx, 0x000B		
			mov si, ImageName 
			push di

			rep cmpsb		
			pop di
			je LOAD_FAT
			pop cx
			add di, 0x0020	
			loop .LOOP
			jmp FAILURE

LOAD_FAT:
			mov si, msgCRLF
			call Print
			mov dx, WORD [di + 0x001A]
			mov WORD [cluster], dx		
          
			xor ax, ax
			mov al, BYTE [bpbNumberOfFATs]	
			mul WORD [bpbSectorsPerFAT]	
			mov cx, ax

			mov ax, WORD [bpbReservedSectors]	
          
			mov bx, 0x0200	
			call ReadSectors

			mov si, msgCRLF
			call Print
			mov ax, 0x0900
			mov es, ax		
			mov bx, 0x0000	
			push bx

LOAD_IMAGE:
			mov ax, WORD [cluster]	
			pop bx			
			call ClusterLBA		
			xor cx, cx
			mov cl, BYTE [bpbSectorsPerCluster]	
			call ReadSectors
			push bx
          
			mov ax, WORD [cluster]	
			mov cx, ax			
			mov dx, ax		
			shr dx, 0x0001		
			add cx, dx		
			mov bx, 0x0200		
			add bx, cx			
			mov dx, WORD [bx]	
			test ax, 0x0001
			jnz .ODD_CLUSTER
          
.EVEN_CLUSTER:     
			and dx, 0000111111111111b	
			jmp .DONE
         
.ODD_CLUSTER:
			shr dx, 0x0004			
          
.DONE:		mov WORD [cluster], dx	
			cmp dx, 0x0FF0			
			jb LOAD_IMAGE
          
DONE:
			mov si, msgCRLF
			call Print
			push WORD 0x0900
			push WORD 0x0000
			retf
          
FAILURE:     
			mov si, msgFailure
			call Print
			mov ah, 0x00
			int 0x16			
			int 0x19		
     
absoluteSector	db 0x00
absoluteHead	db 0x00
absoluteTrack	db 0x00
     
datasector		dw 0x0000
cluster			dw 0x0000
ImageName		db "KRNLDR  SYS"
msgLoading		db 0x0D, 0x0A, "Loading Boot Image ", 0x0D, 0x0A, 0x00
msgCRLF			db 0x0D, 0x0A, 0x00
msgProgress		db ".", 0x00
msgFailure		db 0x0D, 0x0A, "ERROR : Press Any Key to Reboot", 0x0A, 0x00
     
TIMES 510-($-$$) DB 0
DW 0xAA55

