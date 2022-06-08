ASSUME CS:CODE, DS:DATA, SS:MY_STACK

MY_STACK SEGMENT STACK 
	DW 64 DUP(?)
MY_STACK ENDS



CODE SEGMENT

print PROC NEAR
		push ax
		mov ah, 09h
		int	21h
		pop ax
		ret
print ENDP



interr PROC FAR
		jmp start
		PSP_ADDRESS_0 dw 0                            ;3
		PSP_ADDRESS_1 dw 0	                          ;5
		KEEP_CS dw 0                                  ;7
		KEEP_IP dw 0                                  ;9
		interr_set dw 0FEDCh                 ;11
		count db 'Interrupts call count: 0000  $' ;13
	start:
		push ax      
		push bx
		push cx
		push dx

		mov ah, 03h
		mov bh, 00h
		int 10h
		push dx 
	
		mov ah, 02h
		mov bh, 00h
		mov dx, 0220h
		int 10h

		push si
		push cx
		push ds
		mov ax, SEG count
		mov ds, ax
		mov si, OFFSET count
		add si, 1Ah

		mov ah,[si]
		inc ah
		mov [si], ah
		cmp ah, 3Ah
		jne endFunc
		mov ah, 30h
		mov [si], ah	

		mov bh, [si - 1] 
		inc bh
		mov [si - 1], bh
		cmp bh, 3Ah                    
		jne endFunc
		mov bh, 30h
		mov [si - 1], bh

		mov ch, [si - 2]
		inc ch
		mov [si - 2], ch
		cmp ch, 3Ah
		jne endFunc
		mov ch, 30h
		mov [si - 2], ch

		mov dh, [si - 3]
		inc dh
		mov [si - 3], dh
		cmp dh, 3Ah
		jne endFunc
		mov dh, 30h
		mov [si - 3],dh
	
	endFunc:
		pop ds
		pop cx
		pop si
	
		push es
		push bp

		mov ax, SEG count
		mov es, ax
		mov ax, OFFSET count
		mov bp, ax
		mov ah, 13h
		mov al, 00h
		mov cx, 1Dh
		mov bh, 0
		int 10h
	
		pop bp
		pop es
	
		pop dx
		mov ah, 02h
		mov bh, 0h
		int 10h

		pop dx
		pop cx
		pop bx
		pop ax     

		iret
interr ENDP

mem_check PROC
mem_check ENDP

isSet PROC NEAR
		push bx
		push dx
		push es

		mov ah, 35h
		mov al, 1Ch
		int 21h

		mov dx, es:[bx + 11]
		cmp dx, 0FEDCh
		je isSetCheck
		mov al, 00h
		jmp ignoreIsSetCheck

	isSetCheck:
		mov al, 01h
		jmp ignoreIsSetCheck

	ignoreIsSetCheck:
		pop es
		pop dx
		pop bx

		ret
isSet ENDP


checkUN PROC NEAR
		push es
	
		mov ax, PSP_ADDRESS_0
		mov es, ax

		mov bx, 0082h

		mov al, es:[bx]
		inc bx
		cmp al, '/'
		jne UNend

		mov al, es:[bx]
		inc bx
		cmp al, 'u'
		jne UNend

		mov al, es:[bx]
		inc bx
		cmp al, 'n'
		jne UNend

		mov al, 0001h
	UNend:
		pop es

		ret
checkUN ENDP

loadInt PROC NEAR
		push ax
		push bx
		push dx
		push es

		mov ah, 35h
		mov al, 1Ch
		int 21h

		mov KEEP_IP, bx
		mov KEEP_CS, es

		push ds

		mov dx, OFFSET interr
		mov ax, seg interr
		mov ds, ax

		mov ah, 25h
		mov al, 1Ch
		int 21h

		pop ds

		mov dx, OFFSET Loading
		call print

		pop es
		pop dx
		pop bx
		pop ax

		ret
loadInt ENDP

UNloadInt PROC NEAR
		push ax
		push bx
		push dx
		push es

		mov ah, 35h
		mov al, 1Ch
		int 21h

		cli
		push ds  
	
		mov dx, es:[bx + 9]   
		mov ax, es:[bx + 7]   
		
		mov ds, ax
		mov ah, 25h
		mov al, 1Ch
		int 21h

		pop ds
		sti

		mov dx, OFFSET IsRestored
		call print

		push es	
			mov cx, es:[bx + 3]
			mov es, cx
			mov ah, 49h
			int 21h
		pop es
	
		mov cx, es:[bx + 5]
		mov es, cx
		int 21h

		pop es
		pop dx
		pop bx
		pop ax
	
		ret
UNloadInt ENDP




main PROC FAR
		mov bx, 02Ch
		mov ax, [bx]
		mov PSP_ADDRESS_1, ax
		mov PSP_ADDRESS_0, ds  
		sub ax, ax    
		xor bx, bx

		mov ax, DATA  
		mov ds, ax    

		call checkUN
		cmp al, 01h
		je UnloadCheck

		call isSet
		cmp al, 01h
		jne NotLoadedCheck
	
		mov dx, OFFSET IsLoaded
		call print
		jmp ExitCheck
       
		mov ah,4Ch
		int 21h

	NotLoadedCheck:
		call loadInt
	
		mov dx, OFFSET mem_check
		mov cl, 04h
		shr dx, cl
		add dx, 1Bh

		mov ax, 3100h
		int 21h
         
	UnloadCheck:
		call isSet
		cmp al, 00h
		je NotSetCheck
		call UNloadInt
		jmp ExitCheck

	NotSetCheck:
		mov dx, OFFSET NotSet
		call print
		jmp ExitCheck
	
	ExitCheck:
		mov ah, 4Ch
		int 21h
main ENDP

CODE ENDS
DATA SEGMENT
	NotSet db "Did not load", 0dh, 0ah, '$'
	IsRestored db "Restored", 0dh, 0ah, '$'
	IsLoaded db "Already load", 0dh, 0ah, '$'
	Loading db "Loading...", 0dh, 0ah, '$'
DATA ENDS
END main