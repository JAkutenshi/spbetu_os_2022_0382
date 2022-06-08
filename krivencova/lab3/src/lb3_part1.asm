TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC
	ORG	100H
START:	jmp BEGIN


av_mem_print db 'available memory:           ', 0DH, 0AH, '$'
ext_mem_print db 'extended memory:            ', 0DH, 0AH, '$'
MCB_print db 'MCB             adress:      , PCP :            , size:      , SC/SD:           ', 0DH, '$'

TETR_TO_HEX PROC 
	and AL, 0Fh
	cmp AL, 09
	jbe NEXT
	add AL, 07
NEXT:	add AL, 30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC 
; байт в AL переводится в два символа 16-го числа в AX
	push CX
	mov AH, AL
	call TETR_TO_HEX
	xchg AL, AH
	mov CL, 4
	shr AL, CL
	call TETR_TO_HEX ; в AL старшая цифра
	pop CX		 ; в AH младшая
	ret 
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC 
	push BX
	mov BH, AH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	dec DI
	mov AL, BH
	call BYTE_TO_HEX
	mov [DI], AH
	dec DI
	mov [DI], AL
	pop BX
	ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC
	push AX
	push CX
	push DX
	xor AH, AH
	xor DX, DX
	mov CX, 10
loop_bd: div CX
	or DL, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 10
	jae loop_bd
	cmp AL, 00h
	je end_1
	or AL, 30h
	mov [SI], AL
end_1: 
	pop DX
	pop CX
	pop AX
	ret
BYTE_TO_DEC ENDP

WORD_TO_DEC PROC
	push AX
	push BX
	push DX
	push CX
	push SI
	mov BX, 10h
	mul BX
	mov BX, 0Ah
segmentation:
	div BX
	or DX, 30h
	mov [SI], DL
	dec SI
	xor DX, DX
	cmp AX, 0h
	jne segmentation
	pop SI
	pop CX
	pop DX
	pop BX
	pop AX
	ret
WORD_TO_DEC ENDP

print PROC
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
print ENDP
print_sym PROC 
	push AX
	mov AH, 02h
	int 21h
	pop AX
	ret
print_sym ENDP

AM PROC
	push AX
	push BX
	push SI
	xor AX, AX
	mov AH, 4Ah
	mov BX, 0FFFFh
	int 21h
	mov AX, BX
	mov SI, offset av_mem_print 
	add SI, 25
	call WORD_TO_DEC
	mov DX, offset av_mem_print 
	call print
	pop SI
	pop BX
	pop AX
	ret
AM ENDP

EM PROC
	push AX
	push BX
	push SI
	xor AX, AX
	mov AL, 30h
	out 70h, AL
	in AL, 71h
	mov BL, AL
	mov AL, 31h
	out 70h, AL
	in AL, 71h
	mov AH, AL
	mov AL, BL
	mov SI, offset ext_mem_print
	add SI, 25
	call WORD_TO_DEC
	mov DX, offset ext_mem_print 
	call print
	pop SI
	pop BX
	pop AX
	ret
EM ENDP
MCB PROC
	push AX
	push BX
	push CX
	push DX
	push ES
	push SI
	xor AX, AX
	mov AH, 52h
	int 21h
	mov AX, ES:[BX-2]
	mov ES, AX
	mov CL, 1
loop_for_MCB:
	mov AL, CL
	mov SI, offset MCB_print
	add SI, 9
	call BYTE_TO_DEC
	mov AX, ES
	mov DI, offset MCB_print
	add DI, 27
	call WRD_TO_HEX
	mov AX, ES:[01h]
	mov DI, offset MCB_print
	add DI, 46
	call WRD_TO_HEX
	mov AX, ES:[03h]
	add SI, 52
	call WORD_TO_DEC
	mov BX, 8
	push CX
	mov CX, 7
	add SI, 11
loop_sc_or_sd:
	mov DX, ES:[BX]
	mov DS:[SI], DX
	inc BX
	inc SI
	loop loop_sc_or_sd
	mov DX, offset MCB_print
	call print
	mov AH, ES:[0]
	cmp AH, 5Ah
	je END_of_MCB
	
	mov BX, ES:[3]
	mov AX, ES
	add AX, BX
	inc AX
	mov ES, AX
	pop CX
	inc CL
	jmp loop_for_MCB
END_of_MCB:
	pop SI
	pop ES
	pop DX
	pop CX
	pop BX
	pop AX
	ret
MCB ENDP
BEGIN:
	call AM
	call EM
	call MCB
	xor AL, AL
	mov AH, 4Ch
	int 21h
TESTPC ENDS
	END START 