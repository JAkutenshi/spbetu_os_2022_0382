AStack SEGMENT STACK
    DW 100 DUP(?)
AStack ENDS

DATA SEGMENT
ERR_PATH db 'Path is not found!', 0DH,0AH,'$'
ERR_NUM db 'Wrong number!', 0DH,0AH,'$'
ERR_FILE db 'File is not found!', 0DH,0AH,'$'
ERR_DISK db 'Disk error!', 0DH,0AH,'$'
NO_MEM db 'Deficiency memory!', 0DH,0AH,'$'
ERR_ENV db 'Wrong environment!', 0DH,0AH,'$'
ERR_MCB db 'MCB is destroyed!', 0DH,0AH,'$'
ERR_ADR db 'Invalid MCB adress!', 0DH,0AH,'$'
ERR_ADD_MEM db 'Error by adding memory!', 0DH,0AH,'$'
END_S db 0DH,0AH,'$'
NAME_ db 64 DUP(0)
DTA_BLOCK db 43 DUP(0)
SEG_OVL dw 0
ADDRESS_OVL dd 0
KEEP_PSP dw 0
PATH db 'Path: $'
   OVL1 db '1.ovl', 0
   OVL2 db '2.ovl', 0
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

DTA_ PROC
    	push DX
    	mov DX, offset DTA_BLOCK
    	mov AH, 1Ah
    	int 21h
    	pop DX
DTA_ ENDP

CLEAN_MEMORY PROC
    	mov BX, offset LAST_BYTE
   	mov AX, ES
    	sub BX, AX
    	mov CL, 4
    	shr BX, CL
    	mov AH, 4Ah
    	int 21h
    	jnc good
    	cmp AX, 7
    	mov DX, offset ERR_MCB
    	je PRINT_MEM_ERR
    	cmp AX, 8
    	mov DX, offset ERR_ADR
    	je PRINT_MEM_ERR
    	cmp AX, 9
    	mov DX, offset ERR_ADR
PRINT_MEM_ERR:
    	call PRINT
    	xor AL, AL
    	mov AH, 4Ch
    	int 21h
good:
    	ret
CLEAN_MEMORY ENDP

GET_P PROC
    	push ES
    	mov ES, ES:[2Ch]
    	xor SI, SI
    	mov DI, offset NAME_
step_1:
    	add SI, 1
    	cmp word ptr ES:[SI],0000h
    	jne step_1
    	add SI, 4
step_2:
    	cmp byte ptr ES:[SI],00h
    	je step_3
    	mov DL, ES:[SI]
    	mov [DI], DL
    	add SI, 1
    	add DI, 1
    	jmp step_2
step_3:
    	sub SI, 1
    	sub DI, 1
    	cmp byte ptr ES:[SI],'\'
    	jne step_3
    	add DI, 1
   	mov SI, BX
    	push DS
    	pop ES
step_4:
    	lodsb
    	stosb
    	cmp AL, 0
    	jne step_4
    	mov byte ptr [DI],'$'
    	mov DX, offset PATH
    	call PRINT
    	mov DX, offset NAME_
    	call PRINT
    	pop ES
    	ret
GET_P ENDP

ADD_MEM_OVL PROC
	push DS
	push DX
    	push CX
    	xor CX, CX
	mov DX, offset NAME_
    	mov AH, 4Eh
    	int 21h
    	jnc V2
    	cmp AX, 3
	mov DX, offset ERR_PATH
    	je V1
	mov DX, offset ERR_FILE
V1:
    	call PRINT
    	pop CX
    	pop DX
   	pop DS
    	xor AL, AL
    	mov AH, 4Ch
    	int 21h
V2:
    	push ES
    	push BX
    	mov BX, offset DTA_BLOCK
    	mov DX, [BX+1Ch]
    	mov AX, [BX+1Ah]
    	mov CL, 4h
    	shr AX, CL
    	mov CL, 12
    	sal DX, CL
    	add AX, DX
    	add AX, 1
    	mov BX, AX
    	mov AH, 48h
    	int 21h
    	jc V3
    	mov SEG_OVL, AX
    	pop BX
    	pop ES
    	pop CX
    	pop DX
    	pop DS
    	ret
V3:
    	mov DX, offset ERR_ADD_MEM
    	call PRINT
    	mov AH, 4Ch
    	int 21h
ADD_MEM_OVL ENDP

CHECK PROC
    	cmp AX, 1
    	mov DX, offset ERR_NUM
    	je PRINT_ERR
    	cmp AX, 2
    	mov DX, offset ERR_FILE
    	je PRINT_ERR
    	cmp AX, 5
    	mov DX, offset ERR_DISK
    	je PRINT_ERR
    	cmp AX, 8
    	mov DX, offset NO_MEM
    	je PRINT_ERR
    	cmp AX, 10
    	mov DX, offset ERR_ENV
PRINT_ERR:
    	call PRINT
    	ret
CHECK ENDP

LOAD_OVL PROC
    	push DX
    	push BX
   	push AX
    	mov BX, SEG SEG_OVL
    	mov ES, BX
    	mov BX, offset SEG_OVL
    	mov DX, offset NAME_
   	mov AX, 4B03h
    	int 21h
    	jnc LOAD
    	call CHECK
    	jmp OFF_OVL
LOAD:
    	mov AX, DATA
    	mov DS, AX
    	mov AX, SEG_OVL
    	mov word ptr ADDRESS_OVL+2, AX
    	call ADDRESS_OVL
    	mov AX, SEG_OVL
    	mov ES,AX
    	mov AX, 4900h
    	int 21h
    	mov AX, DATA
    	mov DS, AX
OFF_OVL:
    	mov ES, KEEP_PSP
    	pop AX
    	pop BX
    	pop DX
    	ret
LOAD_OVL ENDP

Main PROC FAR
    	mov AX, DATA
    	mov DS, AX
    	mov KEEP_PSP, ES
    	mov DX, offset END_S
    	call PRINT
    	call CLEAN_MEMORY
    	call DTA_
    	mov BX, offset OVL1
    	call GET_P
    	call ADD_MEM_OVL
    	call LOAD_OVL
    	mov BX, offset OVL2
    	call GET_P
    	call ADD_MEM_OVL
    	call LOAD_OVL
    	mov AH, 4Ch
    	int 21h
Main ENDP
	
	LAST_BYTE:
CODE ENDS
    END Main 