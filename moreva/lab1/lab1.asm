TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:TESTPC, SS:TESTPC
   ORG 100H
START: JMP BEGIN
; Данные
PC db  'PC type is PC',0DH,0AH,'$'
PC_XT db 'PC type is PC/XT',0DH,0AH,'$'
AT db  'PC type is AT',0DH,0AH,'$'
PS2_30 db 'PC type is PS2 модель 30',0DH,0AH,'$'
PS2_50_60 db 'PC type is PS2 модель 50 или 60',0DH,0AH,'$'
PS2_80 db 'PC type is PS2 модель 80',0DH,0AH,'$'
PCJR db 'PC type is PСjr',0DH,0AH,'$'
PC_CONVERTIBLE db 'PC type is PC Convertible',0DH,0AH,'$'
PC_OTHER db 'PC type is ',0DH,0AH,'$'

DOS db 'Version MS DOS:  .  ',0DH,0AH,'$'
OEM db  'OEM:  ',0DH,0AH,'$'
USER db  'User:      H', 0DH, 0AH,'$'

; Процедуры
;-----------------------------------------------------
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
PRINT PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
PRINT ENDP

CHECK_PC_TYPE PROC near
   mov ax,0F000h
   mov es,ax
   mov ah,es:[0FFFEh]

   cmp ah,0FFh
   je _pc

   cmp ah,0FEh
   je _xt

   cmp ah, 0FBh
   je _xt

   cmp ah, 0FCh
   je _at

   cmp ah, 0FAh
   je _ps230

   cmp ah, 0FCh
   je _ps25060

   cmp ah, 0F8h
   je _ps280

   cmp ah, 0FDh
   je _pcjr

   cmp ah, 0F9h
   je _pcconv

;если нет в таблице
   mov di,offset PC_OTHER
   add di,11
   mov al,ah
   call BYTE_TO_HEX
   mov [di], ax
   mov dx,offset PC_OTHER
   jmp _out

_pc:
   mov dx,offset PC
   jmp _out

_xt:
   mov dx,offset PC_XT
   jmp _out

_at:
   mov dx,offset AT
   jmp _out

_ps230:
   mov dx,offset PS2_30
   jmp _out

_ps25060:
   mov dx,offset PS2_50_60
   jmp _out

_ps280:
   mov dx,offset PS2_80
   jmp _out

_pcjr:
   mov dx,offset PCJR
   jmp _out

_pcconv:
   mov dx,offset PC_CONVERTIBLE
   jmp _out

_out:
   call PRINT
   ret
CHECK_PC_TYPE ENDP

CHECK_OS_VERS PROC near
   mov ah,30h
   int 21h
   push ax
   
   mov si,offset DOS
   add si,16
   call BYTE_TO_DEC
   pop ax
   add si,3
   mov al,ah
   call BYTE_TO_DEC
   mov dx,offset DOS
   call PRINT

   mov si,offset OEM
   add si,6
   mov al,bh
   call BYTE_TO_DEC
   mov dx ,offset OEM
   call PRINT

   mov di, offset USER
   add di, 10
   mov ax, cx
   call WRD_TO_HEX
   mov al, bl
   call BYTE_TO_HEX
   sub di,2
   mov [di], ax
   mov dx, offset USER
   call PRINT
   ret
   
CHECK_OS_VERS ENDP

; Код
BEGIN:
   call CHECK_PC_TYPE
   call CHECK_OS_VERS
   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START 