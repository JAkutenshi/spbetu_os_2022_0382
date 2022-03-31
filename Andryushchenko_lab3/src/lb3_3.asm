TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	jmp BEGIN

; ДАННЫЕ
AVAIL_MEM db 'Available memory:           ', 0DH, 0AH, '$'
EXTEND_MEM db 'Extended memory:            ', 0DH, 0AH, '$'
MCB_I db 'MCB num   , MCB adress:     h, PCP adress:     h, size:      , SC/SD:           ', 0DH, '$'
ERROR db 'I cannot get extra memory(', 0DH, 0AH, '$'
SUCCESS db 'I get extra memory)', 0DH, 0AH, '$'
; ПРОЦЕДУРЫ
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
;------------------------------
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
;------------------------------
BYTE_TO_DEC PROC near
; перевод в 10 с/с, в SI - адрес поля младшей цифры
	push AX
	push CX
	push DX
	xor AH, AH
	xor DX, DX
	mov CX, 10
loop_bd: div CX
	or DL, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 10
	jae loop_bd
	cmp AL, 00h
	je end_1
	or AL, 30h
	mov [SI], AL
end_1: 
	pop DX
	pop CX
	pop AX
	ret
BYTE_TO_DEC ENDP
;---------------------------------------
WORD_TO_DEC PROC near
	push AX
	push BX
	push DX
	push CX
	push SI
	
	mov BX, 10h
	mul BX
	mov BX, 0Ah
division:
	div BX
	or DX, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 0h
	jne division

	pop SI
	pop CX
	pop DX
	pop BX
	pop AX
	ret
WORD_TO_DEC ENDP
;---------------------------------------
PRINT PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
;----------------------
PRINT_SYM PROC near
	push AX
	mov AH, 02h
	int 21h
	pop AX
	ret
PRINT_SYM ENDP
;----------------------
AM PROC near
	push AX
	push BX
	push SI

	xor AX, AX
	mov AH, 4Ah
	mov BX, 0FFFFh
	int 21h
	mov AX, BX
	mov SI, offset AVAIL_MEM 
	add SI, 25
	call WORD_TO_DEC
	mov DX, offset AVAIL_MEM 
	call PRINT
	
	pop SI
	pop BX
	pop AX
	ret
AM ENDP
;----------------------
EM PROC near
	push AX
	push BX
	push SI
	xor AX, AX
	mov AL, 30h
	out 70h, AL
	in AL, 71h
	mov BL, AL
	mov AL, 31h
	out 70h, AL
	in AL, 71h
	mov AH, AL
	mov AL, BL
	mov SI, offset EXTEND_MEM
	add SI, 25
	call WORD_TO_DEC
	mov DX, offset EXTEND_MEM 
	call PRINT
	pop SI
	pop BX
	pop AX
	ret
EM ENDP
;----------------------------------
MCB PROC near
	push AX
	push BX
	push CX
	push DX
	push ES
	push SI

	xor AX, AX
	mov AH, 52h
	int 21h
	mov AX, ES:[BX-2]
	mov ES, AX
	mov CL, 1
loop_mcb:
	mov AL, CL
	mov SI, offset MCB_I
	add SI, 9
	call BYTE_TO_DEC
	
	mov AX, ES
	mov DI, offset MCB_I
	add DI, 27
	call WRD_TO_HEX

	mov AX, ES:[01h]
	mov DI, offset MCB_I
	add DI, 46
	call WRD_TO_HEX

	mov AX, ES:[03h]
	add SI, 52
	call WORD_TO_DEC

	mov BX, 8
	push CX
	mov CX, 7
	add SI, 11
loop_sc_sd:
	mov DX, ES:[BX]
	mov DS:[SI], DX
	inc BX
	inc SI
	loop loop_sc_sd

	mov DX, offset MCB_I
	call PRINT
	
	mov AH, ES:[0]
	cmp AH, 5Ah
	je end_mcb
	
	mov BX, ES:[3]
	mov AX, ES
	add AX, BX
	inc AX
	mov ES, AX
	pop CX
	inc CL
	jmp loop_mcb
end_mcb:
	pop SI
	pop ES
	pop DX
	pop CX
	pop BX
	pop AX
	ret
MCB ENDP
;----------------------------------
FREE_MEM PROC NEAR
	push AX
	push BX
	push DX

	lea AX, end_programm
	mov BX, 10h
	xor DX, DX
	div BX
	inc AX
	mov BX, AX
	xor AX, AX
	mov AH, 4Ah
	int 21h

	pop DX
	pop BX
	pop AX
	ret
FREE_MEM ENDP
;-----------------------------------
GET_MEM PROC near
	push AX
	push BX
	push DX

	mov BX, 1000h
	xor AX, AX
	mov AH, 48h
	int 21h
	
	jc CF_ERROR
	
	mov DX, offset SUCCESS
	call PRINT
	jmp end_gm

CF_ERROR:
	mov DX, offset ERROR
	call PRINT
	jmp end_gm

end_gm:
	pop DX
	pop BX
	pop AX
	ret
GET_MEM ENDP
;-----------------------------------
BEGIN:
	call AM
	call EM
	call FREE_MEM
	call GET_MEM
	call MCB
	xor AL, AL
	mov AH, 4Ch
	int 21h
end_programm:
TESTPC ENDS
	END START