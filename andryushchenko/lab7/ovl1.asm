TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:NOTHING, SS:NOTHING
MAIN PROC far
	push AX
	push DX
	push DS
	push DI
		
	mov AX, CS
	mov DS, AX
	lea DI, OVL1_ADDRESS
	add DI, 17
	call WRD_TO_HEX
	lea DX, OVL1_ADDRESS
	call PRINT
	
	pop DI
	pop DS
	pop DX
	pop AX
	retf
MAIN ENDP

OVL1_ADDRESS db 'OVL1 address:      ', 0DH, 0AH, '$'
; ПРОЦЕДУРЫ
;----------------------
PRINT PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
;-----------------------------------
TETR_TO_HEX PROC near
	and AL, 0Fh
	cmp AL, 09
	jbe NEXT
	add AL, 07
NEXT:	add AL, 30h
	ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа 16-го числа в AX
	push CX
	mov AH, AL
	call TETR_TO_HEX
	xchg AL, AH
	mov CL, 4
	shr AL, CL
	call TETR_TO_HEX ; в AL старшая цифра
	pop CX		 ; в AH младшая
	ret 
BYTE_TO_HEX ENDP
;-----------------------------------
WRD_TO_HEX PROC near
; перевод в 16 с/с 16-ти разрядного числа
; в AX - число, в DI - адрес последнего символа
	push BX
	mov BH, AH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	dec DI
	mov AL, BH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	pop BX
	ret
WRD_TO_HEX ENDP
TESTPC ENDS
END MAIN