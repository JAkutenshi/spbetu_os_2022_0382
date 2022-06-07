PCinfo	SEGMENT
		ASSUME cs:PCinfo, ds:PCinfo, es:nothing, ss:nothing
	ORG 	100h
	
start:		
	jmp		main

	;data
	available	db 'Available memory:            b$'
	extended 	db 'Extended memory:            Kb$'
	mcb 	db 'Memory control blocks:$'
	MCBtype db 'MCB type: 00h$'
	PSPadr 	db 'PSP adress: 0000h$'
	s 	db 'Size:          b$'
    endl	db  13, 10, '$'
    tab		db 	9,'$'

TETR_TO_HEX proc near
    and 	al, 0Fh
    cmp 	al, 09
    jbe 	next
    add 	al, 07
next:
    add 	al, 30h
    ret
TETR_TO_HEX endp

BYTE_TO_HEX proc near
    push 	cx
    mov 	ah, al
    call 	TETR_TO_HEX
    xchg 	al, ah
    mov 	cl, 4
    shr 	al, cl
    call 	TETR_TO_HEX 
    pop 	cx
    ret
BYTE_TO_HEX endp

WRD_TO_HEX proc near
    push 	bx
    mov 	bh, ah
    call 	BYTE_TO_HEX
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    dec 	di
    mov 	al, bh
    call 	BYTE_TO_HEX
    mov 	[di], ah
    dec 	di
    mov 	[di], al
    pop 	bx
    ret
WRD_TO_HEX endp

BYTE_TO_DEC proc near
    push 	cx
    push 	dx
    xor 	ah, ah
    xor 	dx, dx
    mov 	cx, 10
bloop:
    div 	cx
    or 		dl, 30h
    mov 	[si], dl
    dec 	si
    xor 	dx, dx
    cmp 	ax, 10
    jae 	bloop
    cmp 	al, 00h
    je 		bend
    or 		al, 30h
    mov 	[si], al
bend:
    pop 	dx
    pop 	cx
    ret
BYTE_TO_DEC endp
   
WRD_TO_DEC proc near
    push 	cx
    push 	dx
    mov  	cx, 10
wloop:   
    div 	cx
    or  	dl, 30h
    mov 	[si], dl
    dec 	si
	xor 	dx, dx
    cmp 	ax, 10
    jae 	wloop
    cmp 	al, 00h
    je 		wend
    or 		al, 30h
    mov 	[si], al
wend:      
    pop 	dx
    pop 	cx
    ret
WRD_TO_DEC endp

PRINT proc near
    push 	ax
    push 	dx
    mov 	ah, 09h
    int 	21h
    pop 	dx
    pop 	ax
    ret
PRINT endp

PRINT_SYMBOL proc near
	push	ax
	push	dx
	mov		ah, 02h
	int		21h
	pop		dx
	pop		ax
	ret
PRINT_SYMBOL endp
   


main:

;available    
	mov 	ah, 4Ah
	mov 	bx, 0ffffh
	int 	21h
    xor	dx, dx
	mov 	ax, bx
	mov 	cx, 10h
	mul 	cx
	mov  	si, offset available+27
	call 	WRD_TO_DEC
    mov 	dx, offset available
	call 	PRINT
	mov	dx, offset endl
	call	PRINT

;free
    mov 	ax,offset SegEnd
    mov 	bx, 10h
    xor 	dx, dx
    div 	bx
    inc 	ax
    mov 	bx, ax
    mov 	al, 0
    mov 	ah, 4Ah
    int 	21h
	
;extended
	mov	al, 30h
	out	70h, al
	in	al, 71h
	mov	bl, al ;младший байт
	mov	al, 31h
	out	70h, al
	in	al, 71h ;старший байт
	mov	ah, al
	mov	al, bl
    mov	si, offset extended+24
	xor 	dx, dx
	call 	WRD_TO_DEC
	mov	dx, offset extended
	call	PRINT
	mov	dx, offset endl
	call 	PRINT

;mcb
    mov		dx, offset mcb
    call 	PRINT
	mov		dx, offset endl
	call	PRINT
    mov		ah, 52h
    int 	21h
    mov 	ax, es:[bx-2]
    mov 	es, ax

	
first_check:
    ;MCBtype
	mov 	al, es:[0000h]
    call 	BYTE_TO_HEX
    mov		di, offset MCBtype+10
    mov 	[di], ax
    mov		dx, offset MCBtype
    call 	PRINT
    mov		dx, offset tab
    call 	PRINT
     
    ;PSPadr
    mov 	ax, es:[0001h]
    mov 	di, offset PSPadr+15
    call 	WRD_TO_HEX
    mov		dx, offset PSPadr
    call 	PRINT
    mov		dx, offset tab
    call 	PRINT
    
    ;Size
    mov 	ax, es:[0003h]
    mov 	cx, 10h 
    mul 	cx
	mov		si, offset s+13
    call 	WRD_TO_DEC
    mov		dx, offset s
    call 	PRINT  
    mov		dx, offset tab
    call 	PRINT
	
    ;Last
    push 	ds
    push 	es
    pop 	ds
    mov 	dx, 08h
    mov 	di, dx
    mov 	cx, 8

second_check:
	cmp		cx,0
	je		third_check
    mov		dl, byte PTR [di]
    call	PRINT_SYMBOL
    dec 	cx
    inc		di
    jmp		second_check

third_check:
	pop 	ds
	mov		dx, offset endl
    call 	PRINT
    
    ;if ends
    cmp 	byte ptr es:[0000h], 5ah
    je 		quit
    
    ;go to next
    mov 	ax, es
    add 	ax, es:[0003h]
    inc 	ax
    mov 	es, ax
    jmp 	first_check
         
quit:
    xor 	ax, ax
    mov 	ah, 4ch
    int 	21h

SegEnd:
PCinfo	ENDS
		END    START