ASSUME CS:exeprogramm, DS:DATA, SS:ASTACK

ASTACK SEGMENT STACK
	DW 1024 DUP(?)
ASTACK ENDS

; ДАННЫЕ
DATA SEGMENT
	MODEL0 DB 'IBM PC:   ',0DH,0AH,'$'
	MODEL1 DB 'IBM PC: PC',0DH,0AH,'$'
	MODEL2 DB 'I BM PC: PC/XT',0DH,0AH,'$'
	MODEL3 DB 'IBM PC: AT',0DH,0AH,'$'
	MODEL4 DB 'IBM PC: PS2 model 30',0DH,0AH,'$'
	MODEL5 DB 'IBM PC: PS2 model 50 or 60',0DH,0AH,'$'
	MODEL6 DB 'IBM PC: PS2 model 80',0DH,0AH,'$'
	MODEL7 DB 'IBM PC: PCjr',0DH,0AH,'$'
	MODEL8 DB 'IBM PC: PC Convertible',0DH,0AH,'$'
	VER	  DB 'MS DOS VERSION:  .  ',0DH,0AH,'$'
	OEM	  DB 'OEM SERIAL NUMBER:    ',0DH,0AH,'$'
	USER  DB 'USER SERIAL NUMBER:    ', 0DH,0AH,'$'
DATA ENDS

exeprogramm SEGMENT
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
PRINT PROC NEAR
  push AX
  mov AH, 09h
  int 21h
  pop AX
  ret
PRINT ENDP
;-------------------------------
PC_MODEL PROC NEAR
		push AX
		push DX
		push ES
		mov AX, 0F000h
		mov ES, AX
		mov AL, ES:[0FFFEh]
		
		cmp AL, 0FFh
		mov DX, offset MODEL1
		je result
		cmp AL, 0FEh
		mov DX, offset MODEL2
		je result
		cmp AL, 0FBh
		je result
		cmp     AL, 0FCh
		mov DX, offset MODEL3
		je result
		cmp AL, 0FAh
		mov DX, offset MODEL4
		je result
		cmp AL, 0FCh
		mov DX, offset MODEL5
		je result
		cmp AL, 0F8h
		mov DX, offset MODEL6
		je result
		cmp AL, 0FDh
		mov DX, offset MODEL7
		je result
		cmp AL, 0F9h
		mov DX, offset MODEL8
		je result
		
		call BYTE_TO_HEX
		mov MODEL0[13], AL
		mov MODEL0[14], AH
		mov DX, offset MODEL0
		
		result:
		call PRINT
		pop ES
		pop DX
		pop AX
		ret
	PC_MODEL ENDP
;-------------------------------
SYSTEM_VER PROC NEAR
		push AX
		push BX
		push CX
		push DI
		push SI
		
		sub AX,AX
		mov AH, 30h
		int 21h
		
		; Version
		mov SI, offset VER
		add SI, 16
		call BYTE_TO_DEC
		mov AL, AH
		add SI, 3
		call BYTE_TO_DEC
		mov DX, offset VER
		call PRINT
		
		; OEM Serial Number
		mov AL, BH
		mov DX, offset OEM
		mov SI, DX
		add SI, 21
		call BYTE_TO_DEC
		call PRINT
		
		; User Serial Number
		mov AX, CX
		mov DX, offset USER
		mov DI, DX
		add DI, 23
		call WRD_TO_HEX
		mov AL, BL
		call BYTE_TO_HEX
		call PRINT
		
		pop SI
		pop DI
		pop CX
		pop BX
		pop AX
		ret
	SYSTEM_VER ENDP
;-------------------------------
; КОД
BEGIN PROC NEAR
    sub AX, AX
    mov AX, DATA
    mov DS, AX
    
    call PC_MODEL
    call SYSTEM_VER
    

    ; Выход в DOS
    xor AL,AL
    mov AH,4Ch
    int 21H
BEGIN ENDP
exeprogramm ENDS
 END BEGIN ;конец модуля, START - точка входа