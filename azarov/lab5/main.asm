AStack   SEGMENT STACK
        DB 256 dup (?)
AStack   ENDS


DATA	SEGMENT
	mes_not_set_inter db 'Interrupt is not set', 0dh, 0ah, '$'
	mes_set_inter db 'Interrupt is set', 0dh, 0ah, '$'
	mes_setting_inter db 'Interrupt setting...', 0dh, 0ah, '$'
	mes_unload_inter db 'Interrupt unloading...', 0dh, 0ah, '$'

DATA ENDS


CODE   SEGMENT
ASSUME  CS:CODE, DS:DATA, SS:AStack

PRINT_MES MACRO mes
    mov DX, offset mes
    mov AH, 09h
    int 21h
ENDM

GET_CURS MACRO
	mov AH, 03h
	mov BH, 0
	int 10h
ENDM


SET_CURS MACRO
	mov AH, 02h
	mov BH, 0
	int 10h
ENDM



;----------------------Interrupt-------------------------
Interrupt proc far
	jmp start
		indicator 		dw 8888h
		old_inter_ip 	dw 0
		old_inter_cs 	dw 0
		KEEP_PSP		dw 0
		KEEP_SS 		dw 0
		KEEP_SP 		dw 0
		
		code_key_A		db 1Eh
		code_key_S		db 1Fh
		code_key_space	db 39h
		symb_print		db 0
		
		IStack 	dw 128 dup(?)
		IStack_top 	dw 0
		
start:
	mov keep_ss, ss
	mov keep_sp, sp
	mov sp, seg IStack
	mov ss, sp
	mov sp, offset IStack_top
	
	;сохраниение рег-в
	push ax
	push dx
	push cx
	push es
		
	in AL, 60h  ; получам скан-код
	
	cmp AL, code_key_A 
	je key_a
	
	cmp AL, code_key_S
	je key_s
	
	cmp AL, code_key_space
	je key_space
	
call_std_inter:
	call dword ptr CS:old_inter_ip
	jmp int_end
		
	key_a:
		mov symb_print, ' '
		jmp do_req
	key_s:
		mov symb_print, 'w'
		jmp do_req
	key_space:
		mov symb_print, '#'
		jmp do_req
        
		
do_req:
	in AL, 61h
	mov AH, AL
	or AL, 80h
	out 61h, AL
	xchg AH, AL
	out 61h, AL
	mov AL, 20h
	out 20h, AL
		
print_key:
	mov AH, 05h ; function to write to buffer
	mov CL, symb_print
	
to_buffer:
	mov CH, 00h
	int 16h
	or AL, AL ; check an overflow of buffer
	jmp int_end
   
reset_buffer:
	mov AX, 40h
	mov ES, AX
	mov AX, ES:[1Ah]
	mov ES:[1Ch], AX
	jmp print_key


int_end:
	;вост. рег-в и стека
	pop es
	pop cx
	pop bx
	pop ax
	mov sp, KEEP_SS
	mov ss, sp
	mov sp, KEEP_SP
	mov al, 20h
	out 20h, al
	iret
	
end_interrupt:	
Interrupt endp


;------------------Check_set_inter---------------------
Check_set_inter proc near
	; результат проц.:
	; 	al = 1 если прерывание уст.
	; 	al = 0 если прерывание не уст.
	
	push si
	push dx
	push bx
	push ax
	push es


	mov ah, 35h ; функция получения вектора
	mov al, 09h ; номер вектора
	int 21h
	
	; получение индикатора
	mov si, 0003h ; на этом смещении находится indicator в прерывании
	mov dx, es:[bx + si]
	
	; проверка индикатора
	mov al, 1
	cmp dx, 8888h
	je restore
	mov al, 0

restore:
	pop es
	mov bl, al
	pop ax
	mov al, bl
	pop bx
	pop dx
	pop si
	ret
Check_set_inter endp
	
	
;------------------Load_interrupt---------------------
Load_interrupt proc near
	push dx
	push ax
	push cx

	mov ah, 35h ; функция получения вектора
	mov al, 09h ; номер вектора
	int 21h
	mov old_inter_ip, bx
	mov old_inter_cs, es
	
	; замена на пользов. прерывание
	push ds
	mov dx, offset Interrupt
	mov ax, seg Interrupt
	mov ds, ax
	mov ah, 25H ; функция установки вектора
	mov al, 09H ; номер вектора который изменяем
	int 21h
	pop ds
	
	; оставляем процедуру прерывания резидентной в памяти
	mov dx, offset end_interrupt
	mov cl, 4
	shr dx, cl
	inc dx
	mov ax, cs
	sub ax, keep_psp
	add dx, ax
	xor ax, ax
	mov ah, 31h
	int 21h

	pop cx
	pop ax
	pop dx

	ret
Load_interrupt endp


;------------------Check_param_un---------------------
Check_param_un proc near
	; результат проц.:
	; 	al = 1 если указан /un
	; 	al = 0 если НЕ указан /un
	push bx

	mov al, 0
	mov bh, es:[82h]
	cmp bh, '/'
	jne end_
	
	mov bh, es:[83h]
	cmp bh, 'u'
	jne end_
	
	mov bh, es:[84h]
	cmp bh, 'n'
	jne end_
	
	mov al, 1

	end_:
		pop bx
	ret
Check_param_un endp

	
;------------------Unload_interrupt---------------------
Unload_interrupt proc near
	push ax
	push bx
	
	; получаем es и bx
	mov AH, 35h
	mov AL, 09h
	int 21h
	
	; востанавливаем вектор прерываний
	cli 
	push ds
	mov ax, es:[old_inter_cs]
	mov ds, ax
	mov dx, es:[old_inter_ip]
	mov ah, 25h
	mov al, 09h
	int 21h
	pop ds
	sti

	; освобождение блока памяти занятого резидентом
	mov ax, es:[keep_psp]
	mov es, ax
	push es
	mov ax, es:[2Ch]
	mov es, ax
	mov ah, 49h
	int 21h
	pop es
	int 21h

	pop bx
	pop ax
	ret
Unload_interrupt endp

	
;=======================Main=============================	
Main proc far 
	push  DS       ;\  Сохранение адреса начала PSP в стеке
    sub   AX,AX    ; > для последующего восстановления по
    push  AX       ;/  команде ret, завершающей процедуру.
    mov   AX,DATA             ; Загрузка сегментного
    mov   DS,AX               ; регистра данных. 
	mov   keep_psp, es 
	
	; проверка уст. ли прерывание
	call Check_set_inter
	mov ah, al 
	call Check_param_un
	; ah - установлено ли прерыв
	; al - указан ли параметр /un

	cmp ah, 1
	je j_inter_set

	j_inter_not_set:
		PRINT_MES mes_not_set_inter
		
		cmp al, 0
		je j_stting_inter
		
		j_nothing1:
			jmp finish_program
			
		j_stting_inter:
			PRINT_MES mes_setting_inter
			PRINT_MES mes_set_inter
			call Load_interrupt
			jmp finish_program
	
	j_inter_set:
		PRINT_MES mes_set_inter
		
		cmp al, 1
		je j_unload_inter
		
		j_nothing2:
			jmp finish_program
			
		j_unload_inter:
			PRINT_MES mes_unload_inter
			call Unload_interrupt
			PRINT_MES mes_not_set_inter
			jmp finish_program

		
finish_program:
	xor ax, ax
	mov ah, 4Ch
	int 21h

Main endp
CODE ends
	end Main