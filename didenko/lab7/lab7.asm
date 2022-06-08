AStack    SEGMENT  STACK
    DW 64 DUP(?)   
AStack    ENDS

DATA  SEGMENT

	STR_OVL1_NAME db 'OVL1.OVL$'
	STR_OVL2_NAME db 'OVL2.OVL$'
	STR_PATCH_NAME db 50 dup (0)
   
	LAUNCH_PARAMETERS dw 0,0
	LAUNCH_ADDRESS dd 0
   
	DTA db 43 dup(0)
	STR_ERROR_FREE_MEMORY db 'Error free memory',13,10,'$'
	STR_ERROR_1 db 'Function does not exist', 13,10,'$'
	STR_ERROR_2 db 'File not found',13,10,'$'
	STR_ERROR_3 db 'Route not found',13,10,'$'
	STR_ERROR_4 db 'Too many files were opened',13,10,'$'
	STR_ERROR_5 db 'No access',13,10,'$'
	
	STR_MEMORY_7 db 'Сontrol memory block destroyed',13,10,'$'
	STR_MEMORY_8 db 'Low memory size for function',13,10,'$'
	STR_MEMORY_9 db 'Invalid memory address',13,10,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack

WRITE_STRING PROC near
	push AX
	mov AH,09h
	int 21h
	pop AX
	ret
WRITE_STRING ENDP

FREE_MEMORY PROC
	push ax
	push bx
   
	lea bx, m_end_program
	mov ax,es
	sub bx,ax
	mov ax,bx
	shr bx,4
	inc bx
	mov ah,4ah
	int 21h
	jnc m_end_memory
	
	lea dx, STR_MEMORY_7
	cmp ax,7
	je m_memory_write
	lea dx, STR_MEMORY_8
	cmp ax,7
	je m_memory_write
	lea dx,STR_MEMORY_9
	cmp ax,7
	je m_memory_write
	jmp m_end_memory
   
m_memory_write:
	call WRITE_STRING
	jmp m_end_error_memory
   
m_end_memory:   
	pop bx
	pop ax
	ret
   
m_end_error_memory:
	pop bx
	mov AH,4Ch
	int 21H
FREE_MEMORY ENDP


SET_FULL_FILE_NAME PROC NEAR
   push dx
   push di
   push si
   push es
   
   xor di,di
   mov es,es:[2ch]
   
m_skip_content:
   mov dl,es:[di]
   cmp dl,0h
   je m_last_content
   inc di
   jmp m_skip_content
      
m_last_content:
   inc di
   mov dl,es:[di]
   cmp dl,0h
   jne m_skip_content
   
   add di,3h
   mov si,0
   
m_write_patch:
   mov dl,es:[di]
   cmp dl,0h
   je m_delete_file_name
   mov STR_PATCH_NAME[si],dl
   inc di
   inc si
   jmp m_write_patch

m_delete_file_name:
   dec si
   cmp STR_PATCH_NAME[si],'\'
   je m_ready_add_file_name
   jmp m_delete_file_name
   
m_ready_add_file_name:
   mov di,-1

m_add_file_name:
   inc si
   inc di
   mov dl,bx[di]
   cmp dl,'$'
   je m_set_patch_end
   mov STR_PATCH_NAME[si],dl
   jmp m_add_file_name
   
m_set_patch_end:
   mov STR_PATCH_NAME[si],'$'
   pop es
   pop si
   pop di
   pop dx
   ret
SET_FULL_FILE_NAME ENDP


GET_OVERLAY_SIZE PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push bp
	
	;буфер под оверлей в 43 байта
	mov ah,1Ah
	lea dx,DTA
    int 21h
	; определение размера требуемой памяти
	mov ah,4Eh
    lea dx, STR_PATCH_NAME
	mov cx,0
	int 21h
	jnc m_memory_allocation
	
	lea dx,STR_ERROR_2
	cmp ax,2
	je m_write_error_overlay_size
	lea dx,STR_ERROR_3
	cmp ax,3
	je m_write_error_overlay_size
	
m_write_error_overlay_size:
	call WRITE_STRING
	jmp m_end_get_overlay_size

m_memory_allocation:

mov si, offset DTA
	add si, 1Ah
	mov bx, [si]	
	shr bx, 4 
	mov ax, [si+2]	
	shl ax, 12
	add bx, ax
	add bx, 2
    mov ah,48h
    int 21h
    jnc m_save_seg
    lea dx,STR_ERROR_FREE_MEMORY
    call WRITE_STRING
    jmp m_end_get_overlay_size

m_save_seg:
    mov LAUNCH_PARAMETERS,ax
    mov LAUNCH_PARAMETERS+2,ax

m_end_get_overlay_size:	
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
GET_OVERLAY_SIZE ENDP

LOAD_OVERLAY PROC NEAR
	push ax
	push dx
	push es
	
	lea dx,STR_PATCH_NAME
	push ds
	pop es
	lea bx, LAUNCH_PARAMETERS
	mov ax,4B03h            
    int 21h
	jnc m_success_load
	
	lea dx, STR_ERROR_1
	cmp ax,1
	je m_write_error_load_overlay
	lea dx, STR_ERROR_2
	cmp ax,2
	je m_write_error_load_overlay
	lea dx, STR_ERROR_3
	cmp ax,3
	je m_write_error_load_overlay
	lea dx, STR_ERROR_4
	cmp ax,4
	je m_write_error_load_overlay
	lea dx, STR_ERROR_5
	cmp ax,5
	je m_write_error_load_overlay
	lea dx, STR_MEMORY_8
	cmp ax,8
	je m_write_error_load_overlay
	
m_write_error_load_overlay:
	call WRITE_STRING
	jmp m_end_overlay
	
m_success_load:
	mov ax,LAUNCH_PARAMETERS
    mov word ptr LAUNCH_ADDRESS + 2, ax
    call LAUNCH_ADDRESS
    mov es,ax
	mov ah, 49h
	int 21h
	
m_end_overlay:
	pop es
	pop dx
	pop ax
	ret
LOAD_OVERLAY ENDP

MACRO_CREATE_FULL_FILE_NAME MACRO OVERLAY_NAME
   	push bx
	lea bx,OVERLAY_NAME
   	call SET_FULL_FILE_NAME
   	pop bx
ENDM

MACRO_LOAD_OVERLAY MACRO OVERLAY_NAME
	push dx
	MACRO_CREATE_FULL_FILE_NAME OVERLAY_NAME
	lea dx, STR_PATCH_NAME
	call WRITE_STRING
	call NEW_LINE
	call GET_OVERLAY_SIZE
	call LOAD_OVERLAY
	call NEW_LINE
	pop dx
ENDM


NEW_LINE PROC NEAR
   push dx
   push ax
   
   mov dl,10
   mov ah,02h
   int 21h
   mov dl,13
   mov ah,02h
   int 21h  
   
   pop ax
   pop dx
   ret
NEW_LINE ENDP

Main PROC FAR
	sub   AX,AX
	push  AX
	mov   AX,DATA
	mov   DS,AX
   
	call FREE_MEMORY
	call NEW_LINE
	MACRO_LOAD_OVERLAY STR_OVL1_NAME
	MACRO_LOAD_OVERLAY STR_OVL2_NAME
   
	xor AL,AL
	mov AH,4Ch
	int 21H
Main ENDP
m_end_program:
CODE ENDS
      END Main