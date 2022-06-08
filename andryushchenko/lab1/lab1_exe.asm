AStack    SEGMENT  STACK
          DW 128 DUP(?)   
AStack    ENDS

DATA  SEGMENT
   PC db  'Type: PC',0DH,0AH,'$'
   PC_XT db 'Type: PC/XT',0DH,0AH,'$'
   AT db  'Type: AT',0DH,0AH,'$'
   MODEL_30 db 'Type: PS2 модель 30',0DH,0AH,'$'
   MODEL_50_OR_60  db 'Type: PS2 модель 50 или 60',0DH,0AH,'$'
   MODEL_80  db 'Type: PS2 модель 80',0DH,0AH,'$'
   PCjr db 'Type: PСjr',0DH,0AH,'$'
   PC_CONVERTIBLE db 'Type: PC Convertible',0DH,0AH,'$'

   VERSIONS db 'Version MS-DOS:  .  ',0DH,0AH,'$'
   SERIAL_NUMBER db  'Serial number OEM:  ',0DH,0AH,'$'
   USER_NUMBER db  'User serial number:       H $'
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack

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

BYTE_TO_DEC PROC near

   push CX
   push DX
   xor AH,AH
   xor DX,DX
   mov CX,10
loop_bd:
   div CX
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
end_l:
   pop DX
   pop CX
   ret
BYTE_TO_DEC ENDP

WRITESTRING PROC near
   mov AH,09h
   int 21h
   ret
WRITESTRING ENDP

PC_TYPE PROC near
   mov ax, 0f000h 
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh 
	je pc_mes
	cmp al, 0feh
	je pc_xt_mes
	cmp al, 0fbh
	je pc_xt_mes
	cmp al, 0fch
	je pc_at_mes
	cmp al, 0fah
	je pc_ps2_m30
	cmp al, 0f8h
	je pc_ps2_m80
	cmp al, 0fdh
	je pc_jr
	cmp al, 0f9h
	je pc_conv
pc_mes:
	mov dx, offset PC
	jmp writetype
pc_xt_mes:
	mov dx, offset PC_XT
	jmp writetype
pc_at_mes:
	mov dx, offset AT
	jmp writetype
pc_ps2_m30:
	mov dx, offset MODEL_30
	jmp writetype
pc_ps2_m50_60:
	mov dx, offset MODEL_50_OR_60 
	jmp writetype
pc_ps2_m80:
	mov dx, offset MODEL_80 
	jmp writetype
pc_jr:
	mov dx, offset PCjr
	jmp writetype
pc_conv:
	mov dx, offset PC_CONVERTIBLE
	jmp writetype
writetype:
	call WRITESTRING
	ret
PC_TYPE ENDP

OS_VER PROC near
	mov ah, 30h
	int 21h
	push ax
	
	mov si, offset VERSIONS
	add si, 16
	call BYTE_TO_DEC
   pop ax
   mov al, ah
   add si, 3
	call BYTE_TO_DEC
	mov dx, offset VERSIONS
	call WRITESTRING
   
	
	mov si, offset SERIAL_NUMBER
	add si, 19
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset SERIAL_NUMBER
	call WRITESTRING
	
	mov di, offset USER_NUMBER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER_NUMBER
	call WRITESTRING
	ret
OS_VER ENDP

Main PROC FAR
   sub   AX,AX
   push  AX
   mov   AX,DATA
   mov   DS,AX
   call PC_TYPE
   call OS_VER
   xor AL,AL
   mov AH,4Ch
   int 21H
Main ENDP
CODE ENDS
      END Main