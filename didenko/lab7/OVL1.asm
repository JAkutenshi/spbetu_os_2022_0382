OVL1 SEGMENT
	ASSUME CS:OVL1, DS:NOTHING, SS:NOTHING, ES:NOTHING
	
	
MAIN PROC FAR
	push ax
	push dx
	push ds
	push di
	
	mov ax,cs
	mov ds,ax
	lea dx, STR_LOAD
	call WRITE_STRING
	
	lea di, STR_SEG_ADRESS
	add di, 19
	mov ax, cs
	call WRD_TO_HEX
	
	lea dx, STR_SEG_ADRESS
	call WRITE_STRING
	
	pop di
	pop ds
	pop dx
	pop ax
	
	RETF
MAIN ENDP

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
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

WRITE_STRING PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
WRITE_STRING ENDP

STR_LOAD db 'OVL1.ovl is load!',13,10,'$'
STR_SEG_ADRESS db 'Segment adress:        ',13,10,'$'

OVL1 ENDS
END MAIN
