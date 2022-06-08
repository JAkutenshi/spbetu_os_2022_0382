overlay1 segment
assume cs:overlay1, ds:nothing, ss:nothing

main proc far
    
    push dx
    push di
    push ds
    push ax
    mov ax,cs
    mov ds,ax
    mov di,offset ovl_addr + 21 ; Вывводим адрес сегмента оверлэя
    call wrd_to_hex 
    mov dx,offset ovl_addr
    call print
    pop ax
    pop ds
    pop di
    pop dx
    
    retf
    
main endp

ovl_addr db "Overlay 1 addres:     h", 0dh, 0ah, '$'

print proc near

    push ax
    mov ah, 09h
    int 21h
    pop ax
    ret
    
print endp


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



overlay1 ends
end main