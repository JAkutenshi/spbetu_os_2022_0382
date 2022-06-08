AStack   SEGMENT STACK
        DB 256 dup (?)
AStack   ENDS


DATA SEGMENT
	keep_psp dw 0
	
	;сообщ. об ошибках освобождения памяти
	mes_mem_destroy db '[Error] The CMB is destroyed', 0DH, 0AH,'$'
	mes_insuff_mem db '[Error] Insufficient memory to perform functions', 0DH, 0AH,'$'
	mes_incorrect_addr db '[Error] Incorrect memory block address', 0DH, 0AH,'$'
		
	;сообщ. об ошибках определения размера файла оверлея 
	mes_not_found_file db '[Error] File ovl not found', 0DH, 0AH,'$'
	mes_not_found_route db '[Error] Route ovl not found',13,10,'$'
	
	;сообщ. об ошибках при запросе памяти для ovl
	mes_error_inter_48 db '[Error] Memory ovl request error',13,10,'$'
	
	;сообщ. об ошибкак загрузке ovl
	mes_func_not_exist db '[Error] Function does not exist', 13,10,'$'
	;mes_not_found_file db '[Error] File ovl not found', 0DH, 0AH,'$'
	;mes_not_found_route db '[Error] Route ovl not found',13,10,'$'
	mes_many_open_files db '[Error] Too many files were opened',13,10,'$'
	mes_no_access db '[Error] No access',13,10,'$'
	mes_little_memory db '[Error] Not enough memory',13,10,'$'
	mes_inv_env db '[Error] Wrong environment',13,10,'$'
	
	mes_load_success db 'Load ovl SUCCESS, ovl: $'
	mes_load_fail db 'Load ovl FAIL, ovl: $'
	
	PARAM_BLOCK   dw 0 ;блок содержит сегментный адрес блока памяти, предназначенного для получения оверлея, 
				  dw 0 ;а также сегментную константу перемещения для содержимого оверлейного файла (если это файл .EXE).
					   ;Обычно они совпадают.
				   
	file_name1 db 'ovl1.ovl$'
	file_name2 db 'ovl2.ovl$'
	file_path db 128 DUP (?)
	
	err db 0
	
	DTA db 43 dup(0)
	
	entry_ovl dd 0 ; точка входа в оверлей
	
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


PRINT_TWO_MES MACRO mes1, mes2
	PRINT_MES mes1
	PRINT_MES mes2
	PRINT_MES my_enter
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
	; Если err = 0, освобождение памяти получилось
	; Если err = 1, то не получилось освободить память и 
	;			   выводится сообщение о причине
	
	push dx
	push ax
   
   	call Malloc

	jnc end_free_mem ; Если СF = 0 прыгает (значит все хорошо)
	
	; анализ error
	cmp ax, 7
	je mem_destroy
	
	cmp ax, 8
	je insuff_mem

	cmp ax, 9
	je incorrect_addr

	mem_destroy:
		mov dx, offset mes_mem_destroy
		jmp end_prog

	insuff_mem:
		mov dx, offset mes_insuff_mem
		jmp end_prog

	incorrect_addr:
		mov dx, offset mes_incorrect_addr
		jmp end_prog


end_free_mem:
	pop dx
	pop ax
   	ret

end_prog:
	; выход из програмы	
	PRINT_MES_DX
	PRINT_MES my_enter
	xor ax, ax
	mov ah, 4Ch
	int 21h	
	
Free_mem ENDP



;----------------------Set_file_path-------------------------
Set_file_path proc 
	; BX - file_name 

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
    mov file_path[si],dl
    inc di
    inc si
    jmp m_write_patch
 
m_delete_file_name:
    dec si
    cmp file_path[si],'\'
    je m_ready_add_file_name
    jmp m_delete_file_name
   
m_ready_add_file_name:
    mov di,-1

m_add_file_name:
    inc si
    inc di
    mov dl,[bx+di]
    cmp dl, '$'
    je m_set_patch_end
    mov file_path[si],dl
    jmp m_add_file_name
   
m_set_patch_end:
    mov file_path[si],'$'
    pop es
    pop si
    pop di
    pop dx
    ret
Set_file_path endp


;----------------------Request_mem_ovl-------------------------
Request_mem_ovl proc near
	;Если после выполнения err = 1, значит запрос не удался

	push ax
	push bx
	push cx
	push dx
	push bp
	
	;устанавливаем сисьемный указатель на DTA на наш DTA
	mov ah,1Ah
	lea dx,DTA
    int 21h
	
	;определение размера требуемой памяти для оверлея
	mov ah,4Eh
    lea dx, file_path
	mov cx,0
	int 21h
	
	jnc request_mem ;Если СF = 0 прыгает (значит все хорошо)
	mov err, 1
	
	; обработка ошибки
	lea dx, mes_not_found_file
	cmp ax,2
	je print_er_ovl_size
	
	lea dx, mes_not_found_route
	cmp ax,3
	je print_er_ovl_size
	
print_er_ovl_size:
	PRINT_MES_DX
	jmp end_get_ovl_size


request_mem:
	;определяем размер файла 
	mov si, offset DTA
	mov ax, [si + 1Ah]	; младший
	mov dx, [si + 1Ch]	; старший
	mov cx, 16
	div cx ;  AX = (DX AX) / CX
	mov bx, ax
	add bx, 1
	
	;запрашиваем память
    mov ah, 48h
    int 21h
    jnc save_seg_ovl ;Если СF = 0 прыгает (значит все хорошо)
	
	;обработка ошибки
    PRINT_MES mes_error_inter_48
    jmp end_get_ovl_size

save_seg_ovl:
    mov PARAM_BLOCK,ax
	mov PARAM_BLOCK + 2, ax
	


end_get_ovl_size:	
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
Request_mem_ovl endp



;----------------------Load_ovl-------------------------
Load_ovl proc near
	push ax
	push dx
	push bx
	push es
	
	;проверка успешен ли был запрос памяти для ovl
	cmp err, 1
	jne ok
		mov err, 0
		PRINT_TWO_MES mes_load_fail, file_path
		jmp end_load_ovl
		
ok:	
	; установка точки входа в ovl
	mov ax, PARAM_BLOCK
	mov word ptr entry_ovl+2, ax ; +2 тк 1ое слово entry_ovl - смещение (= 0), 2ое слово адрес сегмента ovl (кот. мы и задаем)
	
	lea dx, file_path ; DS:DX - указывает на file_path
	
	; set ES = DS
	mov ax,ds 
    mov es,ax
	
	lea bx, PARAM_BLOCK ; ES:BX - указывает на PARAM_BLOCK
	
	mov ax,4B03h            
    int 21h
		  
	; обрабтка error	  
	jnc success_load
		call Handle_er_load_ovl
		PRINT_TWO_MES mes_load_fail, file_path
		jmp end_load_ovl
	
success_load:
	PRINT_TWO_MES mes_load_success, file_path
	call dword ptr entry_ovl
	
	; освобождение памяти ovl
    mov es, PARAM_BLOCK
	mov ah, 49h
	int 21h	

end_load_ovl:
	pop es
	pop bx
	pop dx
	pop ax
	ret
Load_ovl endp



;----------------------Handle_er_load_ovl-------------------------
Handle_er_load_ovl proc near
	push dx
	
	lea dx, mes_func_not_exist
	cmp ax,1
	je print_error_load_ovl
	
	lea dx, mes_not_found_file
	cmp ax,2
	je print_error_load_ovl
	
	lea dx, mes_not_found_route
	cmp ax,3
	je print_error_load_ovl
	
	lea dx, mes_many_open_files
	cmp ax,4
	je print_error_load_ovl
	
	lea dx, mes_no_access
	cmp ax,5
	je print_error_load_ovl
	
	lea dx, mes_little_memory
	cmp ax,8
	je print_error_load_ovl
	
	lea dx, mes_inv_env
	cmp ax,10
	je print_error_load_ovl
	
print_error_load_ovl:
	PRINT_MES_DX
	
	pop dx
	ret
Handle_er_load_ovl endp


;----------------------OVERLAY-------------------------
OVERLAY MACRO file_name
	push bx
	
	lea bx, file_name 
	call Set_file_path
	call Request_mem_ovl
	call Load_ovl
	PRINT_MES my_enter
	
	pop bx
ENDM


;=======================Main=============================	
Main proc far 
	push  DS       ;\  Сохранение адреса начала PSP в стеке
    sub   AX,AX    ; > для последующего восстановления по
    push  AX       ;/  команде ret, завершающей процедуру.
    mov   AX,DATA             ; Загрузка сегментного
    mov   DS,AX               ; регистра данных. 
	mov keep_psp, es
	
	call Free_mem
	OVERLAY file_name1
	OVERLAY file_name2

	xor ax, ax
	mov ah, 4Ch
	int 21h
Main endp

end_seg_code:
CODE ends
	end Main