AStack SEGMENT STACK
	DW 200 DUP(?)
AStack ENDS

DATA SEGMENT
SET db 'User interrupt set' , 0DH, 0AH, '$'
ASSIGN   db 'User interrupt assigned', 0DH, 0AH, '$'
DIS db 'User interrupt discharged' , 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack

print PROC 
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
print ENDP

setCurs PROC
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

; 03H читать позицию и размер курсора
;  вход: BH = видео страница
; выход: DH,DL = текущие строка, колонка курсора
;        CH,CL = текущие начальная, конечная строки курсора
getCurs PROC
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
	VAL db 0
	_STACK	dw 100 dup (0)
    	KEEP_SS dw 0
    	KEEP_AX	dw 0
    	KEEP_SP dw 0
	NUMBER db ' quantity of calls: 00000    ','$'

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
    	mov DH, 23 
    	mov DL, 0
    	call setCurs
ROUT_SUM:
    	push SI
    	push CX 
    	push DS
   	push AX
    	mov AX, seg NUMBER
    	mov DS, AX
    	mov BX, offset NUMBER
    	add BX, 21
    	mov SI, 3
loop_for_route:
    	mov AH,[BX+SI]
	add AH, 1
    	cmp AH, 58
    	jne ROUT_NEXT
    	mov AH, 48
    	mov [BX+SI], AH
    	sub SI, 1
    	cmp SI, 0
    	jne loop_for_route
ROUT_NEXT:
    	mov [BX+SI], AH
    	pop DS 
    	pop SI
    	pop BX
    	pop AX 
    	push ES
   	push BP
    	mov AX, seg NUMBER
    	mov ES, AX
    	mov AX, offset NUMBER
    	mov BP, AX
    	mov AH, 13h 
    	mov AL, 1   
    	mov CX, 28 
    	mov BH, 0   
    	int 10h    
    	pop BP
    	pop ES
    	pop DX
    	call setCurs
    	jmp The_end
RES:
    	cli
    	mov DX, KEEP_IP
    	mov AX, KEEP_CS
    	mov DS, AX
    	mov AH, 25h  
 	mov AL, 1CH  
 	int 21H      
    	mov ES, KEEP_PSP 
    	mov ES, ES:[2Ch]
    	mov AH, 49h  
    	int 21h
    	mov ES, KEEP_PSP
    	mov AH, 49h
    	int 21h
    	sti
The_end:
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

Control PROC
    	mov AH, 35h        
    	mov AL, 1Ch        
    	int 21h 		
    	mov SI, offset SIGN 
    	sub SI, offset ROUT 
    	mov AX,'00'
   	cmp AX, ES:[BX+SI] 
    	jne Upload 
    	cmp AX, ES:[BX+SI+2] 
    	je Download
Upload:
    	call Int_Setting
    	mov DX, offset Size_in_bytes  
    	mov CL, 4                 
    	shr DX, CL
    	inc DX                   
    	add DX, CODE
    	sub DX, KEEP_PSP
    	xor AL, AL
    	mov AH, 31h 
   	int 21h
Download:
    	push ES
    	push AX
    	mov AX, KEEP_PSP 
    	mov ES, AX
    	cmp byte ptr ES:[82h],'/'
    	jne stay 
    	cmp byte ptr ES:[83h],'u'
    	jne stay  
    	cmp byte ptr ES:[84h],'n' 
    	je _Upload
stay: 
    	pop AX
    	pop ES
    	mov DX, offset ASSIGN
    	call print
    	ret
_Upload:
    	pop AX
    	pop ES
    	mov byte ptr ES:[BX+SI+10], 1
    	mov DX, offset DIS
    	call print
    	ret
Control ENDP

Int_Setting PROC
   	push DX
    	push DS
    	mov AH, 35h      
    	mov AL, 1Ch        
    	int 21h            
    	mov KEEP_IP, BX     
    	mov KEEP_CS, ES    
    	mov dx, offset ROUT 
    	mov ax, seg ROUT    
   	mov DS, AX       
    	mov AH, 25h        
    	mov AL, 1Ch        
    	int 21h             
    	pop DS
    	mov DX, offset SET
    	call PRINT
    	pop DX
    	ret
Int_Setting ENDP 

Main PROC FAR
    	mov AX, DATA
    	mov DS, AX
   	mov KEEP_PSP, ES
    	call Control
    	xor AL, AL
    	mov AH, 4Ch
    	int 21h
Main ENDP

	Size_in_bytes:
CODE ENDS
    END Main 