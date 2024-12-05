;************************
; AUDIO
;************************

%ifndef __FORTH_AU__
%define __FORTH_AU__


%include "hdaudio.asm"


section .text


;*********************************************
; _au_bar				AUBAR
;	( -- base )
; Retrieves the BaseAddress
;*********************************************
_au_bar:
			mov eax, [pci_hdaudio_base]
			PUSH_PS(eax)
			ret


;*********************************************
; _au_set_isr				AUSETISR
;	( rt -- )
; Sets the runtime-code of the HDAudio-ISR written in FORTH.
; Create a word, e.g. AUISR , then get its rt with TICK.
; Set it to zero to stop.
;*********************************************
_au_set_isr:
; cli !?
			POP_PS(eax)
			mov [hdaudio_rt_isr], eax
; sti !?
			ret


%endif


