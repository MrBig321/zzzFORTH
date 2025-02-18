; NOT USED!!
%ifndef __FORTH_QUAD__
%define __FORTH_QUAD__

; QCELL, 128-bit 


;*********************************************
; _d_to_q				D>Q
;	( d -- q )
;
;	Convert the number d to the quad-cell number q 
;	with the same numerical value. 
;*********************************************
_d_to_q:
			xor ebx, ebx
			test DWORD [esi], (1 << 31)
			jz	.Pos
			mov ebx, 1
			push ebx
			call _d_negate
			pop ebx
.Pos		PUSH_PS(0)
			PUSH_PS(0)
			cmp ebx, 1
			jnz .Back
			call _q_negate
.Back		ret


;*********************************************
; _q_to_d				Q>D
;	( q -- d )
;
;	d is the equivalent of q. An ambiguous condition exists 
;	if q lies outside the range of a signed double-cell number. 
;*********************************************
_q_to_d:
			xor ebx, ebx
			test DWORD [esi], (1 << 31)
			jz	.Pos
			mov ebx, 1
			push ebx
			call _q_negate
			pop ebx
.Pos		call _two_drop 
			cmp ebx, 1
			jnz .Back
			call _d_negate 
.Back		ret


;*********************************************
; _q_plus				Q+
;	( q1 q2 -- q3 )
;	Adds q1 to q2, leaving the sum q3
;*********************************************
_q_plus:
			POP_PS(edx)
			POP_PS(ecx)
			POP_PS(ebx)
			POP_PS(eax)
			clc
			add [esi+3*CELL_SIZE], eax
			adc [esi+2*CELL_SIZE], ebx
			adc [esi+CELL_SIZE], ecx
			adc [esi], edx
	test al, al	; clear overflow and carry flags
			ret


;*********************************************
; _q_minus			Q-
;	( q1 q2 -- q3 )
;	Subtracts q2 from q1 giving the diff q3
;*********************************************
_d_minus:
			POP_PS(edx)
			POP_PS(ecx)
			POP_PS(ebx)
			POP_PS(eax)
			clc
			sub [esi+3*CELL_SIZE], eax
			sbb [esi+2*CELL_SIZE], ebx
			sbb [esi+CELL_SIZE], ecx
			sbb [esi], edx
	test al, al	; clear overflow and carry flags
			ret


;*********************************************
; _q_m_plus				QM+
;	( q1|uq1 d -- q2|uq2 )
;
;	Add d to q1|uq1, giving the sum q2|uq2. 
;*********************************************
_q_m_plus:
			call _d_to_q
			call _q_plus
			ret



;*********************************************
; _q_negate				QNEGATE
;	( q1 -- q2 )
;
;	Negates q1, giving q2
;*********************************************
; can be done in several ways:
; 1. subract q1 from zero
; 2. invert all the bits, then add 1 to it (two's complement) 
; here we use 2.
_q_negate:
			mov edx, [esi]
			mov ecx, [esi+CELL_SIZE]
			mov ebx, [esi+2*CELL_SIZE]
			mov eax, [esi+3*CELL_SIZE]
			not eax
			not ebx
			not ecx
			not edx
			add eax, 1
			adc ebx, 0
			adc ecx, 0
			adc edx, 0
			mov [esi], edx
			mov [esi+CELL_SIZE], ecx
			mov [esi+2*CELL_SIZE], ebx
			mov [esi+3*CELL_SIZE], eax
			ret


;*********************************************
; _q_abs				QABS
;	( q -- uq )
;*********************************************
_q_abs:
			test DWORD [esi], (1 << 31)
			jz	.Back
			call _q_negate
.Back		ret


;*********************************************
; q_l_shift				QLSHIFT
;	( q1 n -- q2 )
;	Return q2, the result of shifting q1 n bits 
;	towards the most-significant bit, filling 
;	the least-significant bit with zero.
;	n needs to be < 31.
;*********************************************
_q_l_shift:
			push ebp
			POP_PS(ecx)
			POP_PS(edx)
			POP_PS(ebp)
			POP_PS(ebx)
			POP_PS(eax)
			shld edx, ebp, cl
			shld ebp, ebx, cl
			shld ebx, eax, cl
			shl eax, cl
			PUSH_PS(eax)
			PUSH_PS(ebx)
			PUSH_PS(ebp)
			PUSH_PS(edx)
			pop ebp
			ret


;*********************************************
; _q_r_shift			QRSHIFT
;	( q1 n -- q2 )
;	Return q2, the result of shifting q1 n bits 
;	towards the least-significant bit, leaving 
;	the most-significant bit unchanged.
;	n needs to be < 31.
;*********************************************
_q_r_shift:
			push edi
			xor edi, edi
			POP_PS(ecx)
			test DWORD [esi], (1 << 31)
			jz	.Pos
			mov edi, 1
			push ecx
			call _q_negate
			pop ecx
.Pos		POP_PS(ecx)
			POP_PS(edx)
			POP_PS(ebp)
			POP_PS(ebx)
			POP_PS(eax)
			shrd eax, ebx, cl
			shrd ebx, ebp, cl
			shrd ebp, edx, cl
			shr edx, cl
			PUSH_PS(eax)
			PUSH_PS(ebx)
			PUSH_PS(ebp)
			PUSH_PS(edx)
			cmp edi, 1 
			jnz	.Back
			call _q_negate
.Back		pop edi
			ret


;*********************************************
; q_two_star		Q2*
;	( q1 -- q2 )
;	Return q2, the result of shifting q1 one bit 
;	towards the most-significant bit, filling 
;	the least-significant bit with zero.
;*********************************************
_q_two_star:
			PUSH_PS(1)
			call _q_l_shift
			ret


;*********************************************
; _q_two_slash		Q2/
;	( q1 -- q2 )
;	Return q2, the result of shifting q1 one bit 
;	towards the least-significant bit, leaving 
;	the most-significant bit unchanged.
;*********************************************
_q_two_slash:
			PUSH_PS(1)
			call _q_r_shift
			ret


;*********************************************
; _q_m_star_slash			QM*/
;	( q1 d1 +d2 -- q2 )
;
;	Multiply q1 by d1 producing the sextuple-cell (192-bit) intermediate result t.
;	Divide t by +d2 giving the QCELL quotient q2. 
;	An ambiguous condition exists if +d2 is zero or negative, 
;	or the quotient lies outside of the range of a quad-precision signed integer. 
;*********************************************
_q_m_star_slash:
			POP_PS(eax)
			mov eax, [ddiv+CELL_SIZE]
			POP_PS(eax)
			mov eax, [ddiv]
			push edi
			xor edi, edi
			test DWORD [esi], (1 << 31)
			jz	.Pos1
			mov edi, 1
			call _d_negate
.Pos1		POP_PS(edx)
			POP_PS(ecx)
			mov [num2], ecx
			mov [num2+CELL_SIZE], edx
			test DWORD [esi], (1 << 31)
			jz	.Pos2
			xor edi, 1
			call _q_negate
.Pos2		POP_PS(edx)
			POP_PS(ecx)
			POP_PS(ebx)
			POP_PS(eax)
			mov [num1], eax
			mov [num1+CELL_SIZE], ebx
			mov [num1+2*CELL_SIZE], ecx
			mov [num1+3*CELL_SIZE], edx
	; IN: num1,num2
	; OUT: res6 (sextuple cell)
			call umulQWithD
	; IN: res6, ddiv
	; OUT: res4 
			call udiv6CellByD	
			mov eax, [res4]
			mov ebx, [res4+CELL_SIZE]
			mov ecx, [res4+2*CELL_SIZE]
			mov edx, [res4+3*CELL_SIZE]		; we throw away the top two cells
			PUSH_PS(eax)
			PUSH_PS(ebx)
			PUSH_PS(ecx)
			PUSH_PS(edx)
			cmp edi, 1 
			jnz	.Back
			call _q_negate
.Back		pop edi
			ret


; Multiply by hand (i.e. on paper)
; ABCD * EFGH   (each letter corresponds to a 32-bit DWORD)
;  positions of the letters are added, and that is their result's position
;  e.g. D*H is the (0,0)th, so their result goes to the lowest 32-bit (i.e. 0+0=0th 32-bit DWORD);
;  and their EDX goes +1, so the first 32-bit DWORD
;  e.g. D*E is the (0,3)th, so their result goes to the 0+3 (i.e. 3rd) 32-bit DWORD, the highest DWORD of the 128-bit quad, since the count starts from zero
;  and their EDX goes +1, but that is the overflow, so we drop it
;  We always add the EDX to a DWORD with adc, to handle Carry (except the first addition).
;  Example of multiplication by hand:
;   4567 * 2345
;   9134
;   13701
;    18268
;     22835		(the 5 of 22835 goes to the lowest 32-bit DWORD)
;-----------
;  10709615

;*********************************************
; _q_star					Q*
;	( q1 q2 -- q3 )
;
;	Multiply q1 by q2 producing q3.
;	Overflow is not handled
;*********************************************
_q_star:
			push edi
			xor edi, edi
			test DWORD [esi], (1 << 31)
			jz	.Pos1
			mov edi, 1
			call _q_negate
.Pos1		POP_PS(edx)
			POP_PS(ecx)
			POP_PS(ebx)
			POP_PS(eax)
			mov [num2], eax
			mov [num2+CELL_SIZE], ebx
			mov [num2+2*CELL_SIZE], ecx
			mov [num2+3*CELL_SIZE], edx
			test DWORD [esi], (1 << 31)
			jz	.Pos2
			xor edi, 1
			call _q_negate
.Pos2		POP_PS(edx)
			POP_PS(ecx)
			POP_PS(ebx)
			POP_PS(eax)
			mov [num1], eax
			mov [num1+CELL_SIZE], ebx
			mov [num1+2*CELL_SIZE], ecx
			mov [num1+3*CELL_SIZE], edx
; multiply
			; clear result
			clc
			mov DWORD [res4], 0
			mov DWORD [res4+CELL_SIZE], 0
			mov DWORD [res4+2*CELL_SIZE], 0
			mov DWORD [res4+3*CELL_SIZE], 0
			mov DWORD [res4+4*CELL_SIZE], 0
			mov DWORD [res4+5*CELL_SIZE], 0
; ABCD * EFGH   (each letter corresponds to a 32-bit DWORD)
		; D*H
			mov eax, [num1]
			mov ebx, [num2]
			mul ebx
			mov [res4], eax
			mov [res4+CELL_SIZE], edx
		; C*H
			mov eax, [num1+CELL_SIZE]
			mov ebx, [num2]
			mul ebx
			add [res4+CELL_SIZE], eax
			adc [res4+2*CELL_SIZE], edx
		; B*H
			mov eax, [num1+2*CELL_SIZE]
			mov ebx, [num2]
			mul ebx
			add [res4+2*CELL_SIZE], eax
			adc [res4+3*CELL_SIZE], edx
		; A*H
			mov eax, [num1+3*CELL_SIZE]
			mov ebx, [num2]
			mul ebx
			add [res4+3*CELL_SIZE], eax
;			adc [res4+4*CELL_SIZE], edx	; overflow is thrown away
; ABCD * EFGH   (each letter corresponds to a 32-bit DWORD)
		; D*G
			mov eax, [num1]
			mov ebx, [num2+CELL_SIZE]
			mul ebx
			add [res4+CELL_SIZE], eax
			adc [res4+2*CELL_SIZE], edx
		; C*G
			mov eax, [num1+CELL_SIZE]
			mov ebx, [num2+CELL_SIZE]
			mul ebx
			add [res4+2*CELL_SIZE], eax
			adc [res4+3*CELL_SIZE], edx
		; B*G
			mov eax, [num1+2*CELL_SIZE]
			mov ebx, [num2+CELL_SIZE]
			mul ebx
			add [res4+3*CELL_SIZE], eax
;			adc [res4+4*CELL_SIZE], edx	; overflow is thrown away
		; A*G	(overflow)
;			mov eax, [num1+3*CELL_SIZE]
;			mov ebx, [num2+CELL_SIZE]
;			mul ebx
;			add [res4+4*CELL_SIZE], eax
;			adc [res4+5*CELL_SIZE], edx	
; ABCD * EFGH   (each letter corresponds to a 32-bit DWORD)
		; D*F
			mov eax, [num1]
			mov ebx, [num2+2*CELL_SIZE]
			mul ebx
			add [res4+2*CELL_SIZE], eax
			adc [res4+3*CELL_SIZE], edx
		; C*F
			mov eax, [num1+CELL_SIZE]
			mov ebx, [num2+2*CELL_SIZE]
			mul ebx
			add [res4+3*CELL_SIZE], eax
;			adc [res4+4*CELL_SIZE], edx	
		; B*F   (overflow)
;			mov eax, [num1+2*CELL_SIZE]
;			mov ebx, [num2+2*CELL_SIZE]
;			mul ebx
;			add [res4+4*CELL_SIZE], eax
;			adc [res4+5*CELL_SIZE], edx 
		; A*F	(overflow)
;			mov eax, [num1+3*CELL_SIZE]
;			mov ebx, [num2+2*CELL_SIZE]
;			mul ebx
;			add [res4+5*CELL_SIZE], eax
;			adc [res4+6*CELL_SIZE], edx	
; ABCD * EFGH   (each letter corresponds to a 32-bit DWORD)
		; D*E
			mov eax, [num1]
			mov ebx, [num2+3*CELL_SIZE]
			mul ebx
			add [res4+3*CELL_SIZE], eax
;			adc [res4+4*CELL_SIZE], edx	; overflow is thrown away
		; C*E   (overflow)
;			mov eax, [num1+CELL_SIZE]
;			mov ebx, [num2+3*CELL_SIZE]
;			mul ebx
;			add [res4+4*CELL_SIZE], eax
;			adc [res4+5*CELL_SIZE], edx	
		; B*E   (overflow)
;			mov eax, [num1+2*CELL_SIZE]
;			mov ebx, [num2+3*CELL_SIZE]
;			mul ebx
;			add [res4+4*CELL_SIZE], eax
;			adc [res4+5*CELL_SIZE], edx 
		; A*E	(overflow)
;			mov eax, [num1+3*CELL_SIZE]
;			mov ebx, [num2+3*CELL_SIZE]
;			mul ebx
;			add [res4+5*CELL_SIZE], eax
;			adc [res4+6*CELL_SIZE], edx	
; put result on stack
			mov eax, [res4]
			mov ebx, [res4+CELL_SIZE]
			mov ecx, [res4+2*CELL_SIZE]
			mov edx, [res4+3*CELL_SIZE]
			PUSH_PS(eax)
			PUSH_PS(ebx)
			PUSH_PS(ecx)
			PUSH_PS(edx)
			cmp edi, 1 
			jnz	.Back
			call _q_negate
.Back		pop edi
			ret


; IN: num1,num2
; OUT: res6 (sextuple cell)
; 128bit * 64bit
umulQWithD:
			; clear result
			clc
			mov DWORD [res6], 0
			mov DWORD [res6+CELL_SIZE], 0
			mov DWORD [res6+2*CELL_SIZE], 0
			mov DWORD [res6+3*CELL_SIZE], 0
			mov DWORD [res6+4*CELL_SIZE], 0
			mov DWORD [res6+5*CELL_SIZE], 0
; ABCD * GH   (each letter corresponds to a 32-bit DWORD)
		; D*H
			mov eax, [num1]
			mov ebx, [num2]
			mul ebx
			mov [res6], eax
			mov [res6+CELL_SIZE], edx
		; C*H
			mov eax, [num1+CELL_SIZE]
			mov ebx, [num2]
			mul ebx
			add [res6+CELL_SIZE], eax
			adc [res6+2*CELL_SIZE], edx
		; B*H
			mov eax, [num1+2*CELL_SIZE]
			mov ebx, [num2]
			mul ebx
			add [res6+2*CELL_SIZE], eax
			adc [res6+3*CELL_SIZE], edx
		; A*H
			mov eax, [num1+3*CELL_SIZE]
			mov ebx, [num2]
			mul ebx
			add [res6+3*CELL_SIZE], eax
			adc [res6+4*CELL_SIZE], edx	
; ABCD * GH   (each letter corresponds to a 32-bit DWORD)
		; D*G
			mov eax, [num1]
			mov ebx, [num2+CELL_SIZE]
			mul ebx
			add [res6+CELL_SIZE], eax
			adc [res6+2*CELL_SIZE], edx 
		; C*G
			mov eax, [num1+CELL_SIZE]
			mov ebx, [num2+CELL_SIZE]
			mul ebx
			add [res6+2*CELL_SIZE], eax
			adc [res6+3*CELL_SIZE], edx
		; B*G
			mov eax, [num1+2*CELL_SIZE]
			mov ebx, [num2+CELL_SIZE]
			mul ebx
			add [res6+3*CELL_SIZE], eax
			adc [res6+4*CELL_SIZE], edx
		; A*G 
			mov eax, [num1+3*CELL_SIZE]
			mov ebx, [num2+CELL_SIZE]
			mul ebx
			add [res6+4*CELL_SIZE], eax
			adc [res6+5*CELL_SIZE], edx 
			ret


; IN: res6, ddiv
; OUT: res4 
udiv6CellByD:
			mov ebx, [ddiv]
			xor edx, edx
			mov eax, [res6+5*CELL_SIZE]
			div	ebx
			mov [res4+5*CELL_SIZE], eax
			mov eax, [res6+4*CELL_SIZE]
			div	ebx
			mov [res4+4*CELL_SIZE], eax
			mov eax, [res6+3*CELL_SIZE]
			div	ebx
			mov [res4+3*CELL_SIZE], eax
			mov eax, [res6+2*CELL_SIZE]
			div	ebx
			mov [res4+2*CELL_SIZE], eax
			mov eax, [res6+CELL_SIZE]
			div	ebx
			mov [res4+CELL_SIZE], eax
			mov eax, [res6]
			div	ebx
			mov [res4], eax
			ret 	; EDX is the remainder


; 128-bit
num1	do 0
num2	do 0
res4	times 6 dd 0

ddiv	dq 0
res6	times 6 dd 0


%endif


