AStack SEGMENT STACK
	DW 256 DUP(?)
AStack ENDS
;-------------------------------
DATA SEGMENT
	NOTYPE db 'IBM type:  ', 0DH, 0AH, '$'
	PC db 'IBM type: PC', 0DH, 0AH, '$'
	XT db 'IBM type: PC/XT', 0DH, 0AH, '$'
	AT db 'IBM type: AT', 0DH, 0AH, '$'
	PS230 db 'IBM type: PS2 model 30', 0DH, 0AH, '$'
	PS250_60 db 'IBM type: PS2 model 50 or 60', 0DH, 0AH, '$'
	PS280 db 'IBM type: PS2 model 80', 0DH, 0AH, '$'
	PCjr db 'IBM type: PCjr', 0DH, 0AH, '$'
	PC_Convertible db 'IBM type: PC Convertible', 0DH, 0AH, '$'
	DOSV db 'MS DOS version:  .  ', 0DH, 0AH, '$'
	OEM db 'OEM number:   ', 0DH, 0AH, '$'
	USR db "User's number:       h", 0DH, 0AH, "$"
DATA ENDS
;-------------------------------
TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:DATA, SS:AStack
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
; Определение одной из систем
PC_VERSION PROC near
	mov AX, 0F000h
    	mov ES, AX
    	mov AL, ES:[0FFFEh]
    	
    	cmp AL, 0FFh
    	je print_pc
    	
    	cmp AL, 0FBh
    	je print_XT
    	
    	cmp AL, 0FCh
    	je print_AT
    	
    	cmp AL, 0FAh
    	je print_ps230
    	
    	cmp AL, 0FCh
    	je print_ps250_60
    	
    	cmp AL, 0F8h
    	je print_ps280
    	
    	cmp AL, 0FDh
    	je print_PCjr
    	
    	cmp AL, 0F9h
    	je print_pc_convertible
    	
    	mov DI, offset NOTYPE
    	add DI, 10
	call BYTE_TO_HEX
	mov [DI], AX
	mov DX, offset NOTYPE
	jmp final
    	
print_pc:
	mov DX, offset PC
	jmp final
	
print_XT:
	mov DX, offset XT
	jmp final
	
print_AT:
	mov DX, offset AT
	jmp final
	
print_ps230:
	mov DX, offset PS230
	jmp final
	
print_ps250_60:
	mov DX, offset ps250_60
	jmp final
	
print_ps280:
	mov DX, offset ps280
	jmp final
	
print_PCjr:
	mov DX, offset PCjr
	jmp final
	
print_pc_convertible:
	mov DX, offset PC_Convertible
	jmp final
	
final:
	call PRINT
	ret
PC_VERSION ENDP
;-----------------------------------
DOS_VERSION PROC near
	xor AX, AX
	mov AH, 30h
	int 21h
	
	mov SI, offset DOSV
	add SI, 16
	call BYTE_TO_DEC
	mov AL, AH
	add SI, 3
	call BYTE_TO_DEC
	mov DX, offset DOSV
	call PRINT
	ret
DOS_VERSION ENDP
;-----------------------------------
OEM_NUMBER PROC near
	xor AX, AX
	mov AH, 30h
	int 21h
	
	mov SI, offset OEM
	add SI, 14
	mov AL, BH
	call BYTE_TO_DEC
	mov DX, offset OEM
	call PRINT
	ret
OEM_NUMBER ENDP
;-----------------------------------
USER_NUMBER PROC near
	xor AX, AX
	mov AH, 30h
	int 21h
	
	mov DI, offset USR
	add DI, 20
	mov AX, CX
	call WRD_TO_HEX
	mov AL, BL
	call BYTE_TO_HEX
	mov di, offset USR
	add DI, 15
	mov [DI], AX
	mov DX, offset USR
	call PRINT
	ret
USER_NUMBER ENDP
;-----------------------------------
MAIN PROC far
	mov ax, data
	mov ds, ax
	call PC_VERSION
	call DOS_VERSION
	call OEM_NUMBER
	call USER_NUMBER
	
	xor AL, AL
	mov AH, 4Ch
	int 21h
MAIN ENDP
TESTPC ENDS
	END MAIN
