TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	jmp BEGIN
; ДАННЫЕ

AM db 'Amount of available memory :        bytes;', 0DH, 0AH, '$'
EM db 'Extended memory size :       kbytes;', 0DH, 0AH, '$'
MCB db 'MCB Type:   , MCB Adress:     , Owner:     h, Size:        b, Name: $'
END_STR db 0DH, 0AH,'$'

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
WRD_TO_DEC PROC near
	push CX
	push DX
	mov CX, 10
loop_wd: 
	div CX
	or DL, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 10
	jae loop_wd
	cmp AL, 00h
	je end_1
	or AL, 30h
	mov [SI], AL
end_2:  
	pop DX
	pop CX
	ret
WRD_TO_DEC ENDP

PRINT PROC near
	mov AH, 09h
	int 21h
	ret
PRINT ENDP

_AM PROC near
	mov SI, offset AM
	add SI, 34
   	mov AH, 4Ah
   	mov BX, 0FFFFh
   	int 21h
   	mov AX, 16
	mul BX
 	call WRD_TO_DEC 
 	mov DX, offset AM
 	call PRINT
 	ret
_AM ENDP

_EM PROC near
	mov SI, offset EM
	add SI, 27
	sub DX, DX

	mov AL, 30h ; запись адреса ячейки CMOS
    	out 70h, AL
    	in AL, 71h  ; чтение младшего байта
    	mov BL, AL  ; размер расширенной памяти
    	mov AL, 31h ; запись адреса ячейки CMOS
    	out 70h, AL
    	in AL, 71h  ; чтение старшего байта
		    ; размера расширенной памяти 
	mov AH, AL  
   	mov Al, BL 
	call WRD_TO_DEC 
 	mov DX, offset EM
 	call PRINT
 	ret
_EM ENDP

_MCB PROC  near
 	mov AH, 52h
        int 21h
	sub BX, 2
	mov AX, ES:[BX]
	mov ES, AX
Chain:
;Type
	mov DI, offset MCB
	add DI, 10
	mov AX, ES:[00h]
	call BYTE_TO_HEX
        mov [DI], AL
        add DI, 1
        mov [DI], AH
;Adress
	mov DI, offset MCB
	add DI, 29
	mov AX, ES
	call WRD_TO_HEX
;Owner
	mov DI, offset MCB
	add DI, 42
        mov AX, ES:[01h]
	call WRD_TO_HEX
;Size
	mov SI, offset MCB
        add SI, 57
        mov AX, ES:[03h]
	mov BX, 16
    	mul BX
        call WRD_TO_DEC
;Print	
 	mov DX, offset MCB
    	call PRINT
;Name
        mov DI, offset MCB
   	add DI, 58
	mov BX, 8
	mov CX, 7
	cycle:
             	mov DL, ES:[BX]
    	  	mov AH, 02h
              	int 21h
		add BX, 1
    		loop cycle
      
	mov DX, offset END_STR
    	call PRINT
	mov AL, ES:[0h]
   	cmp AL, 5ah
    	je final 
 
	mov BX, ES
    	mov AX, ES:[03h]
	add AX, BX
    	add AX, 1
    	mov ES, AX  
    	jmp Chain
final:
        ret
_MCB ENDP

BEGIN:
	call _AM
	call _EM
	call _MCB
; Выход в DOS
	xor AL, AL
	mov AH, 4Ch
	int 21h
ENDING:
TESTPC  ENDS
	END START