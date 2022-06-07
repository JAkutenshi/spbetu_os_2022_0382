AStack  SEGMENT STACK
 DW  256 dup(?)
AStack  ENDS


DATA SEGMENT
    load_flag       DB                                            0
    unload_flag     DB                                            0
    load_msg        DB      "Interrupt was loaded!", 0DH, 0AH, "$"
    in_mem_msg      DB      "Interrupt has already been loaded!", 0DH, 0AH, "$"
    unload_msg      DB      "Interrupt was unloaded!", 0DH, 0AH, "$"
    not_loaded_msg  DB      "Interrupt wasnt loaded!", 0DH, 0AH, "$"
DATA ENDS

CODE SEGMENT
ASSUME  CS:CODE, DS:DATA, SS:AStack


custom_int PROC FAR
    jmp  int_start

    key_value DB 0
    key_code DB 36h
    int_sign DW 6666h
    old_ip DW 0
    old_cs DW 0
    old_psp DW 0
    old_ax DW 0
    old_ss DW 0
    old_sp DW 0
    
    new_stack DW 256 dup(?)

int_start:
    mov old_ax, AX
    mov old_sp, SP
    mov old_ss, SS
    mov AX, SEG new_stack
    mov SS, AX
    mov AX, OFFSET new_stack
    add AX, 256
    mov SP, AX

    push AX
    push BX
    push CX
    push DX
    push SI
    push ES
    push DS
    mov AX, SEG key_value
    mov DS, AX

    in AL, 60h
    cmp AL, key_code
    je rshift_k
    cmp AL, 2Dh 
    je x_k
    cmp AL, 15h
    je y_k
    cmp AL, 2Ch
    je z_k

    pushf
    call dword ptr CS:old_ip
    jmp end_int

rshift_k:
    mov key_value, '_'
    jmp next_key
x_k:
    mov key_value, 'i'
    jmp next_key
y_k:
    mov key_value, 'j'
    jmp next_key
z_k:
    mov key_value, 'k'

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
    mov CL, key_value
    mov CH, 00h
    int 16h
    or AL, AL
    jz end_int
    mov AX, 40h
    mov ES, AX
    mov AX, ES:[1Ah]
    mov ES:[1Ch], AX
    jmp print_key


end_int:
    pop  DS
    pop  ES
    pop  SI
    pop  DX
    pop  CX
    pop  BX
    pop  AX

    mov SP, old_sp 
    mov AX, old_ss
    mov SS, AX
    mov AX, old_ax

    mov  AL, 20h
    out  20h, AL
    iret
custom_int ENDP
 _end:


is_loaded PROC near
    push AX
    push BX
    push SI

    mov  AH, 35h
    mov  AL, 09h
    int  21h
    mov  SI, OFFSET int_sign
    sub  SI, OFFSET custom_int
    mov  AX, ES:[BX + SI]
    cmp  AX, int_sign
    jne  end_proc
    mov  load_flag, 1

end_proc:
    pop  SI
    pop  BX
    pop  AX
    ret
is_loaded ENDP

load_int PROC near
    push AX
    push BX
    push CX
    push DX
    push ES
    push DS

    mov AH, 35h
    mov AL, 09h
    int 21h
    mov old_cs, ES
    mov old_ip, BX
    mov AX, SEG custom_int
    mov DX, OFFSET custom_int
    mov DS, AX
    mov AH, 25h
    mov AL, 09h
    int 21h
    pop DS

    mov DX, OFFSET _end
    mov CL, 4h
    shr DX, CL
    add DX, 10Fh
    inc DX
    xor AX, AX
    mov AH, 31h
    int 21h

    pop ES
    pop DX
    pop CX
    pop BX
    pop AX
ret
load_int ENDP


unload_int PROC near
    cli
    push AX
    push BX
    push DX
    push DS
    push ES
    push SI

    mov AH, 35h
    mov AL, 09h
    int 21h
    mov SI, OFFSET old_ip
    sub SI, OFFSET custom_int
    mov DX, ES:[BX + SI]
    mov AX, ES:[BX + SI + 2]

    push DS
    mov DS, AX
    mov AH, 25h
    mov AL, 09h
    int 21h
    pop DS

    mov AX, ES:[BX + SI + 4]
    mov ES, AX
    push ES
    mov AX, ES:[2Ch]
    mov ES, AX
    mov AH, 49h
    int 21h
    pop ES
    mov AH, 49h
    int 21h

    sti

    pop SI
    pop ES
    pop DS
    pop DX
    pop BX
    pop AX

ret
unload_int ENDP


find_cmd_flag  PROC near
    push AX
    push ES

    mov AX, old_psp
    mov ES, AX
    cmp byte ptr ES:[82h], '/'
    jne end_unload
    cmp byte ptr ES:[83h], 'u'
    jne end_unload
    cmp byte ptr ES:[84h], 'n'
    jne end_unload
    mov unload_flag, 1

end_unload:
    pop ES
    pop AX
 ret
find_cmd_flag ENDP


PRINT PROC near
    push AX
    mov AH, 09h
    int 21h
    pop AX
ret
PRINT ENDP


BEGIN PROC far
    push DS
    xor AX, AX
    push AX
    mov AX, DATA
    mov DS, AX
    mov old_psp, ES

    call is_loaded
    call find_cmd_flag
    cmp unload_flag, 1
    je unload
    mov AL, load_flag
    cmp AL, 1
    jne load
    mov DX, OFFSET in_mem_msg
    call PRINT
    jmp end_begin

load:
    mov DX, OFFSET load_msg
    call PRINT
    call load_int
    jmp  end_begin

unload:
    cmp  load_flag, 1
    jne  not_loaded
    mov DX, OFFSET unload_msg
    call PRINT
    call unload_int
    jmp  end_begin

not_loaded:
    mov  DX, offset not_loaded_msg
    call PRINT

end_begin:
    xor AL, AL
    mov AH, 4ch
    int 21h
BEGIN ENDP
CODE ENDS

END BEGIN
