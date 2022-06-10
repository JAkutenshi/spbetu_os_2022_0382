AStack    SEGMENT  STACK
    DW 64 DUP(?)   
AStack    ENDS

DATA  SEGMENT
	NAME_OVL1 db 'OVL1.OVL$'
	NAME_OVL2 db 'OVL2.OVL$'
	PATH db 50 dup (0)
	LAUNCHING_SETTINGS dw 0,0
	ADDRESS_LAUNCH dd 0
	DTA db 43 dup(0)
	ERROR_FREEMEM db 'Memory release error',13,10,'$'
	ERROR_DF db 'Defunct function', 13,10,'$'
	ERROR_WF db 'File not found',13,10,'$'
	ERROR_WR db 'Route not found',13,10,'$'
	ERROR_MF db 'Too many files open',13,10,'$'
	ERROR_NOT db 'Not available',13,10,'$'
	CNTRL_MEMORY_BL db 'Breakdown Сontrol memory block',13,10,'$'
	NO_MEMORY db 'Not enough free memory',13,10,'$'
	WRONG_MEMORY db 'Wrong memory address',13,10,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack

PRINT PROC
	push AX
	mov AH,09h
	int 21h
	pop AX
	ret
PRINT ENDP

FREEMEM PROC
	push ax
	push bx
	lea bx, end_program
	mov ax,es
	sub bx,ax
	mov ax,bx
	shr bx,4
	inc bx
	mov ah,4ah
	int 21h
	jnc end_memory
	lea dx, CNTRL_MEMORY_BL
	cmp ax,7
	je memory_write
	lea dx, NO_MEMORY
	cmp ax,7
	je memory_write
	lea dx,WRONG_MEMORY
	cmp ax,7
	je memory_write
	jmp end_memory
   
memory_write:
	call PRINT
	jmp end_error_memory
   
end_memory:   
	pop bx
	pop ax
	ret
   
end_error_memory:
	pop bx
	mov AH,4Ch
	int 21H
FREEMEM ENDP


SET_FULL_FILE_NAME PROC NEAR
   push dx
   push di
   push si
   push es
   
   xor di,di
   mov es,es:[2ch]
   
skip_content:
   mov dl,es:[di]
   cmp dl,0h
   je last_content
   inc di
   jmp skip_content
      
last_content:
   inc di
   mov dl,es:[di]
   cmp dl,0h
   jne skip_content
   add di,3h
   mov si,0
   
write_patch:
   mov dl,es:[di]
   cmp dl,0h
   je delete_file_name
   mov PATCH[si],dl
   inc di
   inc si
   jmp write_patch

delete_file_name:
   dec si
   cmp PATCH[si],'\'
   je ready_add_file_name
   jmp delete_file_name
   
ready_add_file_name:
   mov di,-1

add_file_name:
   inc si
   inc di
   mov dl,bx[di]
   cmp dl,'$'
   je set_patch_end
   mov PATCH[si],dl
   jmp add_file_name
   
set_patch_end:
   mov PATCH[si],'$'
   pop es
   pop si
   pop di
   pop dx
   ret
SET_FULL_FILE_NAME ENDP

OVL_SIZE PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push bp
	mov ah,1Ah
	lea dx,DTA
    int 21h
	mov ah,4Eh
    lea dx, PATCH
	mov cx,0
	int 21h
	jnc memory_allocation
	lea dx,ERROR_WF
	cmp ax,2
	je write_error_overlay_size
	lea dx,ERROR_WR
	cmp ax,3
	je write_error_overlay_size
	
write_error_overlay_size:
	call PRINT
	jmp end_get_overlay_size

memory_allocation:
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
    jnc save_seg
    lea dx,ERROR_FREEMEM
    call PRINT
    jmp end_get_overlay_size

save_seg:
    mov LAUNCHING_SETTINGS,ax
    mov LAUNCHING_SETTINGS+2,ax

end_get_overlay_size:	
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
OVL_SIZE ENDP

LOAD_OVERLAY PROC NEAR
	push ax
	push dx
	push es
	lea dx,PATCH
	push ds
	pop es
	lea bx, LAUNCHING_SETTINGS
	mov ax,4B03h            
    int 21h
	jnc success_load
	lea dx, ERROR_DF
	cmp ax,1
	je write_error_load_overlay
	lea dx, ERROR_WF
	cmp ax,2
	je write_error_load_overlay
	lea dx, ERROR_WR
	cmp ax,3
	je write_error_load_overlay
	lea dx, ERROR_MF
	cmp ax,4
	je write_error_load_overlay
	lea dx, ERROR_NOT
	cmp ax,5
	je write_error_load_overlay
	lea dx, NO_MEMORY
	cmp ax,8
	je write_error_load_overlay
	
write_error_load_overlay:
	call PRINT
	jmp end_overlay
	
success_load:
	mov ax,LAUNCHING_SETTINGS
    mov word ptr ADDRESS_LAUNCH + 2, ax
    call ADDRESS_LAUNCH
    mov es,ax
	mov ah, 49h
	int 21h
	
end_overlay:
	pop es
	pop dx
	pop ax
	ret
LOAD_OVERLAY ENDP

MAKE_FILE_NAME MACRO OVERLAY_NAME
   	push bx
	lea bx,OVERLAY_NAME
   	call SET_FULL_FILE_NAME
   	pop bx
ENDM

OVL_LOADING MACRO OVERLAY_NAME
	push dx
	MAKE_FILE_NAME OVERLAY_NAME
	lea dx, PATCH
	call PRINT
	call LINE
	call OVL_SIZE
	call LOAD_OVERLAY
	call LINE
	pop dx
ENDM 


LINE PROC
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
LINE ENDP

Main PROC FAR
	sub   AX,AX
	push  AX
	mov   AX,DATA
	mov   DS,AX
	call FREEMEM
	call LINE
	OVL_LOADING NAME_OVL1
	OVL_LOADING NAME_OVL2
	xor AL,AL
	mov AH,4Ch
	int 21H
Main ENDP
end_program:
CODE ENDS
      END Main 