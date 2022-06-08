TESTPC SEGMENT
    ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
    ORG 100H
START: JMP BEGIN


unavailable_mem db 'Address unavailable memory:     h',0DH,0AH,'$' ;31
adress_env db 'Environment address:     h',0DH,0AH,'$' ;24
tail_mes db 'Content tail:$'
env_mes db 'Content environment:',0DH,0AH,'$'
path_mes db 'Path: $'

my_enter db 0DH,0AH,'$'
my_tab db '    $'


PRINT_MES MACRO mes
    mov DX, offset mes
    mov AH, 09h
    int 21h
ENDM

PRINT_TO_ZERO MACRO  ;start = ES:[BX]
	mov AH, 02h
@@:	
	mov DL, ES:[BX]	
	cmp DL, 0
	je @f
	
	int 21h
	inc BX
	jmp @b
@@:	
ENDM

BEGIN:
;1
    mov AX, ES:[2h] ;AX = unavailable memory
	
	mov SI, offset unavailable_mem
	add SI, 31
	call WRD_TO_HEX
	PRINT_MES unavailable_mem

;2	
	mov AX, ES:[2Ch] ; AX = environment address
	
	mov SI, offset adress_env
	add SI, 24
	call WRD_TO_HEX
	PRINT_MES adress_env

;3	
	PRINT_MES tail_mes
	mov BX, 80h
	mov CL, ES:[BX] ;CL =amount symbols
	cmp CX, 0
	je END_TAIL
	
	mov AH, 02h
WRITE_TAIL:	
	inc BX
	mov DL, ES:[BX]
	int 21h
	loop WRITE_TAIL

END_TAIL:	
	PRINT_MES my_enter

;4
	PRINT_MES env_mes
	mov AX, ES:[2Ch] 
	mov ES, AX  ;ES = environment address
	mov BX, 0  ;counter

PRINT_LINE:	
	PRINT_MES my_tab
	PRINT_TO_ZERO
	PRINT_MES my_enter
	
	inc BX
	mov DL, ES:[BX]	
	cmp DL, 0
	jne PRINT_LINE

;5
PRINT_MES path_mes
	add bx, 3
	PRINT_TO_ZERO
	
;EXIT
    xor AL,AL
    mov AH,4Ch
    int 21H



;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ;в AL старшая цифра
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, SI - адрес последнего символа
    push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [SI],AH
    dec SI
    mov [SI],AL
    dec SI
    mov AL,BH
    call BYTE_TO_HEX
    mov [SI],AH
    dec SI
    mov [SI],AL
    pop BX
    ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
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

TESTPC ENDS
    END START 