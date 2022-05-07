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
		indicator dw 8888h
		number db 'Interrupt called 0000 times$'
		old_inter_ip dw 0
		old_inter_cs dw 0
		keep_psp dw 0
		keep_ss dw 0
		keep_sp dw 0
		keep_ax dw 0
		IStack db 128 dup(?)
start:

	;организовываем свой стек
	mov keep_ax, ax
	mov ax, ss
	mov keep_ss, ax
	mov keep_sp, sp
	mov ax, seg IStack
	mov ss, ax
	mov sp, offset start
	
	;сохраниение рег-в
	push cx
	push bx
	push dx
	
	
	;печатаем строку
	GET_CURS
	push dx

	mov dh, 0
	mov dl, 0
	SET_CURS
	push si

	push cx
	push ds
	push bp

	mov ax, seg number
	mov ds, ax
	mov si, offset number
	add si, 16
	mov cx, 4

loop_int:
	mov bp, cx
	mov ah, [si+bp]
	inc ah
	mov [si+bp], ah
	cmp ah, 3Ah
	jne print_msg
	mov ah, 30h
	mov [si+bp], ah
	loop loop_int

print_msg:
	pop bp
	pop ds
	pop cx
	pop si
	
	push es
	push bp

	mov ax, seg number
	mov es, ax
	mov ax, offset number
	mov bp, ax
	mov ah, 13h
	mov al, 0
	mov cx, 27
	mov bh, 0
	int 10h

	pop bp
	pop es
	
	pop dx
	SET_CURS
	
	
	;вост. рег-в и стека
	pop dx
	pop bx
	pop cx

	mov sp, keep_sp
	mov ax, keep_ss
	mov ss, ax
	mov ax, keep_ax
	
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
	mov al, 1Ch ; номер вектора
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
	mov al, 1Ch ; номер вектора
	int 21h
	mov old_inter_ip, bx
	mov old_inter_cs, es
	
	; замена на пользов. прерывание
	push ds
	mov dx, offset Interrupt
	mov ax, seg Interrupt
	mov ds, ax
	mov ah, 25H ; функция установки вектора
	mov al, 1CH ; номер вектора который изменяем
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


;------------------Check_set_inter---------------------
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
	mov AL, 1Ch
	int 21h
	
	; востанавливаем вектор прерываний
	cli 
	push ds
	mov ax, es:[old_inter_cs]
	mov ds, ax
	mov dx, es:[old_inter_ip]
	mov ah, 25h
	mov al, 1Ch
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