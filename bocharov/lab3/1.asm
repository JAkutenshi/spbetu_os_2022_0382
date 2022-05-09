TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100h

start:
    jmp begin
    available_memory_size db 		"Available memory size:         ", 0dh, 0ah, "$"
				  
    cmos_size db 					"Cmos size:         ", 0dh, 0ah, "$"

    mcb_info db 					"Mcb_N:   , mcb_addr:      , PSP:      , size:        , sd/sc:         ", 0dh, 0ah, "$"

begin:
    call main
    xor al, al
    mov ah, 4ch
    int 21h


print_byte proc near
    push ax
    mov ah, 02h
    mov ah, 02h
    int 21h
    pop ax
    ret
print_byte endp

print_word proc near
    mov ah, 09h
    int 21h
    ret
print_word endp

tetr_to_hex proc near 
    and al,0fh
    cmp al,09
    jbe next
    add al,07
next: 
    add al,30h
    ret
tetr_to_hex endp

byte_to_hex proc near
    push cx
    mov ah,al
    call tetr_to_hex
    xchg al,ah
    mov cl,4
    shr al,cl
    call tetr_to_hex
    pop cx
    ret
byte_to_hex endp 

wrd_to_hex proc near
    push bx
    mov bh,ah
    call byte_to_hex
    mov [di],ah
    dec di
    mov [di],al
    dec di
    mov al,bh
    call byte_to_hex
    mov [di],ah
    dec di
    mov [di],al
    pop bx
    ret
wrd_to_hex endp 

byte_to_dec proc near
    push cx
    push dx
    push ax
    xor ah,ah
    xor dx,dx
    mov cx,10
loop_bd:
    div cx
    or dl,30h
    mov [si],dl
    dec si
    xor dx,dx
    cmp ax,10
    jae loop_bd
    cmp al,00h
    je end_l
    or al,30h
    mov [si],al
end_l: 
    pop ax
    pop dx
    pop cx
    ret
byte_to_dec endp



;----------------Start---------------------

byte_to_dec_2 proc near
    push cx
    push dx
    push ax
    mov cx,10
loop_bd_2:
    div cx
    add dx,30h
    mov [si],dl
    dec si
    xor dx,dx
    cmp ax,10
    jae loop_bd_2
    cmp al,00h
    je end_l
    or al,30h
    mov [si],al
end_l_2: 
    pop ax
    pop dx
    pop cx
    ret
byte_to_dec_2 endp



par_to_dec proc near
    push bx
    push ax
    push dx
    push si

    mov bx, 16
    mul bx               ; par too byte
	call byte_to_dec_2	  ; byte to dec

    pop si
    pop dx
    pop ax
    pop bx
    ret
par_to_dec endp




print_available_memory_size proc near
    mov ah, 4ah 
    mov bx, 0ffffh
    int 21h
    mov ax, bx
    mov si, offset available_memory_size
    add si, 30
    call par_to_dec
    mov dx, offset available_memory_size
    call print_word
    ret
print_available_memory_size endp




print_cmos_size proc near
    push ax
    push dx

    mov al, 30h
    out 70h, al
    in al, 71h
    mov al, 31h
    out 70h, al
    in al, 71h
    mov ah, al

    mov si, offset cmos_size
    add si, 19
    call par_to_dec
    mov dx, offset cmos_size
    call print_word    

    pop dx
    pop ax
    ret
print_cmos_size endp




print_mcb proc near
    push ax
    push si
    push di
    push cx
    push dx
    push bx

    mov al, cl
    mov si, offset mcb_info
    add si, 8
    call byte_to_dec
    
    mov ax, es
    mov di, offset mcb_info 
    add di, 25
    call wrd_to_hex
    
    mov ax, es:[1]
    mov di, offset mcb_info
    add di, 37
    call wrd_to_hex

    mov ax, es:[3]
    mov si, offset mcb_info
    add si, 52
	
    call par_to_dec
    


    mov bx, 8
    mov cx, 7
    mov si, offset mcb_info
    add si, 63
scsd_print_lp:
    mov dx, es:[bx]
    mov ds:[si], dx
    inc bx
    inc si
    loop scsd_print_lp

    mov dx, offset mcb_info
    call print_word

    pop bx
    pop dx
    pop cx
    pop di
    pop si
    pop ax
    ret
print_mcb endp



print_mcb_chain proc near
    push ax
    push es
    push cx
    push bx
    
    mov ah, 52h
    int 21h
    mov ax, es:[bx-2] ; first mcb
    mov es, ax
    mov cl, 1          ; number

get_mcb:
    call print_mcb

    mov al, es:[0]
    cmp al, 5ah        ; if last mcb
    je mcb_end
    
	
  
    mov ax, es          ; curent address
    add ax, es:[3] 			 ; get next	address
    inc ax
    mov es, ax				
    inc cl				; inc number
    jmp get_mcb

mcb_end:
    pop bx
    pop cx
    pop es
    pop ax
    ret
print_mcb_chain endp



main proc near
    call print_available_memory_size
    call print_cmos_size
    call print_mcb_chain
    ret
main endp
TESTPC ends
end start