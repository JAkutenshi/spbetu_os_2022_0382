MYSTACK SEGMENT STACK
   DW 200 DUP(?)
MYSTACK ENDS

DATA SEGMENT
    LOADED db 'Interruption is loaded', 0DH, 0AH, '$'
    LOADED_YES db 'Interruption loading is success', 0DH, 0AH, '$'
    LOADED_NO db 'Interruption loading is not success', 0DH, 0AH, '$'
    LOADED_RESTORED db 'Interruption is restored', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:MYSTACK

    WRITE_MESSAGE_WORD  PROC  near
		push AX
		
		mov AH, 9
		int 21h
		
		pop AX
		ret
	WRITE_MESSAGE_WORD  ENDP

    INTERRUPT PROC far ;обработчик прерываний
        jmp begin
        sign dw 7777h
        keep_IP dw 0 ; для хранения сегмента
        keep_CS dw 0 ; и смещения прерывания
		psp_address dw ?
        keep_SS dw 0
        keep_SP dw 0
        keep_AX dw 0
        my_stack dw 16 dup(?)
		key DB 0

    begin:
        mov keep_SP, SP
        mov keep_AX, AX
        mov keep_SS, SS
		
        mov SP, offset begin
        mov AX, seg my_stack
        mov SS, AX
		
        push AX ;сохранение изменяемых регистров
        push CX 
        push DX
		push ES
		push SI

        mov AX, seg key
		mov DS, AX
		
		in AL, 60h ;читать ключ
		
		cmp AL, 10h ;это требуемый код?
		je key_q ;да, активизировать обработку
		
		cmp AL, 13h
		je key_r
		
		cmp AL, 24h
		je key_j
		
		pushf
		call dword ptr CS:keep_IP
		jmp fin
		
		key_q:
			mov key, 'g'
			jmp next_step
		key_r:
			mov key, 'u'
			jmp next_step
		key_j:
			mov key, 't'
			jmp next_step
			
		next_step:
			in al,61h ;взять значение порта управления клавиатурой
			mov ah,al ; сохранить его
			or al,80h ;установить бит разрешения для клавиатуры
			out 61h,al ; и вывести его в управляющий порт
			xchg ah,al ;извлечь исходное значение порта
			out 61h,al ;и записать его обратно
			mov al,20h ;послать сигнал "конец прерывания"
			out 20h,al ; контроллеру прерываний 8259
			
		key_print:
			mov ah,05h ; Код функции
			mov cl, key ; Пишем символ в буфер клавиатуры
			mov ch,00h ; 
			int 16h ;
			or al,al ; проверка переполнения буфера
			jz fin
			mov AX, 0040h
			mov ES, AX
			mov AX, ES:[1AH]
			mov ES:[1ch], AX
			jmp key_print
			
		fin:
			pop SI
			pop ES
			pop DX
			pop CX 
			pop AX 
			
		mov SP, keep_SP
		mov SS, keep_SS
		mov AX, keep_AX
		mov AL, 20h
		out 20h, al
		
		iret
        INTERRUPT_last:
	INTERRUPT ENDP

	CHECK_UN PROC near ;kk
		push AX
		push BP
	
		mov CL, 0h
		mov BP, 81h
		mov AL, ES:[BP + 1]
		cmp AL, '/'
		jne finish
	
		mov AL, ES:[BP + 2]
		cmp AL, 'u'
		jne finish
	
		mov AL, ES:[BP + 3]
		cmp AL, 'n'
		jne finish
		
		mov CL, 1h

		finish:
			pop BP
			pop AX
		ret
	CHECK_UN ENDP


	IS_LOADED PROC near ;kk
		push AX
		push DX
		push ES
		push SI
	
		mov CL, 0h
		mov AH, 35h
		mov AL, 09h ;  с вектором 09h
		int 21h
		
		mov SI, offset sign
		sub SI, offset INTERRUPT
		mov DX, ES:[BX+SI]
		cmp DX, sign
		jne if_end
		mov CL, 1h 

		if_end:
			pop SI
			pop ES
			pop DX
			pop AX
		ret
	IS_LOADED ENDP


	LOAD PROC near 
		push AX
		push CX
		push DX
	
		call IS_LOADED
		cmp CL, 1h
		je already_load
	
		mov psp_address, ES 
		;загрузка обработчика прерывания
		mov AH, 35h ; функция получения вектора
		mov AL, 09h ; номер вектора
		int 21h
	
		mov keep_CS, ES ; запоминание сегмента
		mov keep_IP, BX ; и смещения
	
		push ES
		push BX
		push DS
	
		;настройка прерывания
		lea DX, INTERRUPT  ; смещение для процедуры в DX
		mov AX, seg INTERRUPT ; сегмент процедуры
		mov DS, AX  ; помещаем в DS
		mov AH, 25h ; функция установки вектора
		mov AL, 09h ; номер вектора
		int 21h ;нменяем прерывание
	
		pop DS
		pop BX
		pop ES
	
		mov DX, offset LOADED_YES
		call WRITE_MESSAGE_WORD
		lea DX, INTERRUPT_last
		mov CL, 4h
		shr DX, CL
		inc DX 
		add DX, 100h
		xor AX,AX
		mov AH, 31h
		int 21h
	
		jmp end_load

		already_load:
     	mov DX, offset LOADED
        call WRITE_MESSAGE_WORD

		end_load:
			pop DX
			pop CX
			pop AX
		ret
	LOAD ENDP


	UNLOAD PROC near ;kk
		push AX
		push SI
	
		call IS_LOADED
		cmp CL, 1h
		jne not_load
	
		;при выгрузке обработчика прерывания
		cli
	
		push DS
		push ES
		mov AH, 35h
		mov AL, 09h
		int 21h ; восстанавливаем вектор
	
		mov SI, offset keep_IP
		sub SI, offset INTERRUPT
		mov DX, ES:[BX+SI]
		mov AX, ES:[BX+SI+2]
		mov DS, AX
		mov AH, 25h
		mov AL, 09h
		int 21h
	
		mov AX, ES:[BX+SI+4]
		mov ES, AX
	
		push ES
	
		mov AX, ES:[2ch]
		mov ES, AX
		mov AH, 49h
		int 21h
	
		pop ES
		mov AH, 49h
		int 21h
	
		pop ES
		pop DS
		sti
		mov DX, offset LOADED_RESTORED
		call WRITE_MESSAGE_WORD
		jmp end_unload

		not_load:
			mov DX, offset LOADED_NO
			call WRITE_MESSAGE_WORD

		end_unload:
			pop SI
			pop AX
		ret
    UNLOAD ENDP

    MAIN PROC far
		sub AX, AX
       	mov AX, DATA
       	mov DS, AX
		
        call CHECK_UN ;проверка на /un
        cmp CL, 0h
        jne un
        call LOAD ;загрузить
        jmp end_main

		un:
			call UNLOAD ;выгрузить

		end_main:
			xor AL, AL
			mov AH, 4ch
        int 21h
    MAIN ENDP

CODE ENDS

END MAIN