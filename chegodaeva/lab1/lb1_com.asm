TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	jmp BEGIN
; ДАННЫЕ
PC db 'IBM PC type : PC;', 0DH, 0AH, '$'
XT db 'IBM PC type : PC/XT;', 0DH, 0AH, '$'
AT db 'IBM PC type : AT;', 0DH, 0AH, '$'
PS230 db 'IBM PC type : PS2 model 30;', 0DH, 0AH, '$'
PS25060 db 'IBM PC type : PS2 model 50 or 60;', 0DH, 0AH, '$'
PS280 db 'IBM PC type : PS2 model 80;', 0DH, 0AH, '$'
PCjr db 'IBM PC type : PCjr;', 0DH, 0AH, '$'
PC_C db 'IBM PC type : PC Convertible;', 0DH, 0AH, '$'
NT db 'IBM :  ;',0DH,0AH,'$'
DOS db 'DOS :  . ;', 0DH, 0AH, '$'
OEM db 'OEM :  ;', 0DH, 0AH, '$'
USER db 'USER :       h.', 0DH, 0AH, '$'

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

IBM PROC near
	mov AX, 0F000h
	mov ES, AX
	mov AH, ES:[0FFFEh]

	cmp AH, 0FFh
	je _PC
	
	cmp AH, 0FEh
	je _XT	

	cmp AH, 0FBh
	je _XT

	cmp AH, 0FCh
	je _AT

	cmp AH, 0FAh
	je _PS230

	cmp AH, 0F8h
	je _PS280

	cmp AH, 0FDh
	je _PCjr

	cmp AH, 0F9h
	je _PC_C

_OTHER:
        mov DI,offset NT
        add DI, 6
        call BYTE_TO_HEX
        mov [DI], AX
        mov DX, offset NT
        jmp final

_PC:
	mov DX, offset PC
	jmp final
_XT:
	mov DX, offset XT
	jmp final
_AT:
	mov DX, offset AT
	jmp final
_PS230:
	mov DX, offset PS230
	jmp final
_PS280:
	mov DX, offset PS280
	jmp final
_PCjr:
	mov DX, offset PCjr
	jmp final
_PC_C:
	mov DX, offset PC_C

final:
	call PRINT
	ret
IBM ENDP

MS_DOS PROC near
	mov AH, 30h
	int 21h
_DOS:
	mov SI, offset DOS
	add SI, 6
	call BYTE_TO_DEC
	mov AL, AH
	add SI, 3
	call BYTE_TO_DEC
	mov DX, offset DOS
	call PRINT
_OEM:
	mov SI, offset OEM
	add SI, 6 
	mov AL, BH
	call BYTE_TO_DEC
	mov DX, offset OEM
	call PRINT
_USER:
	mov DI, offset USER
	add DI, 12
	mov AX, CX
	call WRD_TO_HEX
	mov AL, BL
	call BYTE_TO_HEX
	sub DI, 2
	mov [DI], AX
	mov DX, offset USER
	call PRINT
	ret
MS_DOS ENDP

BEGIN:
	call IBM
	call MS_DOS
; Выход в DOS
	xor AL, AL
	mov AH, 4Ch
	int 21h
TESTPC  ENDS
	END START