main_seg SEGMENT
    ASSUME CS:main_seg, DS:main_seg, ES:NOTHING, SS:NOTHING
    ORG 100h

start:
    jmp begin

data:
    NMEM_ADDR db "Adress of not available memory:     h",0Dh, 0Ah,"$"
    ENV_ADDR db "Adress of enviroment:     h",0Dh,0Ah,"$"
    EMPTY_TAIL_MSG db "CMD tail is empty.",0Dh,0Ah,"$"
    TAIL_MSG db "CMD tail is: ", "$"
    ENV_MSG db "Enviroment content: ","$"
    PATH_MSG db "Executable module path: ","$"

begin:
    call main
    xor al, al
    mov ah, 01h
    int 21h
    mov ah, 4Ch
    int 21h

print_nmem_addr PROC NEAR
    mov ax, ds:[2h]
    mov di, OFFSET NMEM_ADDR + 35
    call wrd_to_hex
    mov dx, OFFSET NMEM_ADDR
    call print
    ret
print_nmem_addr ENDP

print_env_addr PROC NEAR
    mov ax, ds:[2Ch]
    mov di, OFFSET ENV_ADDR + 25
    call wrd_to_hex
    mov dx, OFFSET ENV_ADDR
    call print
    ret
print_env_addr ENDP

print_symbol PROC NEAR
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
print_symbol ENDP
    
print_cmd_tail PROC NEAR
    mov cl, ds:[80h]
    cmp cl, 0h
    je empty_tail
    mov dx, OFFSET TAIL_MSG
    call print
    mov si, 81h
loop_tail:
    mov dl, ds:[si]
    call print_symbol
    inc si
    loop loop_tail
    mov dl, 0Dh
    call print_symbol
    mov dl, 0Ah
    call print_symbol
    ret
empty_tail:
    mov dx, OFFSET EMPTY_TAIL_MSG
    call print
    ret
print_cmd_tail ENDP

print_env PROC NEAR
    mov dx, OFFSET ENV_MSG
    call print
    mov es, ds:[2Ch]
    xor di, di
    mov ax, es:[di]
    cmp ax, 00h
    jz loop_fin
    add di, 2
read_loop:
    mov dl, al
    call print_symbol
    mov al, ah
    mov ah, es:[di]
    inc di
    cmp ax, 00h
    jne read_loop
loop_fin:
    mov dl, 0Dh
    call print_symbol
    mov dl, 0Ah
    call print_symbol
    mov dx, OFFSET PATH_MSG
    call print
    add di, 2
    mov dl, es:[di]
    inc di
path_loop:
    call print_symbol
    mov dl, es:[di]
    inc di
    cmp dl, 00h
    jne path_loop
    ret
print_env ENDP
    
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

main PROC NEAR
    call print_nmem_addr
    call print_env_addr
    call print_cmd_tail
    call print_env
    ret
main ENDP

main_seg ENDS
END start
