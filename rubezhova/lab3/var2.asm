TESTPC	SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:	JMP  BEGIN
; Данные
 AVAIL_MEMORY DB "Available memory:        bytes", 0DH, 0AH, '$'
 EXT_MEMORY DB "Extended memory:          bytes", 0DH, 0AH, '$'
 MCB DB " _MCB  Address:       PSP_address:       Size:        SD/SC: $"
 NEW_STRING_SYMBOL DB 0DH, 0AH, '$'
 ; ------------------------------------------------------
; Процедуры
TETR_TO_HEX PROC near
		and AL, 0Fh
		cmp AL, 09
		jbe NEXT
		add AL, 07
NEXT:	add AL, 30h
		ret
TETR_TO_HEX ENDP
; -------------------------------------------------------
; байт в AL переводится в два символа шестн. числа в AX
BYTE_TO_HEX	PROC near
		push CX
		mov AH, AL
		call TETR_TO_HEX
		xchg AL, AH
		mov CL, 4
		shr AL, CL
		call TETR_TO_HEX
		pop CX
		ret
BYTE_TO_HEX ENDP
; -------------------------------------------------------
; перевод в 16 с/с 16-ти разрядного числа в AX - число, DI - адрес последнего символа
WRD_TO_HEX PROC near
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
; -------------------------------------------------------
; перевод в 10 с/с, SI - адрес поля младшей цифры
BYTE_TO_DEC PROC near
		push CX
		push DX
		xor AH, AH
		xor DX, DX
		mov CX, 10
loop_bd:	div CX
		or DL, 30h
		mov [SI], DL
		dec SI
		xor DX, DX
		cmp AX, 10
		jae loop_bd
		cmp AL, 00h
		je end_l
		or AL, 30h
		mov [SI], AL
end_l:	pop DX
		pop CX
		ret
BYTE_TO_DEC ENDP
; -------------------------------------------------------
HEX_TO_DEC PROC near

    mov bx, 0Ah   ;bx=10
    
    dividing:
    	div bx
    	add dx,30h    
    	mov [si], dl
    	xor dx,dx
    	dec si
        cmp ax,0
    	jne dividing
    ret
    
HEX_TO_DEC ENDP
; -------------------------------------------------------
PAR_TO_DEC PROC near
;num of paragraphs->bytes(hex)->bytes(dec)
;restore registers here because in HEX_TO_DEC procedure we don't restore them
    push ax
    push bx
    push dx
    push si
    
    mov bx,10h
    mul bx     ; *16
    call HEX_TO_DEC
    pop si
    pop dx
    pop bx
    pop ax
    ret
    
PAR_TO_DEC ENDP
; -------------------------------------------------------
PRINT PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
PRINT ENDP
; -------------------------------------------------------
AVAIL_MEM_PRINT PROC NEAR

    mov ah,4Ah
    mov bx, 0FFFFh
    int 21h
    
    mov ax, bx
    mov si, offset AVAIL_MEMORY + 23
    call PAR_TO_DEC
    mov dx, offset AVAIL_MEMORY
    call PRINT
    ret

AVAIL_MEM_PRINT ENDP
; -------------------------------------------------------
kB_TO_BYTE PROC NEAR

    push ax
    push bx
    push dx
    push si
    mov bx,10000
    div bx  ;ax=(dx ax) div bx, dx=(dx ax) mod bx
    push ax 
    mov ax,dx 
    xor dx,dx
    call HEX_TO_DEC
    pop ax
    call HEX_TO_DEC
    
    pop si
    pop dx
    pop bx
    pop ax
    ret

kB_TO_BYTE ENDP
; ------------------------------------------------------
EXT_MEM_PRINT proc near
    mov al,30h 
    out 70h,al 
    in al,71h      ;read a lower byte 
    mov bl,al	    ;of extended memory size
    mov al,31h 	;write address of CMOS cell
    out 70h, al
    in al,71h     ;read a higher byte
    mov bh, al	   ;of extended memory size
    mov ax, bx 
    mov si, offset EXT_MEMORY + 24
    mov bx, 400h  ;*1024
    mul bx
    call kB_TO_BYTE

    mov dx, offset EXT_MEMORY
    call PRINT
    ret
    
EXT_MEM_PRINT endp
; --------------------------------------------------
MCB_PRINT PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push di
	push si
   
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	xor cx,cx

	MCB_block:
		inc cx
		mov al, cl
		mov dx, offset MCB
		mov si, dx
		
		call BYTE_TO_DEC
		add si, 4

		mov ax, es
		mov di, si
		add di, 15
		call WRD_TO_HEX
			
		mov ax, es:[01h]
		add di, 23
		call WRD_TO_HEX
			
		mov ax, es:[03h]	
		mov si, di
		add si, 16
		call PAR_TO_DEC
		call PRINT
		xor di,di
		
	print_char:
		mov dl, es:[di+8]
		mov ah, 02h
		int 21h
		inc di
		cmp di, 8
		jl print_char
		mov dx, offset NEW_STRING_SYMBOL
		call PRINT
			
		mov al, es:[00h]
		cmp al, 4Dh    
		jne ending    ;if al!=4DH => it's last MCB
		mov bx, es    
		add bx, es:[03h] ;size in paragraphs
		inc bx
		mov es, bx
		jmp MCB_block
	ending:
		pop si
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		ret
		
MCB_PRINT ENDP
; --------------------------------------------------
MEM_FREE PROC near
	push ax
	push bx
	push dx 
	mov ax, offset module_ending
	mov bx, 10h
	xor dx,dx
	div bx
	add ax, 4
	mov bx, ax
	mov ah, 4Ah
	int 21h
   	pop dx
	pop bx
	pop ax
	ret
MEM_FREE endp
; --------------------------------------------------
; Основной код
BEGIN:
	call AVAIL_MEM_PRINT
	call EXT_MEM_PRINT
	call MEM_FREE
	call MCB_PRINT
; Выход в DOS
	xor AL, AL
	mov AH, 4Ch
	int 21h

module_ending:
TESTPC ENDS
END START
