TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG	100H
START:	jmp BEGIN
;-------------------------------
MEMORY_SIZE db 'Available memory:          ', 0DH, 0AH, '$'
CMOS_SIZE db 'Extended memory:          ', 0DH, 0AH, '$'
MCB db 'MCB:   | addr:      | owner PSP:     | size:        | SD/SC:   $'
ENDLINE db 0DH, 0AH, '$'
MESSAGE db 'Request Failed!', 0DH, 0AH, '$'
;-------------------------------
TETR_TO_HEX PROC near
	and AL, 0Fh
	cmp AL, 09
	jbe NEXT
	add AL, 07
NEXT:	add AL, 30h
	ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа 16-го числа в AX
	push CX
	mov AH, AL
	call TETR_TO_HEX
	xchg AL, AH
	mov CL, 4
	shr AL, CL
	call TETR_TO_HEX ; в AL старшая цифра
	pop CX		 ; в AH младшая
	ret 
BYTE_TO_HEX ENDP
;------------------------------
WRD_TO_HEX PROC near
; перевод в 16 с/с 16-ти разрядного числа
; в AX - число, в DI - адрес последнего символа
	push BX
	mov BH, AH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	dec DI
	mov AL, BH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	pop BX
	ret
WRD_TO_HEX ENDP
;---------------------------------------
WRD_TO_DEC PROC near
	push CX
	push DX
	mov CX, 10
loop_wd: 
	div CX
	or DL, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 10
	jae loop_wd
	cmp AL, 00h
	je end_2
	or AL, 30h
	mov [SI], AL
end_2:  
	pop DX
	pop CX
	ret
WRD_TO_DEC ENDP
;---------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10 с/с, в SI - адрес поля младшей цифры
	push CX
	push DX
	xor AH, AH
	xor DX, DX
	mov CX, 10
loop_bd: div CX
	or DL, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 10
	jae loop_bd
	cmp AL, 00h
	je end_1
	or AL, 30h
	mov [SI], AL
end_1:  pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
;----------------------
BYTE_FUNC PROC near
	push ax
	push bx
	push dx
	push si
	
	mov bx, 10h
    	mul bx
    	mov bx, 0ah
	byte_loop:
    	    div bx
    	    add dx, 30h
    	    mov es:[si], dl
    	    xor dx, dx
    	    dec si
    	    cmp ax, 0000h
            jne byte_loop
        pop si
        pop dx
        pop bx
        pop ax
	ret
BYTE_FUNC ENDP
;----------------------
PRINT PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
;----------------------
memory_func PROC near
	mov ah, 4ah 
    	mov bx, 0FFFFh
    	int 21h
    	mov ax, bx
    	mov si, offset MEMORY_SIZE
    	add si, 23
    	call BYTE_FUNC
    	mov dx, offset MEMORY_SIZE
    	call PRINT
	ret
memory_func ENDP
;-----------------------------------
cmos_func PROC near
	push ax
    	push dx
    	
    	mov al, 30h
    	out 70h, al
    	in al, 71h
    	mov al, 31h
    	out 70h, al
    	in al, 71h
    	mov ah, al
    	mov si, offset CMOS_SIZE
    	add si, 22
    	call BYTE_FUNC
    	mov dx, offset CMOS_SIZE
    	call PRINT 
    	   
    	pop dx
    	pop ax
	ret
cmos_func ENDP
;-----------------------------------
mcb_func PROC near	
    	mov ah, 52h
    	int 21h
    	mov ax, es:[bx-2]
    	mov es, ax
    	
    	check_mcb:
		mov di, offset MCB
		add di, 5
		mov ax, es:[00h]
		call BYTE_TO_HEX
		mov [di], al
		add di, 1
		mov [di], ah
		    
		mov di, offset MCB
		add di, 18
		mov ax, es
		call WRD_TO_HEX
		    
		mov di, offset MCB
		add di, 34
		mov ax, es:[01h]
		call WRD_TO_HEX

		mov si, offset MCB
		add si, 49
		mov ax, es:[03h]
		mov bx, 16
		mul bx
		call WRD_TO_DEC
		
		mov dx, offset MCB
		call PRINT
		
		mov di, offset MCB
		add di, 62
		mov bx, 8
		mov cx, 7
		scsd_loop:
		    mov dl, es:[bx]
		    mov ah, 02h
		    int 21h
		    add bx, 1
		    loop scsd_loop
		    
		mov al, es:[0h]
		cmp al, 5ah
		je final
	    	 
    		mov bx, es
    		mov ax, es:[03h]
    		add ax, bx
    		inc ax
    		mov es, ax
    		mov dx, offset ENDLINE
    		call PRINT
    		jmp check_mcb
	final:
		ret
mcb_func ENDP
;-----------------------------------
free_memory PROC NEAR
    push ax
    push bx
    push dx

    lea ax, quit_prog
    mov bx, 10h
    xor dx, dx
    div bx
    inc ax
    mov bx, ax
    mov al, 0
    mov ah, 4ah
    int 21h

    pop dx
    pop bx
    pop ax
    ret
free_memory ENDP
;-----------------------------------
memory_request PROC NEAR
    push ax
    push bx
    push dx
    
    mov bx, 1000h
    mov ah, 48h
    int 21h
    jnc success
    mov dx, offset MESSAGE
    call PRINT
    
    success:
	    pop dx
	    pop bx
	    pop ax
	    ret
memory_request ENDP
;-----------------------------------
BEGIN:
	call memory_func
	call cmos_func
	call memory_request
	call free_memory
	call mcb_func
	
	xor AL, AL
	mov AH, 4Ch
	int 21h
quit_prog:
TESTPC ENDS
	END START
