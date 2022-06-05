ASSUME CS:CODE, DS:DATA, SS:ASTACK

ASTACK SEGMENT STACK
	DW 1024 DUP(?)
ASTACK ENDS

DATA SEGMENT
	TYPE0 DB 'IBM PC TYPE:   ',0DH,0AH,'$'
	TYPE1 DB 'IBM PC TYPE: PC',0DH,0AH,'$'
	TYPE2 DB 'IBM PC TYPE: PC/XT',0DH,0AH,'$'
	TYPE3 DB 'IBM PC TYPE: AT',0DH,0AH,'$'
	TYPE4 DB 'IBM PC TYPE: PS2 Model 30',0DH,0AH,'$'
	TYPE5 DB 'IBM PC TYPE: PS2 Model 50 or 60',0DH,0AH,'$'
	TYPE6 DB 'IBM PC TYPE: PS2 Model 80',0DH,0AH,'$'
	TYPE7 DB 'IBM PC TYPE: PCjr',0DH,0AH,'$'
	TYPE8 DB 'IBM PC TYPE: PC Convertible',0DH,0AH,'$'
	VER	  DB 'MS DOS VERSION:  .  ',0DH,0AH,'$'
	OEM	  DB 'OEM SERIAL NUMBER:    ',0DH,0AH,'$'
	USER  DB 'USER SERIAL NUMBER:    ',0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
	TETR_TO_HEX PROC NEAR
		and AL,0Fh
		cmp AL,09
		jbe next
		add AL,07
		next: add AL,30h
		ret
	TETR_TO_HEX ENDP
	
	BYTE_TO_HEX PROC NEAR
		; input: AL, output: AX 
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX
		pop CX
		ret
	BYTE_TO_HEX ENDP
	
	WRD_TO_HEX PROC NEAR
		; input: AX, output: DI 
		push BX
		mov BH,AH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		dec DI
		mov AL,BH
		call BYTE_TO_HEX
		mov [DI],AH
		dec DI
		mov [DI],AL
		pop BX
		ret
	WRD_TO_HEX ENDP
	
	BYTE_TO_DEC PROC NEAR
	; input: AL, output: SI 
		push CX
		push DX
		xor AH,AH
		xor DX,DX
		mov CX,10
		loop_bd: div CX
		or DL,30h
		mov [SI],DL
		dec SI
		xor DX,DX
		cmp AX,10
		jae loop_bd
		cmp AL,00h
		je end_l
		or AL,30h
		mov [SI],AL
		end_l: pop DX
		pop CX
		ret
	BYTE_TO_DEC ENDP
	
	PRINT PROC NEAR
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
	PRINT ENDP
	
	PC_TYPE PROC NEAR
		push AX
		push DX
		push ES
		mov AX, 0F000h
		mov ES, AX
		mov AL, ES:[0FFFEh]
		
		cmp AL, 0FFh
		mov DX, offset TYPE1
		je result
		cmp AL, 0FEh
		mov DX, offset TYPE2
		je result
		cmp AL, 0FBh
		je result
		cmp AL, 0FCh
		mov DX, offset TYPE3
		je result
		cmp AL, 0FAh
		mov DX, offset TYPE4
		je result
		cmp AL, 0FCh
		mov DX, offset TYPE5
		je result
		cmp AL, 0F8h
		mov DX, offset TYPE6
		je result
		cmp AL, 0FDh
		mov DX, offset TYPE7
		je result
		cmp AL, 0F9h
		mov DX, offset TYPE8
		je result
		
		call BYTE_TO_HEX
		mov TYPE0[13], AL
		mov TYPE0[14], AH
		mov DX, offset TYPE0
		
		result:
		call PRINT
		pop ES
		pop DX
		pop AX
		ret
	PC_TYPE ENDP
	
	SYSTEM_VER PROC NEAR
		push AX
		push BX
		push CX
		push DI
		push SI
		
		sub AX,AX
		mov AH, 30h
		int 21h
		
		; Version
		mov SI, offset VER
		add SI, 16
		call BYTE_TO_DEC
		mov AL, AH
		add SI, 3
		call BYTE_TO_DEC
		mov DX, offset VER
		call PRINT
		
		; OEM Serial Number
		mov AL, BH
		mov DX, offset OEM
		mov SI, DX
		add SI, 21
		call BYTE_TO_DEC
		call PRINT
		
		; User Serial Number
		mov AX, CX
		mov DX, offset USER
		mov DI, DX
		add DI, 23
		call WRD_TO_HEX
		mov AL, BL
		call BYTE_TO_HEX
		call PRINT
		
		pop SI
		pop DI
		pop CX
		pop BX
		pop AX
		final:
		ret
	SYSTEM_VER ENDP
	
	main PROC FAR
		sub AX, AX
		mov AX, DATA
		mov DS, AX
		
		call PC_TYPE
		call SYSTEM_VER
		xor AL,AL
		mov AH,4Ch
		int 21H
	main ENDP
CODE ENDS
END main