stack segment  stack
	dw 128 dup(?)   
stack ends


data segment 

   	ovl_1_name db 'over_1.ovl', 0 
   	ovl_2_name db 'over_2.ovl', 0
	
   	curent_f_name dw 0
   	dta db 43 dup(0)
   	full_p db 128 dup(0) 
	
   	param dd 0          
   	keep_psp dw 0
	
	
	; message 4ah   free mem
	mem_free_mes db 					'[4ah]: memory was successfully free ' , 0dh, 0ah, '$'
    mcb_crash_mes db 					'[4ah]: mcb was crashed.', 0dh, 0ah, '$' 
	no_memory_mes db 					'[4ah]: not enough memory', 0dh, 0ah, '$' 
	ivalid_address_mes db 				'[4ah]: invalid memory addressess', 0dh, 0ah, '$'
    
	;load message
   	load_1_mes db 						'load 1 overlay :', 13, 10, '$'
   	load_2_mes db 						'load 2 overlay :', 13, 10, '$'
	
	; message 4b03h
   	err_1_mes db 						'[4b03h]: wrong function', 13, 10, '$'
   	err_2_mes db 						'[4b03h]: file not found', 13, 10, '$'
   	err_3_mes db 						'[4b03h]: path not found', 13, 10, '$'
   	err_4_mes db 						'[4b03h]: too many open files', 13, 10, '$'
   	err_5_mes db 						'[4b03h]: disk error', 13, 10, '$'
   	err_8_mes db						'[4b03h]: not enough memory to load programm', 13, 10, '$'
   	err_10_mes db						'[4b03h]: error environment', 13, 10, '$'
   	err_11_mes db 						'[4b03h]: error format', 13, 10, '$'   

   	alloc_success_mes db 				'memory allocated successfully', 13, 10, '$'
   	file_err_mes db 					'file not found', 13, 10, '$'
   	route_err_mes db 					'route not found', 13, 10, '$'
	
	endl_s db 							 0dh,0ah,'$'
	
   	data_end db 0
data ends

code segment
	assume cs:code,ds:data,ss:stack

print proc
   	push ax
   	mov ah, 09h
   	int 21h
   	pop ax
   	ret
print endp


free_memory proc  near
	push ax
	push bx
	push cx
	push dx
		
	mov bx, offset end_address
	mov ax, es
	sub bx, ax
	mov cl, 4
	shr bx, cl       ; byte to par
	mov ah, 4ah 
	int 21h
	
	
	jnc end_proc

	cmp ax, 7
	je error_crash
	
	cmp ax, 8
	je error_no_memory
	
	cmp ax, 9
	je error_address
	
error_crash:
	mov dx, offset mcb_crash_mes
	call print
	jmp ret_p

error_no_memory:
	mov dx, offset no_memory_mes
	call print
	jmp ret_p

error_address:
	mov dx, offset ivalid_address_mes
	call print
	jmp ret_p

end_proc:
	mov dx, offset endl_s
	call print
	mov dx, offset mem_free_mes
	call print
	
ret_p:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
free_memory endp




str_plus_str proc near
push dx

add_loop:  ;si - source   di - dest  
						
	mov dl, byte ptr [si]
	mov byte ptr [di], dl
	inc di 
	inc si
	cmp dl, 0 
	
	jne add_loop	

pop dx
	ret
str_plus_str endp




set_full_name proc near
   	push ax
   	push bx
   	push cx
   	push dx
   	push di
   	push si
   	push es
	
   	mov curent_f_name, dx   
   	mov ax, keep_psp
   	mov es, ax
   	mov es, es:[2ch]
   	mov bx, 0
   
skip_env:                      ;skip_env
	cmp byte ptr es:[bx], 0
	je separator_word
	inc bx
	jmp skip_env	
separator_word:
	inc bx
	
	cmp byte ptr es:[bx], 0 
	je  read_p
	
	inc bx
	jmp skip_env
	 
read_p:
	add bx, 3
	mov di, 0
read_loop:

	mov dl, es:[bx]
	mov byte ptr [full_p + di], dl
	inc di
	inc bx
	cmp dl, 0
	je create_full_name
	cmp dl, '\'
	jne read_loop
	mov cx, di
	jmp read_loop

create_full_name:
	mov si, curent_f_name
	mov di , offset full_p
	add di, cx
	call str_plus_str
	
   	pop es
   	pop si
   	pop di
   	pop dx
   	pop cx
   	pop bx
   	pop ax
   	ret

set_full_name endp






alloc proc
  	push ax
   	push bx
   	push cx
   	push dx
   	push dx
	
   	mov dx, offset dta
   	mov ah, 1ah
   	int 21h
   	pop dx
   	mov cx, 0
   	mov ah, 4eh
   	int 21h

   	jnc success_alloc
	
   	cmp ax, 2
   	je path_not_found
	
file_not_found:	
   	mov dx, offset file_err_mes
   	call print
   	jmp end_alloc
	
path_not_found:
   	mov dx, offset route_err_mes
   	call print
   	jmp end_alloc

success_alloc:
   	push di
   	push cx
	
   	mov di, offset dta
  	mov bx, [di + 1ah]
   	mov ax, [di + 1ch]
  
   	mov cl, 4
   	shr bx, cl
   	mov cl, 12
   	shl ax, cl
	
   	add bx, ax
   	add bx, 1
	
   	pop cx
	pop di
	
   	mov ah, 48h
   	int 21h
	
   	mov word ptr param, ax
   	mov dx, offset alloc_success_mes
   	call print
end_alloc:
   	pop dx
   	pop cx
   	pop bx
   	pop ax
   	ret
alloc endp







load_over proc near
   	push ax
   	push bx
   	push cx
   	push dx
   	push ds
   	push es  
   	mov ax, data
   	mov es, ax
   	mov bx, offset param
   	mov dx, offset full_p
   	mov ax, 4b03h
   	int 21h    
   	jnc transition

	cmp ax, 1
	je error_1
	cmp ax, 2
	je error_2
	cmp ax, 3
	je error_3
	cmp ax, 4
	je error_4
	cmp ax, 5
	je error_5
	cmp ax, 8
	je error_8
	cmp ax, 10
	je error_10
	cmp ax, 11
	je error_11
	
error_1:
   	mov dx, offset err_1_mes
   	call print
   	jmp load_over_end

error_2:
   	mov dx, offset err_2_mes
   	call print
   	jmp load_over_end
	
error_3:
   	mov dx, offset err_1_mes
   	call print
   	jmp load_over_end

error_4:
   	mov dx, offset err_2_mes
   	call print
   	jmp load_over_end
	
error_5:
   	mov dx, offset err_5_mes
   	call print
   	jmp load_over_end

error_8:
   	mov dx, offset err_8_mes
   	call print
   	jmp load_over_end

error_10:
   	mov dx, offset err_10_mes
   	call print
   	jmp load_over_end

error_11:
   	mov dx, offset err_11_mes
   	call print
   	jmp load_over_end

transition:

   	mov ax, word ptr param
   	mov es, ax
	
   	mov word ptr param, 0
   	mov word ptr param + 2, ax
	
   	call param
	
   	mov es, ax
   	mov ah, 49h
   	int 21h

load_over_end:
   	pop es
   	pop ds
   	pop dx
   	pop cx
   	pop bx
   	pop ax
   	ret
load_over endp









main proc far
   	push ds
   	xor ax, ax
   	push ax
   	mov ax, data
   	mov ds, ax
   	mov keep_psp, es
   	call free_memory
	
f1:	
	mov dx, offset load_1_mes
	call print
   	mov dx, offset ovl_1_name
   	push dx
   	call set_full_name
   	mov dx, offset full_p
   	call alloc
   	call load_over
   	pop dx
	
   	mov dx, offset endl_s
   	call print

f2:	
	mov dx, offset load_2_mes
	call print
   	mov dx, offset ovl_2_name
   	push dx
   	call set_full_name
   	mov dx, offset full_p
   	call alloc
   	call load_over
   	pop dx
   
   	xor al,al
   	mov ah,4ch
   	int 21h

main endp
end_address:
code ends
end main