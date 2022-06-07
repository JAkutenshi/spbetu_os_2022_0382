AStack SEGMENT STACK
 DW 128 DUP(?)
AStack ENDS

DATA SEGMENT
	NOT_LOAD db 'Interruption did not load', 0DH, 0AH, '$'
	LOAD db 'Interruption was loaded', 0DH, 0AH, '$'
	UNLOAD db 'Interruption was unloaded', 0DH, 0AH, '$'
	ALREADY_LOAD db 'Interruption is already loaded', 0DH, 0AH, '$'
DATA ENDS

TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:DATA, SS:AStack

;-----------------------------------
; ПРОЦЕДУРЫ
;-----------------------------------
PRINT PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
;-----------------------------------
MY_INT PROC far
	jmp handle
	PSP dw 0
	KEEP_IP dw 0
	KEEP_CS dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_AX dw 0
	KEY_SYM db 0
	signature dw 9871h
	IStack db 50 dup(" ")
handle:
	mov KEEP_AX, AX
	mov AX, SS
	mov KEEP_SS, AX
	mov KEEP_SP, SP
	mov AX, seg IStack
	mov SS, AX
	mov SP, offset handle

	push AX
	push BX
	push CX
	push DX

	in AL, 60h
	cmp AL, 38h
	je space
	cmp AL, 2Ch
	je z_key
	cmp AL, 12h
	je e_key

	call dword ptr CS:KEEP_IP
	jmp exit_int

space:
	mov KEY_SYM, '_'
	jmp next_key
z_key:
	mov KEY_SYM, 'X'
	jmp next_key
e_key:
	mov KEY_SYM, 'R'
	
next_key:
	in AL, 61h
    	mov AH, AL
    	or AL, 80h
    	out 61h, AL
    	xchg AL, AL
    	out 61h, AL
    	mov AL, 20h
    	out 20h, AL

print_key:
    	mov AH, 05h
    	mov CL, KEY_SYM
    	mov CH, 00h
    	int 16h
    	or AL, AL
    	jz exit_int
    	mov AX, 40h
    	mov ES, AX
    	mov AX, ES:[1Ah]
    	mov ES:[1Ch], AX
    	jmp print_key

exit_int:	
	pop DX
	pop CX
	pop BX
	pop AX

	mov SP, KEEP_SP
	mov AX, KEEP_SS
	mov SS, AX
	mov AX, KEEP_AX
	mov AL, 20h
	out 20h, AL
	iret
end_int:
MY_INT ENDP
;-----------------------------------
MY_INT_LOAD PROC near
	mov PSP, ES
	mov AH, 35h
	mov AL, 09h
	int 21h
	mov KEEP_IP, BX
	mov KEEP_CS, ES

	push DS
	mov DX, offset MY_INT
	mov AX, seg MY_INT
	mov DS, AX
	mov AH, 25h
	mov AL, 09h
	int 21h
	pop DS

	mov DX, offset end_int
	mov CL, 4
	shr DX, CL
	inc DX
	mov AX, CS
	sub AX, PSP
	add DX, AX
	mov AL, 0
	mov AH, 31h
	int 21h
	ret
MY_INT_LOAD ENDP
;-----------------------------------
MY_INT_UNLOAD PROC near
	CLI
	push DS
	mov AX, ES:[KEEP_CS]
	mov DS, AX
	mov DX, ES:[KEEP_IP]
	mov AH, 25h
	mov AL, 09h
	int 21h
	pop DS	
	STI

	mov AX, ES:[PSP]
	mov ES, AX
	push ES
	mov AX, ES:[2Ch]
	mov ES, AX
	mov AH, 49h
	int 21h
	pop ES
	int 21h
	ret
MY_INT_UNLOAD ENDp
;-----------------------------------
IS_LOADED PROC near
	push BX
	push ES
	mov AH, 35h
	mov AL, 09h
	int 21h
	
	mov AX, ES:[signature]
	cmp AX, 9871h
	je loaded
	mov AL, 0h
	jmp end_isloaded
loaded:
	mov AL, 01h
end_isloaded:
	pop ES
	pop BX
	ret
IS_LOADED ENDP
;-----------------------------------
IS_FLAG PROC near
	push BP
	mov BP, 0082h

	mov AL, ES:[BP]
	cmp AL, '/'
	jne not_good

	mov AL, ES:[BP+1]
	cmp AL, 'u'
	jne not_good

	mov AL, ES:[BP+2]
	cmp AL, 'n'
	jne not_good

	mov AL, 01h
	jmp good
not_good:
	mov AL, 0h
good:
	pop BP
	ret
IS_FLAG endp
;-----------------------------------
MAIN PROC far
	mov ax, data
	mov ds, ax
	
	call IS_FLAG
	mov BX, AX
	
	call IS_LOADED
	cmp AL, 0h
	je not_loaded
	cmp BL, 0h
	jne int_unload
	mov DX, offset ALREADY_LOAD
	call PRINT
	jmp end_main

not_loaded:
	cmp BL, 0h
	je int_load
	mov DX, offset NOT_LOAD
	call PRINT
	jmp end_main
int_load:
	mov DX, offset LOAD
	call PRINT
	call MY_INT_LOAD
	jmp end_main
int_unload:
	mov AH, 35h
	mov AL, 09h
	int 21h
	mov DX, offset UNLOAD
	call PRINT
	call MY_INT_UNLOAD

end_main:
	xor AL, AL
	mov AH, 4Ch
	int 21h
MAIN ENDP
TESTPC ENDS
END MAIN  
