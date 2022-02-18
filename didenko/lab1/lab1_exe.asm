; Стек программы
AStack SEGMENT STACK
 DW 128 DUP(?)
AStack ENDS


DATA SEGMENT
PC_n db "PC",0Dh,0Ah,'$'
PC_XT_n db "PC/XT",0Dh,0Ah,'$'
PC_AT_n db "AT",0Dh,0Ah,'$'
PS2_model_30_n db "PS2 model 30",0Dh,0Ah,'$'
PS2_model_50_or_60_n db "PS2 model 50 or 60",0Dh,0Ah,'$'
PS2_model_80_n db "PS2 model 80",0Dh,0Ah,'$'
PCjr_n db "PCjr",0Dh,0Ah,'$'
PC_conv_n db "PC Convertible",0Dh,0Ah,'$'
def_n db "None coincidences",0Dh,0Ah,'$'

VERSIONS db 'Version MS-DOS:  .  ',0DH,0AH,'$'
SERIAL_NUMBER db  'Serial number OEM:  ',0DH,0AH,'$'
USER_NUMBER db  'User serial number:       H $'


DATA ENDS

CODE SEGMENT
 ASSUME CS:CODE, DS:DATA, SS:AStack

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
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


PRINT proc near
mov AH,09h
INT 21h
ret
PRINT endp

type_PC proc near
 mov ax, 0f000h
 mov es, ax
 mov al, es:[0fffeh]
 cmp al, 0F8h
 jb define
 cmp al,0FFh
 jae pc
 cmp al, 0FEh
 jae pc_xt
 cmp al, 0FDh
 jae pcjr
 cmp al, 0FCh
 jae ps2_model_50_or_60
 cmp al, 0FBh
 jae pc_xt
 cmp al, 0FAh
 jae ps2_model_30
 cmp al, 0F9h
 jae pc_conv
 cmp al, 0F8h
 jae ps2_model_80
 pc:
  mov dx,offset PC_n
  jmp call_print
 pc_xt:
  mov dx,offset PC_XT_n
  jmp call_print
 pc_at:
  mov dx,offset PC_AT_n
  jmp call_print
 ps2_model_30:
  mov dx,offset PS2_model_30_n
  jmp call_print
 ps2_model_50_or_60:
  mov dx,offset PS2_model_50_or_60_n
  jmp call_print
 ps2_model_80:
  mov dx,offset PS2_model_80_n
  jmp call_print
 pcjr:
  mov dx,offset PCjr_n
  jmp call_print
 pc_conv:
  mov dx,offset PC_conv_n
  jmp call_print
 define:
  mov dx,offset def_n
  jmp call_print
 call_print:
  call PRINT  
 ret
 type_PC endp
 

ms_version PROC near
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
 call PRINT
   	
 mov si, offset SERIAL_NUMBER
 add si, 19
 mov al, bh
 call BYTE_TO_DEC
 mov dx, offset SERIAL_NUMBER
 call PRINT
	
 mov di, offset USER_NUMBER
 add di, 25
 mov ax, cx
 call WRD_TO_HEX
 mov al, bl
 call BYTE_TO_HEX
 sub di, 2
 mov [di], ax
 mov dx, offset USER_NUMBER
 call PRINT
 ret
ms_version endp
 

Main PROC FAR
 push DS
 sub AX,AX
 push AX
 mov AX,DATA
 mov DS,AX
 call type_PC
 call ms_version

 ret

Main ENDP
CODE ENDS
 END Main
