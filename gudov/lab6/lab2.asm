PC  Segment
        Assume CS:PC, DS:PC, ES:NOTHING, SS:NOTHING
        ORG 100H

START: JMP BEGIN

;ÄÀÍÍÛÅ

Unavailable_Memory_Msg db 'Unavailable memory address:     ', 0ah, '$'
Segment_Env_Addres_Msg db 'Environment address:     ', 0ah, '$'
Input_String db 'Input string:', '$'

;ÏÐÎÖÅÄÓÐÛ

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near ;áàéò â AL ïåðåâîäèòñÿ â äâà ñèìâîëà øåñò. ÷èñëà â AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;â AL ñòàðøàÿ öèôðà
   pop CX ;â AH ìëàäøàÿ
   ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near ;ïåðåâîä â 16 ñ/ñ 16-òè ðàçðÿäíîãî ÷èñëà
					 ; â AX - ÷èñëî, DI - àäðåñ ïîñëåäíåãî ñèìâîëà
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

BYTE_TO_DEC PROC near ; ïåðåâîä â 10ñ/ñ, SI - àäðåñ ïîëÿ ìëàäøåé öèôðû
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

print PROC NEAR
  push ax
  mov ah, 09h
  int 21h
  pop ax
  ret
print ENDP

Prnt_Unavailable proc near
  push ax
  push di
  push dx

  mov ax, es:[02h]
  mov di, offset Unavailable_Memory_Msg
  add di, 31
  call wrd_to_hex
  mov dx, offset Unavailable_Memory_Msg
  call print

  pop dx
  pop di
  pop ax
  ret
Prnt_Unavailable endp

Prnt_Env_Address proc near
  push ax
  push di
  push dx

  mov ax, es:[02Ch]
  mov di, offset Segment_Env_Addres_Msg
  add di, 24
  call wrd_to_hex
  mov dx, offset Segment_Env_Addres_Msg
  call print

  pop dx
  pop di
  pop ax
  ret
Prnt_Env_Address endp

Prnt_Input_String proc near
  push dx
  push cx
  push si
  push ax

  mov dx, offset Input_String
  call print
  mov cl, ds:[80h]
  mov si, 081h
  mov ah, 02h  
  cmp cl, 0
  je end_


  print_symbol:
    mov dl, [si]
    int 21h
    inc si
    loop print_symbol


  end_:
    mov dl, 0ah
    int 21h
  
  pop ax
  pop si
  pop cx
  pop dx

  ret

Prnt_Input_String endp

Prnt_String proc near
  push dx
  push ax
  mov ah, 02h

  print_sym:
    mov dl, ds:[si]
    inc si
      
    cmp dl, 0
    jz end_of_string
      
    int 21h
    jmp print_sym 

  end_of_string:
    mov dl, 0ah
    int 21h

  pop ax
  pop dx
  ret
Prnt_String endp

Prnt_Environment_Content_And_Path proc near
  push ds
  push si
  push ax
  push cx
  push dx

  mov ds, es:[2ch]
  mov si, 0

  Prnt_Strings:
    call Prnt_String
    mov bl, ds:[si]
    cmp bl, 0
    jz print_path
    jmp Prnt_Strings

  print_path:
    add si, 3 
    call Prnt_String

  the_end:
    pop dx
    pop cx
    pop ax
    pop si
    pop ds

  ret

Prnt_Environment_Content_And_Path endp

BEGIN:

  call Prnt_Unavailable
  call Prnt_Env_Address
  call Prnt_Input_String
  call Prnt_Environment_Content_And_Path

  xor ax, ax
  mov ah, 01h
  int 21h

  mov ah, 4Ch
  int 21h

PC  ENDS
        END     START