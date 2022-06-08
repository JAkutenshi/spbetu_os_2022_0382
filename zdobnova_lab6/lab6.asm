MY_STACK SEGMENT STACK
	dw 128 dup (?)
MY_STACK ENDS

CODE SEGMENT
	ASSUME CS: CODE, DS: CODE, SS:MY_STACK
	
	KEEP_PGPH 	db 14 dup(0)   	
	KEEP_PATH 	db 50 dup(0)  
	KEEP_SS 	dw 0
	KEEP_SP 	dw 0
	lab2 	db 'lab2.com', 0
	retCode 	db 'Returned: $'
	nextLine	db  13, 10, '$'

	term_1 		db 'Normal$'
	term_2 		db '^C$'
	term_3 		db 'Error with device$'
	term_4 		db 'int 31h$'
	term_5 		db 'Unknown error$'

	err_0		db 'Error! Memory can not be allocated!$'
	err_1 		db 'Error! Wrong number!$'
	err_2 		db 'Error! No file found!$'
	err_3 		db 'Error! Disk error!$'
	err_4 		db 'Error! Need more memory!$'
	err_5 		db 'Error! Wrong enviroment!$'
	err_6 		db 'Error! Wrong format!$'
	err_7 		db 'Error! Unknown error!$'

print PROC NEAR
		push ax
		mov ah, 09h
		int 21h
		pop ax
		ret
print ENDP

main PROC NEAR	
		mov 	ax, seg code
		mov 	ds, ax
		mov		bx, seg code
		add		bx, OFFSET EndProg
		add		bx, 256
		mov 	cl, 4h
		shr 	bx, cl
		mov		ah, 4Ah
		int 	21h
		jnc		memCheck
		mov		dx, OFFSET err_0
		call	print
		mov		dx,	OFFSET nextLine
		call	print
		jmp		return

	memCheck:	
		mov		es, es:[002Ch]
		xor		bx, bx


	check_0:
		mov 	dl, byte PTR es:[bx] 
		cmp 	dl, 0h
		je 		ch1
		inc 	bx
		jmp 	check_0

	ch1:
		inc 	bx
		mov 	dl, byte PTR es:[bx] 
		cmp 	dl, 0h
		je 		ch2
		jmp 	check_0

	ch2:		
		add		bx,3	
		push	si
		mov		si, OFFSET KEEP_PATH

	check_1:	
		mov 	dl, byte PTR es:[bx]
		mov		[si], dl
		inc		si
		inc		bx
		cmp		dl, 0
		jne		check_1
	
	check_2:
		mov		al, [si]
		cmp		al, '\'
		je		check_3
		dec		si
		jmp		check_2
	
	check_3:	
		inc		si
		push	di
		mov		di, OFFSET lab2


	check_4:
		mov		ah, [di]
		mov		[si], ah
		inc		si
		inc		di
		cmp		ah, 0
		jne		check_4
	
		pop		di
		pop		si

		mov		KEEP_SP, sp
		mov		KEEP_SS, ss
		mov		ax, ds
		mov		es, ax

		mov		bx, OFFSET KEEP_PGPH
		mov		dx, OFFSET KEEP_PATH
		mov		ax, 4B00h
		int 	21h

		mov		dx, OFFSET nextLine
		call	print
		jc 		err1Check
		jmp		NoErr
	
	err1Check:	
		cmp 	ax, 1
		jne 	err2Check
		mov 	dx, OFFSET err_1
		jmp		printErr	
	
	err2Check:	
		cmp 	ax, 2
		jne 	err3Check
		mov 	dx, OFFSET err_2
		jmp		printErr	
	
	err3Check:	
		cmp 	ax, 5
		jne 	err4Check
		mov 	dx, OFFSET err_3
		jmp		printErr	
	
	err4Check:	
		cmp 	ax, 8
		jne 	err5Check
		mov 	dx, OFFSET err_4
		jmp		printErr	

	err5Check:	
		cmp 	ax, 10
		jne 	err6Check
		mov 	dx, OFFSET err_5
		jmp		printErr	

	err6Check:	
		cmp 	ax, 11
		jne 	err7Check
		mov 	dx, OFFSET err_6
		jmp		printErr	

	err7Check:	
		mov 	dx, OFFSET err_7
		jmp		printErr	

	printErr:
		call	print
		mov		dx, OFFSET nextLine
		call	print
		jmp		return

	NoErr:
		mov 	ax, seg code
		mov 	ds, ax
		mov 	ss, KEEP_SS
		mov 	sp, KEEP_SP

		mov 	ah, 4Dh
		int 	21h
	
		push 	ax
		
		cmp 	ah, 0
		jne 	term2Check
		mov		dx, OFFSET term_1
		jmp		printTerm	

	term2Check:	
		cmp 	ah, 1
		jne 	term3Check
		mov		dx, OFFSET term_2
		jmp		printTerm	

	term3Check:	
		cmp 	ah, 2
		jne 	term4Check
		mov		dx, OFFSET term_3
		jmp		printTerm

	term4Check:	
		cmp 	ah, 3
		jne 	term5Check
		mov		dx, OFFSET term_4
		jmp		printTerm
	
	term5Check:
		mov		dx, OFFSET term_5

	printTerm:
		call	print
		mov		dx, OFFSET nextLine
		call	print
		jmp		ExitCode
	
	ExitCode:	
		mov		dx, OFFSET retCode
		call	print
		pop		ax
		mov 	dl, al
		mov		ah, 02h
		int		21h
		mov		dx, OFFSET nextLine
		call	print

	return:	
		xor 	al, al
		mov 	ah, 4Ch
		int 	21h
		ret	
main ENDP
EndProg:  
CODE ENDS
END main