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

ROUT PROC FAR
    jmp _ROUT
	_STACK dw 100 dup (0)
	SIGN db '0000'
	KEEP_IP dw 0 
   	KEEP_CS dw 0       
   	KEEP_PSP dw 0
    	KEEP_SS dw 0
    	KEEP_AX	dw 0
    	KEEP_SP dw 0  
	FIRST db 53h
    	RES db 15h
		
_ROUT:
    	mov KEEP_SS, SS
    	mov KEEP_AX, AX
    	mov KEEP_SP, SP
   	mov AX, seg _STACK
    	mov SS, AX
    	mov SP, 0
    	mov AX, KEEP_AX
    	in AL, 60h   
    	cmp AL, FIRST  
    	je DO_REQ    
    	pushf
    	call dword ptr KEEP_IP  
    	jmp The_end
		
DO_REQ:
    	push AX
    	in al, 61h   
    	mov AH, AL  
   	or AL, 80h  
    	out 61h, AL 
    	xchg AH, AL  
    	out 61h, AL  
    	mov AL, 20h  
    	out 20h, AL  
    	pop AX

Update:
    	mov AL, 0 
    	mov AH, 05h  
    	mov CL, RES  
    	mov CH, 00h
    	int 16h
    	or AL, AL    
    	jz The_end      
    	jmp Update


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
    	mov AL, 09h        
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
    	call Delete_INT
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

Delete_INT PROC
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
Delete_INT ENDP

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