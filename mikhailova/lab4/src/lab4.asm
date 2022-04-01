AStack SEGMENT STACK
	DW 256 DUP(?)
AStack ENDS

DATA SEGMENT
	INT_LOAD db "Interrupt was load successfully", 0Dh, 0Ah, '$'
	INT_NOT_LOAD db "Interrupt is not load", 0Dh, 0Ah, '$'
	INT_UNLOAD db "Interrupt was unload", 0Dh, 0Ah, '$'
	INT_ALREADY_LOAD db "Interrupt has already been loaded", 0Dh, 0Ah, '$'

	flag_cmd db 0
	flag_load db 0

DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack


PRINT_STRING PROC near
	push ax
    	mov ah, 09h
    	int 21h
	pop ax
    	ret
PRINT_STRING ENDP

MY_INTERRUPT PROC far
	jmp start_func

	KEEP_PSP dw ?
	KEEP_IP dw 0
	KEEP_CS dw 0
	INT_ID dw 5555h
   	INT_COUNT db 'Interrupt counter: 0000 $'

	KEEP_SS dw ?
	KEEP_SP dw ?
	KEEP_AX dw ?
	INTERRUPT_STACK dw 128 dup (?)
	END_INT_STACK dw ?

start_func:
   	mov KEEP_SS, ss
   	mov KEEP_SP, sp
   	mov KEEP_AX, ax
	mov ax, cs
	mov ss, ax
	mov sp, offset END_INT_STACK

	push bx
	push cx
	push dx


	mov ah, 3h
	mov bh, 0h
	int 10h
	push dx


	mov ah, 02h
	mov bh, 0h
	mov dh, 0h
	mov dl, 0h
	int 10h


	push si
	push cx
	push ds
	push bp

	mov ax, SEG INT_COUNT
	mov ds, ax
	mov si, offset INT_COUNT
	add si, 18 
	mov cx, 4

l_loop:
	mov bp, cx
	mov ah, [si+bp]
	inc ah
	mov [si+bp], ah	
	cmp ah, 3Ah
	jl metka	
	mov ah, 30h
	mov [si+bp], ah
	loop l_loop

metka:	
	pop bp	
	pop ds
	pop cx	
	pop si

	push es
	push bp

	mov ax, SEG INT_COUNT
	mov es, ax
	mov ax, offset INT_COUNT
	mov bp, ax
	mov ah, 13h
	mov al, 00h
	mov cx, 24 
	mov bh, 0h
	int 10h

	pop bp
	pop es


	pop dx
	mov ah, 02h
	mov bh, 0h
	int 10h

	pop dx
	pop cx
	pop bx

	mov ax, KEEP_SS
	mov ss, ax
	mov ax, KEEP_AX
	mov sp, KEEP_SP

	iret
int_end:
MY_INTERRUPT ENDP

CHECK_COMMAND PROC NEAR
	push es
	mov ax, KEEP_PSP
	mov es, ax
	mov bx, 82h
	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne check_end

	mov al, es:[bx]
	inc bx
	cmp al, 'u'
	jne check_end

	mov al, es:[bx]
	inc bx
	cmp al, 'n'
	jne check_end
	mov flag_cmd, 1h

check_end:
	pop es
	ret
CHECK_COMMAND ENDP



IS_INTERRUPT_LOAD PROC NEAR
	push ax
	push bx
	push si

	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov si, offset INT_ID
	sub si, offset MY_INTERRUPT
	mov dx, es:[bx + si]
	cmp dx, 5555h
	jne is_load_end
	mov flag_load, 1h

is_load_end:
	pop si
	pop bx
	pop ax

	ret
IS_INTERRUPT_LOAD ENDP



LOAD_INTERRUPT PROC NEAR
	push ax
	push cx
	push dx
	push es
	push ds

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov KEEP_IP, bx
	mov KEEP_CS, es

	mov dx, offset MY_INTERRUPT
	mov ax, seg MY_INTERRUPT
	mov ds, ax

	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds

	mov dx, offset INT_LOAD
	call PRINT_STRING

	mov dx, offset int_end
	mov cl, 4h
	shr dx, cl
	inc dx
	
	mov ax, cs
   	sub ax, KEEP_PSP
   	add dx, ax
	xor ax, ax
	
	mov ah, 31h
	int 21h

	pop es
	pop dx
	pop cx
	pop ax

	ret
LOAD_INTERRUPT ENDP

INTERRUPT_UNLOAD PROC NEAR
	push ax
	push bx
	push dx
	push si
	push es

	cli
	push ds

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov si, offset KEEP_IP
	sub si, offset MY_INTERRUPT
	mov dx, es:[bx + si]
	mov ax, es:[bx + si + 2]

	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
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

	mov dx, offset INT_UNLOAD
	call PRINT_STRING

	pop es
	pop si
	pop dx
	pop bx
	pop ax

	ret
INTERRUPT_UNLOAD ENDP



Main PROC FAR
	mov ax, DATA
	mov ds, ax
	mov KEEP_PSP, es

	call CHECK_COMMAND
        cmp flag_cmd, 1
        je unload_int

        call IS_INTERRUPT_LOAD
        cmp flag_load, 0
        je not_load
        mov DX, OFFSET INT_ALREADY_LOAD
        call PRINT_STRING
        jmp final

not_load:  
        call LOAD_INTERRUPT
        jmp final

unload_int:     
        call IS_INTERRUPT_LOAD
        cmp flag_load, 0
        jne already_load
        mov DX, OFFSET INT_NOT_LOAD
        call PRINT_STRING
        jmp final
already_load:  
        call INTERRUPT_UNLOAD

final:
	mov ah, 4Ch
	int 21h

Main ENDP
CODE ENDS
END Main