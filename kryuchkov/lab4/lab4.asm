code segment
assume cs:code, ds:data, ss:astack

interrupt proc far
jmp int_start
psp			dw ?
keep_cs 	dw ?
keep_ip 	dw ?
keep_ss 	dw ?
keep_sp 	dw ?
int_id  	dw 07777
counter		db 'counts: 0000'
int_stack 	db 128 dup(?)

int_start:
;запомнили стэк программы
mov keep_ss, ss
mov keep_sp, sp
;поменяли стэк программы на стэк прерывания
mov sp, seg interrupt
mov ss, sp
mov sp, offset int_start
push ds
push es
push ax
push bx
push cx
push dx
push si
push bp
;запоминаем текущую позицию курсора
mov ah, 03h
mov bh, 0
int 10h
push dx

;меняем положение курсора
mov ah, 02h
mov bh, 0
mov dl, 30h
mov dh, 4h
int 10h

mov si, seg counter
mov ds, si
mov si, offset counter
add si, 7

mov cx, 4
num_loop:  
mov bp, cx
mov ah, [si+bp]
inc ah
mov [si+bp], ah
cmp ah, 3ah
jne num_loop_end
mov ah, 30h
mov [si+bp], ah
loop num_loop
num_loop_end:   

mov bp, seg counter
mov es, bp
mov bp, offset counter
mov ah, 13h
mov al, 1
mov bh, 0
mov cx, 12
int 10h


;восстанавливаем изначальное положение курсора
mov ah, 02h
mov bh, 0
pop dx
int 10h

pop bp
pop si 
pop dx
pop cx
pop bx
pop ax
pop es
pop ds
mov sp, keep_ss
mov ss, sp
mov sp, keep_sp
mov al, 20h
out 20h, al
iret
LAST_BYTE:
interrupt endp

is_int_installed proc near
push ax
push bx
push dx
push si

mov int_installed, 1
mov ah, 35h
mov al, 1ch
int 21h
mov si, offset int_id
sub si, offset interrupt
mov dx, es:[bx+si]
cmp dx, 07777
je loaded
mov int_installed, 0

loaded: 
pop si
pop dx
pop bx
pop ax
ret
is_int_installed endp

install_int proc near
push ds
push es
push ax
push bx
push cx
push dx

mov ah, 35h
mov al, 1ch
int 21h
mov keep_ip, bx
mov keep_cs, es

mov dx, offset interrupt
mov ax, seg interrupt
mov ds, ax
mov ah, 25h
mov al, 1ch
int 21h

;сохраняем наше прерывание до LAST_BYTE
mov dx, offset LAST_BYTE
mov cl,4
shr dx,cl
inc dx
mov ax, cs
sub ax, psp
add dx, ax
xor ax, ax
mov ah,31h
int 21h

pop dx
pop cx
pop bx
pop ax
pop es
pop ds
ret
install_int endp

uninstall_int proc near
push ds
push es
push ax
push bx
push dx

cli
mov ah,35h
mov al,1ch
int 21h
mov dx, es:[offset keep_ip]
mov ax, es:[offset keep_cs]
mov ds, ax
mov ah, 25h
mov al, 1ch
int 21h

mov ax, es:[offset psp]
mov es, ax
mov dx, es:[2ch]
mov ah, 49h
int 21h
mov es, dx
mov ah, 49h
int 21h
sti

pop dx
pop bx
pop ax
pop es
pop ds
ret
uninstall_int endp

check_console proc near
push ax	

mov int_installed, 0
mov al, es:[82h]
cmp al, '/'
jne no_key
mov al, es:[83h]
cmp al, 'u'
jne no_key
mov al, es:[84h]
cmp al, 'n'
jne no_key
mov int_installed, 1	

no_key: 
pop     ax
ret
check_console endp

print proc near
push ax
mov ah, 09h
int 21h
pop ax
ret
print endp

main proc far
push ds
xor ax, ax
mov ax, data
mov ds, ax

mov psp, es
call check_console

cmp int_installed, 1
je int_unload

call is_int_installed
cmp int_installed, 0
je int_load
mov dx, offset already_loaded_msg
call print
jmp exit

int_load:  
mov dx, offset loaded_msg
call print
call install_int
jmp exit

int_unload:     
call is_int_installed
cmp int_installed, 0
je unloaded
call uninstall_int
unloaded:
mov dx, offset unloaded_msg
call print

exit:    
pop ds
mov ah, 4ch
int 21h
main endp
code ends

astack segment stack
dw 128 dup(?)
astack ends

data segment
int_installed			   db 0
loaded_msg		   db 'Interrupt loaded',0dh,0ah,'$'
unloaded_msg	   db 'Interrupt unloaded',0dh,0ah,'$'
already_loaded_msg db 'Interrupt already loaded',0dh,0ah,'$'
data ends
end main

