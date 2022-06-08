AStack SEGMENT STACK
 DW 32 DUP(?)
AStack ENDS

DATA SEGMENT
	PARAM dw 0 
              dd 0 
              dd 0  
              dd 0 
               
	FILE_NAME db 'LB2.COM', 0
	CMD_L db 1h, 0dh
	FILE_PATH db 128 DUP (?)
   
	FREE_MEM_1 db 'The control memory block is destroyed', 0DH, 0AH,'$'
	FREE_MEM_2 db 'Not enough memory to execute the function', 0DH, 0AH,'$'
	FREE_MEM_3 db 'Invalid memory block address', 0DH, 0AH,'$'
	FREE_MEM_4 db 'Success free memory', 0DH, 0AH,'$'
	FREE_MEM_FLAG db 0
   
   	LOAD_ERROR_1 db 'Invalid function number', 0DH, 0AH,'$'
   	LOAD_ERROR_2 db 'File not found', 0DH, 0AH,'$'
   	LOAD_ERROR_3 db 'Disk error', 0DH, 0AH,'$'
   	LOAD_ERROR_4 db 'Not enough memory', 0DH, 0AH,'$'
   	LOAD_ERROR_5 db 'Incorrect environment string', 0DH, 0AH,'$'
   	LOAD_ERROR_6 db 'Incorrect format', 0DH, 0AH,'$'
   
   	GOOD_END db 0DH, 0AH,'Programm ended with code =    ', 0DH, 0AH,'$'

   	CTRLC_END db 'Programm ended ctrl-break', 0DH, 0AH,'$'
   	DEVICE_END db 'Programm ended device error', 0DH, 0AH,'$'
   	INT31_END db 'Programm ended int 31h', 0DH, 0AH,'$'
   
  	KEEP_SS dw 0
  	KEEP_SP dw 0
	KEEP_PSP dw 0
   
	END_DATA db 0
DATA ENDS

TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:DATA, SS:AStack

; ПРОЦЕДУРЫ
;----------------------
PRINT PROC near
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP
;----------------------
FREE_MEM PROC near
	push AX
   	push BX
	push CX
	push DX
   
   	lea BX, end_programm
   	lea AX, END_DATA
   	add BX, AX
	mov CL, 4
   	shr BX, CL
   	add BX, 2Bh
   	mov AH, 4Ah
   	int 21h

   	jnc free_mem_suc

	mov FREE_MEM_FLAG, 0   
	cmp AX, 7
	jne low_mem
	lea DX, FREE_MEM_1
	jmp free_mem_print
low_mem:
	cmp AX, 8
	jne inv_addr
	lea DX, FREE_MEM_2
	jmp free_mem_print
inv_addr:
	cmp AX, 9
	lea DX, FREE_MEM_3
	jmp free_mem_print
   
free_mem_suc:
	mov FREE_MEM_FLAG, 1
	lea DX, FREE_MEM_4

free_mem_print:
   	call PRINT

end_free_mem:   
	pop DX
	pop CX
   	pop BX
   	pop AX
   	ret
FREE_MEM ENDP
;-----------------------------------
LOAD PROC near
	push AX
	push BX
	push CX
	push DX
	push DS
	push ES
	mov KEEP_SP, SP
	mov AX, SS
	mov KEEP_SS, AX

	mov AX, DATA
	mov ES, AX
	mov bx, offset PARAM
	mov dx, offset CMD_L
	mov [bx+2], dx
	mov [bx+4], ds
	mov dx, offset FILE_PATH

	mov ax, 4B00h
	int 21h

	mov ss, KEEP_SS
	mov sp, KEEP_SP
	pop es
	pop ds

	jnc success_load

	cmp AX, 1
	jne not_found
	lea DX, LOAD_ERROR_1
	jmp load_print
not_found:
	cmp AX, 2
	jne disk_error
	lea DX, LOAD_ERROR_2
	jmp load_print
disk_error:
	cmp AX, 5
	jne not_enough_mem
	lea DX, LOAD_ERROR_3
	jmp load_print
not_enough_mem:
	cmp AX, 8
	jne env_error
	lea DX, LOAD_ERROR_4
	jmp load_print

env_error:
	cmp AX, 10
	jne not_correct_format
	lea DX, LOAD_ERROR_5
	jmp load_print

not_correct_format:
	cmp AX, 11
	mov DX, offset LOAD_ERROR_6
	jmp load_print

success_load:
	mov AX, 4D00h
	int 21h

	cmp AH, 0
	jne ctrlc
	push DI
	lea DI, GOOD_END
	mov [DI+30], AL
	pop SI
	lea DX, GOOD_END
	jmp load_print
ctrlc:
	cmp AH, 1
	jne device
	lea DX, CTRLC_END
	jmp load_print
device:
	cmp AH, 2
	jne int_31h
	lea DX, DEVICE_END
	jmp load_print
int_31h:
	cmp AH, 3
	lea DX, INT31_END

load_print:
	call PRINT

end_load:
	pop DX
	pop CX
	pop BX
	pop AX
	ret
LOAD ENDP
;-----------------------------------
PATH PROC near
	push AX
	push BX
	push CX
	push DX
	push DI
	push SI
	push ES

	mov AX, KEEP_PSP
	mov ES, AX
	mov ES, ES:[2Ch]
	mov BX, 0

find_zero:
	inc BX
	cmp byte ptr ES:[BX-1], 0
	jne find_zero

	cmp byte ptr ES:[BX+1], 0
	jne find_zero

	add BX, 2
	mov DI, 0

path_loop:
	mov DL, ES:[BX]
	mov byte ptr [FILE_PATH+DI], DL
	inc DI
	inc BX
	cmp DL, 0
	je path_end_loop
	cmp DL, '\'
	jne path_loop
	mov CX, DI
	jmp path_loop
path_end_loop:
	mov DI, CX
	mov SI, 0

_file_name:
	mov DL, byte ptr [FILE_NAME+SI]
	mov byte ptr [FILE_PATH+DI], DL
	inc DI
	inc SI
	cmp DL, 0
	jne _file_name

	pop ES
	pop SI
	pop DI
	pop DX
	pop CX
	pop BX
	pop AX
	ret
PATH ENDP
;-----------------------------------
; КОД
MAIN PROC far
	mov ax, data
	mov ds, ax
	mov KEEP_PSP, ES

	call FREE_MEM
	cmp FREE_MEM_FLAG, 0
	je main_end
	call PATH
	call LOAD
; Выход в DOS
main_end:
	xor AL, AL
	mov AH, 4Ch
	int 21h
MAIN ENDP
end_programm:
TESTPC ENDS
END MAIN