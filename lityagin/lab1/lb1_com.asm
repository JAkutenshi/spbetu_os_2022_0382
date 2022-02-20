TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	jmp BEGIN

; ДАННЫЕ
NOTYPE db 'IBM type:  ', 0DH, 0AH, '$'
PC db 'IBM type: PC', 0DH, 0AH, '$'
XT db 'IBM type: PC/XT', 0DH, 0AH, '$'
AT db 'IBM type: AT', 0DH, 0AH, '$'
PS230 db 'IBM type: PS2 model 30', 0DH, 0AH, '$'
PS25060 db 'IBM type: PS2 model 50 or 60', 0DH, 0AH, '$'
PS280 db 'IBM type: PS2 model 80', 0DH, 0AH, '$'
PCjr db 'IBM type: PCjr', 0DH, 0AH, '$'
PCConvertible db 'IBM type: PC Convertible', 0DH, 0AH, '$'
DOSV db 'MS DOS version:  .  ', 0DH, 0AH, '$'
OEM db 'OEM number:   ', 0DH, 0AH, '$'
USR db 'User_s number:       h', 0DH, 0AH, '$'

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
end_1: pop DX
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
IBM_TYPE PROC near
	push AX
	push DX
	push ES
	mov AX, 0F000h
	mov ES, AX
	mov AL, ES:[0FFFEh]

	cmp AL, 0FFh
	je _pc
	
	cmp AL, 0FEh
	je _xt	

	cmp AL, 0FBh
	je _xt

	cmp AL, 0FCh
	je _at

	cmp AL, 0FAh
	je _ps230

	cmp AL, 0F8h
	je _ps280

	cmp AL, 0FDh
	je _pcjr

	cmp AL, 0F9h
	je _pcc

	mov DI, offset NOTYPE + 10
	call BYTE_TO_HEX
	mov [DI], AX
	mov DX, offset NOTYPE
	jmp p_ibm	

_pc:
	mov DX, offset PC
	jmp p_ibm
_xt:
	mov DX, offset XT
	jmp p_ibm
_at:
	mov DX, offset AT
	jmp p_ibm
_ps230:
	mov DX, offset PS230
	jmp p_ibm
_ps280:
	mov DX, offset PS280
	jmp p_ibm
_pcjr:
	mov DX, offset PCjr
	jmp p_ibm
_pcc:
	mov DX, offset PCConvertible
p_ibm:
	call PRINT
	pop ES
	pop DX
	pop AX
	ret
IBM_TYPE ENDP
;-----------------------------------
DOS_VER PROC near
	push AX
	push BX
	push CX
	xor AX, AX
	mov AH, 30h
	int 21h

	mov SI, offset DOSV + 16
	call BYTE_TO_DEC
	mov AL, AH
	add SI, 3
	call BYTE_TO_DEC
	mov DX, offset DOSV
	call PRINT

	mov SI, offset OEM + 13
	mov AL, BH
	call BYTE_TO_DEC
	mov DX, offset OEM
	call PRINT

	mov DI, offset USR + 20
	mov AX, CX
	call WRD_TO_HEX
	mov AL, BL
	call BYTE_TO_HEX
	mov di, offset USR + 15
	mov [DI], AX
	mov DX, offset USR
	call PRINT
	pop CX
	pop BX
	pop AX
	ret
DOS_VER ENDP
;-----------------------------------
; КОД
BEGIN:
	call IBM_TYPE
	call DOS_VER
	xor AL, AL
	mov AH, 4Ch
	int 21h
TESTPC ENDS
	END START