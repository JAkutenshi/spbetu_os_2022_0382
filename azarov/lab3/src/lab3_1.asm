TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN


mes_avail_mem db "Size available memory:          bytes", 0dh, 0ah, '$' ;30
mes_extended_mem db "Size extended memory:           bytes", 0dh, 0ah, '$' ;30
mes_number_MCB db "MCB #0 ", 0dh, 0ah, '$' ;6
mes_addr_MCB db "Address MCB:     ", 0dh, 0ah, '$' ;16
mes_addr_psp_owner db "Address PSP owner:     ", 0dh, 0ah, '$' ;22
mes_size_MCB db "Size:         bytes", 0dh, 0ah, '$' ;12
mes_scsd db "SC/SD: ", '$'

my_enter db 0DH,0AH,'$'
my_tab db '    $'


PRINT_MES MACRO mes
    mov DX, offset mes
    mov AH, 09h
    int 21h
ENDM



BEGIN:
	call print_avail_mem
	call print_extended_mem
	call print_all_MCB

	
;EXIT
    xor AL,AL
    mov AH,4Ch
    int 21H



;====================My PROC=============================

;---------------Getting and print size available memory-------------------
print_avail_mem proc near
    mov ah, 4Ah
    mov bx, 0ffffh
    int 21h ; now bx contains size of available memory

    mov si, offset mes_avail_mem
    add si, 30

    mov ax, bx
    call parag_to_dec

    PRINT_MES mes_avail_mem
    ret
print_avail_mem endp


;---------------Convert paragraph to decimal-------------------
parag_to_dec proc near
    ; ax - paragraph
    ; si - low digit of result
    push bx
    push dx

    mov bx, 16
    mul bx ; convert to num of bytes

    mov bx, 10
    division:
        div bx
        add dl, '0'
        mov [si], dl
        dec si
        xor dx, dx
        cmp ax, 0000h
        jne division

    pop dx
    pop bx
    ret
parag_to_dec endp


;---------------Getting and print size extended memory-------------------
print_extended_mem proc near
    mov AL,30h 
    out 70h,AL
    in AL,71h 
    mov BL,AL

    mov AL,31h 
    out 70h,AL
    in AL,71h  
    mov bh, al

    mov ax, bx 
    mov si, offset mes_extended_mem
    add si, 30

    call parag_to_dec

    PRINT_MES mes_extended_mem
    ret
print_extended_mem endp


;---------------Print all MCB-------------------
print_all_MCB proc near
    ; get address of first block
    mov ah, 52h
    int 21h
    mov es, es:[bx-2]
	
	mov cx, 0 ; counter
	
	
    print_curr_MCB:
		PRINT_MES my_enter
		
		inc cx
		
        call print_MCB
        mov ah, es:[0]
        
		cmp ah, 5Ah
        je @f
		
        mov ax, es
        add ax, es:[3]
        inc ax
        mov es, ax
        jmp print_curr_MCB

    @@:        

    ret
print_all_MCB endp


;---------------Print MCB-------------------
print_MCB proc near
	; es - address of current mcb
	; cx - number of current mcb

	call print_number_MCB
    call print_MCB_address
    call print_addr_psp_owner
    call print_size_MCB
    call print_scsd
  
    ret
print_MCB endp


;----------------------------------------------------------
print_number_MCB proc near
	push ax
	push si 
	
	; cx - number of current mcb
	mov si, offset mes_number_MCB
	add si, 6
	mov ax,cx
	call BYTE_TO_DEC
	PRINT_MES mes_number_MCB
	
	pop ax
	pop si
	ret
print_number_MCB endp


;----------------------------------------------------------
print_MCB_address proc near
	push ax
	push si
	
	; es - address of current mcb
	mov si, offset mes_addr_MCB
	add si, 16
	mov ax,es
	call WRD_TO_HEX
	PRINT_MES mes_addr_MCB
	
	pop ax
	pop si
	ret
print_MCB_address endp


;----------------------------------------------------------
print_addr_psp_owner proc near
	push ax
	push si
	
	; es - address of current mcb
	mov si, offset mes_addr_psp_owner
	add si, 22
	mov ax, es:[1]
	call WRD_TO_HEX
	PRINT_MES mes_addr_psp_owner
	
	pop ax
	pop si
	ret
print_addr_psp_owner endp


;----------------------------------------------------------
print_size_MCB proc near
	push ax
	push si
	
	; es - address of current mcb
	mov si, offset mes_size_MCB
	add si, 12
	mov ax, es:[3]
	call parag_to_dec
	PRINT_MES mes_size_MCB
	
	pop ax
	pop si
	ret
print_size_MCB endp


;----------------------------------------------------------
print_scsd proc near
	push ax
	push dx
	push si
	
	; es - address of current mcb
	PRINT_MES mes_scsd
	mov si, 8
	mov ah, 02h
	
	print_symb:
		mov dl, es:[si]
		int 21h
		inc si
		
		cmp si, 15
		je @f 
		jmp print_symb

	@@:	
	
	PRINT_MES my_enter
	
	pop ax
	pop dx
	pop si
	ret
print_scsd endp



;==================NOT MY PROC==========================

;-----------------------------------------------------
TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP


;----------------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ;в AL старшая цифра
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP


;---------------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, SI - адрес последнего символа
    push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [SI],AH
    dec SI
    mov [SI],AL
    dec SI
    mov AL,BH
    call BYTE_TO_HEX
    mov [SI],AH
    dec SI
    mov [SI],AL
    pop BX
    ret
WRD_TO_HEX ENDP


;---------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd: div CX
    or DL,30h
    mov [SI],DL
    dec SI
    xor DX,DX
    cmp AX,10
    jae loop_bd
    cmp AL,00h
    je end_l
    or AL,30h
    mov [SI],AL
end_l: pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP


TESTPC ENDS
    END START 