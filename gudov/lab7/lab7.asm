AStack    SEGMENT  STACK
    DW 64 DUP(?)   
AStack    ENDS

DATA  SEGMENT
	DTA db 43 dup(0)
	PARAMETERS 	DW 0,0
	L_ADDRESS 	DD 0
	PATH	DB 32 dup(0)
	OVL1_NAME 	DB 'OVL1.OVL$'
	OVL2_NAME 	DB 'OVL2.OVL$'
	MEM_ERROR	DB 'Error',13,10,'$'
	READ_ERROR	DB 13,10,'Reading error',13,10,'$'
	ALLOC_ERROR	DB 'Allocation error',13,10,'$'
	LOAD_ERROR	DB 'Loading error',13,10,'$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE,DS:DATA,SS:AStack

PRINT PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
;---------------------------
MEM_FREE PROC NEAR
	push AX
	push BX
	push DX
   
	mov BX, offset end_address
	mov AX, ES
	sub BX, AX
	shr BX, 4
	inc BX
	mov AH, 4Ah 
	int 21h
	
	jnc MEM_FREE_end
	mov DX, offset MEM_ERROR
	call PRINT	
	MEM_FREE_end:
	pop DX
	pop BX
	pop AX
	ret
MEM_FREE ENDP
;---------------------------	
SET_PATH PROC NEAR
	push dx
	push di
	push si
	push es
  
	mov ES, ES:[2Ch]
	mov SI, offset PATH
	xor DI, DI

	read_byte:
	mov DL, ES:[DI]
	check_byte:
	inc DI
	cmp DL, 0
	jne read_byte
	mov DL, ES:[DI]
	cmp DL, 0
	jne check_byte

	add DI, 3
	write_path:
	mov DL, ES:[DI]
	mov [SI], DL
	inc SI
	inc DI
	cmp DL, 0
	jne write_path

	backslash_loop:
	dec SI
	cmp PATH[si-1],'\'
	jne backslash_loop
	mov di,0
	write_filename:
	mov dl,bx[di]
	mov PATH[si],dl
	inc si
	inc di
	cmp dl,'$'
	jne write_filename
   
	pop es
	pop si
	pop di
	pop dx
	ret
SET_PATH ENDP
;---------------------------
PREP_OVERLAY PROC NEAR
	push AX
	push BX
	push CX
	push DX
		
	mov AH, 1Ah
	lea DX, DTA
	int 21h
	
	mov AH, 4Eh
	lea DX, PATH
	mov CX, 0
	int 21h
	jnc allocation
	mov DX, offset READ_ERROR
	call PRINT
	jmp overlay_size_end

	allocation:
	mov SI, offset DTA
	add SI, 1Ah
	mov BX, [SI]	
	shr BX, 4 
	mov AX, [SI+2]	
	shl AX, 12
	add BX, AX
	add BX, 2
	mov AH, 48h
	int 21h
	jnc save_seg
	mov DX, offset ALLOC_ERROR
	call PRINT
	jmp overlay_size_end
	save_seg:
	mov PARAMETERS, AX
	mov PARAMETERS+2, AX

	overlay_size_end:	
	pop DX
	pop CX
	pop BX
	pop AX
	ret
PREP_OVERLAY ENDP
;---------------------------
LOAD PROC NEAR
	push AX
	push DX
	push ES
		
	call SET_PATH
	mov DX, offset PATH
	call PRINT
	call PREP_OVERLAY
		
	mov DX, offset PATH
	push DS
	pop ES
	mov BX, offset PARAMETERS
	mov AX, 4B03h            
	int 21h
	jnc loaded
		
	mov DX, offset LOAD_ERROR
	call PRINT
	jmp overlay_end
		
	loaded:
	mov AX, PARAMETERS
	mov word ptr L_ADDRESS + 2, AX
	call L_ADDRESS
	mov ES, AX
	mov AH, 49h
	int 21h
		
	overlay_end:
	pop ES
	pop DX
	pop AX
	ret
LOAD ENDP
;---------------------------	
Main PROC FAR
	sub AX,AX
	push AX
	mov AX, DATA
	mov DS,AX
	  
	call MEM_FREE
	mov BX, offset OVL1_NAME
	call LOAD
	mov BX, offset OVL2_NAME
	call LOAD 
	xor AL,AL
	mov AH,4Ch
	int 21H
Main ENDP
	end_address:
CODE ENDS
END Main