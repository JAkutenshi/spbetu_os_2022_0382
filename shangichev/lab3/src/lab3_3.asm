TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100h

start:
    jmp begin

data:
    available_memory_msg db "Available memory size:           ", 0dh, 0ah, '$'
    extended_memory_msg db "Extended memory size:             ", 0dh, 0ah, '$'
    mcb_msg db "Address:      PCP owner:     Size:             SC/SD:           ", 0dh, 0ah, '$'
    error_msg db "Error: the size of requested memory is too large.", 0dh, 0ah, '$'

tetr_to_hex PROC near 
    and AL,0Fh
    cmp AL,09
    jbe next
    add AL,07
next: 
    add AL,30h
    ret
tetr_to_hex ENDP

byte_to_hex PROC near
    push CX
    mov AH,AL
    call tetr_to_hex
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call tetr_to_hex
    pop CX
    ret
byte_to_hex ENDP 

wrd_to_hex PROC near
    push BX
    mov BH,AH
    call byte_to_hex
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call byte_to_hex
    mov [DI],AH
    dec DI
    mov [DI],AL
    pop BX
    ret
wrd_to_hex ENDP 

byte_to_dec PROC near
    push CX
    push DX
    push ax
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd:
    div CX
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
end_l: 
    pop ax
    pop DX
    pop CX
    ret
byte_to_dec ENDP


convert_to_decimal proc near
    ; ax - paragraph
    ; si - low digit of result
    push bx
    push dx

    mov bx, 16
    mul bx ; convert to num of bytes

    mov bx, 10
    convert:
        div bx
        add dl, '0'
        mov [si], dl
        dec si
        xor dx, dx
        cmp ax, 0000h
        jne convert

    pop dx
    pop bx
    ret
convert_to_decimal endp

print proc near
    ; dx - offset of message
    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
print endp


print_available_memory proc near
    mov ah, 4Ah
    mov bx, 0ffffh
    int 21h ; now bx contains size of available memory

    mov si, offset available_memory_msg
    add si, 33

    mov ax, bx
    call convert_to_decimal

    mov dx, offset available_memory_msg
    call print
    ret
print_available_memory endp

print_extended_memory proc near
    mov AL,30h 
    out 70h,AL
    in AL,71h 
    mov BL,AL

    mov AL,31h 
    out 70h,AL
    in AL,71h  
    mov bh, al

    mov ax, bx 
    mov si, offset extended_memory_msg
    add si, 33

    call convert_to_decimal

    mov dx, offset extended_memory_msg
    call print
    ret
print_extended_memory endp

set_mcb_address proc near
    ; ax - address
    push di
    mov di, offset mcb_msg
    add di, 12
    call wrd_to_hex
    pop di
    ret
set_mcb_address endp

set_pcp_owner proc near
    ; es - address of mcb
    push ax
    push di
    mov ax, es:[1]
    mov di, offset mcb_msg
    add di, 27
    call wrd_to_hex
    pop di
    pop ax
    ret    
set_pcp_owner endp

set_size proc near
    ; es - address of mcb
    push si
    push ax

    mov si, offset mcb_msg
    add si, 45
    mov ax, es:[3]
    call convert_to_decimal

    pop ax
    pop si
    ret
set_size endp

set_sc proc near
	push di
	push ax
	push bx

    mov di, offset mcb_msg
    add di, 54
    mov si, 8
    sc_write:
    	mov bx, es:[si]
    	mov [di], bx
    	add si, 2
    	add di, 2
    	cmp si, 16
    	jb sc_write

    pop bx
    pop ax
    pop di
    ret
set_sc endp

print_mcb proc near
    ; es - address of mcb
    push ax
    push dx

    mov ax, es
    call set_mcb_address
    call set_pcp_owner
    call set_size
    call set_sc
    mov dx, offset mcb_msg
    call print
    
    pop dx
    pop ax
    ret
print_mcb endp

print_memory_control_blocks proc near
    ; get address of first block
    mov ah, 52h
    int 21h
    mov es, es:[bx-2]

    print_msbs:
        call print_mcb
        mov ah, es:[0]
        cmp ah, 5Ah
        je end_
        mov ax, es
        add ax, es:[3]
        inc ax
        mov es, ax
        jmp print_msbs

    end_:        

    ret
print_memory_control_blocks endp


free_memory proc near
    push ax
    push bx
    push dx

    lea ax, finish_program
    mov bx, 10h
    xor dx, dx
    div bx
    inc ax

    start_free:
        mov bx, ax
        xor ax, ax
        mov ah, 4ah
        int 21h

    pop dx
    pop bx
    pop ax
    ret
free_memory endp

request_memory proc near
    ; bx - size of requested memory
    push ax

    mov ah, 48h
    int 21h
    jnc end_proc

    handle_error:
        push dx
        mov dx, offset error_msg
        call print
        pop dx

    end_proc:
        pop ax

    ret
request_memory endp


begin:
    call print_available_memory
    call print_extended_memory
    call free_memory
    mov bx, 1000h
    call request_memory
    call print_memory_control_blocks


    xor al, al
    mov ah, 4Ch
    int 21h

finish_program:

TESTPC ENDS
END start



