;********************************************
;	PCI bus
;
;********************************************


%ifndef __PCI__
%define __PCI__


;%include "defs.asm"
%include "gstdio.asm"
%include "gutil.asm"


%define PCI_CONFIG_ADDR 0x0CF8
%define PCI_CONFIG_DATA 0x0CFC
%define PCI_MAX_BUS		256
%define PCI_MAX_DEV		32
%define PCI_MAX_FUN		8

; Class codes
%define PCI_CLASS_CODE_MSD			0x01
%define PCI_CLASS_CODE_MULTIMED		0x04
%define PCI_CLASS_CODE_SERIALBUS	0x0C

; Subclass codes
%define PCI_SUBCLASS_CODE_IDE	0x01
%define PCI_SUBCLASS_CODE_AUDIO	0x03
%define PCI_SUBCLASS_CODE_SATA	0x06
%define PCI_SUBCLASS_CODE_USB	0x03


; 64 standardized bytes of the 256-byte PCI Config-Space
; PCI Registers (or offsets) HeaderType=0
%define PCI_VENDOR_ID			0x00	; WORD
%define PCI_DEVICE_ID			0x02	; WORD
%define PCI_COMMAND				0x04	; WORD
%define PCI_STATUS				0x06	; WORD
%define PCI_REVISION_ID			0x08	; BYTE
%define PCI_PROG_IF				0x09	; BYTE
%define PCI_SUB_CLASS			0x0A	; BYTE
%define PCI_CLASS_CODE			0x0B	; BYTE
%define PCI_CACHE_LINE_SIZE		0x0C	; BYTE
%define PCI_LATENCY_TIMER		0x0D	; BYTE
%define PCI_HEADER_TYPE			0x0E	; BYTE
%define PCI_BIST				0x0F	; BYTE
%define PCI_BAR0				0x10	; DWORD
%define PCI_BAR1				0x14	; DWORD
%define PCI_BAR2				0x18	; DWORD
%define PCI_BAR3				0x1C	; DWORD
%define PCI_BAR4				0x20	; DWORD
%define PCI_BAR5				0x24	; DWORD
%define PCI_CARDBUS_CIS_POINTER	0x28	; DWORD
%define PCI_SUBSYSTEM_VENDOR_ID	0x2C	; WORD
%define PCI_SUBSYSTEM_ID		0x2E	; WORD
%define PCI_EXP_ROM_BASE_ADDR	0x30	; DWORD
%define PCI_CAPABILITIES_PTR	0x34	; BYTE
%define PCI_INTERRUPT_LINE		0x3C	; BYTE
%define PCI_INTERRUPT_PIN		0x3D	; BYTE
%define PCI_MIN_GRANT			0x3E	; BYTE
%define PCI_MAX_LATENCY			0x3F	; BYTE

; USB Controller Types
%define PCI_USB_TYPE_UHCI	0x00
%define PCI_USB_TYPE_OHCI	0x10
%define PCI_USB_TYPE_EHCI	0x20
%define PCI_USB_TYPE_XHCI	0x30


%define PCI_UHCI_INTERRUPT_REG		0x04
%define PCI_OHCI_INTERRUPT_DISABLE	0x14
%define PCI_EHCI_CAPS_CAPLENGTH		0x00
%define PCI_EHCI_OPS_USBINTERRUPT	0x08
%define PCI_EHCI_OPS_USBSTATUS		0x04
%define PCI_XHCI_CAPS_CAPLENGTH		0x00
%define PCI_XHCI_OPS_USBCOMMAND		0x00
%define PCI_XHCI_OPS_USBSTATUS		0x04


section .text


pci_ls:
			mov ebx, PCIHeaderTxt
			call gstdio_draw_text
			mov eax, 0					; bus
.NextBus	mov ebx, 0					; slot (or device)
			mov ecx, 0					; function
			mov edx, PCI_VENDOR_ID		; offset
.NextSlot	push eax
			call pci_config_read_dword
			cmp eax, 0xFFFFFFFF	; check if deviceId and vendorID are not FFFF. Maybe check ClassId too?
			jz	.Restore
			pop eax
			call pci_print_function
			call pci_check_functions
			jmp .Continue
.Restore	pop eax
.Continue 	inc ebx
			cmp ebx, 32
			jnge .NextSlot
			inc eax
			cmp eax, 256
			jnge .NextBus
			ret


; IN: EAX bus, EBX slot(or device)
pci_check_functions:
			push ecx
			push edx
			push eax
			; check header type
			mov edx, PCI_HEADER_TYPE
			call pci_config_read_byte
			and al, 0x80				; multi-function device if not zero
			jz	.End
			pop eax
			push eax
			mov ecx, 1
.NextFun	push eax
			mov edx, PCI_VENDOR_ID		; read VendorId, if it's not 0xFFFF then function exists
			call pci_config_read_dword
			cmp ax, 0xFFFF
			jz	.Restore
			pop eax
			call pci_print_function
			jmp .IncFun
.Restore	pop eax
.IncFun		inc ecx
			cmp ecx, 0x08
			jnz	.NextFun
.End		pop eax
			pop edx
			pop ecx
			ret


; IN: EAX bus, EBX slot(or device), ECX func
; Should be printed according to BASE (DEC or HEX) !!!! or always HEX!?
pci_print_function:
			push eax
			push ebx
			push ecx
			push edx
			push esi
			push edi
			mov esi, eax
			mov edi, ebx
			; bus and slot
			mov edx, eax
			shl dx, 8
			call gstdio_draw_hex8
			mov ebx, PCI2SpacesTxt
			call gstdio_draw_text
			mov ebx, edi
			mov edx, ebx
			shl dx, 8
			call gstdio_draw_hex8
			mov ebx, PCI3SpacesTxt
			call gstdio_draw_text
			; function
			mov dh, cl
			call gstdio_draw_hex8
			mov ebx, PCI2SpacesTxt
			call gstdio_draw_text
			; get deviceId and vendorId
;			mov eax, esi
			mov ebx, edi
			mov edx, PCI_VENDOR_ID
			call pci_config_read_dword
			mov edx, eax
			shr edx, 16
			call gstdio_draw_hex16
			mov ebx, PCI2SpacesTxt
			call gstdio_draw_text
			mov edx, eax
			and edx, 0xFFFF
			call gstdio_draw_hex16
			mov ebx, PCI2SpacesTxt
			call gstdio_draw_text
			; class, subclass
			mov eax, esi
			mov ebx, edi
			mov edx, PCI_CLASS_CODE
			call pci_config_read_byte
			mov dh, al
			call gstdio_draw_hex8
			mov ebx, PCI4SpacesTxt
			call gstdio_draw_text
			mov eax, esi
			mov ebx, edi
			mov edx, PCI_SUB_CLASS
			call pci_config_read_byte
			mov dh, al
			call gstdio_draw_hex8
			call gstdio_new_line
			pop edi
			pop esi
			pop edx
			pop ecx
			pop ebx
			pop eax
			ret


; IN: EAX bus, EBX slot(or device), ECX func
pci_cfg:
			push esi
			mov edx, 0
.Next		push eax
			call pci_config_read_dword
			mov esi, [pci_cfg_arr]
			add esi, edx
			mov [esi], eax
			add edx, 4
			pop eax
			cmp edx, 0x100
			jnz	.Next

			mov esi, [pci_cfg_arr]
			mov ecx, 256
			call gutil_mem_dump
			pop esi
			ret


; lspci on Linux will help you to identify the devices on the PCI bus
pci_init:
			call pci_init_hd 
			call pci_init_ide_ctrlr
			call pci_init_sata_ctrlr	; this is necessary if we have a SATA-controller that can be switched to IDE (like ASUS EEEPC 1001px)
			call pci_init_usb
			call pci_init_hdaudio	
			ret


; Enable bus-master and memory-space, disable IRQs for PATA and SATA disks 
pci_init_hd:
			pushad
			mov eax, 0					; bus
.NextBus	mov ebx, 0					; slot (or device)
.NextDev	mov ecx, 0					; function
.NextFun	mov edx, PCI_VENDOR_ID		; offset
			push eax	
			call pci_config_read_word
			mov dx, ax
			pop eax
			cmp dx, 0xFFFF				; check vendorID
			jz	.Continue
			push eax
			mov edx, PCI_CLASS_CODE
			call pci_config_read_byte
			mov dl, al
			pop eax
			cmp dl, PCI_CLASS_CODE_MSD
			jnz	.Continue
			push eax
			mov edx, PCI_SUB_CLASS
			call pci_config_read_byte
			mov dl, al
			pop eax
			cmp dl, PCI_SUBCLASS_CODE_IDE
			jz	.FndIDE
			cmp dl, PCI_SUBCLASS_CODE_SATA
			jz	.FndSATA
			jmp .Continue
.FndIDE		mov BYTE [pci_ide_det], 1
			jmp .Fnd
.FndSATA	mov BYTE [pci_sata_det], 1
			jmp .Fnd
			; found
.Fnd		mov edx, PCI_COMMAND
			push eax
			call pci_config_read_word
			or ax, 0x0407	
			mov WORD [pci_tmp], ax
			pop eax
			call pci_config_write_word
;			jmp .Back
.Continue	inc ecx
			cmp ecx, PCI_MAX_FUN
			jnge .NextFun
			inc ebx
			cmp ebx, PCI_MAX_DEV
			jnge .NextDev
			inc eax
			cmp eax, PCI_MAX_BUS
			jnge .NextBus
.Back		popad
			ret


pci_init_ide_ctrlr:			; SHOULDN'T WE INIT bit0 and bit2 of COMMAND register!? (i/o space, bus-master)
			; Intel?					; see ICH7-datasheet
			mov eax, 0
			mov ebx, 0x1F	; 31
			mov ecx, 1
			mov edx, PCI_VENDOR_ID
			call pci_config_read_word
			cmp ax, 0x8086			; Intel
			jnz	.AMD

			; Set IDE-controller to native-mode. Only one controller should have a channel set to compatibility mode at a time. 
			mov eax, 0	
			mov ebx, 0x1F	; 31
			mov ecx, 1
			mov edx, PCI_PROG_IF
			push eax
			call pci_config_read_byte
			or al, 0x05
			mov BYTE [pci_tmp], al
			pop eax
			call pci_config_write_byte
			jmp .Back


			; AMD/ATI?					; SB700/710/750 Register Reference Guide
.AMD		mov eax, 0
			mov ebx, 0x14
			mov ecx, 1
			mov edx, PCI_VENDOR_ID
			call pci_config_read_word
			cmp ax, 0x1002
;			jnz .Back
			jnz .VIA

			; Set IDE-controller to native-mode. Only one controller should have a channel set to compatibility mode at a time. 
			mov eax, 0
			mov ebx, 0x14
			mov ecx, 1
			mov edx, PCI_PROG_IF
			push eax
			call pci_config_read_byte
			or al, 0x05
			mov BYTE [pci_tmp], al
			pop eax
			call pci_config_write_byte
;			jmp .Back

.VIA		mov eax, 0
			mov ebx, 0x0F
			mov ecx, 0
			mov edx, PCI_VENDOR_ID
			call pci_config_read_word
			cmp ax, 0x1106					; VIA ?
			jnz	.Back

			mov eax, 0						; IRQ-disabling
			mov ebx, 0x0F
			mov ecx, 0
			mov edx, PCI_COMMAND
			push eax
			call pci_config_read_word
			or	ax, 1024
			mov WORD [pci_tmp], ax
			pop eax
			call pci_config_write_word

			mov eax, 0						; IRQ-disabling
			mov ebx, 0x0F
			mov ecx, 1
			mov edx, PCI_COMMAND
			push eax
			call pci_config_read_word
			or	ax, 1024
			mov WORD [pci_tmp], ax
			pop eax
			call pci_config_write_word

.Back		ret


pci_init_sata_ctrlr:
			; Intel?						; ICH7 datasheet
			mov eax, 0
			mov ebx, 0x1F	; 31
			mov ecx, 2
			mov edx, PCI_VENDOR_ID
			call pci_config_read_word
			cmp ax, 0x8086				; Intel
			jnz	.AMD

			mov eax, 0						; IRQ-disabling
			mov ebx, 0x1F
			mov ecx, 2
			mov edx, PCI_COMMAND
			push eax
			call pci_config_read_word
			or	ax, 1024
			mov WORD [pci_tmp], ax
			pop eax
			call pci_config_write_word

			; set "SATA as IDE" mode (0 to register 0x90 of the controller);
			mov edx, 0x90
			mov BYTE [pci_tmp], 0
			call pci_config_write_byte

			; set Legacy-mode (i.e. compatibility) in register 0x09 by setting bits 0 and 2 to 0 (primary and secondary channel)
			push eax
			mov edx, 0x09
			call pci_config_read_byte
			and al, 0xFA
			mov BYTE [pci_tmp], al
			pop eax
			call pci_config_write_byte
			jmp .Back

			; AMD/ATI?					; SB700/710/750 Register Reference Guide
.AMD		mov eax, 0
			mov ebx, 0x11	; 17
			mov ecx, 0
			mov edx, PCI_VENDOR_ID
			call pci_config_read_word
			cmp ax, 0x1002
			jnz	.Back			; .VIA

			mov eax, 0						; IRQ-disabling
			mov ebx, 0x11
			mov ecx, 0
			mov edx, PCI_COMMAND
			push eax
			call pci_config_read_word
			or	ax, 1024
			mov WORD [pci_tmp], ax
			pop eax
			call pci_config_write_word

			; set bit0 of register 0x40 in order to be able to program the followings
			push eax
			mov edx, 0x40
			call pci_config_read_byte
			or al, 0x01
			mov BYTE [pci_tmp], al
			pop eax
			call pci_config_write_byte
			; clear bit24 of register 0x40 in order to be able to program the followings
			push eax
			mov edx, 0x43
			call pci_config_read_byte
			and al, 0xFE
			mov BYTE [pci_tmp], al
			pop eax
			call pci_config_write_byte

			; set deviceId to 0x4390 (IDE)
			mov edx, 0x02
			mov WORD [pci_tmp], 0x4390
			call pci_config_write_word

			; set "SATA as IDE" mode (0x01 to register 0x0A (Subclass))
			mov edx, 0x0A
			mov BYTE [pci_tmp], 0x01
			call pci_config_write_byte

			; set Legacy-mode (i.e. compatibility) in register 0x09 by setting bits 0 and 2 to 0 (primary and secondary channel)
			push eax
			mov edx, 0x09
			call pci_config_read_byte
			and al, 0xFA
			mov BYTE [pci_tmp], al
			pop eax
			call pci_config_write_byte
;			jmp .Back
.Back		ret


; Enables bus-master and memory-space and IRQs 
; Selects HDA if HDA and AC97 are shared
; Saves BAR
; Clears TCSEL
pci_init_hdaudio:
			mov eax, 0					; bus
.NextBus	mov ebx, 0					; slot (or device)
.NextDev	mov ecx, 0					; function
.NextFun	mov edx, PCI_VENDOR_ID		; offset
			push eax	
			call pci_config_read_word
			mov dx, ax
			pop eax
			cmp dx, 0xFFFF				; check vendorID
			jz	.Continue
			; is it audio?
			push eax
			mov edx, PCI_CLASS_CODE
			call pci_config_read_byte
			mov dl, al
			pop eax
			cmp dl, PCI_CLASS_CODE_MULTIMED	
			jnz	.Continue
			push eax
			mov edx, PCI_SUB_CLASS
			call pci_config_read_byte
			mov dl, al
			pop eax
			cmp dl, PCI_SUBCLASS_CODE_AUDIO
			jnz	.Continue
			; read PROG_IF
			push eax
			mov edx, PCI_PROG_IF
			call pci_config_read_byte
			mov dl, al
			pop eax
			cmp dl, 0					; ProgIF is zero ==> audio device
			je	.Fnd
.Continue	inc ecx
			cmp ecx, PCI_MAX_FUN
			jnge .NextFun
			inc ebx
			cmp ebx, PCI_MAX_DEV
			jnge .NextDev
			inc eax
			cmp eax, PCI_MAX_BUS
			jnge .NextBus
			jmp .Back
.Fnd		mov edx, PCI_COMMAND
			push eax
			call pci_config_read_word
			or ax, 0x06							; enable BusMaster and MemoryI/O
			and ax, ~0x0400						; enable IRQs
			mov WORD [pci_tmp], ax
			pop eax
			call pci_config_write_word
			mov edx, PCI_INTERRUPT_LINE			; get IRQ num
			push eax
			call pci_config_read_byte
			mov BYTE [pci_hdaudio_irq_num], al
			pop eax
			; Select HDA if HDA and AC97 are shared
			mov edx, 0x40
			push eax
			call pci_config_read_byte
			or al, 0x01
			mov BYTE [pci_tmp], al
			pop eax
			call pci_config_write_byte
			; Save BAR
			mov edx, PCI_BAR0
			push eax
			call pci_config_read_dword
			mov edx, eax
			pop eax
			mov [pci_hdaudio_base_bits4], edx
			and DWORD [pci_hdaudio_base_bits4], 0x0F	
			and edx, ~0xF
			mov [pci_hdaudio_base], edx
			test DWORD [pci_hdaudio_base_bits4], 1
			jz	.Chk64
;			mov ebx, pci_hdaudio_NotMemMappedIOTxt
;			call gstdio_draw_text
			jmp .Back
.Chk64		cmp DWORD [pci_hdaudio_base_bits4], 0x04
			jne	.ClrTCSEL
			; get upper 32bits of base0
			push eax
			mov edx, PCI_BAR1
			call pci_config_read_dword
			mov edx, eax
			pop eax
			cmp edx, 0
			je	.ClrTCSEL
;			mov ebx, pci_hdaudio_64bitBaseTxt
;			call gstdio_draw_text
			jmp .Back
			; Clear TCSEL
.ClrTCSEL	mov edx, 0x44					; TCSEL-reg
			push eax
			call pci_config_read_byte
			and al, ~0x07
			mov BYTE [pci_tmp], al
			pop eax
			call pci_config_write_byte

			; Should we enable snooping for several NVIDIA and Intel devices!?

			mov BYTE [pci_hdaudio_det], 1
.Back		ret


; detect controllers and disable IRQs 
; Enable IRQs in case of XHCI, if USB_XHCI_IRQ_DEF is defined, and get IRQNUM
pci_init_usb:
			mov eax, 0					; bus
.NextBus	mov ebx, 0					; slot (or device)
.NextDev	mov ecx, 0					; function
.NextFun	mov edx, PCI_VENDOR_ID		; offset
			push eax	
			call pci_config_read_word
			mov dx, ax
			pop eax
			cmp dx, 0xFFFF				; check vendorID
			jz	.Continue
			; is it a USB controller?
			push eax
			mov edx, PCI_CLASS_CODE
			call pci_config_read_byte
			mov dl, al
			pop eax
			cmp dl, PCI_CLASS_CODE_SERIALBUS
			jnz	.Continue
			push eax
			mov edx, PCI_SUB_CLASS
			call pci_config_read_byte
			mov dl, al
			pop eax
			cmp dl, PCI_SUBCLASS_CODE_USB
			jnz	.Continue
			push eax
			mov edx, PCI_PROG_IF
			call pci_config_read_byte
			mov dl, al
			pop eax
			cmp dl, PCI_USB_TYPE_UHCI
			jnz	.OHCI
			mov BYTE [pci_usb_uhci_det], 1
			call pci_uhci_disable_interrupts
			jmp .Continue
.OHCI		cmp dl, PCI_USB_TYPE_OHCI
			jnz	.EHCI
			mov BYTE [pci_usb_ohci_det], 1
			call pci_ohci_disable_interrupts
			jmp .Continue
.EHCI		cmp dl, PCI_USB_TYPE_EHCI
			jnz	.XHCI
			mov BYTE [pci_usb_ehci_det], 1
			call pci_ehci_disable_interrupts
			jmp .Continue
.XHCI		cmp dl, PCI_USB_TYPE_XHCI
			jnz	.Continue
			mov BYTE [pci_usb_xhci_det], 1
			call pci_xhci_disable_interrupts
%ifdef USB_XHCI_IRQ_DEF 
			push eax
			mov edx, PCI_INTERRUPT_LINE
			call pci_config_read_byte
			mov [pci_xhci_irq_num], al
			pop eax
%endif
.Continue	inc ecx
			cmp ecx, PCI_MAX_FUN
			jnge .NextFun
			inc ebx
			cmp ebx, PCI_MAX_DEV
			jnge .NextDev
			inc eax
			cmp eax, PCI_MAX_BUS
			jnge .NextBus
			ret


;UHCI
pci_uhci_disable_interrupts:
			push eax
			mov edx, PCI_BAR4
			call pci_config_read_dword
			and eax, 0xFFFFFFFC			; get rid of bits 1:0
			mov edx, eax
			add edx, PCI_UHCI_INTERRUPT_REG
			mov ax, 0
			out dx, ax
			pop eax
			ret

;OHCI
pci_ohci_disable_interrupts:
			push eax
			mov edx, PCI_BAR0
			call pci_config_read_dword
			and eax, ~0x0F
			add eax, PCI_OHCI_INTERRUPT_DISABLE
			mov DWORD [eax], 0x80000000
			pop eax
			ret

;EHCI
pci_ehci_disable_interrupts:
			pushad
			mov edx, PCI_BAR0
			call pci_config_read_dword
			and eax, ~0xF
			mov ebx, eax
			add eax, PCI_EHCI_CAPS_CAPLENGTH
			xor edx, edx
			mov dl, [eax]					; opbase in DL
			add ebx, edx
			add ebx, PCI_EHCI_OPS_USBINTERRUPT
			and DWORD [ebx], ~0x3F			; disable all interrupts
			sub edx, PCI_EHCI_OPS_USBINTERRUPT
			add edx, PCI_EHCI_OPS_USBSTATUS
			mov DWORD [edx], 0x3F			; clear any pending interrupts
			popad
			ret

;XHCI
pci_xhci_disable_interrupts:
			pushad
			mov edx, PCI_BAR0
			call pci_config_read_dword
			and eax, ~0xF

			; to OperationalBase
			mov edx, eax
			add edx, PCI_XHCI_CAPS_CAPLENGTH
			xor ebx, ebx
			mov bl, [edx]
			add eax, ebx
			add eax, PCI_XHCI_OPS_USBCOMMAND
			and DWORD [eax], ~0x04			; disable interrupts

			add eax, PCI_XHCI_OPS_USBSTATUS
			or	DWORD [eax], 0x08			; clear any pending interrupts
			popad
			ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; IN: EAX bus, EBX slot(or device), ECX func, EDX offset
pci_set_config_addr:
			push ebp
			shl	eax, 16
			mov ebp, eax
			shl	ebx, 11
			or	ebp, ebx
			shl	ecx, 8
			or	ebp, ecx
			and	edx, 0x000000FC
			or	ebp, edx
			or	ebp, 0x80000000
			mov eax, ebp
			mov dx, PCI_CONFIG_ADDR
			out dx, eax
			pop ebp
			ret


; IN: EAX bus, EBX slot(or device), ECX func, EDX offset
; OUT: AL	
pci_config_read_byte:
			push ebx
			push ecx
			push edx

			call pci_set_config_addr

			pop edx
			push edx
			and edx, 3
			add edx, PCI_CONFIG_DATA
			xor eax, eax
			in al, dx

			pop edx
			pop ecx
			pop ebx
			ret


; IN: EAX bus, EBX slot(or device), ECX func, EDX offset
; OUT: AX	
pci_config_read_word:
			push ebx
			push ecx
			push edx

			call pci_set_config_addr

		; should here be a little delay!?
			pop edx
			push edx
			and edx, 2
			add edx, PCI_CONFIG_DATA
			xor eax, eax
			in ax, dx

			pop edx
			pop ecx
			pop ebx
			ret


; IN: EAX bus, EBX slot(or device), ECX func, EDX offset
; OUT: EAX	
pci_config_read_dword:
			push ebx
			push ecx
			push edx

			call pci_set_config_addr

			mov dx, PCI_CONFIG_DATA
			in eax, dx

			pop edx
			pop ecx
			pop ebx
			ret


; IN: EAX bus, EBX slot(or device), ECX func, EDX offset, [pci_tmp] byte to write
pci_config_write_byte:
			push eax
			push ebx
			push ecx
			push edx

			call pci_set_config_addr

			pop edx
			push edx
			and edx, 3
			add edx, PCI_CONFIG_DATA
			xor eax, eax
			mov al, [pci_tmp]
			out dx, al

			pop edx
			pop ecx
			pop ebx
			pop eax
			ret


; IN: EAX bus, EBX slot(or device), ECX func, EDX offset, [pci_tmp] word to write
pci_config_write_word:
			push eax
			push ebx
			push ecx
			push edx

			call pci_set_config_addr

			pop edx
			push edx
			and edx, 2
			add edx, PCI_CONFIG_DATA
			xor eax, eax
			mov ax, [pci_tmp]
			out dx, ax

			pop edx
			pop ecx
			pop ebx
			pop eax
			ret


; IN: EAX bus, EBX slot(or device), ECX func, EDX offset, [pci_tmp] dword to write
pci_config_write_dword:
			push eax
			push ebx
			push ecx
			push edx

			call pci_set_config_addr

			mov dx, PCI_CONFIG_DATA
			mov eax, [pci_tmp]
			out dx, eax

			pop edx
			pop ecx
			pop ebx
			pop eax
			ret


section .data


pci_cfg_arr dd 0x92000	; Pointer to 256-byte PCI Config Space

pci_tmp	dd 0

pci_ide_det			db 0
pci_sata_det		db 0
pci_usb_uhci_det	db 0
pci_usb_ohci_det	db 0
pci_usb_ehci_det	db 0
pci_usb_xhci_det	db 0
pci_xhci_irq_num	db 0
pci_hdaudio_irq_num	db 0
pci_hdaudio_base	dd 0
pci_hdaudio_base_bits4	dd 0
pci_hdaudio_det		db 0

PCIHeaderTxt	db "bus slot fun devId venId class sub", 0x0A, 0
PCI2SpacesTxt	db "  ", 0
PCI3SpacesTxt	db "   ", 0
PCI4SpacesTxt	db "    ", 0

;pci_hdaudio_NotMemMappedIOTxt	db "Not memory mapped IO. ", 0
;pci_hdaudio_64bitBaseTxt		db "Base is 64-bits (32bit OS). ", 0


%endif


