main_seg SEGMENT
    ASSUME CS:main_seg, DS:main_seg, ES:NOTHING, SS:NOTHING
    ORG 100h

start:
    jmp begin

data:
    MEM_SIZE db "Available mem size:         ", 0dh, 0ah, "$"
    CMOS_SIZE db "Extended mem size:         ", 0dh, 0ah, "$"
    MCB_ROW db "MCB:   , addr:      , owner PSP:      , size:        , SD/SC:         ", 0dh, 0ah, "$"
    MEM_FAIL db "Memory allocation failed!", 0dh, 0ah, "$"

begin:
    call main
    xor al, al
    mov ah, 4Ch
    int 21h

print PROC NEAR
    mov ah, 09h
    int 21h
    ret
print ENDP

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

print_symbol PROC NEAR
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
print_symbol ENDP

par_to_byte PROC NEAR
    ; ES - dest seg, SI - dest offset (end), AX - paragraphs number
    push bx
    push ax
    push dx
    push si

    mov bx, 10h
    mul bx
    mov bx, 0ah
div_loop:
    div bx
    add dx, 30h
    mov es:[si], dl
    xor dx, dx
    dec si
    cmp ax, 0000h
    jne div_loop

    pop si
    pop dx
    pop ax
    pop bx
    ret
par_to_byte ENDP

print_mem_size PROC NEAR
    mov ah, 4ah 
    mov bx, 0ffffh
    int 21h
    mov ax, bx
    mov si, offset MEM_SIZE
    add si, 27
    call par_to_byte
    mov dx, offset MEM_SIZE
    call print
    ret
print_mem_size ENDP

print_cmos_size PROC NEAR
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
    add si, 27
    call par_to_byte
    mov dx, offset CMOS_SIZE
    call print    

    pop dx
    pop ax
    ret
print_cmos_size ENDP

print_one_mcb PROC NEAR
    push ax
    push si
    push di
    push cx
    push dx
    push bx

    mov al, cl
    mov si, offset MCB_ROW
    add si, 6
    call byte_to_dec
    
    mov ax, es
    mov di, offset MCB_ROW 
    add di, 19
    call wrd_to_hex
    
    mov ax, es:[1]
    mov di, offset MCB_ROW
    add di, 37
    call wrd_to_hex

    mov ax, es:[3]
    mov si, offset MCB_ROW
    add si, 52
    push es
    mov dx, ds
    mov es, dx
    call par_to_byte
    pop es

    mov bx, 8
    mov cx, 7
    mov si, offset MCB_ROW
    add si, 62
scsd_loop:
    mov dx, es:[bx]
    mov ds:[si], dx
    inc bx
    inc si
    loop scsd_loop

    mov dx, offset MCB_ROW
    call print

    pop bx
    pop dx
    pop cx
    pop di
    pop si
    pop ax
    ret
print_one_mcb ENDP

print_mcb_list PROC NEAR
    push ax
    push es
    
    mov ah, 52h
    int 21h
    mov ax, es:[bx-2]
    mov es, ax
    mov cl, 1

mcb_loop:
    call print_one_mcb

    mov al, es:[0]
    cmp al, 5ah
    je mcb_end
    
    mov bx, es:[3]
    mov ax, es
    add ax, bx
    inc ax
    mov es, ax
    inc cl
    jmp mcb_loop

mcb_end:
    pop es
    pop ax
    ret
print_mcb_list ENDP

free_mem PROC NEAR
    push ax
    push bx
    push dx

    lea ax, end_addr
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
free_mem ENDP

main PROC NEAR
    call print_mem_size
    call print_cmos_size
    call free_mem
    call print_mcb_list
    ret
main ENDP

end_addr:
main_seg ENDS
END start
