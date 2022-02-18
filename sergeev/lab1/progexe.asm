AStack SEGMENT STACK
    DW 12 DUP(?)
AStack ENDS

DATA SEGMENT

PC db  'Your PC type is -> PC',0DH,0AH,'$'
PC_XT db 'Your PC type is -> PC/XT',0DH,0AH,'$'
AT db  'Your PC type is -> AT',0DH,0AH,'$'
PS2_30 db 'Your PC type is -> PS2 модель 30',0DH,0AH,'$'
PS2_50_60 db 'Your PC type is -> PS2 модель 50 или 60',0DH,0AH,'$'
PS2_80 db 'Your PC type is -> PS2 модель 80',0DH,0AH,'$'
PCJR db 'Your PC type is -> PСjr',0DH,0AH,'$'
PC_CONVERTIBLE db 'Your PC type is -> PC Convertible',0DH,0AH,'$'
PC_UNK db 'Your PC type is ->  ',0DH,0AH,'$'

VERSIONS db 'Version MS-DOS:  .  ',0DH,0AH,'$'
SERIAL_NUMBER db  'Serial number OEM:   ',0DH,0AH,'$'
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
;-------------------------------
WRITESTRING PROC near
   mov AH,09h
   int 21h
   ret
WRITESTRING ENDP

CHECK_PC_TYPE PROC near
   mov ax,0F000h
   mov es,ax
   mov ah,es:[0FFFEh]
   ;mov ah,0EBh

   cmp ah,0FFh
   je pc_lab

   cmp ah,0FEh
   je xt_lab

   cmp ah, 0FBh
   je xt_lab

   cmp ah, 0FCh
   je at_lab

   cmp ah, 0FAh
   je ps230_lab

   cmp ah, 0FCh
   je ps25060_lab

   cmp ah, 0F8h
   je ps280_lab

   cmp ah, 0FDh
   je pcjr_lab

   cmp ah, 0F9h
   je pcconv_lab

unk:
   mov di,offset PC_UNK
   add di,19
   mov al,ah
   call BYTE_TO_HEX
   mov [di], ax
   mov dx,offset PC_UNK
   jmp final_1

pc_lab:
   mov dx,offset PC
   jmp final_1

xt_lab:
   mov dx,offset PC_XT
   jmp final_1

at_lab:
   mov dx,offset AT
   jmp final_1

ps230_lab:
   mov dx,offset PS2_30
   jmp final_1

ps25060_lab:
   mov dx,offset PS2_50_60
   jmp final_1

ps280_lab:
   mov dx,offset PS2_80
   jmp final_1

pcjr_lab:
   mov dx,offset PCJR
   jmp final_1

pcconv_lab:
   mov dx,offset PC_CONVERTIBLE
   jmp final_1

final_1:
   call WRITESTRING
   ret
CHECK_PC_TYPE ENDP

CHECK_OS_VERS PROC near
   mov ah,30h
   int 21h
   push ax
   
   mov si,offset VERSIONS
   add si,16
   call BYTE_TO_DEC
   pop ax
   add si,3
   mov al,ah
   call BYTE_TO_DEC
   mov dx,offset VERSIONS
   call WRITESTRING

   mov si,offset SERIAL_NUMBER
   add si,21
   mov al,bh
   call BYTE_TO_DEC
   mov dx ,offset SERIAL_NUMBER
   call WRITESTRING

   mov di, offset USER_NUMBER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di,2
	mov [di], ax
	mov dx, offset USER_NUMBER
	call WRITESTRING
	ret

final_2:
   ret
CHECK_OS_VERS ENDP

Main PROC FAR
    push DS
    sub AX,AX
    push AX
    mov AX,DATA
    mov DS,AX

   call CHECK_PC_TYPE
   call CHECK_OS_VERS
   xor AL,AL
   mov AH,4Ch
   int 21H

Main ENDP
CODE ENDS
    END Main