

AStack SEGMENT STACK
  DW 256 DUP(?)
AStack ENDS

DATA SEGMENT
  ; Данные
  pc_type_message db 'PC type: ', '$'
  pc_model_message db 'PC ', 0ah, '$'
  pc_xt_model_message db 'PC/XT ', 0ah, '$'
  pc_at_model_message db 'AT ', 0ah, '$'
  pc_ps2_model_30_message db 'PS2 model 30 ', 0ah, '$'
  pc_ps2_model_80_message db 'PS2 model 80 ', 0ah, '$'
  pc_jr_model_message db 'PCjr ', 0ah, '$'
  pc_convertible_model_message db 'PC Convertible ', 0ah, '$'
  unknown_message db 'Unknown byte:   ', 0ah, '$'
  dos_version_message db 'DOS version:  .   ', 0ah, '$'
  oem_message db 'OEM number:    ', 0ah, '$'
  user_number_message db 'User number: ', '$'
  user_num db '  :    ', 0ah, '$'
DATA ENDS


TESTPC  Segment
        Assume CS:TESTPC, DS:DATA, SS:AStack

;-----------------


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
;-------------------------------------------

print PROC NEAR
  ; процедура вывода 
  ; dx - смещение сообщения
  mov ah, 09h
  int 21h
  ret
print ENDP
;-------------------------------------------

type_model_type PROC NEAR
  ; процедура выводит на экран тип модели
  ; персонального компьютера.
  mov ax, 0F000h
  mov es, ax
  mov al, es:[0FFFEh]
  
  mov dx, offset pc_type_message
  call print

  ; сравнение с каждым типом
  pc_model:
    cmp al, 0FFh
    jne pc_xt_model

    mov dx, offset pc_model_message
    jmp _out

  pc_xt_model:
    cmp al, 0FEh
    je pc_xt_process

    cmp al, 0FBh
    jne pc_at_model

    pc_xt_process:
      mov dx, offset pc_xt_model_message
      jmp _out

  pc_at_model:
    cmp al, 0FCh
    jne pc_ps2_model_30

    mov dx, offset pc_at_model_message
    jmp _out

  pc_ps2_model_30:
    cmp al, 0FAh
    jne pc_ps2_model_80

    mov dx, offset pc_ps2_model_30_message
    jmp _out

  pc_ps2_model_80:
    cmp al, 0F8h
    jne pc_jr_model

    mov dx, offset pc_ps2_model_80_message
    jmp _out

  pc_jr_model:
    cmp al, 0FDh
    jne pc_convertible_model

    mov dx, offset pc_jr_model_message
    jmp _out

  pc_convertible_model:
    cmp al, 0F9h
    jne unknown_type

    mov dx, offset pc_convertible_model_message
    jmp _out

  unknown_type:
    mov dx, offset unknown_message
    call byte_to_hex
    mov di, offset unknown_message
    add di, 14
    mov [di], ax


  _out:
    call print
    ret

type_model_type ENDP
;--------------------------------------------

type_dos_version PROC NEAR
  ; печатает версию MS DOS
  mov ah, 30h
  int 21h

  mov si, offset dos_version_message + 13
  call byte_to_dec
  add si, 3
  mov al, ah
  call byte_to_dec
  mov dx, offset dos_version_message
  call print
  ret

type_dos_version ENDP
;---------------------------------------------

type_oem PROC NEAR
  ; печатает серийный номер OEM
  mov si, offset OEM_message + 13
  mov al, bh
  call byte_to_dec
  mov dx, offset OEM_message
  call print
  ret
type_oem ENDP
;----------------------------------------------

type_user_number PROC NEAR
  ; печатает 24-битовый серийный номер пользователя
  mov dx, offset user_number_message
  call print

  mov ah, 30h
  int 21h

  mov di, offset user_num

  ; bl:cx - серийный номер пользователя
  mov al, bl
  call byte_to_hex
  mov [di], ax
  add di, 6

  mov ax, cx
  call wrd_to_hex

  mov dx, offset user_num
  call print
  ret

type_user_number ENDP

main PROC FAR
  mov ax, data
  mov ds, ax

  call type_model_type
  call type_dos_version
  call type_oem
  call type_user_number

  ; Выход в DOS
  xor al, al
  mov ah, 4Ch
  int 21H
main ENDP

TESTPC  ENDS
        END     main







