TESTPC	SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START:	JMP  BEGIN

AVAILABLE_MEMORY db 'Available memory: $'
EXTENDED_MEMORY db 'Extended memory: $'
MCB_TABLE db 'MCB table:', 0DH, 0AH, '$'
TABLE_ADDRESS db 'Address:      $'
SPACE db ' $'
PSP_ADDRESS db 'PSP address:      $'
AREA_SIZE db 'Area size: $'
SC_SD db 'SC/SD: $'

TETR_TO_HEX PROC near
		and AL, 0Fh
		cmp AL, 09
		jbe NEXT
		add AL, 07
NEXT:	add AL, 30h
		ret
TETR_TO_HEX ENDP

BYTE_TO_HEX	PROC near
		push CX
		mov AH, AL
		call TETR_TO_HEX
		xchg AL, AH
		mov CL, 4
		shr AL, CL
		call TETR_TO_HEX
		pop CX
		ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
		push BX
		mov BH, AH
		call BYTE_TO_HEX
		mov [DI], AH
		dec DI
		mov [DI], AL
		dec DI
		mov AL, BH
		call BYTE_TO_HEX
		mov [DI], AH
		dec DI
		mov [DI], AL
		pop BX
		ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near
		push CX
		push DX
		xor AH, AH
		xor DX, DX
		mov CX, 10
loop_bd:	div CX
		or DL, 30h
		mov [SI], DL
		dec SI
		xor DX, DX
		cmp AX, 10
		jae loop_bd
		cmp AL, 00h
		je end_l
		or AL, 30h
		mov [SI], AL
end_l:	pop DX
		pop CX
		ret
BYTE_TO_DEC ENDP

WRITE_MESSAGE_BYTE PROC near
	push AX
	mov AH, 02h
	int 21h
	pop AX
	ret
WRITE_MESSAGE_BYTE ENDP

WRITE_MESSAGE_WORD PROC near ;вывести строку
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
WRITE_MESSAGE_WORD ENDP

TO_DEC PROC near ; доступная память в десятичном виде
	push BX
	push CX
	push AX
	push DX
	push DI
	
	xor CX, CX
	mov BX, 10
	
	lp1:
		div BX
	    push DX
		xor DX, DX
		inc CX
		cmp AX, 0
		jne lp1  ;получение остатка числа при делении на 10 пока не останется 0, все заносится в стек
		
	lp2:
		pop DX
		add DL, '0' ;
		call WRITE_MESSAGE_BYTE
		loop lp2	;извлечение из стека чисел, перевод в символы и вывод
		
	pop DI
	pop DX
	pop AX
	pop CX
	pop BX
	ret
TO_DEC ENDP

PRINT_AVAILABLE_MEMORY PROC near ;вывести свободную память
	push DX
	push AX
	push BX

	mov DX, offset AVAILABLE_MEMORY
	call WRITE_MESSAGE_WORD

	mov AH, 4ah ;освободить неисользованную память, в BX заносится доступная память под программу
	mov BX, 0ffffh
	int 21h

	mov AX, BX ;в AX заносится доступная память под программу (в параграфах)
	mov BX, 16
	mul BX ;в BX заносится 16, в AX заносится результат перемножения содержимых AX*BX (перевод параграфов в байты)
	
	call TO_DEC
	
	mov DL, 0dh
	call WRITE_MESSAGE_BYTE
	mov DL, 0ah
	call WRITE_MESSAGE_BYTE
	
	pop BX
	pop AX
	pop DX
	ret
PRINT_AVAILABLE_MEMORY ENDP

PRINT_EXTENDED_MEMORY PROC near
	push DX
	push AX
	push BX
	
	mov DX, offset EXTENDED_MEMORY
	call WRITE_MESSAGE_WORD
	
	mov AL, 30h ; запись адреса ячейки 
	out 70h, AL ; 30h в выходной порт 70h
	in AL, 71h ; чтение младшего байта размера расширенной памяти (из входного порта в AL)
	mov BL, AL ; в BL младший байт
	mov AL, 31h  
	out 70h, AL 
	in AL, 71h ; чтение старщего байта размера расширенной памяти
	
	mov BH, AL ;в BH старший байт
	mov AX, BX 
	
	mov BX, 16
	mul BX
	
	call TO_DEC
	
	mov DL, 0dh
	call WRITE_MESSAGE_BYTE
	mov DL, 0ah
	call WRITE_MESSAGE_BYTE
	
	pop BX
	pop AX
	pop DX
	ret
PRINT_EXTENDED_MEMORY ENDP

PRINT_MCB_TABLE PROC near
	push DX
	push AX
	push BX
	push CX
	push SI
	
	mov DX, offset MCB_TABLE
	call WRITE_MESSAGE_WORD
	
	mov AH, 52h ; в AH список списков MCB таблицы
	int 21h
	mov AX, ES:[BX-2] ; адрес начала таблицы
	mov ES, AX
	
	lp3:
		mov AX, ES
		mov DI, offset TABLE_ADDRESS
		add DI, 12
		call WRD_TO_HEX
		mov DX, offset TABLE_ADDRESS
		call WRITE_MESSAGE_WORD ;вывод адресса
		
		mov AX, ES:[1]
		mov DI, offset PSP_ADDRESS
		add DI, 16
		call WRD_TO_HEX 
		mov DX, offset PSP_ADDRESS
		call WRITE_MESSAGE_WORD ;вывод PSP-адресса
		
		mov DX, offset AREA_SIZE
		call WRITE_MESSAGE_WORD ;вывод размера участка
		mov AX, ES:[3]
		mov DI, 11
		mov BX, 16
		mul BX
		call TO_DEC
		
		mov DX, offset SPACE
		call WRITE_MESSAGE_WORD
		
		mov DX, offset SC_SD
		call WRITE_MESSAGE_WORD
		
		mov BX, 8 ; для вывода последних 8 байт таблицы
		mov CX, 7
		
		lp4:
			mov DL, ES:[BX]
			call WRITE_MESSAGE_BYTE
			inc BX
			loop lp4 ; вывод последних 8 байт (индексы в списке у них 1-15)
		
		mov DL, 0dh
		call WRITE_MESSAGE_BYTE
		mov DL, 0ah
		call WRITE_MESSAGE_BYTE
		
		mov AL, ES:[0h]
		cmp AL, 5ah ; если в типе списка MCB записано 5ah - он последний (в других случаях 4dh)
		je finish
		
		mov AX, ES
		inc AX
		mov BX, ES:[3h]
		add AX, BX
		mov ES, AX ;переход к другому списку (по смещению размер текущего списка + 1)
		jmp lp3
		
	finish:
		pop SI
		pop CX
		pop BX
		pop AX
		pop DX
		ret
PRINT_MCB_TABLE ENDP

FREE PROC near
	push AX
	push BX
	push DX
	
	xor DX, DX
	lea AX, FINISH_CODE ;текущий адрес конца программы в AX
	mov BX, 10h
	div BX
	add AX, DX
	mov BX, AX ;В BX занятый размер памяти
	xor AX, AX
	
	mov AH, 4ah
	int 21h ;высвобождение неиспользованной памяти
	
	pop DX
	pop BX
	pop AX
ret
FREE ENDP

BEGIN:
	call PRINT_AVAILABLE_MEMORY
	call PRINT_EXTENDED_MEMORY
	call FREE
	call PRINT_MCB_TABLE
	
	xor AL, AL
	mov AH, 4ch
	int 21h

FINISH_CODE:
TESTPC ENDS
END START