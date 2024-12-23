%ifndef __HDAUDIO__
%define __HDAUDIO__


%include "forth/common.asm"


section .text


hdaudio_handle_irq:
			mov eax, [hdaudio_rt_isr]
			cmp eax, 0
			jz	.Back

			; save vars to stack
			mov eax, [_pstack0]
			push eax
			mov eax, [_rstack0]
			push eax
			mov eax, [_ip]
			push eax
			mov eax, [tmpip] 
			push eax

		; This seems to work !!
			 mov DWORD [_rstack0], 0xA01000  ; from FMM
			 mov edi, [_rstack0]
			 mov DWORD [_pstack0], 0xA02000  ; from FMM   
			 mov esi, [_pstack0]

			; have clean STACKs 
; The code below repeats a few seconds of music, something gets overwritten.
; This is why currently the code above is used.
;			sub edi, (CELL_SIZE*16)				; To have a clean RSTACK (no Deref in e.g. EXECUTE)
;			mov [_rstack0], edi
;			sub esi, (CELL_SIZE*16)				; To have a clean PSTACK !?
;			mov [_pstack0], esi

			mov eax, [hdaudio_rt_isr]
			PUSH_PS(eax)
			call _execute

			; restore vars
			pop eax
			mov [tmpip], eax
			pop eax
			mov [_ip], eax
			pop eax
			mov [_rstack0], eax
			pop eax
			mov [_pstack0], eax
.Back		ret


section .data


; runtime-ptr of handler written in FORTH
hdaudio_rt_isr dd 0


%endif


