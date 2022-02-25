TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	jmp BEGIN
; ДАННЫЕ
UNV db 'Address of unavailable memory :     h;', 0DH, 0AH, '$'
ENV db 'Address of environment :     h;', 0DH, 0AH, '$'
CMD db 'Command line tail :', '$'
CMD_Emp db ' empty;', 0DH, 0AH, '$'
END_C db ';', 0DH, 0AH, '$'
ENV_Cnt db 'Contents of the environment area:',0DH, 0AH,'$'
PATH db 'Path :', '$'
END_P db ';', '$'

; ПРОЦЕДУРЫ
;-----------------------------------------------------
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
; КОД

PRINT PROC near
	mov AH, 09h
	int 21h
	ret
PRINT ENDP

PRINT_SYM PROC near
	push AX
	mov AH, 02h
	int 21h
	pop AX
	ret
PRINT_SYM ENDP

_UNV PROC near
	mov DI, offset UNV
	add DI, 35
	mov AX, DS:[2h]
 	call WRD_TO_HEX
 	mov DX, offset UNV
 	call PRINT
 	ret
_UNV ENDP

_ENV PROC near
	mov DI, offset ENV
	add DI, 28
	mov AX, DS:[2Ch]
	call WRD_TO_HEX
	mov DX, offset ENV
	call PRINT
	ret
_ENV ENDP

_CMD PROC near  
	mov DX, offset CMD
 	call PRINT
	mov CL, DS:[80h]
 	cmp CL, 0
 	je empty
	mov BX, 81h 
	
lp:
 		mov DL, DS:[BX]
		call PRINT_SYM
 		inc BX
		loop lp

 	mov DX, offset END_C
    	call PRINT
	ret
empty:
	mov DX, offset CMD_Emp
   	call PRINT 
   	ret
_CMD ENDP

_ENV_Cnt_and_PATH PROC near

ENV_Contents:
	mov DX, offset ENV_Cnt
	call PRINT
	mov ES, DS:[2Ch]
	xor DI, DI
	mov DL, ES:[DI]
read_env:
   	cmp DL, 0
   	je final_env
   	call PRINT_SYM
   	inc DI
	mov DL, ES:[DI]
   	jmp read_env

final_env:
  	mov DL, 0Dh
   	call PRINT_SYM
   	mov DL, 0Ah
   	call PRINT_SYM
	inc DI
   	mov DL, ES:[DI]
   	cmp DL, 00h
   	jne read_env

module_PATH:
	mov DX, offset PATH
	call PRINT
	add DI, 2
	mov DL, ES:[DI]
	inc DI

read_path:
	call PRINT_SYM
	mov DL, ES:[DI]
	inc DI
	cmp DL, 0
	jne read_path

	mov DX, offset END_P
	call PRINT
	ret
_ENV_Cnt_and_PATH ENDP

BEGIN:
	call _UNV
	call _ENV
	call _CMD
	call _ENV_Cnt_and_PATH
; Выход в DOS
	xor AL, AL
	mov AH, 4Ch
	int 21h
TESTPC  ENDS
	END START