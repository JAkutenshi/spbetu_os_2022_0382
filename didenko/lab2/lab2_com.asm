main_segment SEGMENT
 ASSUME CS:main_segment, DS:main_segment, ES:NOTHING, SS:NOTHING
 ORG 100H
START: 
 JMP BEGIN
 
 ;---------------------Данные--------------------------
DATA:
 seg_adr_first db "Segment address of first byte inaccessible memory:     h",0Dh,0Ah,'$'
 seg_adr_env db "Segment address of the medium being transferred program:     h",0Dh,0Ah,'$'
 tail_com_str db "Tail command string:                                                                      ",0Dh,0Ah,'$'
 env_area_con db "Environment area content:  ",'$'
 path db "Loadable module path:  ",'$'
 NULL_TAIL db "In Command tail no sybmols",0Dh,0Ah,'$'
 END_STRING db 0Dh,0Ah,'$'
 
 ;ПРОЦЕДУРЫ
 ;-----------------------------------------------------
TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
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
loop_bd: div CX
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
end_l: pop DX
 pop CX
 ret
BYTE_TO_DEC ENDP
;-------------------------------
; КОД

PRINT proc near
mov AH,09h
INT 21h
ret
PRINT endp

PRINT_SEG_ADR_FIRST proc near
 mov di, offset seg_adr_first + 54
 mov ax, ds:[2h]
 call WRD_TO_HEX
 mov dx, offset seg_adr_first
 call PRINT
 ret
 PRINT_SEG_ADR_FIRST endp

PRINT_SWG_ADR_ENV proc near
 mov ax, ds:[2Ch]
 mov di, OFFSET seg_adr_env + 60
 call WRD_TO_HEX
 mov dx, offset seg_adr_env
 call PRINT
 ret
 PRINT_SWG_ADR_ENV endp

PRINT_TAIL_COM_STR PROC near   
 mov cl, ds:[80h]
 mov si, offset tail_com_str
 add si, 21
 cmp cl, 0h
 je empty_tail
 xor di, di
readtail: 
 mov al, ds:[81h+di]
 inc di
 mov [si], al
 inc si
 loop readtail
 mov dx, offset tail_com_str
 jmp end_tail
empty_tail:
		mov dx, offset NULL_TAIL
end_tail: 
   call PRINT 
   ret
PRINT_TAIL_COM_STR ENDP


PRINT_CONTENT PROC near
   mov dx, offset env_area_con
   call PRINT
   xor di,di
   mov ds, ds:[2Ch]
read_string:
	cmp byte ptr [di], 00h
	jz end_str
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp find_end
end_str:
   cmp byte ptr [di+1],00h
   jz find_end
   push ds
   mov cx, cs
	mov ds, cx
	mov dx, offset END_STRING
	call PRINT
	pop ds
find_end:
	inc di
	cmp word ptr [di], 0001h
	jz read_path
	jmp read_string
read_path:
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset path
	call PRINT
	pop ds
	add di, 2
loop_path:
	cmp byte ptr [di], 00h
	jz complete
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp loop_path
complete:
	ret
PRINT_CONTENT ENDP

BEGIN:
 call PRINT_SEG_ADR_FIRST
 call PRINT_SWG_ADR_ENV
 call PRINT_TAIL_COM_STR
 call PRINT_CONTENT
 
 
; Выход в DOS
 xor AL,AL
 mov AH,4Ch
 int 21H
 main_segment ENDS
 END START ;конец модуля, START - точка входа