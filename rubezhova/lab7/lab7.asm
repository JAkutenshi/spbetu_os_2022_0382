AStack SEGMENT STACK
    DB 256 dup('!')   
AStack ENDS

DATA SEGMENT
	FILEPATH 	DB 64 dup(0)
	NAME1 		DB 'OVERLAY1.OVL$'
	NAME2 		DB 'OVERLAY2.OVL$'
	DTA 		DB 43 dup(0) ; buffer that the function 4Eh will..
				      ;  ..fill if the overlay file is found
	PARAMS 	DW 0, 0
	SEGM_ADDR 	DD 0
	MEM_ERR	DB '[ERROR]: Failed to free memory.', 0DH, 0AH,'$'
	FILE_ERR	DB '[ERROR]: The overlay file or route to him could not be found.', 0DH, 0AH,'$'
	ALLOC_ERR	DB '[ERROR]: Failed to allocate memory.', 0DH, 0AH,'$'
	LOADING_ERR	DB '[ERROR]: Failed to load overlay.', 0DH, 0AH,'$'
DATA ENDS
; -------------------------------------------------------------
CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:AStack

MEM_FREE PROC NEAR
	push AX
	push BX
	push DX
  
	mov BX, offset code_ending
	mov AX, ES
	sub BX, AX
	shr BX, 4
	inc BX ; BX - required memory block size in paragraphs = programm size
	mov AH, 4Ah  ; function of free memory
	int 21h
	
	jnc procedure_ending
	mov DX, offset MEM_ERR
	call PRINT
	
	procedure_ending:
		pop DX
		pop BX
		pop AX
		ret
MEM_FREE ENDP
; ------------------------------------------------------------	
GET_PATH PROC NEAR ; in variable FILEPATH puts the string with the path of the called file
	push DX
	push DI
	push SI
	push ES
	
	mov ES, ES:[2Ch] ; upload the environmnet
	mov SI, offset FILEPATH
	xor DI, DI
	
	read_:
		mov DL, ES:[DI] ; get a segment address of the environment
	looking_for_zeros:
		inc DI
		cmp DL, 0
		jne read_
		mov DL, ES:[DI]
		cmp DL, 0
		jne looking_for_zeros
		add DI, 3
	path_cycle:
		mov DL, ES:[DI]
		mov [SI], DL
		inc SI
		inc DI
		cmp DL, 0
		jne path_cycle	
	update_filepath:
		dec SI
		cmp FILEPATH[SI-1], '\'
		jne update_filepath
		mov di, 0
	add_filename:	; filename stored in BX before the procedure
		mov DL, BX[DI]
		mov FILEPATH[SI], DL
		inc SI
		inc DI
		cmp DL, '$'
		jne add_filename		
	pop ES
	pop SI
	pop DI
	pop DX
	ret
GET_PATH ENDP
; --------------------------------------------------------------
BEFORE_LOADING PROC NEAR
	push AX
	push BX
	push CX
	push DX
	
	; to free memory before the loading of overlay
	mov AH, 1Ah
	lea DX, DTA
	int 21h
	
	; to get the size of overlay
	mov AH, 4Eh
	lea DX, FILEPATH ; path to overlay
	mov CX, 0 ; value of attribute byte
	int 21h
	
	jnc mem_alloc
	mov DX, offset FILE_ERR
	call PRINT
	jmp procedure_end
	mem_alloc:
		mov SI, offset DTA
		add SI, 1Ah
		mov BX, [SI]	
		shr BX, 4 
		mov AX, [SI+2]	
		shl AX, 12
		add BX, AX
		add BX, 2
		; to call the function of memory allocation
		mov AH, 48h
		int 21h
		jnc set_params_for_4B03h
		mov DX, offset ALLOC_ERR
		call PRINT
		jmp procedure_end
	set_params_for_4B03h:
		mov PARAMS, AX
		mov PARAMS+2, AX
	procedure_end:	
		pop DX
		pop CX
		pop BX
		pop AX
		ret
BEFORE_LOADING ENDP
; ------------------------------------------------------------------
LOADING_OVL PROC NEAR
	push AX
	push DX
	push ES
		
	call GET_PATH
	mov DX, offset FILEPATH
	call PRINT
	call BEFORE_LOADING
	
	; loading the overlay via 4B03h
	mov DX, offset FILEPATH
	push DS
	pop ES
	mov BX, offset PARAMS
	mov AX, 4B03h            
	int 21h
	
	jnc loading_successful
	mov DX, offset LOADING_ERR
	call PRINT
	jmp end_of_the_procedure
		
	loading_successful:
		mov AX, PARAMS
		mov word ptr SEGM_ADDR + 2, AX
		call SEGM_ADDR
		
		; to free the memory after overlay processing
		mov ES, AX
		mov AH, 49h
		int 21h
		
	end_of_the_procedure:
		pop ES
		pop DX
		pop AX
		ret
LOADING_OVL ENDP
; ------------------------------------------------------------
PRINT PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
; ------------------------------------------------------------
MAIN PROC FAR
	sub ax, ax
	push ax
	mov ax, DATA
	mov ds, ax
   
	call MEM_FREE
	mov BX, offset NAME1
	call LOADING_OVL
	mov BX, offset NAME2
	call LOADING_OVL
   
	xor al, al
	mov ah,4Ch
	int 21h
MAIN ENDP
; -----------------------------------------------------------
code_ending:
CODE ENDS
END MAIN
