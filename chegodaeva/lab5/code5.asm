AStack SEGMENT STACK
	DW 100 DUP(?)
AStack ENDS

DATA SEGMENT
LOADING  db 'User interrupt loaded...' , 0DH, 0AH, '$'
LOADED   db 'User interrupt installed!', 0DH, 0AH, '$'
UNLOADED db 'User interrupt unloaded!' , 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack

PRINT PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP

ROUT PROC far
    	jmp _ROUT

	_STACK dw 100 dup (0)
	SIGN db '0000'
	KEEP_IP dw 0 
   	KEEP_CS dw 0       
   	KEEP_PSP dw 0
    	KEEP_SS dw 0
    	KEEP_AX	dw 0
    	KEEP_SP dw 0  
	OLD db 26h
    	NEW db 03h

_ROUT:
    	mov KEEP_SS, SS
    	mov KEEP_AX, AX
    	mov KEEP_SP, SP
   	mov AX, seg _STACK
    	mov SS, AX
    	mov SP, 0
    	mov AX, KEEP_AX

   	in AL, 60h   ;читать ключ
    	cmp AL, OLD  ;это требуемый код?
    	je DO_REQ    ;да,активизировать обработку REQ_KEY
 		     ;нет,уйти на исходный обработчик
    	pushf
    	call dword ptr KEEP_IP  ;переход на первоначальный обработчик
    	jmp FINAL

DO_REQ:
    	push AX
    	in al, 61h   ;взять значение порта управления клавиатурой
    	mov AH, AL   ;сохранить его
   	or AL, 80h   ;установить бит разрешения для клавиатуры
    	out 61h, AL  ;и вывести его в управляющий порт
    	xchg AH, AL  ;извлечь исходное значение порта
    	out 61h, AL  ;и записать его обратно
    	mov AL, 20h  ;послать сигнал "конец прерывания"
    	out 20h, AL  ;контроллеру прерываний 8259
    	pop AX

UPDATE:
    	mov AL, 0 
    	mov AH, 05h   ;Код функции
    	mov CL, NEW   ;Пишем символ в буфер клавиатуры
    	mov CH, 00h
    	int 16h
    	or AL, AL     ;проверка переполнения буфера
    	jz FINAL      
    	jmp UPDATE

FINAL:
    	pop ES
    	pop DS
    	pop DX
    	pop AX
    	mov AX,KEEP_SS
    	mov SS, AX
    	mov SP, KEEP_SP
    	mov AX, KEEP_AX

	mov AL, 20h
    	out 20h, AL

    	iret
ROUT ENDP


CHECK PROC
    	mov AH, 35h        ; функция получения вектора
    	mov AL, 09h        ; номер вектора
    	int 21h 		
    	mov SI, offset SIGN 
    	sub SI, offset ROUT 
    	mov AX,'00'
   	cmp AX, ES:[BX+SI] 
    	jne UNLOAD 
    	cmp AX, ES:[BX+SI+2] 
    	je LOAD

UNLOAD:
    	call SET_INT
    	mov DX, offset LAST_BYTE  ; размер в байтах от начала сегмента
    	mov CL, 4                 ; перевод в параграфы
    	shr DX, CL
    	inc DX                    ; размер в параграфах
    	add DX, CODE
    	sub DX, KEEP_PSP
    	xor AL, AL
    	mov AH, 31h 
   	int 21h

LOAD:
    	push ES
    	push AX
    	mov AX, KEEP_PSP 
    	mov ES, AX
    	cmp byte ptr ES:[82h],'/'
    	jne stop 
    	cmp byte ptr ES:[83h],'u'
    	jne stop  
    	cmp byte ptr ES:[84h],'n' 
    	je _UNLOAD

stop: 
    	pop AX
    	pop ES
    	mov DX, offset LOADED
    	call PRINT
    	ret

_UNLOAD:
    	pop AX
    	pop ES
    	call DEL_INT
    	mov DX, offset UNLOADED
    	call PRINT
    	ret
CHECK ENDP

SET_INT PROC
   	push DX
    	push DS
    	mov AH, 35h         ; функция получения вектора
    	mov AL, 09h         ; номер вектора
    	int 21h            
    	mov KEEP_IP, BX     ; запоминание смещения
    	mov KEEP_CS, ES     ; и сегмента

    	mov DX, offset ROUT ; смещение для процедуры в DX
    	mov AX, seg ROUT    ; сегмент процедуры
   	mov DS, AX          ; помещаем в DS
    	mov AH, 25h         ; функция установки вектора
    	mov AL, 09h         ; номер вектора
    	int 21h             ; меняем прерывание
    	pop DS
    	mov DX, offset LOADING
    	call PRINT
    	pop DX
    	ret
SET_INT ENDP 

DEL_INT PROC
	CLI
    	push DS
    	mov DX, ES:[BX+SI+4]
    	mov AX, ES:[BX+SI+6]
    	mov DS, AX
    	mov AX, 2509h
    	int 21h
	push ES
    	mov AX, ES:[BX+SI+8]
    	mov ES, AX
    	mov ES, ES:[2Ch]
    	mov AH, 49h
    	int 21h
	pop ES
	mov ES, ES:[BX+SI+8]
    	mov AH, 49h
    	int 21h
	pop DS
    	STI
    	ret
DEL_INT ENDP

Main PROC FAR
    	mov AX, DATA
    	mov DS, AX
   	mov KEEP_PSP, ES
    	call CHECK
    	xor AL, AL
    	mov AH, 4Ch
    	int 21h
Main ENDP

	LAST_BYTE:
CODE ENDS
    END Main