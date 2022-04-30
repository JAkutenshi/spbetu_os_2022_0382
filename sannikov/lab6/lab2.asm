TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	jmp BEGIN
;-------------------------------
UM db 'Unavailable memory:     h', 0DH, 0AH, '$'
EA db 'Address of the environment:     h', 0DH, 0AH, '$'
CLT db 'Command line tail: ', '$'
EMP db 'Command line tail is empty', 0DH, 0AH, '$'
CEA db 'Contents of the environment area:  ', 0DH, 0AH,'$'
PTH db 'The path of the load module:  ', 0DH, 0AH, '$'
;-------------------------------
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
;---------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10 с/с, в SI - адрес поля младшей цифры
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
end_1:  pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;----------------------
PRINT PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
;----------------------
PRINT_SYMB PROC near
	push AX
	mov AH, 02h
	int 21h
	pop AX
	ret
PRINT_SYMB ENDP
;----------------------
UM_FUNC PROC near
	mov AX, DS:[2h]
	mov DI, offset UM
	add DI, 23
	call WRD_TO_HEX
	mov DX, offset UM
	call PRINT
	ret
UM_FUNC ENDP
;-----------------------------------
EA_FUNC PROC near
	mov AX, DS:[2Ch]
	mov DI, offset EA
	add DI, 31
	call WRD_TO_HEX
	mov DX, offset EA
	call PRINT
	ret
EA_FUNC ENDP
;-----------------------------------
CLT_FUNC PROC near
	xor CX, CX
	mov CL, DS:[80h]
	cmp CL, 0h
	je if_empty
	mov DX, offset CLT
	call PRINT
	mov SI, 81h
loop_clt:
	mov DL, DS:[SI]
	call PRINT_SYMB
	inc SI
	loop loop_clt
	
	mov DL, 0Dh
	call PRINT_SYMB
	mov DL, 0Ah
	call PRINT_SYMB
	ret
if_empty:
	mov DX, offset EMP
	call PRINT
	ret
CLT_FUNC ENDP
;-----------------------------------
CEA_FUNC PROC near
	mov DX, offset CEA
	call PRINT
	mov ES, DS:[2Ch]
	xor DI, DI
print1:
	mov DL, ES:[DI]
	cmp DL, 0h
	je print2
	call PRINT_SYMB
	inc DI
	jmp print1
print2:
	mov DL, 0Dh
	call PRINT_SYMB
	mov DL, 0Ah
	call PRINT_SYMB
	inc DI
	mov DL, ES:[DI]
	cmp DL, 0h
	jne print1

	mov DX, offset PTH
	call PRINT
	add DI, 3
print3:
	mov DL, ES:[DI]
	cmp DL, 0h
	je end_print
	call PRINT_SYMB
	inc DI
	jmp print3
end_print:
	mov DL, 0dh
	call PRINT_SYMB
	mov DL, 0ah
	call PRINT_SYMB
	ret
CEA_FUNC ENDP
;-----------------------------------
BEGIN:
	call UM_FUNC
	call EA_FUNC
	call CLT_FUNC
	call CEA_FUNC
	xor AL, AL
	mov AH, 01h
 	int 21h
	mov AH, 4Ch
	int 21h
TESTPC ENDS
	END START
