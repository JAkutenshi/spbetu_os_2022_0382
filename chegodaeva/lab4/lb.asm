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

setCurs PROC
;Установка позиции курсора
 	push AX
 	push BX
	push DX
 	push CX
 	mov AH,02h
	mov BH,0
 	int 10h   ; выполнение.
 	pop CX
	pop DX
 	pop BX
 	pop AX
    	ret
setCurs ENDP

getCurs PROC
; 03H читать позицию и размер курсора
;  вход: BH = видео страница
; выход: DH,DL = текущие строка, колонка курсора
;        CH,CL = текущие начальная, конечная строки курсора
 	push AX
 	push BX
 	push CX
 	mov AH,03h
	mov BH,0
 	int 10h    ; выполнение.
 	pop CX
 	pop BX
	pop AX
    	ret
getCurs ENDP

ROUT PROC FAR
    jmp _ROUT
	
    	SIGN db '0000'
   	KEEP_CS dw 0    ; для хранения сегмента
    	KEEP_IP dw 0    ; и смещения прерывания
   	KEEP_PSP dw 0
	VAL db 0
	_STACK	dw 100 dup (0)
    	KEEP_SS dw 0
    	KEEP_AX	dw 0
    	KEEP_SP dw 0
	COUNT db '   Number of calls: 00000    ','$'

_ROUT:
    	mov KEEP_SS, SS
    	mov KEEP_AX, AX
    	mov KEEP_SP, SP
   	mov AX, seg _STACK
    	mov SS, AX
    	mov SP, 0
    	mov AX, KEEP_AX
    	push AX 
    	push DX
    	push DS
    	push ES
    	cmp VAL, 1
    	je RES
    	call getCurs
    	push DX
    	mov DH, 23 ; DH,DL = строка, колонка (считая от 0)
    	mov DL, 0
    	call setCurs
ROUT_SUM:
    	push SI
    	push CX 
    	push DS
   	push AX
    	mov AX, seg COUNT
    	mov DS, AX
    	mov BX, offset COUNT
    	add BX, 21
    	mov SI, 3
lp:
    	mov AH,[BX+SI]
	add AH, 1
    	cmp AH, 58
    	jne ROUT_NEXT
    	mov AH, 48
    	mov [BX+SI], AH
    	sub SI, 1
    	cmp SI, 0
    	jne lp
ROUT_NEXT:
    	mov [BX+SI], AH
    	pop DS 
    	pop SI
    	pop BX
    	pop AX 
    	push ES
   	push BP
    	mov AX, seg COUNT
    	mov ES, AX
    	mov AX, offset COUNT
    	mov BP, AX
    	mov AH, 13h 
    	mov AL, 1   ; sub function code
    	mov CX, 28  ; число экземпляров символа для записи
    	mov BH, 0   ; номер видео страницы
    	int 10h     ; выполнить функцию
    	pop BP
    	pop ES
    	pop DX
    	call setCurs
    	jmp FINAL
RES:
    	cli
    	mov DX, KEEP_IP
    	mov AX, KEEP_CS
    	mov DS, AX
    	mov AH, 25h  
 	mov AL, 1CH  
 	int 21H      ; восстанавливаем вектор
    	mov ES, KEEP_PSP 
    	mov ES, ES:[2Ch]
    	mov AH, 49h  
    	int 21h
    	mov ES, KEEP_PSP
    	mov AH, 49h
    	int 21h
    	sti
FINAL:
    	pop ES
    	pop DS
    	pop DX
    	pop AX 
   	mov AX, KEEP_SS
    	mov SS, AX 
    	mov SP, KEEP_SP
    	mov AX, KEEP_AX

	mov AL, 20H
 	out 20H,AL

    	iret
ROUT ENDP

CHECK PROC
    	mov AH, 35h        ; функция получения вектора
    	mov AL, 1Ch        ; номер вектора
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
    	mov byte ptr ES:[BX+SI+10], 1
    	mov DX, offset UNLOADED
    	call PRINT
    	ret
CHECK ENDP

SET_INT PROC
   	push DX
    	push DS
    	mov AH, 35h         ; функция получения вектора
    	mov AL, 1Ch         ; номер вектора
    	int 21h            
    	mov KEEP_IP, BX     ; запоминание смещения
    	mov KEEP_CS, ES     ; и сегмента

    	mov dx, offset ROUT ; смещение для процедуры в DX
    	mov ax, seg ROUT    ; сегмент процедуры
   	mov DS, AX          ; помещаем в DS
    	mov AH, 25h         ; функция установки вектора
    	mov AL, 1Ch         ; номер вектора
    	int 21h             ; меняем прерывание
    	pop DS
    	mov DX, offset LOADING
    	call PRINT
    	pop DX
    	ret
SET_INT ENDP 

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