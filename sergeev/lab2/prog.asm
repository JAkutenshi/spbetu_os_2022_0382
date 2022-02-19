TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; Данные
PC db  'Your PC type is -> PC',0DH,0AH,'$'
InacMemory db 'Inaccessable memory:     h',0DH,0AH,'$'
SegAdr db 'Segment Address:     h',0DH,0AH,'$'
Tail db 'Tail:','$'
Enviroment db 'Enviroment:',0DH,0AH,'$'
ModulePath db 'Path: ','$'

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
WRITESTRING PROC near
   mov AH,09h
   int 21h
   ret
WRITESTRING ENDP

IncMem PROC near
   mov ax,ds:[2]
   mov di, offset InacMemory
   add di,24
   call WRD_TO_HEX
   mov dx, offset InacMemory
   call WRITESTRING
   ret
IncMem ENDP

SegAd PROC near
   mov ax,ds:[2Ch]
   mov di, offset SegAdr
   add di,20
   call WRD_TO_HEX
   mov dx, offset SegAdr
   call WRITESTRING
   ret
SegAd ENDP

PrintSym PROC near
   push ax
   mov ah,02h
   int 21H
   pop ax
   ret
PrintSym ENDP

CmdTail PROC near
   mov cl,ds:[80h]
   mov dx,offset Tail
   call WRITESTRING
   cmp cl,0
   je end_t
   mov di,81h
metka:
   mov dl,ds:[di]
   call PrintSym
   inc di
   loop metka
end_t:
   mov dl,0DH  
   call PrintSym
   mov dl,0AH
   call PrintSym
   ret
CmdTail ENDP

Env PROC near
   mov es,ds:[2Ch]
   xor di,di
   mov dx,offset Enviroment
   call WRITESTRING
metka2:
   mov dl,es:[di]
   cmp dl,0
   je end_e
   call PrintSym
   inc di
   jmp metka2
end_e:
   mov dl,0DH  
   call PrintSym
   mov dl,0AH
   call PrintSym
   inc di
   mov dl,es:[di]
   cmp dl,0
   jne metka2
   ret
Env ENDP

MPath PROC near
   add di,3
   mov dx, offset ModulePath
   call WRITESTRING
metka3:
   mov dl,es:[di]
   cmp dl,0
   je end_m
   call PrintSym
   inc di
   jmp metka3
end_m:
   mov dl,0DH  
   call PrintSym
   mov dl,0AH
   call PrintSym
   ret
Mpath ENDP

; Код
BEGIN:
   call IncMem
   call SegAd
   call CmdTail
   call Env
   call MPath
   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START