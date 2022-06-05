PC  Segment
        Assume CS:PC, DS:PC, ES:NOTHING, SS:NOTHING
        ORG 100H

START: JMP BEGIN

;ДАННЫЕ

Type_Message db 'PC type: ', '$'
Model_Message db 'PC ', 0ah, '$'
XT_Model_Message db 'PC/XT ', 0ah, '$'
AT_Model_Message db 'AT ', 0ah, '$'
PS2_Model_30_Message db 'PS2 model 30 ', 0ah, '$'
PS2_Model_80_Message db 'PS2 model 80 ', 0ah, '$'
Jr_Model_Message db 'PCjr ', 0ah, '$'
Convertible_Model_Message db 'PC Convertible ', 0ah, '$'
Unknown_Message db 'Unknown byte:   ', 0ah, '$'
Dos_Ver_Message db 'DOS version:  .   ', 0ah, '$'
Oem_Message db 'OEM number:    ', 0ah, '$'
User_Num_Message db 'User number: ', '$'
User_Num db '  :    ', 0ah, '$'

;ПРОЦЕДУРЫ

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near ;байт в AL переводится в два символа шест. числа в AX
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

WRD_TO_HEX PROC near ;перевод в 16 с/с 16-ти разрядного числа
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

BYTE_TO_DEC PROC near ; перевод в 10с/с, SI - адрес поля младшей цифры
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

write PROC NEAR
  mov ah, 09h
  int 21h
  ret
write ENDP

Model_type PROC NEAR
  mov ax, 0F000h
  mov es, ax
  mov al, es:[0FFFEh]
  
  mov dx, offset Type_Message
  call write


  Model: 
    cmp al, 0FFh
    jne Xt_Model
    mov dx, offset Model_Message
    jmp _out

  Xt_Model:
    cmp al, 0FEh
    je pc_xt_process
    cmp al, 0FBh
    jne At_Model

    pc_xt_process:
      mov dx, offset XT_Model_Message
      jmp _out

  At_Model:
    cmp al, 0FCh
    jne Ps2_Model_30
    mov dx, offset AT_Model_Message
    jmp _out

  Ps2_Model_30:
    cmp al, 0FAh
    jne Ps2_Model_80
    mov dx, offset PS2_Model_30_Message
    jmp _out

  Ps2_Model_80:
    cmp al, 0F8h
    jne Jr_Model
    mov dx, offset PS2_Model_80_Message
    jmp _out

  Jr_Model:
    cmp al, 0FDh
    jne Convertible_Model
    mov dx, offset Jr_Model_Message
    jmp _out

  Convertible_Model:
    cmp al, 0F9h
    jne Unknown_type

    mov dx, offset Convertible_Model_Message
    jmp _out

  Unknown_type:
    mov dx, offset Unknown_Message
    call byte_to_hex
    mov di, offset Unknown_Message
    add di, 14
    mov [di], ax


  _out:
    call write
    ret
	
Model_type ENDP

Dos_Version PROC NEAR
  mov ah, 30h
  int 21h

  mov si, offset Dos_Ver_Message + 13
  call byte_to_dec
  add si, 3
  mov al, ah
  call byte_to_dec
  mov dx, offset Dos_Ver_Message
  call write
  ret

Dos_Version ENDP

Oem PROC NEAR 
  mov si, offset Oem_Message + 13
  mov al, bh
  call byte_to_dec
  mov dx, offset Oem_Message
  call write
  ret
Oem ENDP

User_Number PROC NEAR 
  mov dx, offset User_Num_Message
  call write

  mov ah, 30h
  int 21h
  mov di, offset User_Num

  mov al, bl
  call byte_to_hex
  mov [di], ax
  add di, 6

  mov ax, cx
  call wrd_to_hex
  mov dx, offset User_Num
  call write
  ret

User_Number ENDP

BEGIN:
  call Model_type
  call Dos_Version
  call Oem
  call User_Number

  ; Выход в DOS
  xor al, al
  mov ah, 4Ch
  int 21H

PC  ENDS
        END     START