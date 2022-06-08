AStack SEGMENT STACK
	DW 256 DUP(?)
AStack ENDS

DATA SEGMENT
LOADED db 'Loaded.' , 0DH, 0AH, '$'
INSTALLED db 'Installed.', 0DH, 0AH, '$'
UNLOADED db 'Unloaded.' , 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack

PRINT PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP

ROUT PROC FAR
    	jmp start_func
	SIGN db '0000'
	KEEP_PSP dw 0
	KEEP_IP dw 0
	KEEP_CS dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_AX dw 0
	value db 0

	INTERRUPT_STACK dw 128 dup (?)
	END_INT_STACK dw ?

start_func:
   	mov KEEP_SS, ss
   	mov KEEP_SP, sp
   	mov KEEP_AX, ax
	mov ax, cs
	mov ss, ax
	mov sp, offset END_INT_STACK

	push ax
	push bx
	push cx
	push dx
	push si
	push es
	push ds
	
	mov ax, seg value
	mov ds, ax
	
	
	in al, 60h
	cmp al, 32h
	je do_req


	pushf
	call dword ptr cs:KEEP_IP
	jmp int_final

do_req:
	in al, 61h
	mov ah, al
	or al, 80h
	out 61h, al
	xchg ah, al
	out 61h, al
	mov al, 20h
	out 20h, al

print_key:
	mov ah, 05h
	mov cl, 06h
	mov ch, 00h
	int 16h
	or al, al
	jz int_final
	mov ax, 40h
	mov es, ax
	mov ax, es:[1ah]
	mov es:[1ch], ax
	jmp print_key
	
int_final:
		
	pop ds
	pop es
	pop si
	pop dx
	pop cx
	pop bx
	pop ax

	mov ax, KEEP_SS
	mov ss, ax
	mov ax, KEEP_AX
	mov sp, KEEP_SP

	mov al, 20h
	out 20h, al
	iret
FINAL:
ROUT ENDP
	

CHECK_USER_INT PROC NEAR
	push ax
	push bx
	push si
	
    mov AH, 35h        ; функция получения вектора
    mov AL, 09h        ; номер вектора
    int 21h 		
    mov SI, offset SIGN 
    sub SI, offset ROUT 
    mov AX,'00'
	cmp AX, ES:[BX+SI] 
    jne UNLOAD 
    cmp AX, ES:[BX+SI+2] 
    je LOAD
UNLOAD:
    call SET_INT
	
    mov DX, offset FINAL  ; размер в байтах от начала сегмента
    mov CL, 4                 ; перевод в параграфы
    shr DX, CL
    inc DX                    ; размер в параграфах
    add DX, CODE
    sub DX, KEEP_PSP
    xor AL, AL
    mov AH, 31h 
   	int 21h
	
LOAD:
    push ES
    push AX
    mov AX, KEEP_PSP 
    mov ES, AX
    cmp byte ptr ES:[82h],'/'
    jne INST 
    cmp byte ptr ES:[83h],'u'
    jne INST  
    cmp byte ptr ES:[84h],'n' 
    je UNL
INST: 
    pop AX
    pop ES
    mov DX, offset INSTALLED
    call PRINT
	
	pop si
	pop bx
	pop ax
    ret
UNL:
    pop AX
    pop ES
	
    call INT_UN
    mov DX, offset UNLOADED
    call PRINT
	
	pop si
	pop bx
	pop ax
    ret
CHECK_USER_INT ENDP

SET_INT PROC NEAR
   	push AX
	push BX
	push DX
	push ES
    push DS
    mov AH, 35h         ; функция получения вектора
    mov AL, 09h         ; номер вектора
    int 21h            
    mov KEEP_IP, BX     ; запоминание смещения
    mov KEEP_CS, ES     ; и сегмента
	
    mov dx, offset ROUT ; смещение для процедуры в DX
    mov ax, seg ROUT    ; сегмент процедуры
   	mov DS, AX          ; помещаем в DS
    mov AH, 25h         ; функция установки вектора
    mov AL, 09h         ; номер вектора
    int 21h             ; меняем прерывание
    pop DS
    mov DX, offset LOADED
    call PRINT
	
	
    pop ES
	pop DX
	pop BX
	pop AX
    ret
SET_INT ENDP 

INT_UN PROC NEAR
	cli
	push ax
	push bx
	push dx
	push si
	push es
	push ds

	mov ah, 35h
	mov al, 09h
	int 21h

	mov si, offset KEEP_IP
	sub si, offset ROUT
	mov dx, es:[bx + si]
	mov ax, es:[bx + si + 2]

	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h
	pop ds

	mov ax, es:[bx + si - 2] 
    	mov es, ax
    	push es
    	mov ax, es:[2ch]
    	mov es, ax
    	mov ah, 49h
    	int 21h
    	pop es
    	mov ah, 49h
    	int 21h

	sti

	pop es
	pop si
	pop dx
	pop bx
	pop ax

	ret
INT_UN ENDP

MAIN PROC FAR
    mov AX, DATA
    mov DS, AX
   	mov KEEP_PSP, ES
    call CHECK_USER_INT	
    xor AL, AL
    mov AH, 4Ch
    int 21h
MAIN ENDP
CODE ENDS
    END MAIN 