; Шаблон текста программы на ассемблере для модуля типа .COM
TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ

PC db 'PC TYPE: PC', 0DH, 0AH, '$'
PC_XT db 'PC TYPE: PC/XT', 0DH, 0AH, '$'
AT db 'PC TYPE: AT', 0DH, 0AH, '$'
MODEL_30 db 'PC TYPE: PS2 model 30', 0DH, 0AH, '$'
MODEL_50_OR_60 db 'PC TYPE: PS2 model 50 or 60', 0DH, 0AH, '$'
MODEL_80 db 'PC TYPE: PS2 model 80', 0DH, 0AH, '$'
PCjr db 'PC TYPE: PCjr', 0DH, 0AH, '$'
PC_CONVERTIBLE db 'PC TYPE: PC Convertible', 0DH, 0AH, '$'
MS_DOS_VERSION db 'MS DOS VERSION:  .  ', 0DH, 0AH, '$'
OEM db 'OEM SERIAL NUMBER:    ', 0DH, 0AH, '$'
USER db 'USER SERIAL NUMBER:    ', 0DH, 0AH, '$'

;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
 push CX
 mov AH,AL
 call TETR_TO_HEX
 xchg AL,AH
 mov CL,4
 shr AL,CL
 call TETR_TO_HEX ;в AL старшая цифра
 pop CX ;в AH младшая
 ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
 push BX
 mov BH,AH
 call BYTE_TO_HEX
 mov [DI],AH
 dec DI
 mov [DI],AL
 dec DI
 mov AL,BH
 call BYTE_TO_HEX
 mov [DI],AH
 dec DI
 mov [DI],AL
 pop BX
 ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
 push CX
 push DX
 xor AH,AH
 xor DX,DX
 mov CX,10
loop_bd: div CX
 or DL,30h
 mov [SI],DL
 dec SI
 xor DX,DX
 cmp AX,10
 jae loop_bd
 cmp AL,00h
 je end_l
 or AL,30h
 mov [SI],AL
end_l: pop DX
 pop CX
 ret
BYTE_TO_DEC ENDP
;-------------------------------
; КОД
; вовод сообщения 

PRINT_MESSAGE:
	mov AH, 09h
	int 21h

	pop DX
	pop ES
	pop AX

	ret
; вывод информации 
PRINT_PC_TYPE PROC NEAR
	push AX
	push ES
	push DX

	mov AX, 0F000h
	mov ES, AX
	mov AL, ES:[0FFFEh]

	cmp AL, 0FFh
	je PC_TYPE_MES

	cmp AL, 0FEh
	je PC_XT_MES

	cmp AL, 0FBh
	je PC_XT_MES

	cmp AL, 0FCh
	je AT_MES

	cmp AL, 0FAh
	je MODEL_30_MES

	cmp AL, 0FCh
	je MODEL_50_60_MES

	cmp AL, 0F8h
	je MODEL_80_MES

	cmp AL, 0FDh
	je PCGR_TYPE

	cmp AL, 0F9h
	je PC_CONVERTIBLE_MES

PC_TYPE_MES:
	mov DX, offset PC
	jmp PRINT_MESSAGE

PC_XT_MES:
	mov DX, offset PC_XT
	jmp PRINT_MESSAGE

AT_MES:
	mov DX, offset AT
	jmp PRINT_MESSAGE

MODEL_30_MES:
	mov DX, offset MODEL_30
	jmp PRINT_MESSAGE

MODEL_50_60_MES:
	mov DX, offset MODEL_50_OR_60
	jmp PRINT_MESSAGE

MODEL_80_MES:
	mov DX, offset MODEL_80
	jmp PRINT_MESSAGE

PCGR_TYPE:
	mov DX, offset PCjr
	jmp PRINT_MESSAGE

PC_CONVERTIBLE_MES:
	mov DX, offset PC_CONVERTIBLE
	jmp PRINT_MESSAGE



PRINT_PC_TYPE ENDP

PRINT_MES_SYS PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT_MES_SYS ENDP

PRINT_SYSTEM_VERSION PROC near
	push AX
	push BX
	push CX
	push DI
	push SI

	sub AX, AX
	mov AH, 30h
	int 21h

	mov SI, offset MS_DOS_VERSION
	add SI, 16
	call BYTE_TO_DEC
	mov AL, AH ; AH - DOS VERSION
	add SI, 3
	call BYTE_TO_DEC
	mov DX, offset MS_DOS_VERSION
	call PRINT_MES_SYS

	mov SI, offset OEM
	add SI, 14
	mov AL, BH ; BH - OEM NUMBER
	call BYTE_TO_DEC
	mov DX, offset OEM
	call PRINT_MES_SYS

	mov DI, offset USER
	add DI, 15
	mov AX, CX
	call WRD_TO_HEX
	mov AL, BL
	call BYTE_TO_HEX
	mov DX, offset USER
	call PRINT_MES_SYS

	pop SI
	pop DI
	pop CX
	pop BX
	pop AX
	
	ret
PRINT_SYSTEM_VERSION ENDP



BEGIN:

	call PRINT_PC_TYPE
	call PRINT_SYSTEM_VERSION

; Выход в DOS
 
 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START ;конец модуля, START - точка входа