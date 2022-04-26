AStack SEGMENT  STACK
          DW 256 DUP(?)
AStack ENDS

DATA SEGMENT
	IS_LOAD DB 0
	IS_UNLOAD DB 0
	INTP_LOAD db "User interruption has loaded.$"
	INTP_LOADED db "User interruption already loaded.$"
	INTP_UNLOAD db "User interruption has unloaded.$"
	INTP_NOT_LOADED db "User interruption is not loaded.$"
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack


PRINT PROC NEAR
    push ax
    mov ah, 09h
    int 21h
    pop ax
	ret
PRINT ENDP


INTERRUPT PROC FAR
jmp start

interrupt_data:
	keep_ip DW 0
	keep_cs DW 0
	keep_psp DW 0
	keep_ax DW 0
	keep_ss DW 0
	keep_sp DW 0
	intp_stack DW 256 DUP(0)
	sym DB 0
	sign DW 1234h

    start:
	    mov keep_ax, ax
	    mov keep_sp, sp
	    mov keep_ss, ss
	    mov ax, seg intp_stack
	    mov ss, ax
	    mov ax, offset intp_stack
	    add ax, 256
	    mov sp, ax
	
        push ax
        push bx
   	    push cx
        push dx
        push si
        push es
        push ds

	    mov ax, seg sym
	    mov ds, ax
    
	    in al, 60h   ;считывание номера клавиши
        cmp al, 10h	 ;скан-символ
        je change_q
        cmp al, 11h
        je change_w
        cmp al, 13h
        je change_r

	    pushf
	    call dword ptr cs:keep_ip
	    jmp end_p

    change_q:
       	mov sym, '&'
    	jmp next
    change_w:
    	mov sym, '!'
        jmp next
    change_r:
        mov sym, '*'

next:                   ;обработка аппартаного прерывания
    	in al, 61h
    	mov ah, al
    	or al, 80h
    	out 61h, al
    	xchg al, al
    	out 61h, al
    	mov al, 20h
    	out 20h, al
  
print_sym:
    	mov ah, 05h ;запись символа в буфер клавитуры
    	mov cl, sym
    	mov ch, 00h
    	int 16h
    	or al, al
    	jz end_p
    	mov ax, 0040h
    	mov es, ax
    	mov ax, es:[1ah]
    	mov es:[1ch], ax
    	jmp print_sym

    end_p:
    	pop ds
    	pop es
    	pop si
    	pop dx
    	pop cx
    	pop bx
    	pop ax

	mov sp, keep_sp
	mov ax, keep_ss
	mov ss, ax
	mov ax, keep_ax
	mov al, 20h
	out 20h, al
	iret
INTERRUPT endp

END_I:
CHECK_LOAD PROC NEAR
	push ax
	push bx
	push si
	mov ah, 35h
	mov al, 09h
	int 21h

	mov si, offset sign
	sub si, offset INTERRUPT
	mov ax, es:[bx + si]
	cmp ax, sign
	jne load_end
	mov IS_LOAD, 1
    
load_end:
	pop  si
	pop  bx
	pop  ax
	ret
CHECK_LOAD ENDP


CHECK_UNLOAD PROC NEAR
    push ax
    push es
   	mov ax, keep_psp
   	mov es, ax
    cmp byte ptr es:[82h], '/'
    jne check_end
    cmp byte ptr es:[83h], 'u'
    jne check_end
    cmp byte ptr es:[84h], 'n'
    jne check_end
    mov IS_UNLOAD, 1
 
    check_end:
    	pop es
   	    pop ax
	    ret
CHECK_UNLOAD ENDP

INTERRUPT_LOAD PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push ds
	push es

 	mov ah, 35h
    mov al, 09h
    int 21h
   	mov keep_cs, es
    mov keep_ip, bx
    mov ax, seg INTERRUPT
    mov dx, offset INTERRUPT
    mov ds, ax
    mov ah, 25h
    mov al, 09h

    int 21h

    pop ds
    mov dx, offset END_I
    mov cl, 4h
    shr dx, cl
    add dx, 10fh
    inc dx
    xor ax, ax
    mov ah, 31h
    int 21h

    pop es
    pop dx
    pop cx
    pop bx
    pop ax
	ret
INTERRUPT_LOAD ENDP


INTERRUPT_UNLOAD PROC NEAR
   	cli
    push ax
    push bx
   	push dx
    push ds
    push es
    push si
    
    mov ah, 35h
    mov al, 09h
    int 21h
    mov si, offset keep_ip
    sub si, offset INTERRUPT
    mov dx, es:[bx+si]
    mov ax, es:[bx+si+2]
 
    push ds
    mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds
    
    mov ax, es:[bx+si+4]
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
    pop si
    pop es
    pop ds
    pop dx
    pop bx
    pop ax
	ret
INTERRUPT_UNLOAD ENDP

MAIN PROC
    push ds
    xor ax, ax
   	push ax

    mov ax, data
    mov ds, ax
    mov keep_psp, es
    
    call CHECK_LOAD
    call CHECK_UNLOAD
    cmp IS_UNLOAD, 1
    je unload
    mov al, IS_LOAD
    cmp al, 1
    jne load
    mov dx, offset INTP_LOADED
    call PRINT
    jmp end_main

    load:
        mov dx, offset INTP_LOAD
        call PRINT
        call INTERRUPT_LOAD
        jmp  end_main
 
    unload:
        cmp  IS_LOAD, 1
        jne  not_loaded
        mov dx, offset INTP_UNLOAD
        call PRINT
        call INTERRUPT_UNLOAD
        jmp  end_main
        
    not_loaded:
        mov  dx, offset INTP_NOT_LOADED
        call PRINT

    end_main:
        xor al, al
        mov ah, 4ch
        int 21h
MAIN ENDP
CODE ENDS
END MAIN