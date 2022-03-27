TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN


;----------------------------
AVAILABLE_MEMORY db 'Available Memory in Bytes: $'
EXTENDED_MEMORY db 'Extended Memory in KiloBytes: $'
MCB_LIST db 'MCB  List:', 0DH, 0AH, '$'
MCB_LIST_NUMBER db 'MCB #  $'
MCB_LIST_SIZE db 'Size:      $'
MCB_LIST_ADDRESS db 'Address:      $'
MCB_LIST_SC_SD db 'SC/SD:  $'

PSP_TYPE db 'PSP TYPE:  $'
PSP_FREE db 'Free PSP             $'
PSP_EXCLUDED_HIGH_DRIVER_MEM db'Excluded high driver $'
PSP_OS_XMS_UMB db 'Belongs to OS XMS UMB$'
PSP_MS_DOS db 'Belong MS DOS        $'
PSP_OCCUPIED_386MAX_UMB db 'Occupied mem by 386MAX UMB$'
PSP_BLOCKED_386MAX db 'Blocked 386MAX        $'
PSP_BELONGS_386MAX db 'Belongs 386MAX        $'

DEFAULT_TYPE db '                     $'

;----------------------------
TETR_TO_HEX PROC near
    and AL, 0Fh
    cmp AL, 09
    jbe NEXT
    add AL, 07
NEXT:
    add AL, 30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX
    mov AH, AL
    call TETR_TO_HEX
    xchg AL, AH
    mov CL, 4
    shr AL, CL
    call TETR_TO_HEX
    pop CX
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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

;-----------------------
PRINT_MESSAGE  PROC  NEAR
    push AX
    mov AH, 9
    int 21h
    pop AX
    ret
PRINT_MESSAGE  ENDP

PRINT_MESSAGE_BYTE  PROC  NEAR
    push AX
    mov AH, 02h
    int 21h
    pop AX
    ret
PRINT_MESSAGE_BYTE  ENDP

PRINT_EOF PROC NEAR
    push AX
    push DX
    mov DL, 0dh
    call PRINT_MESSAGE_BYTE
    mov DL, 0ah
    call PRINT_MESSAGE_BYTE
    pop DX
    pop AX
    ret
PRINT_EOF ENDP

PRINT_AV_MEMORY PROC NEAR
    push AX
    push BX
    push CX
    push DX
    push DI
    xor CX, CX
    mov BX, 010h
    mul BX
    mov DI, DX
    mov BX, 0ah

loop_for_division_1:
    div BX
    push DX
    xor DX, DX
    inc CX
    cmp AX, 0h
    jne loop_for_division_1

loop_for_print_symbol_1:
    pop DX
    add DL, 30h
    call PRINT_MESSAGE_BYTE
    loop loop_for_print_symbol_1
	
    pop DI
    pop DX
    pop CX
    pop BX
    pop AX
    ret
PRINT_AV_MEMORY ENDP

PRINT_EX_MEMORY PROC NEAR
    push AX
    push BX
    push CX
    push DX
    push DI
    xor CX, CX
    xor DX, DX
    mov BX, 0ah

loop_for_division_2:
    div BX
    push DX
    xor DX, DX
    inc CX
    cmp AX, 0h
    jne loop_for_division_2

loop_for_print_symbol_2:
    pop DX
    add DL, 30h
    call PRINT_MESSAGE_BYTE
    loop loop_for_print_symbol_2

    pop DI
    pop DX
    pop CX
    pop BX
    pop AX
    ret
PRINT_EX_MEMORY ENDP

;-----------------------
AV_MEM PROC NEAR
    push ax
    push bx
    push dx
    mov dx, offset AVAILABLE_MEMORY
    call PRINT_MESSAGE
    mov ah, 4ah
    mov bx, 0ffffh
    int 21h
    mov ax, bx
    call PRINT_AV_MEMORY
    call PRINT_EOF
    pop dx
    pop bx
    pop ax
    ret
AV_MEM ENDP

 EX_MEM PROC NEAR
    push AX
    push BX
    push DX
    mov AL, 30h
    out 70h, AL
    in AL, 71h
    mov bl, AL
    mov AL, 31h
    out 70h, AL
    in AL, 71h
    mov BH, AL
    mov DX, offset EXTENDED_MEMORY
    call PRINT_MESSAGE
    mov AX, BX
    call PRINT_EX_MEMORY
    call PRINT_EOF
    pop DX
    pop BX
    pop AX
    ret
EX_MEM ENDP

PRINT_MCB PROC near
    push AX
    push DX
    push DI
    mov DX, offset PSP_TYPE
    call PRINT_MESSAGE
    cmp AX, 0000h
    je print_free
    cmp AX, 0006h
    je print_OS_XMS_UMB
    cmp AX, 0007h
    je print_excluded_high_driver_mem
    cmp AX, 0008h
    je print_MS_DOS
    cmp AX, 0FFFAh
    je print_occupied_386MAX_UMB
    cmp AX, 0FFFDh
    je print_blocked_386MAX
    cmp AX, 0FFFEh
    je print_belongs_386MAX_UMB
    jmp print_default

print_free:
    mov DX, offset PSP_FREE
    call PRINT_MESSAGE
    jmp end_print

print_OS_XMS_UMB:
    mov DX, offset PSP_OS_XMS_UMB
    call PRINT_MESSAGE
    jmp end_print

print_excluded_high_driver_mem:
    mov DX, offset PSP_EXCLUDED_HIGH_DRIVER_MEM
    call PRINT_MESSAGE
    jmp end_print

print_MS_DOS:
    mov DX, offset PSP_MS_DOS
    call PRINT_MESSAGE
    jmp end_print

print_occupied_386MAX_UMB:
    mov DX, offset PSP_OCCUPIED_386MAX_UMB
    call PRINT_MESSAGE
    jmp end_print

print_blocked_386MAX:
    mov DX, offset PSP_BLOCKED_386MAX
    call PRINT_MESSAGE
    jmp end_print

print_belongs_386MAX_UMB:
    mov DX, offset PSP_BELONGS_386MAX
    call PRINT_MESSAGE
    jmp end_print

print_default:
    mov DI, offset DEFAULT_TYPE
    add DI, 3
    call WRD_TO_HEX
    mov DX, offset DEFAULT_TYPE
    call PRINT_MESSAGE

end_print:
    pop DI
    pop DX
    pop AX
    ret
PRINT_MCB ENDP

LIST_MCB PROC NEAR
    push AX
    push BX
    push DX
    push CX
    push SI
    push DI
    call PRINT_EOF
    mov DX, offset MCB_LIST
    call PRINT_MESSAGE
    mov AH, 52h
    int 21h
    mov AX, ES:[BX-2]
    mov ES, AX
    xor CX, CX
    mov CL, 01h

loop_for_mcb:
    mov AL, CL
    mov SI, offset MCB_LIST_NUMBER
    add SI, 5
    call BYTE_TO_DEC
    mov DX, offset MCB_LIST_NUMBER
    call PRINT_MESSAGE
    mov AX, ES
    mov DI, offset MCB_LIST_ADDRESS
    add DI, 12
    call WRD_TO_HEX
    mov DX, offset MCB_LIST_ADDRESS
    call PRINT_MESSAGE
    mov AX, ES:[1]
    call PRINT_MCB
    mov AX, ES:[3]
    mov DI, offset MCB_LIST_SIZE
    add DI, 9
    call WRD_TO_HEX
    mov DX, offset MCB_LIST_SIZE
    call PRINT_MESSAGE
    mov BX, 8
    mov DX, offset MCB_LIST_SC_SD
    call PRINT_MESSAGE
    push CX
    mov CX, 7
	
    loop_for_print_sc_sd:
        mov DL, ES:[BX]
        call PRINT_MESSAGE_BYTE
        inc BX
        loop loop_for_print_sc_sd
		
    call PRINT_EOF
    pop CX
    mov AH, ES:[0]
    cmp AH, 5ah
    je end_LIST_MCB
    mov BX, ES:[3]
    inc BX
    mov AX, ES
    add AX, BX
    mov ES, AX
    inc CL
    jmp loop_for_mcb

end_LIST_MCB:
    pop DI
    pop SI
    pop CX
    pop DX
    pop BX
    pop AX
    ret
LIST_MCB ENDP


REQUEST_MEMORY PROC NEAR
    push AX
    push BX
    push DX
    mov BX, 1000h
    mov AH, 48h
    int 21h
    pop DX
    pop BX
    pop AX
REQUEST_MEMORY ENDP

FREE_MEMORY PROC NEAR
    push AX
    push BX
    push DX
    xor DX, DX
    lea AX, end_programm
    mov BX, 10h
    div BX
    add AX, DX
    mov BX,AX
    xor AX, AX
    mov AH,4Ah
    int 21h
    pop DX
    pop BX
    pop AX
    ret
FREE_MEMORY ENDP

BEGIN:
	mov AH, 4ah
    mov BX, 0ffffh
    int 21h
    call AV_MEM
    call EX_MEM
	call FREE_MEMORY
	call REQUEST_MEMORY
    call LIST_MCB
    xor AL, AL
    mov AH, 4ch
    int 21h
end_programm:
TESTPC  ENDS
        END START