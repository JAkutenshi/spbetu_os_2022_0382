AStack SEGMENT  STACK
          DW 128 DUP(?)
AStack ENDS

DATA SEGMENT

	FILE1 db 'ovl1.ovl', 0	
	FILE2 db 'ovl2.ovl', 0
	PATH db 128 dup(0)
	PROG dw 0
	DTA db 43 dup(0)
	CL_POS db 128 dup(0)
	OVL_ADDR dd 0
	KEEP_PSP dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0

	EOF db 0Dh, 0Ah, '$'

	MEM_CMB db 'Memory error: control block destroyed', 0Dh, 0Ah, '$'
	MEM_NOT_ENOUGH db 'Memory error: not enough memory to execute the function', 0Dh, 0Ah, '$'
	MEM_WRONG_ADDR db 'Memory error: invalid block address', 0Dh, 0Ah, '$'
	MEM_FREE_SUCCESS db 'Memory successfully freed', 0Dh, 0Ah, '$'

	WRONG_FUNC_NUM db 'Load error: invalid function number', 0Dh, 0Ah, '$'
	FILE_NOT_FOUND db 'Load error: file not found', 0Dh, 0Ah, '$'
	ROUT_NOT_FOUND db 'Load error: route not found', 0Dh, 0Ah, '$'
	TOO_MUCH_FILES db 'Load error: too much open files', 0Dh, 0Ah, '$'
	NO_ACCESS db 'Load error: no access', 0Dh, 0Ah, '$'
	LOAD_MEM_ERROR db 'Load error: not enough memory', 0Dh, 0Ah, '$' 
	WRONG_ENV db 'Load error: wrong environment', 0Dh, 0Ah, '$'
	LOAD_OVL_SUCCESS db 'Load successful', 0Dh, 0Ah, '$'

	ALLOC_FILE_NOT_FOUND db 'Allocation error: file not found', 0Dh, 0Ah, '$'
    	ALLOC_ROUTE_NOT_FOUND db 'Allocation error: route not found', 0Dh, 0Ah, '$'
	ALLOC_SUCCESS db 'Allocation successful', 0Dh, 0Ah, '$'

	data_end db 0
	flag db 0

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

FREE_MEMORY PROC near
	push ax
	push bx
	push cx
	push dx

	mov ax, offset data_end
	mov bx, offset proc_end
	add bx, ax	
	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h
	jnc free_memory_success
	mov flag, 1 

mem_error_7:
	cmp ax, 7
	jne mem_error_8
	mov dx, offset MEM_CMB
	call PRINT_STRING
	jmp end_free_memory

mem_error_8:
	cmp ax, 8
	jne mem_error_9
	mov dx, offset MEM_NOT_ENOUGH
	call PRINT_STRING
	jmp end_free_memory

mem_error_9:
	cmp ax, 9
	mov dx, offset MEM_WRONG_ADDR
	call PRINT_STRING
	jmp end_free_memory

free_memory_success:
	mov dx, offset MEM_FREE_SUCCESS
	call PRINT_STRING

end_free_memory:
	pop dx
	pop cx
	pop bx
	pop ax
	ret

FREE_MEMORY ENDP


PATH_READ proc near
	push ax	
	push si
	push es
	push bx
	push di
	push dx

	mov ax, KEEP_PSP
	mov es, ax
	mov ax, es:[2Ch]
	mov es, ax
	xor si, si

find_two_zeros:
	inc si
	mov dl, es:[si-1]
	cmp dl, 0
	jne find_two_zeros
	mov dl, es:[si]
	cmp dl, 0
	jne find_two_zeros

	add si, 3
	mov bx, offset PATH

not_point:
	mov dl, es:[si]
	mov [bx], dl
	cmp dl, '.'
	je b_loop

	inc bx
	inc si

	jmp not_point

b_loop:
	mov dl, [bx]
	cmp dl, '\'
	je break
	mov dl, 0h
	mov [bx], dl
	dec bx
	jmp b_loop

break:
	pop dx
	mov di, dx
	push dx
	inc bx

new_file:
	mov dl, [di]
	cmp dl, 0
	je end_path_read
	mov [bx], dl
	inc di
	inc bx
	jmp new_file

end_path_read:
	mov [bx], byte ptr '$'
	pop dx
	pop di
	pop bx
	pop es
	pop si
	pop ax

	ret
PATH_READ endp


LOAD PROC near
	push ax
	push bx
	push cx
	push dx
	push ds
	push es

	mov ax, DATA
	mov es, ax
	mov bx, offset OVL_ADDR
	mov dx, offset PATH	
	mov ax, 4b03h 
	int 21h 	

	jnc load_success

load_error_1:	
	cmp ax, 1
	jne load_error_2
	mov dx, offset WRONG_FUNC_NUM
	call PRINT_STRING
	jmp end_load

load_error_2:
	cmp ax, 2
	jne load_error_3
	mov dx, offset FILE_NOT_FOUND
	call PRINT_STRING
	jmp end_load

load_error_3:
	cmp ax, 3
	jne load_error_4
	mov dx, offset ROUT_NOT_FOUND
	call PRINT_STRING
	jmp end_load

load_error_4:
	cmp ax, 4
	jne load_error_5
	mov dx, offset TOO_MUCH_FILES
	call PRINT_STRING
	jmp end_load

load_error_5:
	cmp ax, 5
	jne load_error_8
	mov dx, offset NO_ACCESS
	call PRINT_STRING
	jmp end_load

load_error_8:
	cmp ax, 8
	jne load_error_10
	mov dx, offset LOAD_MEM_ERROR
	call PRINT_STRING
	jmp end_load

load_error_10:
	cmp ax, 10
	mov dx, offset WRONG_ENV
	call PRINT_STRING
	jmp end_load

load_success:
	mov dx, offset LOAD_OVL_SUCCESS
	call PRINT_STRING

	mov ax, word ptr OVL_ADDR
	mov es, ax
	mov word ptr OVL_ADDR, 0
	mov word ptr OVL_ADDR+2, ax

	call OVL_ADDR
	mov es, ax
	mov ah, 49h
	int 21h	

end_load:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret

LOAD ENDP


ALLOCATION_MEM proc near

	push ax
	push bx
	push cx
	push dx

	push dx
	mov dx, offset DTA
	mov ah, 1ah
	int 21h
	pop dx
	xor cx, cx
	mov ah, 4eh
	int 21h

	jnc allocation_success
	cmp ax, 2
	je alloc_error_2
	cmp ax, 3
	je alloc_error_3

alloc_error_2:
	mov dx, offset ALLOC_FILE_NOT_FOUND
	call PRINT_STRING
	jmp end_allocation

alloc_error_3:
	mov dx, offset ALLOC_ROUTE_NOT_FOUND
	call PRINT_STRING
	jmp end_allocation

allocation_success:
	push di
	mov di, offset DTA
	mov bx, [di+1ah]
	mov ax, [di+1ch]
	pop di
	push cx
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	pop cx
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	mov word ptr OVL_ADDR, ax
	mov dx, offset ALLOC_SUCCESS
	call PRINT_STRING

end_allocation:
	pop dx
	pop cx
	pop bx
	pop ax
	ret

ALLOCATION_MEM ENDP


OVL_PROC proc near
	push dx
	call PATH_READ
	mov dx, offset PATH
	call ALLOCATION_MEM
	call LOAD
	pop dx

	ret
OVL_PROC ENDP


Main PROC FAR
	push ds
	push ax
	mov ax, DATA
	mov ds, ax

	mov KEEP_PSP, es
	call FREE_MEMORY
	cmp flag, 0
	jne final
	mov dx, offset FILE1
	call OVL_PROC
	mov dx, offset FILE2
	call OVL_PROC

final:
	mov ah, 4Ch
	int 21h
Main ENDP
proc_end:
CODE ENDS
END Main