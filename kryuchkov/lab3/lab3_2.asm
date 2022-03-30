code segment
assume cs:code, ds:code, es:nothing, ss:nothing
org 100h
start: jmp begin

free_mem db "Available memory size:         bytes",0dh,0ah,'$'
exp_mem  db "Expanded memory size:          bytes",0dh,0ah,'$'
mcbt 	 db "Mcb:0   adress:       psp adress:       size:          sd/sc: $"
newline	 db 0dh,0ah,'$'

tetr_to_hex proc near
and al,0fh
cmp al,09
jbe next
add al,07
next: add al,30h
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
xor ah,ah
xor dx,dx
mov cx,10
loop_bd: div cx
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
end_l: pop dx
pop cx
ret
byte_to_dec endp

par_to_dec proc near
push ax
push bx
push dx
push si
add si, 7
mov bx,10h
mul bx
mov bx,10
write_loop:
div bx
or dl,30h
mov [si], dl
dec si
xor dx,dx
cmp ax,0h
jnz write_loop 
pop si
pop dx
pop bx
pop ax
ret
par_to_dec endp

print proc near
push ax
mov ah, 09h
int 21h
pop ax
ret
print endp

memory proc near
push ax
push bx
push dx
push si

mov ah, 4ah
mov bx, 0ffffh
int 21h
mov ax, bx
mov dx, offset free_mem
mov si, dx
add si, 22
call par_to_dec
call print

mov al, 30h
out 70h, al
in al, 71h
mov bl, al
mov al, 31h
out 70h, al
in al, 71h
mov bh, al
mov ax, bx
mov dx, offset exp_mem
mov si, dx
add si, 22
call par_to_dec
call print

pop si
pop dx
pop bx
pop ax
ret
memory endp

mcb proc near
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

mcb_block:
inc cx
mov al, cl
mov dx, offset mcbt
mov si, dx
add si, 5
call byte_to_dec

mov ax, es
mov di, si
add di, 14
call wrd_to_hex

mov ax, es:[1]
add di, 21
call wrd_to_hex

mov ax, es:[3]	
mov si, di
add si, 11
call par_to_dec
call print

xor di,di
write_char:
mov dl, es:[di+8]
mov ah, 02h
int 21h
inc di
cmp di, 8
jl write_char
mov dx, offset newline
call print

mov al, es:[0]
cmp al, 4dh
jne exit
mov bx, es
add bx, es:[3]
inc bx
mov es, bx
jmp mcb_block
exit:
pop si
pop di
pop dx
pop cx
pop bx
pop ax
ret
mcb endp


free proc near
push ax
push bx
push dx
mov ax, offset enddd
mov bx, 10h
xor dx,dx
div bx
add ax, 4
mov bx, ax
mov ah, 4ah
int 21h
pop dx
pop bx
pop ax
ret
free endp

begin:
call memory

call free

call mcb
xor al,al
mov ah, 4ch
int 21h
enddd:
code ends
end start