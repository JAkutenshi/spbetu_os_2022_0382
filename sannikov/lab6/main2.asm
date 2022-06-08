AStack SEGMENT  STACK
          DW 128 DUP(?)
AStack ENDS
;-------------------------------
DATA SEGMENT
	PARAMETR_BLOCK dw 0 ;сегментный адрес среды
                       dd 0 ;сегмент и смещение командной строки
                       dd 0 ;сегмент и смещение FCB 
                       dd 0 ;сегмент и смещение второго FCB 

	FILE_NAME db 'lab2.com', 0	
	PATH_TMP db 128 DUP(0)
	FLAG db 0
	CMD db 1h, 0dh

	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_PSP DW 0

    	MEMORY_ERROR_7 db 'Control memory block is destroyed!', 0DH, 0AH, '$'
        MEMORY_ERROR_8 db 'Not enough memory for function!', 0DH, 0AH, '$'
        MEMORY_ERROR_9 db 'Invalid memory address!', 0DH, 0AH, '$'
        
	ERROR_1 db 'Function number not correct!', 0DH, 0AH, '$'
   	ERROR_2 db 'File not found!', 0DH, 0AH, '$'
   	ERROR_5 db 'Disk crash!', 0DH, 0AH, '$'
   	ERROR_8 db 'Low memory size!', 0DH, 0AH, '$'
   	ERROR_10 db 'Bad string enviroment!', 0DH, 0AH, '$'
   	ERROR_11 db 'Incorrect format!', 0DH, 0AH, '$'
   	
	AH_ERROR_0 db 'Normal execution:        ', 0DH, 0AH, '$'
   	AH_ERROR_1 db 'Crtl-Break execution!', 0DH, 0AH, '$'
   	AH_ERROR_2 db 'Device execution error!', 0DH, 0AH, '$'
   	AH_ERROR_3 db 'Resident error execution!', 0DH, 0AH, '$'
   	
   	NEW_STR db 0DH, 0AH, '$'
	DATA_END db 0
DATA ENDS
;-------------------------------
CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack
;-------------------------------
PRINT PROC
 	push ax
 	mov ah, 09h
 	int 21h 
 	pop ax
 	ret
PRINT ENDP
;-------------------------------
FREE_MEMORY PROC 
	push ax
	push bx
	push cx
	push dx
	mov ax, offset DATA_END
	mov bx, offset end_main
	add bx, ax	
	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h 
	jnc end_free
	mov FLAG, 1

error_7:
	cmp ax, 7
	jne _error_8
	mov dx, offset MEMORY_ERROR_7
	call PRINT
	jmp exit_free

_error_8:
	cmp ax, 8
	jne error_9
	mov dx, offset MEMORY_ERROR_8
	call PRINT
	jmp exit_free

error_9:
	cmp ax, 9
	mov dx, offset MEMORY_ERROR_9
	call PRINT
	jmp exit_free

end_free:
	mov flag, 1
	mov dx, offset NEW_STR
	call PRINT
	
exit_free:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEMORY ENDP
;-------------------------------
LOAD_FILE PROC
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	mov KEEP_SP, sp
	mov KEEP_SS, ss	
	mov ax, DATA
	mov es, ax
	mov bx, offset PARAMETR_BLOCK
	mov dx, offset CMD
	mov [bx+2], dx
	mov [bx+4], ds 
	mov dx, offset PATH_TMP	
	mov ax, 4b00h  
	int 21h 
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	pop es
	pop ds	
	jnc load_okey
	
	cmp ax, 1
	jne err_2

	mov dx, offset ERROR_1
	call PRINT

	jmp exit_load

err_2:
	cmp ax, 2
	jne err_5
	mov dx, offset ERROR_2
	call PRINT
	jmp exit_load

err_5:
	cmp ax, 5
	jne err_8
	mov dx, offset ERROR_5
	call PRINT
	jmp exit_load

err_8:
	cmp ax, 8
	jne err_10
	mov dx, offset ERROR_8
	call PRINT
	jmp exit_load

err_10:
	cmp ax, 10
	jne err_11
	mov dx, offset ERROR_10
	call PRINT
	jmp exit_load

err_11:
	cmp ax, 11
	mov dx, offset ERROR_11
	call PRINT
	jmp exit_load

load_okey:
	mov ah, 4dh
	mov al, 00h
	int 21h 
	cmp ah, 0
	jne ah_1
	push di 
	mov di, offset AH_ERROR_0
	mov [di+18], al 
	pop si
	mov dx, offset NEW_STR
	call PRINT
	mov dx, offset AH_ERROR_0
	call PRINT
	jmp exit_load

ah_1:
	cmp ah, 1
	jne ah_2
	mov dx, offset AH_ERROR_1
	call PRINT
	jmp exit_load

ah_2:
	cmp ah, 2 
	jne ah_3
	mov dx, offset AH_ERROR_2
	call PRINT
	jmp exit_load

ah_3:
	cmp ah, 3
	mov dx, offset AH_ERROR_3
	call PRINT

exit_load:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LOAD_FILE ENDP
;-------------------------------
PREPARE_PATH PROC 
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	mov ax, KEEP_PSP
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0
	
find_path:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne find_path
	cmp byte ptr es:[bx+1], 0 
	jne find_path	
	add bx, 2
	mov di, 0
	
find_loop:
	mov dl, es:[bx]
	mov byte ptr [PATH_TMP + di], dl
	inc di
	inc bx
	cmp dl, 0
	je end_find_loop
	cmp dl, '\'
	jne find_loop
	mov cx, di
	jmp find_loop

end_find_loop:
	mov di, cx
	mov si, 0
	
end_p:
	mov dl, byte ptr [FILE_NAME + si]
	mov byte ptr [PATH_TMP + di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne end_p	
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PREPARE_PATH ENDP
;-------------------------------
MAIN PROC far
	push ds
	xor ax, ax
	push ax
	mov ax, DATA
	mov ds, ax
	mov KEEP_PSP, es
	call FREE_MEMORY 
	cmp FLAG, 0
	je exit_main
	call PREPARE_PATH
	call LOAD_FILE
	
	exit_main:
		xor AL, AL
		mov AH, 4Ch
		int 21h
MAIN ENDP
end_main:
CODE ENDS
END MAIN 
