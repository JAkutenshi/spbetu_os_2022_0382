AStack   SEGMENT STACK
        DB 256 dup (?)
AStack   ENDS


DATA SEGMENT
	keep_psp dw 0
	keep_ss dw 0
  	keep_sp dw 0
	
	mes_mem_destroy db 'The CMB is destroyed', 0DH, 0AH,'$'
	mes_insuff_mem db 'Insufficient memory to perform functions', 0DH, 0AH,'$'
	mes_incorrect_addr db 'Incorrect memory block address', 0DH, 0AH,'$'
	mes_success_malloc db 'Success free memory', 0DH, 0AH,'$'
	
	PARAM_BLOCK   dw 0 ;сегментный адрес среды
    cmd_off       dw 0 ;смещение командной строки
    cmd_seg       dw 0 ;сегмент командной строки
	fcb1		  dd 0 ;сегмент и смещение FCB 
    fcb2          dd 0 ;сегмент и смещение FCB 
				  
	cmd_line db 8,'parm str'			 
	file_name db 'LB2.COM', 0
	file_path db 128 DUP (?)
	
	mes_inv_numb_func db 'Invalid number function ', 0DH, 0AH,'$'
   	mes_not_found_file db 'File not found', 0DH, 0AH,'$'
   	mes_disk_error db 'Disk error', 0DH, 0AH,'$'
   	mes_insuff_mem_load db 'Insufficient memory for loading program', 0DH, 0AH,'$'
   	mes_inv_env db 'Incorrect environment string', 0DH, 0AH,'$'
   	mes_inv_format db 'Incorrect format', 0DH, 0AH,'$'
	
	mes_exit_ctrl_break db 'Programm ended ctrl-break', 0DH, 0AH,'$'
   	mes_exit_device_error db 'Programm ended device error', 0DH, 0AH,'$'
   	mes_exit_31h db 'Programm ended int 31h', 0DH, 0AH,'$'
	mes_code_end db 'Programm normal ended with code =    ', 0DH, 0AH,'$'
	
	my_enter db 0DH,0AH,'$'
	
	end_seg_data db 0
DATA ENDS


CODE   SEGMENT
ASSUME  CS:CODE, DS:DATA, SS:AStack

PRINT_MES MACRO mes
	push ax
	push dx
	
    mov DX, offset mes
    mov AH, 09h
    int 21h
	
	pop dx
	pop ax
ENDM

PRINT_MES_DX MACRO 
	push ax

    mov AH, 09h
    int 21h
	
	pop ax
ENDM

;----------------------Malloc-------------------------
Malloc proc near
	push ax
	push bx
	push dx

   	xor dx, dx
    mov ax, offset end_seg_data
    mov bx, offset end_seg_code
    add ax, bx
    mov bx, 16
    div bx
    add ax, 50h
    mov bx, ax
    and ax, 0

    mov ah, 4ah
    int 21h 

	pop dx
    pop bx
    pop ax
    ret
Malloc endp


;----------------------Free_mem-------------------------
Free_mem PROC near
	; В резудьтате: 
	; Если СF = 0, освобождение памяти получилось
	; Если СF = 1, то не получилось освободить память и 
	;			   выводится сообщение о причине
	
	push dx
	push ax
   
   	call Malloc

	jnc success_malloc ; Если СF = 0 прыгает
	
	cmp ax, 7
	je mem_destroy
	
	cmp ax, 8
	je insuff_mem

	cmp ax, 9
	je incorrect_addr

	mem_destroy:
		mov dx, offset mes_mem_destroy
		jmp end_free_mem

	insuff_mem:
		mov dx, offset mes_insuff_mem
		jmp end_free_mem

	incorrect_addr:
		mov dx, offset mes_incorrect_addr
		jmp end_free_mem

	success_malloc:
		mov dx, offset mes_success_malloc

end_free_mem:
	PRINT_MES_DX
	PRINT_MES my_enter
	pop dx
	pop ax
   	ret
Free_mem ENDP


;----------------------Set_param_block-------------------------
Set_param_block PROC near
	push bx
	
	mov bx, offset cmd_line
	mov cmd_off, bx
	mov cmd_seg, ds
	
	pop bx
	ret
Set_param_block ENDP


;----------------------Set_file_path-------------------------
Set_file_path PROC near
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es
	
	;записываем в es адрес среды
	mov ax, keep_psp
	mov es, ax
	mov es, es:[2Ch]
	
	mov bx, 0 ; смещение es - среды

; ищем два 0, после них в среде идет путь 
find_double_zero:
	mov al, es:[bx]
	inc bx
	cmp byte ptr es:[bx], 0
	je check_prev_zero
	jmp find_double_zero

	check_prev_zero:
		cmp al, 0
		je skip_trash
		jmp find_double_zero

skip_trash:
	add BX, 3
	
	mov DI, 0 ; смещение file_path
	; CX - индекс последнего '\'  в file_path

; записываем путь в file_path
path_write:
	mov dl, es:[bx]
	mov byte ptr [file_path+di], dl
	inc di
	inc bx
	
	cmp dl, 0 ;дошли до конца
	je path_end
	
	cmp dl, '\' ; встретили '\'
	jne path_write
		mov cx, di  ; если dl = '\' сохраняем di в cx
		jmp path_write
path_end:

	mov di, cx ; CX - индекс последнего '\'  в file_path
	mov si, 0  ; смещение file_name

write_file_name:
	mov dl, byte ptr [file_name+si]
	mov byte ptr [file_path+di], dl
	inc di
	inc si
	cmp dl, 0
	jne write_file_name

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
Set_file_path ENDP


;----------------------Load_prog-------------------------
Load_prog PROC near
	push ds
	push es
   
	mov keep_sp,sp
	mov keep_ss,ss
	
	; ES:BX -> PARAM_BLOCK, DS:DX -> file_path
	mov ax,ds
	mov es,ax
	mov dx, offset file_path
	mov bx, offset PARAM_BLOCK
	
	mov ax,4B00h
	int 21h
	
	mov ss,KEEP_SS
	mov sp,KEEP_SP
   
	pop es
	pop ds 
	
	
	jnc j_handle_exit
		call Handle_errors
		jmp end_load
		
	j_handle_exit:
		PRINT_MES my_enter
		call Handle_exit

end_load:
	ret
Load_prog ENDP


;----------------------Handle_errors-------------------------
Handle_errors PROC near
	push dx
	
	cmp ax, 1
	je inv_numb_func

	cmp ax, 2
	je not_found

	cmp ax, 5
	je disk_error

	cmp ax, 8
	je insuff_mem_load

	cmp ax, 10
	je inv_env

	cmp ax, 11
	je inv_format


inv_numb_func:
	mov dx, offset mes_inv_numb_func
	jmp end_handle_er

not_found:
	mov dx, offset mes_not_found_file
	jmp end_handle_er

disk_error:
	mov dx, offset mes_disk_error
	jmp end_handle_er
	
insuff_mem_load:
	mov dx, offset mes_insuff_mem_load
	jmp end_handle_er

inv_env:
	mov dx, offset mes_inv_env
	jmp end_handle_er

inv_format:
	mov dx, offset mes_inv_format
	jmp end_handle_er


end_handle_er:
	PRINT_MES_DX
	pop dx
	ret
Handle_errors ENDP


;----------------------Handle_exit-------------------------
Handle_exit PROC near
	push dx
	push ax
	push di
	
	mov ah, 4Dh
	int 21h
	
	cmp ah, 0
	je normal_exit

	cmp ah, 1
	je ctrl_break

	cmp ax, 2
	je device_error

	cmp ax, 3
	je exit_31h


ctrl_break:
	mov dx, offset mes_exit_ctrl_break
	jmp end_handle_exit

device_error:
	mov dx, offset mes_exit_device_error
	jmp end_handle_exit
	
exit_31h:
	mov dx, offset mes_exit_31h
	jmp end_handle_exit

normal_exit:
	mov di, offset mes_code_end
	mov [di+34], al
	mov dx, di
	jmp end_handle_exit


end_handle_exit:
	PRINT_MES_DX
	pop di
	pop ax
	pop dx
	ret
Handle_exit ENDP


;=======================Main=============================	
Main proc far 
	push  DS       ;\  Сохранение адреса начала PSP в стеке
    sub   AX,AX    ; > для последующего восстановления по
    push  AX       ;/  команде ret, завершающей процедуру.
    mov   AX,DATA             ; Загрузка сегментного
    mov   DS,AX               ; регистра данных. 
	mov keep_psp, es
	
	call Free_mem
	jc end_main ; Если CF = 1, то выделение памяти не удалось
	
	call Set_param_block
	call Set_file_path
	call Load_prog
	
end_main:
	xor ax, ax
	mov ah, 4Ch
	int 21h
Main endp

end_seg_code:
CODE ends
	end Main