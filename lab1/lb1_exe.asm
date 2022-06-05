AStack SEGMENT STACK
    DW 128 DUP (?)
AStack ENDS

data SEGMENT

PCvar1 DB 'PC',0DH,0AH,'$'
PCvar2 DB 'PC/XT',0DH,0AH,'$' 
PCvar3 DB 'PC: AT',0DH,0AH,'$' 
PCvar4 DB 'PC: PS2 model 30',0DH,0AH,'$'  
PCvar5 DB 'PC: PS2 model 50 or 60',0DH,0AH,'$' 
PCvar6 DB 'PC: PS2 model 80',0DH,0AH,'$'
PCvar7 DB 'PCjr',0DH,0AH,'$' 
PCvar8 DB 'PC Convertible',0DH,0AH,'$'
DOS DB 'DOS:  .  ',0DH,0AH,'$'
OEM DB 'OEM:   ',0DH, 0AH, '$'
USER DB 'User:     h',0DH, 0AH, '$'

data ENDS

main SEGMENT
    ASSUME CS:main, DS:data, SS:AStack


print_function PROC
    mov ah, 09h
    int 21h
    ret
print_function ENDP

	TETR_TO_HEX PROC NEAR
		and AL,0Fh
		cmp AL,09
		jbe next
		add AL,07
	next: add AL,30h
		ret
	TETR_TO_HEX ENDP
	
	BYTE_TO_HEX PROC 
		;байт в AL переводится в два символа
		;шестнадцатиричного числа в AX 
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX;в AL старшая цифра
		pop CX;в AH младшая
		ret
	BYTE_TO_HEX ENDP
	
	WRD_TO_HEX PROC 
		;перевод в 16 с/с 16-ти разрядного числа
		;в AX - число, DI - адрес последнего символа
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
	
	BYTE_TO_DEC PROC NEAR
	;перевод в 10 с/с, SI - адрес поля младшей цифры
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


PC_proc PROC
    mov AX, 0F000h
    mov ES, AX
    mov AL, ES:[0FFFEh]
	
    cmp AL, 0ffh
    mov DX, offset PCvar1
    je print
	
    cmp AL, 0feh
    mov DX, offset PCvar2
    je print
	
    cmp AL, 0fbh
    je print
	
    cmp AL, 0fch
    mov DX, offset PCvar3
    je print
	
    cmp AL, 0fah
    mov DX, offset PCvar4
    je print	
	
    cmp AL, 0fch
    mov DX, offset PCvar5
    je print
	
	cmp AL, 0f8h
    mov DX, offset PCvar6
    je print
	
    cmp AL, 0fdh
    mov DX, offset PCvar7
    je print
	
    cmp AL, 0f9h
    mov DX, offset PCvar8
    je print

print:
    call print_function
    ret
PC_proc ENDP


DOS_proc PROC
    mov AH, 30h
    int 21h
    mov SI, offset DOS + 5
    call BYTE_TO_DEC
    mov AL, AH
    mov SI, offset DOS + 8
    call BYTE_TO_DEC
    mov DX, offset DOS
    call print_function
    ret
DOS_proc ENDP

OEM_proc PROC
    mov SI, offset OEM + 5
    mov AL, BH
    call BYTE_TO_DEC
    mov DX, offset OEM
    call print_function 
    ret
OEM_proc ENDP
   
User_proc PROC
   mov DI, offset User
    add DI, 9
    mov AX, CX
    call WRD_TO_HEX
    mov AL, BL
    call BYTE_TO_HEX
    mov DI, offset User + 6
    mov [DI], AX
    mov DX, offset User
    call print_function
    ret
User_proc ENDP

begin PROC FAR
    mov AX, data
    mov DS, AX
    call PC_proc
    call DOS_proc
    call OEM_proc
    call User_proc
    xor AL, AL
    mov AH, 4Ch
    int 21h
begin ENDP

main ENDS
END begin