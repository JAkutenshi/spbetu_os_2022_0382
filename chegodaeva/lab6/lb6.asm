AStack SEGMENT STACK
    DW 100 DUP(?)
AStack ENDS

DATA SEGMENT
ERRMEM db 'Memory cleanup error: $'
ERR_MCB db 'MCB is destroyed', 0DH, 0AH, '$'
NO_MEM db 'Deficiency memory', 0DH,0AH,'$'
ERR_ADR db 'error of the address', 0DH,0AH,'$'
ERR_FUN db 'Feature number error!', 0DH, 0AH, '$'
ERR_FILE db 'Error of the file!', 0DH, 0AH, '$'
ERR_DISK db 'Error of the disk!', 0DH, 0AH, '$'
ERR_ENV db 'Error of env!', 0DH, 0AH, '$'
ERR_FORM db 'Error of format!', 0DH, 0AH, '$'
ERR_DEVICE db 'Device error!', 0DH, 0AH, '$'
END_CTRL db 'End ctrl', 0DH, 0AH, '$'
ERR_RES db 'End 31h', 0DH, 0AH, '$'
CODE_ELEM db 'Code of finish: $'
SUCCESS db 'Completed successfully!', 0DH,0AH,'$'
END_S db  0DH, 0AH, '$'
PARAM dw 0
  dd 0     
  dd 0
  dd 0
PATH db 50h dup ('$')
KEEP_SS dw 0
KEEP_SP dw 0
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

TETR_TO_HEX PROC near
	and AL, 0Fh
	cmp AL, 09
	jbe NEXT
	add AL, 07
NEXT:	add AL, 30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
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

CLEAN_MEMORY PROC
    	mov AX, AStack
    	mov BX, ES
    	sub AX, BX
    	add AX, 10h
    	mov BX, AX
    	mov AH, 4Ah
    	int 21h
    	jnc FINAL

    	mov DX, offset ERRMEM
	call PRINT
    	cmp AX, 7
    	mov DX, offset ERR_MCB
    	je PRINT_MEM
    	cmp AX, 8
    	mov DX, offset NO_MEM
    	je PRINT_MEM
    	cmp AX, 9
    	mov DX, offset ERR_ADR

PRINT_MEM:
	call PRINT
	xor AL, AL
    	mov AH, 4Ch
    	int 21H
FINAL:
    	ret
CLEAN_MEMORY ENDP

GET_P PROC
    	mov AX, AStack
    	sub AX, CODE
    	add AX, 100h
    	mov BX, AX
    	mov AH, 4ah
    	int 21h
    	jnc step_1
    	call DEAL
step_1:
    	call PARAMETERS
    	mov ES, ES:[2ch]
    	mov BX, -1
step_2:
    	add BX, 1
    	cmp word ptr ES:[BX], 0000h
    	jne step_2
    	add BX, 4
    	mov SI, -1
step_3:
    	add SI, 1
    	mov AL, ES:[BX+SI]
    	mov PATH[SI], AL
   	cmp byte ptr ES:[BX+SI], 00h
    	jne step_3
    	add SI, 1
step_4:
    	mov PATH[SI], 0
    	sub SI, 1
    	cmp byte ptr ES:[BX+SI],'\'
    	jne step_4
    	add SI, 1
    	mov PATH[SI],'l'
    	add SI, 1
   	mov PATH[SI],'b'
    	add SI, 1
   	mov PATH[SI],'2'
    	add SI, 1
    	mov PATH[SI],'.'
    	add SI, 1
    	mov PATH[SI],'C'
    	add SI, 1
    	mov PATH[SI],'O'
    	add SI, 1
    	mov PATH[SI],'M'
    	ret
GET_P ENDP

PARAMETERS PROC
    	mov AX, ES:[2Ch]
    	mov PARAM, AX
    	mov PARAM+2, ES
    	mov PARAM+4, 80h
   	ret
PARAMETERS ENDP

DEAL PROC
    	mov DX, offset PATH
    	xor CH, CH
    	mov CL, ES:[80h]
    	cmp CX, 0
    	je UNTAIL
    	mov SI, CX
    	push SI
lp:
    	mov AL, ES:[81h+SI]
    	mov [offset PATH+SI-1], AL
    	sub SI, 1
    	loop lp
    	pop SI
    	mov [PATH+SI-1], 0
    	mov DX,offset PATH
UNTAIL:
    	push DS
    	pop ES
    	mov BX, offset PARAM
    	mov KEEP_SP, SP
    	mov KEEP_SS, SS
   	mov AX, 4b00h
    	int 21h
    	jnc FIN
    	push AX
    	mov AX, DATA
    	mov DS, AX
    	pop AX
    	mov SS, KEEP_SS
    	mov SP, KEEP_SP

    	cmp AX,1
    	mov DX, offset ERR_FUN
    	je PRINT_DEAL
    	cmp ax,2
    	mov DX, offset ERR_FILE
    	je PRINT_DEAL
    	cmp ax,5
    	mov DX, offset ERR_DISK
    	je PRINT_DEAL
    	cmp ax,8
    	mov DX, offset NO_MEM
    	je PRINT_DEAL
    	cmp ax,10
    	mov DX, offset ERR_ENV
    	je PRINT_DEAL
    	cmp ax,11
    	mov DX, offset ERR_FORM
PRINT_DEAL:
	call PRINT
    	xor AL, AL
    	mov AH, 4Ch
    	int 21H
FIN:
	mov DX, offset END_S
	call PRINT
    	mov AX, 4d00h
    	int 21h
    	cmp AH, 0
    	mov DX, offset SUCCESS
    	je REASONS
    	cmp ah,1
    	mov DX, offset END_CTRL
    	je REASONS
    	cmp ah,2
    	mov DX, offset ERR_DEVICE
    	je REASONS
    	cmp ah,3
    	mov DX, offset ERR_RES
REASONS:
    	call PRINT
    	mov DX, offset CODE_ELEM
    	call PRINT
    	call BYTE_TO_HEX
    	push AX
    	mov AH, 02h
    	mov DL, AL
    	int 21h
    	pop AX
    	xchg AH, AL
    	mov AH, 02h
    	mov DL, AL
    	int 21h
	mov DX, offset END_S
	call PRINT
    	ret
DEAL ENDP

Main PROC FAR
    	mov AX, DATA
    	mov DS, AX
    	call CLEAN_MEMORY
    	call GET_P
    	call DEAL
    	xor AL, AL
    	mov AH, 4Ch
    	int 21h
Main ENDP

CODE ENDS
    END Main