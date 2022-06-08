OVERLAY1 SEGMENT
ASSUME CS:OVERLAY1, DS:NOTHING, SS:NOTHING, ES:NOTHING
MAIN PROC FAR
	push AX
	push DX
	push DI
	push DS
	
	mov AX, CS
	mov DS, AX
	mov DX, offset SEG_ADDR
	mov DI, DX
	add DI, 37
	call WRD_TO_HEX
	call PRINT
		
	pop DS
	pop DI
	pop DX
	pop AX
	retf
MAIN ENDP
; ------------------------------------------------------------		
PRINT PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
; ------------------------------------------------------------
TETR_TO_HEX PROC NEAR
	and AL, 0Fh
	cmp AL, 09
	jbe next_
	add AL, 07
	next_: 
		add AL, 30h
		ret
TETR_TO_HEX ENDP
; -----------------------------------------------------------
BYTE_TO_HEX PROC NEAR
	push CX
	mov AH, AL
	call TETR_TO_HEX
	xchg AL, AH
	mov CL, 4
	shr AL, CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP
; ------------------------------------------------------------
WRD_TO_HEX PROC NEAR
	push BX
	mov BH,AH
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
; ------------------------------------------------------------
; ------------------------------------------------------------
SEG_ADDR DB ' Segment address of overlay1.ovl:     h', 0DH, 0AH, '$'

OVERLAY1 ENDS
END MAIN
