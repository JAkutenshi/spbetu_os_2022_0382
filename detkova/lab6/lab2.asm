MainSeg SEGMENT
    ASSUME CS:MainSeg, DS:MainSeg, ES:NOTHING, SS:NOTHING
    ORG 100H
    
start:
    jmp begin
    
data:
    SegAddrOfFirst db 'Segment adress of the first byte of unvailable memory -     .', 0DH, 0AH, '$'
    SegAddrOfEnv db 'Segment adress of the environment -     .', 0DH, 0AH, '$'
    CMDTail db 'CMD tail - ', '$'
    CMDTail_empty db 'CMD tail is empty.', 0DH, 0AH, '$'
    Env db 'Environment content - ', '$'
    Path db 'Path - ', '$'

begin:
    call main
    xor AL,AL
    mov AH,4CH
    int 21H
   
_print PROC NEAR
    
    push AX
    
    mov AH, 09H
    int 21H
    
    pop AX
    
    ret
    
_print ENDP

byte_to_dec PROC NEAR

    ; AH - number, SI - adress of last symbol

    push CX
    push DX
    push AX
    
    xor AH,AH
    xor DX,DX
    mov CX,10
    
  loop_bd:
    div CX
    or DL,30H
    mov [SI],DL
    dec SI
    xor DX,DX
    cmp AX,10
    jae loop_bd
    
    cmp AL,00H
    je end_l
    
    or AL,30H
    mov [SI],AL
    
  end_l:
    pop AX
    pop DX
    pop CX
    
    ret

byte_to_dec ENDP

tetr_to_hex PROC NEAR

    and AL,0FH    ; save only last part of byte
    cmp AL,09
    jbe next
    add AL,07
  next:
    add AL,30H
    ret

tetr_to_hex ENDP

byte_to_hex PROC NEAR

    ; AL - number -> 2 symbols in 16 numb. syst. in AX

    push CX
    
    mov AH,AL    ; save AL
    call tetr_to_hex
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call tetr_to_hex    ; AL - high numb ascii, AH - low numb ascii
    
    pop CX
    ret

byte_to_hex ENDP

wrd_to_hex PROC NEAR

    ; AX - number, DI - last symbol adress

    push BX
    push AX
    
    mov BH,AH
    call byte_to_hex
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call byte_to_hex
    mov [DI],AH
    dec DI
    mov [DI],AL
    
    pop AX
    pop BX
    ret

wrd_to_hex ENDP

print_seg_adr_of_first PROC NEAR

    mov AX,ES:[0002H]
    mov DI,offset SegAddrOfFirst + 59
    call wrd_to_hex
    mov DX,offset SegAddrOfFirst
    call _print
    
    ret

print_seg_adr_of_first ENDP


print_seg_addr_of_env PROC NEAR

    mov AX,ES:[002CH]
    mov DI,offset SegAddrOfEnv + 39
    call wrd_to_hex
    mov DX,offset SegAddrOfEnv
    call _print
    
    ret

print_seg_addr_of_env ENDP


print_tail_cmd_str PROC NEAR

    xor CX,CX
    mov CL,ES:[0080H]
    
    cmp CL,0H
    je _empty_tail
    
    mov SI,0081H
    
    mov DX,offset CMDTail
    call _print
    
  _tail:
    mov DL,ES:[SI]
    call print_symbol
    inc SI
    loop _tail
    
    mov DL,0DH
    call print_symbol
    mov DL,0AH
    call print_symbol
    
    ret
    
  _empty_tail:
    mov DX,offset CMDTail_empty
    call _print
    
    ret

print_tail_cmd_str ENDP


print_symbol PROC NEAR

   push AX
   
   mov AH,02H
   int 21h
   
   pop AX
   
   ret

print_symbol ENDP


print_env_and_path PROC NEAR

    mov DX,offset Env
    call _print
    
    mov ES,DS:[002CH]
    xor DI,DI
    mov AX,ES:[DI]
    
    cmp AX,00H
    jz _fin
    
    add DI,2
    
  _read_symb:
    mov DL,AL
    call print_symbol
    mov AL,AH
    mov AH,ES:[DI]
    inc DI
    cmp AX,00H
    jne _read_symb
    
  _fin:
    mov DL,0DH
    call print_symbol
    mov DL,0AH
    call print_symbol
    
    mov DX,offset Path
    call _print
    
    add DI,2
    mov DL,ES:[DI]
    inc DI
  _path_read:
    call print_symbol
    mov DL,ES:[DI]
    inc DI
    cmp DL,00H
    jne _path_read
    
    ret

print_env_and_path ENDP
  
    
main PROC NEAR
    
    call print_seg_adr_of_first
    call print_seg_addr_of_env
    call print_tail_cmd_str
    call print_env_and_path
    
    xor AL,AL
    mov AH,01H
    int 21H
    
    mov AH,4CH
    int 21H
    
main ENDP

MainSeg ENDS
END start
