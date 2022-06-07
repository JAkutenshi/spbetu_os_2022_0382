CODE SEGMENT
ASSUME  CS:CODE, DS:DATA, SS:MY_STACK

MY_STACK SEGMENT STACK
 dw  256 dup(0)
MY_STACK  ENDS

DATA SEGMENT
    NotSet db "Did not load", 0dh, 0ah, '$'
	IsRestored db "Restored", 0dh, 0ah, '$'
	IsLoaded db "Already load", 0dh, 0ah, '$'
	Loading db "Loading...", 0dh, 0ah, '$'
    IS_LOAD  db  0
    IS_UN db  0
DATA ENDS


;Начало прерывания
inter PROC FAR
        jmp  start

    interdata:
    ;Здесь будем хранить информацию об измененных значениях
        keyInf db 0
        SIGN dw 6666h
        KEEP_IP dw 0
        KEEP_CS dw 0
        KEEP_PSP dw 0
        KEEP_AX dw 0
        KEEP_SS dw 0
        KEEP_SP dw 0
        BUFF dw 256 dup(0)
		
    start:
        mov KEEP_AX, ax
        mov KEEP_SP, sp
        mov KEEP_SS, ss
        mov ax, seg BUFF
        mov ss, ax
        mov ax, offset BUFF
        add ax, 256
        mov sp, ax	

        push ax
        push bx
        push cx
        push dx
        push si
        push es
        push ds
        mov ax, seg keyInf
        mov ds, ax
    
        in al, 60h
        cmp al, 10h	
        je key_1
        cmp al, 11h
        je key_2
        cmp al, 12h
        je key_3
    
        pushf
        call dword ptr cs:KEEP_IP
        jmp inter_end

    key_1:
        mov keyInf, '1'
        jmp next
    key_2:
        mov keyInf, '2'
        jmp next
    key_3:
        mov keyInf, '3'

    next:
        in al, 61h
        mov ah, al
        or 	al, 80h
        out 61h, al
        xchg al, al
        out 61h, al
        mov al, 20h
        out 20h, al
  
    print:
        mov ah, 05h
        mov cl, keyInf
        mov ch, 00h
        int 16h
        or 	al, al
        jz 	inter_end
        mov ax, 0040h
        mov es, ax
        mov ax, es:[1ah]
        mov es:[1ch], ax
        jmp print

    inter_end:
        pop  ds
        pop  es
        pop	 si
        pop  dx
        pop  cx
        pop  bx
        pop	 ax

        mov sp, KEEP_SP
        mov ax, KEEP_SS
        mov ss, ax
        mov ax, KEEP_AX

        mov  al, 20h
        out  20h, al
        iret
inter ENDP
 _end:

isSet PROC
        push ax
        push bx
        push si
    
        mov  ah, 35h
        mov  al, 09h
        int  21h
        mov  si, offset SIGN
        sub  si, offset inter
        mov  ax, es:[bx + si]
        cmp	 ax, SIGN
        jne  isSetCheck
        mov  is_load, 1
    
    isSetCheck:
        pop  si
        pop  bx
        pop  ax
        ret
isSet ENDP

loadInt  PROC
        push ax
        push bx
        push cx
        push dx
        push es
        push ds

        mov ah, 35h
        mov al, 09h
        int 21h
        mov KEEP_CS, es
        mov KEEP_IP, bx
        mov ax, seg inter
        mov dx, offset inter
        mov ds, ax
        mov ah, 25h
        mov al, 09h
        int 21h
        pop ds

        mov dx, offset _end
        mov cl, 4h
        shr dx, cl
        add	dx, 10fh
        inc dx
        xor ax, ax
        mov ah, 31h
        int 21h

        pop es
        pop dx
        pop cx
        pop bx
        pop ax
        ret
loadInt  ENDP

UNloadInt PROC
        cli
        push ax
        push bx
        push dx
        push ds
        push es
        push si
    
        mov ah, 35h
        mov al, 09h
        int 21h
        mov si, offset KEEP_IP
        sub si, offset inter
        mov dx, es:[bx + si]
        mov ax, es:[bx + si + 2]
 
        push ds
        mov ds, ax
        mov ah, 25h
        mov al, 09h
        int 21h
        pop ds
    
        mov ax, es:[bx + si + 4]
        mov es, ax
        push es
        mov ax, es:[2ch]
        mov es, ax
        mov ah, 49h
        int 21h
        pop es
        mov ah, 49h
        int 21h
    
        sti
    
        pop si
        pop es
        pop ds
        pop dx
        pop bx
        pop ax
 
        ret
UNloadInt ENDP

checkUN  PROC
        push ax
        push es

        mov ax, KEEP_PSP
        mov es, ax
        cmp byte ptr es:[82h], '/'
        jne UNend
        cmp byte ptr es:[83h], 'u'
        jne UNend
        cmp byte ptr es:[84h], 'n'
        jne UNend
        mov is_un, 1
 
    UNend:
        pop es
        pop ax
        ret
checkUN ENDP

printRes PROC near
        push ax
		mov ah, 09h
		int	21h
		pop ax
		ret
printRes ENDP

main PROC
        push ds
        xor ax, ax
        push ax
        mov ax, data
        mov ds, ax
        mov KEEP_PSP, es
    
        call isSet

        call checkUN

        cmp is_un, 1
        je UnloadCheck
        mov al, is_load
        cmp al, 1
        jne NotSetCheck
        mov dx, offset IsLoaded

        call printRes

        jmp ExitCheck

    NotSetCheck:
        mov dx, offset Loading

        call printRes

        call loadInt

        jmp  ExitCheck

    UnloadCheck:
        cmp  is_load, 1
        jne  NotLoadedCheck
        mov dx, offset IsRestored

        call printRes

        call UNloadInt

        jmp  ExitCheck

    NotLoadedCheck:
        mov  dx, offset NotSet

        call printRes

    ExitCheck:
        xor al, al
        mov ah, 4ch
        int 21h
main ENDP

CODE ENDS

END main