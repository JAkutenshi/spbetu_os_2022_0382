AStack SEGMENT STACK
 DW 32 DUP(?)
AStack ENDS

DATA SEGMENT
	PARAM dw 0 
          dd 0 
          dd 0  
          dd 0 
               
	file_name db 'lb2.COM', 0
	cmd db 1h, 0dh
	file_path db 128 DUP (?)
   
	memory_destroied_msg db 'The control memory block is destroyed', 0DH, 0AH,'$'
	not_enough_msg db 'Not enough memory to execute the function', 0DH, 0AH,'$'
	inv_address_msg db 'Invalid memory block address', 0DH, 0AH,'$'
	success_mem_msg db 'Success free memory', 0DH, 0AH,'$'
	free_mem_flag db 0
   
   	invalid_function_msg db 'Invalid function number', 0DH, 0AH,'$'
   	file_not_found_msg db 'File not found', 0DH, 0AH,'$'
   	disk_error_msg db 'Disk error', 0DH, 0AH,'$'
   	not_enough_load_msg db 'Not enough memory', 0DH, 0AH,'$'
   	invalid_env_string_msg db 'Incorrect environment string', 0DH, 0AH,'$'
   	incorrect_format_msg db 'Incorrect format', 0DH, 0AH,'$'
   
   	success_end db 0DH, 0AH,'Programm ended with code =    ', 0DH, 0AH,'$'

   	ctrl_c_end db 'Programm ended ctrl-break', 0DH, 0AH,'$'
   	device_end db 'Programm ended device error', 0DH, 0AH,'$'
   	int31_end db 'Programm ended int 31h', 0DH, 0AH,'$'
   
  	keep_ss dw 0
  	keep_sp dw 0
	keep_psp dw 0
   
	END_DATA db 0
DATA ENDS

TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:DATA, SS:AStack

; ПРОЦЕДУРЫ
;----------------------
print PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
print ENDP
;----------------------
memory_alloc proc near
	push ax
	push bx

   	xor dx, dx
    mov ax, offset end_data
    mov bx, offset end_programm
    add ax, bx
    mov bx, 16
    div bx
    add ax, 50h
    mov bx, ax
    and ax, 0

    mov ah, 4ah
    int 21h 

    pop bx
    pop ax
    ret
memory_alloc endp
;----------------------
FREE_MEM PROC near
	push dx
	push ax
   
   	call memory_alloc

	jnc success_free
	
	cmp ax, 7
	je mem_destr
	
	cmp ax, 8
	je not_enough

	cmp ax, 9
	je inv_addr

	mem_destr:
		mov dx, offset memory_destroied_msg
		jmp finish_proc

	not_enough:
		mov dx, offset not_enough_msg
		jmp finish_proc

	inv_addr:
		mov dx, offset inv_address_msg
		jmp finish_proc

	success_free:
		mov dx, offset success_mem_msg
		mov free_mem_flag, 1

	finish_proc:
		call print
		pop dx
		pop ax
   	ret
FREE_MEM ENDP
;-----------------------------------
handle_errors proc near
	; bl:
	; 1 - some errors were detected
	; 0 - no errors
	; dx - message
	push ax
	

	jnc finish_handle
	mov bl, 1

	cmp ax, 1
	je inv_func_msg

	cmp ax, 2
	je not_found

	cmp ax, 5
	je disk_error

	cmp ax, 8
	je not_enough_mem

	cmp ax, 10
	je env_error

	cmp ax, 11
	je not_correct_format


inv_func_msg:
	lea dx, invalid_function_msg
	jmp finish_handle

not_found:
	lea dx, file_not_found_msg
	jmp finish_handle

disk_error:
	lea dx, disk_error_msg
	jmp finish_handle

not_enough_mem:
	lea dx, not_enough_load_msg
	jmp finish_handle

env_error:
	lea dx, invalid_env_string_msg
	jmp finish_handle

not_correct_format:
	mov dx, offset incorrect_format_msg
	jmp finish_handle

finish_handle:
	pop ax
	ret
handle_errors endp
;-----------------------------------
load proc near
	push ax
	push bx
	push cx
	push dx
	push ds
	push es

	mov keep_sp, sp
	mov ax, ss
	mov keep_ss, ax

	; load program
	mov ax, DATA
	mov es, ax
	mov bx, offset PARAM
	mov dx, offset cmd
	mov [bx+2], dx
	mov [bx+4], ds
	mov dx, offset file_path
	xor bx, bx
	mov ax, 4B00h
	int 21h

	; restore registers
	mov ss, keep_ss
	mov sp, keep_sp
	pop es
	pop ds

	call handle_errors
	cmp bl, 0
	jne load_print

success_load:
	mov ax, 4D00h
	int 21h

	cmp ah, 0
	jne ctrlc
	push di
	lea di, success_end
	mov [di+30], al
	pop si
	lea dx, success_end
	jmp load_print
ctrlc:
	cmp ah, 1
	jne device
	lea dx, ctrl_c_end
	jmp load_print
device:
	cmp ah, 2
	jne int_31h
	lea dx, device_end
	jmp load_print
int_31h:
	cmp ah, 3
	lea dx, int31_end

load_print:
	call print

end_load:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
load ENDP
;-----------------------------------
path proc near
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	mov ax, keep_psp
	mov es, ax
	mov es, es:[2Ch]
	mov bx, 0

find_zero:
	mov al, es:[bx]
	inc bx
	cmp byte ptr es:[bx], 0
	je second_zero
	jmp find_zero

	second_zero:
		cmp al, 0
		je skip_0_1
	jmp find_zero

skip_0_1:
	add BX, 3
	mov DI, 0

path_loop:
	mov dl, es:[bx]
	mov byte ptr [file_path+di], dl
	inc di
	inc bx
	cmp dl, 0
	je path_end_loop
	cmp dl, '\'
	jne path_loop
	mov cx, di
	jmp path_loop
path_end_loop:
	mov di, cx
	mov si, 0

_file_name:
	mov dl, byte ptr [file_name+si]
	mov byte ptr [file_path+di], dl
	inc di
	inc si
	cmp dl, 0
	jne _file_name

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
path ENDP
;-----------------------------------
main proc far
	mov ax, data
	mov ds, ax
	mov keep_psp, es

	call free_mem

	cmp FREE_MEM_FLAG, 0
	je main_end
	call path
	call load
; Выход в DOS
main_end:
	xor AL, AL
	mov AH, 4Ch
	int 21h
MAIN ENDP
end_programm:
TESTPC ENDS
END MAIN 



