AStack SEGMENT  STACK
	DW 128 DUP(?)   
AStack ENDS

DATA SEGMENT
	FREE_MEM_ERR	DB '[ERROR]: Failed to free memory', 0DH, 0AH, '$'
<<<<<<< HEAD
	MEM_SUCCESS    DB '[MESSAGE]: Memory free has done succefully.', 0DH, 0AH, '$'
=======
	MEM_SUCCESS    DB '[MESSAGE]: Memory free has done succefully.', 0DH, 0AH, '$'
>>>>>>> f3db84eea6e04e8dcbe3a3071a402029820932d0
	PARAM_BLOCK	DW 0 ; segment address of the environment
			DD 0 ; segment and offset of the command string
			DD 0 ; segment and offset of the first FCB
			DD 0 ; segment and offset of the second FCB
	FILEPATH	DB 64 dup(0)
	FILENAME	DB "lr2.com$", 0
	LOAD_ERR	DB '[ERROR]: Failed to load the program', 0DH, 0AH, '$'
	CAUSE_0	DB 0DH, 0AH,'Normal termination with code:  .', 0DH, 0AH, '$'
	CAUSE_1	DB 0DH, 0AH,'Ctrl-Break termination', 0DH, 0AH, '$'
	CAUSE_2	DB 0DH, 0AH,'Device error termination', 0DH, 0AH, '$'
	CAUSE_3	DB 0DH, 0AH,'31h-function termination', 0DH, 0AH, '$'
	KEEP_SS 	DW 0
	KEEP_SP 	DW 0
DATA ENDS
; ---------------------------------------
CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack
; ---------------------------------------
PRINT PROC NEAR
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
; ----------------------------------------	
BYTE_TO_DEC PROC near
	push CX
	push DX
	xor AH, AH
	xor DX, DX
	mov CX, 10
loop_bd:	
	div CX
	or DL, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 10
	jae loop_bd
	cmp AL, 00h
	je end_l
	or AL, 30h
	mov [SI], AL
end_l:	
	pop DX
	pop CX
	ret
BYTE_TO_DEC ENDP
; -----------------------------------------
MEM_FREE PROC NEAR ; - to prepare an area in memory
	push AX
	push BX
	push CX
	push DX
  
	mov BX, offset code_ending  ; BX stores how much memory is required by the program
	mov AX, ES
	sub BX, AX
	mov CL, 4
	shr BX, CL ; now BX stores a number of paragraphs is required by the program
	mov AH, 4Ah ; 4Ah - the function of free memory
	int 21h

	jnc without_errors ; if 4Ah couldn't be executed, CF=1 => FreeMemError
	
	; print the message about FreeMemError
	mov DX, offset FREE_MEM_ERR
	call PRINT
	
	without_errors:
		mov DX, offset MEM_SUCCESS
		call PRINT
		pop DX
		pop CX
		pop BX
		pop AX
		ret
MEM_FREE ENDP
; ------------------------------------------
CREATE_PARAM_BLOCK PROC NEAR
	push AX
	push DI
	mov DI, offset PARAM_BLOCK
	mov [DI+2], ES
	mov AX, 80h 
	mov [DI+4], AX
	pop DI
	pop AX
	ret
CREATE_PARAM_BLOCK ENDP
; -------------------------------------------
GET_FILEPATH PROC NEAR
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
		
	update_filename:
		mov DL, [SI-2]
		dec SI
		cmp DL, '\'
		jne update_filename		
		mov DI, offset FILENAME
	write_filename:
		mov DL, [DI]
		mov [SI], DL
		inc SI
		inc DI
		cmp DL, 0
		jne write_filename
	pop ES
	pop SI
	pop DI
	pop DX
	ret
GET_FILEPATH ENDP
; ---------------------------------	
TO_CALL_MODULE PROC NEAR
	push AX
	push BX
	push DX
	push SI
	push ES
	
	; remember SS and SP
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	mov AX, DS
	mov ES, AX
	mov BX, offset PARAM_BLOCK
	mov DX, offset FILEPATH
	
	; to call the module via loader OS
	mov AX, 4B00h
	int 21h
	
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	mov DX, offset LOAD_ERR
	jc termination_info
	
	success_termination:
		; processing the program termination
		mov AH, 4Dh
		int 21h
		mov DX, offset CAUSE_0
		cmp AH, 0
		je read_code
		mov DX, offset CAUSE_1
		cmp AH, 1
		je termination_info
		mov DX, offset CAUSE_2
		cmp AH, 2
		je termination_info
		mov DX, offset CAUSE_3
		cmp AH, 3
		je termination_info
	read_code:
		mov SI, DX
		add SI, 33
		call BYTE_TO_DEC
	termination_info:
		call PRINT
	pop ES
	pop SI
	pop DX
	pop BX
	pop AX
	ret
TO_CALL_MODULE ENDP
; --------------------------------------
MAIN PROC FAR
	sub AX, AX
	mov AX, DATA
	mov DS, AX
	call MEM_FREE
	jc to_ending
	call CREATE_PARAM_BLOCK
	call GET_FILEPATH
	call TO_CALL_MODULE
	to_ending:
		xor AL, AL
		mov AH, 4Ch
		int 21h
MAIN ENDP
	code_ending:
CODE ENDS
end MAIN 
