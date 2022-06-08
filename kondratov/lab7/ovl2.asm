CODE SEGMENT
	ASSUME CS:CODE
	
main PROC FAR
	push AX
	push DX
	push DS
	push DI
	
	mov AX, CS
	mov DS, AX
	lea DX, OVL_LOAD
	call WRITE_STRING
	
	lea DI, SEG_ADRESS
	add DI, 19
	mov AX, cs
	call WRD_TO_HEX
	
	lea DX, SEG_ADRESS
	call WRITE_STRING
	
	pop DI
	pop DS
	pop DX
	pop AX
	
	RETF
main ENDP

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
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX 
   pop CX 
   ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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

OVL_LOAD db 'ovl2.ovl is successfully load!',13,10,'$'
SEG_ADRESS db 'Segment adress:        ',13,10,'$'

CODE ENDS
END main
