AStack SEGMENT STACK
AStack ENDS

DATA SEGMENT
PC_Type			db	'PC Type:  ', 0dh, 0ah,'$'
Mod_numb		db	'Modification number:  .  ', 0dh, 0ah,'$'
OEM				db	'OEM:   ', 0dh, 0ah, '$'
S_numb	    db	'Serial Number:       ', 0dh, 0ah, '$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack
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
main:
	push ds
	sub ax, ax
	push ax
	mov ax, DATA
	mov ds, ax
;PC_Type
	push es
	push bx
	push ax
	mov bx, 0F000h
	mov es, bx
	mov ax, es:[0FFFEh]
	mov ah, al
	call BYTE_TO_HEX
	lea bx, PC_Type
	mov [bx+9], ax; смещение по колву символов, записали в PC_Type по адресу
	pop ax
	pop bx
	pop es

	mov ah, 30h; Воспользуемся функцией получения информации о MS DOS
	int 21h

;Mod_numb
	push ax
	push si
	lea si, Mod_numb; в si адрес Mod_numb
	add si, 21; Сместимся на 21 символ
	call BYTE_TO_DEC; al - Basic version number
	add si, 3; Еще на три
	mov al, ah
	call BYTE_TO_DEC; al - Modification number
	pop si
	pop ax

;OEM
	mov al, bh
	lea si, OEM
	add si, 7
	call BYTE_TO_DEC; al - OEM number

;S_numb
	mov al, bl
	call BYTE_TO_HEX; al - 24b number
	lea di, S_numb
	add di, 15
	mov [di], ax
	mov ax, cx
	lea di, S_numb
	add di, 20
	call WRD_TO_HEX

;Output
	mov AH,09h	
	lea DX, PC_Type
	int 21h
	lea DX, Mod_numb
	int 21h
	lea DX, OEM
	int 21h
	lea DX, S_numb
	int 21h

; Выход в DOS
	xor AL,AL
	mov AH,4Ch
	int 21H
CODE ENDS
	END main