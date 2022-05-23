OVL2 SEGMENT
	ASSUME CS:OVL2, DS:NOTHING, SS:NOTHING, ES:NOTHING
		
	Main PROC FAR
		push AX
		push DX
		push DI
		push DS
		
		mov AX,CS
		mov DS,AX
		mov DX, offset SEG_STR
		mov DI, DX
		add DI, 38
		call WRD_TO_HEX
		call PRINT
		
		pop DS
		pop DI
		pop DX
		pop AX
		retf
	Main ENDP
	
	TETR_TO_HEX PROC NEAR
		and AL,0Fh
		cmp AL,09
		jbe next
		add AL,07
		next: add AL,30h
		ret
	TETR_TO_HEX ENDP

	BYTE_TO_HEX PROC NEAR
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

	PRINT PROC NEAR
		push AX
		mov AH, 09h
		int 21h
		pop AX
		ret
	PRINT ENDP
	
	SEG_STR DB 13,10,'OVL2.OVL loaded. Segment adress:     h',13,10,'$'
OVL2 ENDS
END Main