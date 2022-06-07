AStack SEGMENT STACK
	DW 100 DUP(?)
AStack ENDS

DATA SEGMENT
LOADED db 'Loaded.' , 0DH, 0AH, '$'
INSTALLED db 'Installed.', 0DH, 0AH, '$'
UNLOADED db 'Unloaded.' , 0DH, 0AH, '$'
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
 	int 10h 
 	pop CX
	pop DX
 	pop BX
 	pop AX
    	ret
setCurs ENDP

getCurs PROC
; чтение позиции и размера курсора
;  вход: BH = видео страница
; выход: DH,DL = текущие строка, колонка курсора
;        CH,CL = текущие начальная, конечная строки курсора
 	push AX
 	push BX
 	push CX
 	mov AH,03h
	mov BH,0
 	int 10h  
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
	STOP_VAL db 0
	PROC_STACK	dw 100 dup (0)
    KEEP_SS dw 0
    KEEP_AX	dw 0
    KEEP_SP dw 0
	COUNT db '   Counts of interupt: 00000    ','$'

_ROUT:
	mov KEEP_SS, SS
	mov KEEP_AX, AX
	mov KEEP_SP, SP
   	mov AX, seg PROC_STACK
    mov SS, AX
    xor SP, SP
    mov AX, KEEP_AX
    push AX 
    push DX
    push DS
    push ES
    cmp STOP_VAL, 1
    je RES
    call getCurs
    push DX
    mov DH, 15 ; DH,DL = строка, колонка (считая от 0)
    mov DL, 25
    call setCurs
; подсчет общего числа прерываний
    push SI
    push CX 
    push DS
   	push AX
    mov AX, seg COUNT
    mov DS, AX
    mov BX, offset COUNT
    add BX, 24
    mov SI, 4
_LOOP:
    mov AH,[BX+SI]
	inc AH
    cmp AH, 3AH
    jne ROUT_NEXT
    mov AH, 30H
    mov [BX+SI], AH
    dec SI
    cmp SI, 0
    jne _LOOP
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
    mov AL, 1  
    mov CX, 31  ; число экземпляров символа для записи
    mov BH, 0   ; номер видео страницы
    int 10h  
    pop BP
    pop ES
    pop DX
    call setCurs
    jmp EXIT
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
EXIT:
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

CHECK_USER_INT PROC
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
    mov DX, offset FINAL  ; размер в байтах от начала сегмента
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
    jne INST 
    cmp byte ptr ES:[83h],'u'
    jne INST  
    cmp byte ptr ES:[84h],'n' 
    je UNL
INST: 
    pop AX
    pop ES
    mov DX, offset INSTALLED
    call PRINT
    ret
UNL:
    pop AX
    pop ES
    mov byte ptr ES:[BX+SI+10], 1
    mov DX, offset UNLOADED
    call PRINT
    ret
CHECK_USER_INT ENDP

SET_INT PROC
   	push AX
	push BX
	push DX
	push ES
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
    mov DX, offset LOADED
    call PRINT
    pop ES
	pop DX
	pop BX
	pop AX
    ret
SET_INT ENDP 

MAIN PROC FAR
    mov AX, DATA
    mov DS, AX
   	mov KEEP_PSP, ES
    call CHECK_USER_INT
    xor AL, AL
    mov AH, 4Ch
    int 21h
MAIN ENDP

	FINAL:
CODE ENDS
    END MAIN 