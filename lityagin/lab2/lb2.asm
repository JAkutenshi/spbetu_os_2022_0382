TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	jmp BEGIN

; ДАННЫЕ
SAUM db 'Segment address of unavailable memory:     ', 0DH, 0AH, '$'
SAE db 'Segment address of the environment:    ', 0DH, 0AH, '$'
CLT db 'Command line tail:  ', '$'
ECLT db 'Command line tail is empty', 0DH, 0AH, '$'
CEA db 'Contents of the environment area:  ',0DH, 0AH,'$'
PLM db 'The path of the loaded module:  ', 0DH, 0AH, '$'

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
PSAUM PROC near
	mov AX, DS:[2h]
	mov DI, offset SAUM + 42
	call WRD_TO_HEX
	mov DX, offset SAUM
	call PRINT
	ret
PSAUM ENDP
;----------------------------------
PSAE PROC near
	mov AX, DS:[2Ch]
	mov DI, offset SAE + 39
	call WRD_TO_HEX
	mov DX, offset SAE
	call PRINT
	ret
PSAE ENDP
;----------------------------------
PCEA PROC near
	mov DX, offset CEA
	call PRINT
	mov ES, DS:[2Ch]
	xor DI, DI
line:
	mov DL, ES:[DI]
	cmp DL, 0h
	je end_line
	call PRINT_SYM
	inc DI
	jmp line
end_line:
	mov DL, 0Dh
	call PRINT_SYM
	mov DL, 0Ah
	call PRINT_SYM
	inc DI
	mov DL, ES:[DI]
	cmp DL, 0h
	jne line

	mov DX, offset PLM
	call PRINT
	add DI, 3
path_line:
	mov DL, ES:[DI]
	cmp DL, 0h
	je end_path
	call PRINT_SYM
	inc DI
	jmp path_line
end_path:
	ret
PCEA ENDP
;----------------------------------
PCLT PROC near	
	xor CX, CX
	mov CL, DS:[80h]
	cmp CL, 0h
	je empty
	mov DX, offset CLT
	call PRINT
	mov SI, 81h
loop_clt:
	mov DL, DS:[SI]
	call PRINT_SYM
	inc SI
	loop loop_clt
	mov DL, 0Dh
	call PRINT_SYM
	mov DL, 0Ah
	call PRINT_SYM
	ret
empty:
	mov DX, offset ECLT
	call PRINT
	ret
PCLT ENDP
;-----------------------------------
; КОД
BEGIN:
	call PSAUM
	call PSAE
	call PCLT
	call PCEA
	xor AL, AL
	mov AH, 4Ch
	int 21h
TESTPC ENDS
	END START