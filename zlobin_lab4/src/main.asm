AStack   SEGMENT STACK
        DB 256 dup (?)
AStack   ENDS

DATA	SEGMENT
    flag    DB 0
    load_msg DB 'Interrupt was loaded!$'
    unload_msg DB 'Interrupt was unloaded!$'
    in_mem_msg DB 'Interrupt has already been loaded!$'
    not_loaded_msg DB 'Interrupt wasnt loaded!$'
DATA ENDS

CODE   SEGMENT
ASSUME  CS:CODE, DS:DATA, SS:AStack

custom_int PROC far
        jmp    int_start

        int_sign DW 7777h
        PSP     DW ?
        old_cs  DW 0
        old_ip  DW 0
        old_ss  DW 0
        old_sp  DW 0
        old_ax  DW 0
        count_msg DB 'Counter:      0000'
        msg_len = $ - count_msg
        int_stack DB 128 dup (?)
        stack_end:

int_start: 
        mov     old_ss, SS
        mov     old_sp, SP
        mov     old_ax, AX
        mov     AX, CS
        mov     SS, AX
        mov     SP, OFFSET stack_end
        push    BX
        push    CX
        push    DX
        push    DS
        push    ES
        push    SI
        push    DI
        push    BP

        mov     AH, 03h
        mov     BH, 0
        int     10h
        push    DX

        mov     AH, 02h
        mov     BH, 0
        mov     DX, 0
        int     10h

        push    BP
        push    DS
        push    SI
        mov     DX, SEG count_msg
        mov     DS, DX
        mov     SI, OFFSET count_msg
        mov     CX, 5
inc_loop:  
        mov     BP, CX
        dec     BP
        mov     AL, byte ptr [SI+BP+13]
        inc     AL
        mov     [SI+BP+13], AL
        cmp     AL, 3Ah
        jne     oklab
        mov     AL, 30h
        mov     byte ptr [SI+BP+13], AL
        loop    inc_loop
oklab:   
        pop     SI
        pop     DS

        push    ES
        mov     DX, SEG count_msg
        mov     ES, DX
        mov     BP, OFFSET count_msg
        mov     AH, 13h
        mov     AL, 1
        mov     BH, 0
        mov     CX, msg_len
        mov     DX, 0
        int     10h
        pop     ES
        pop     BP

        mov     AH, 02h
        mov     BH, 0
        pop     DX
        int     10h

        pop     BP
        pop     DI
        pop     SI
        pop     ES
        pop     DS
        pop     DX
        pop     CX
        pop     BX
        mov     AX, old_ss
        mov     SS, AX
        mov     SP, old_sp
        mov     AX, old_ax
        mov     AL, 20h
        out     20h, AL
        iret
int_end:
custom_int ENDP

load_int PROC
        push    AX
        push    CX
        push    DX

        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     old_ip, BX
        mov     old_cs, ES

        push    DS
        mov     DX, OFFSET custom_int
        mov     AX, SEG custom_int 
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 1Ch
        int     21h
        pop     DS

        mov     DX, OFFSET int_end
        mov     CL, 4
        shr     DX, CL
        inc     DX
        mov     AX, CS
        sub     AX, PSP
        add     DX, AX
        xor     AX, AX
        mov     AH, 31h
        int     21h
        pop     DX
        pop     CX
        pop     AX
        ret
load_int ENDP

unload_int PROC
        push    AX
        push    DX
        push    SI
        push    ES

        cli
        push    DS
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     SI, OFFSET old_cs
        sub     SI, OFFSET custom_int
        mov     DX, ES:[BX+SI+2]
        mov     AX, ES:[BX+SI]
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 1Ch
        int     21h
        pop     DS
        mov     AX, ES:[BX+SI-2]
        mov     ES, AX
        push    ES
        mov     AX, ES:[2Ch]
        mov     ES, AX
        mov     AH, 49h
        int     21h
        pop     ES
        mov     AH, 49h
        int     21h
        sti
        pop     ES
        pop     SI
        pop     DX
        pop     AX
        ret
unload_int ENDP

find_cmd_flag PROC
        push    AX
        mov     AL, ES:[82h]
        cmp     AL, '/'
        jne     nparam
        mov     AL, ES:[83h]
        cmp     AL, 'u'
        jne     nparam
        mov     AL, ES:[84h]
        cmp     AL, 'n'
        jne     nparam
        mov     flag, 1
nparam: 
        pop     AX
        ret
find_cmd_flag ENDP

is_loaded PROC
        push    AX
        push    DX
        push    SI
        mov     flag, 1
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     SI, OFFSET int_sign
        sub     SI, OFFSET custom_int
        mov     DX, ES:[BX+SI]
        cmp     DX, 7777h
        je      loaded_lab
        mov     flag, 0
loaded_lab:     
        pop     SI
        pop     DX
        pop     AX
        ret
is_loaded ENDP

PRINT_STRING   PROC
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
        ret
PRINT_STRING   ENDP

MAIN   PROC far
        mov     AX, data
        mov     DS, AX
        mov     PSP, ES
        mov     flag, 0
        call    find_cmd_flag
        cmp     flag, 1
        je      unload_lab

        call    is_loaded
        cmp     flag, 0
        je      not_loaded_lab
        mov     DX, OFFSET in_mem_msg
        call    PRINT_STRING
        jmp     final_lab
not_loaded_lab:  
        mov     DX, OFFSET load_msg
        call    PRINT_STRING
        call    load_int

        jmp     final_lab

unload_lab:     
        call    is_loaded
        cmp     flag, 0
        jne     already_loaded_lab
        mov     DX, OFFSET not_loaded_msg
        call    PRINT_STRING
        jmp     final_lab
already_loaded_lab:  
        call    unload_int
        mov     DX, OFFSET unload_msg
        call    PRINT_STRING

final_lab:    
        mov     AX, 4C00h
        int     21h
MAIN   ENDP
CODE  ENDS
END    MAIN