MainSeg SEGMENT
    ASSUME CS:MainSeg, DS:MainSeg, ES:NOTHING, SS:NOTHING
    ORG 100H
    
start:
    jmp begin
    
data:
    pc db 'IBM PC type - PC.', 0DH, 0AH, '$'
    pcxt db 'IBM PC type - PC/XT.', 0DH, 0AH, '$'
    at db 'IBM PC type - AT.', 0DH, 0AH, '$'
    ps2_30 db 'IBM PC type - PS2 model 30.', 0DH, 0AH, '$'
    ps2_50_60 db 'IBM PC type - PS2 model 50 or 60.', 0DH, 0AH, '$'
    ps2_80 db 'IBM PC type - PS2 model 80.', 0DH, 0AH, '$'
    pcjr db 'IBM PC type - PCjr.', 0DH, 0AH, '$'
    pcconv db 'IBM PC type - PC Convertible.', 0DH, 0AH, '$'
    
    dos_vers db 'MS DOS version -  . .', 0DH, 0AH, '$'
    oem_numb db 'OEM number -    .', 0DH, 0AH, '$'
    user_numb db 'User number -       h.', 0DH, 0AH, '$'

begin:
    call main
    xor AL,AL
    mov AH,4CH
    int 21H
   
_print PROC NEAR
    
    mov AH, 09H
    int 21H
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

print_PC_type PROC NEAR

    mov AX,0F000H
    mov ES,AX ; ES -> ROM BIOS
    mov AL,ES:[0FFFEH]
    
    cmp AL,0FFH
    je _pc_
    cmp AL,0FEH
    je _pc_xt_
    cmp AL,0FBH
    je _pc_xt_
    cmp AL,0FCH
    je _at_
    cmp AL,0FAH
    je _ps2_30_
    cmp AL,0FCH
    je _ps2_50_60_
    cmp AL,0F8H
    je _ps2_80_
    cmp AL,0FDH
    je _pcjr_
    cmp AL,0F9H
    je _pcconv_
    
  _pc_:
    mov DX,offset pc
    jmp _end_
    
  _pc_xt_:
    mov DX,offset pcxt
    jmp _end_
    
  _at_:
    mov DX,offset at
    jmp _end_
    
  _ps2_30_:
    mov DX,offset ps2_30
    jmp _end_
    
  _ps2_50_60_:
    mov DX,offset ps2_50_60
    jmp _end_
    
  _ps2_80_:
    mov DX,offset ps2_80
    jmp _end_
    
  _pcjr_:
    mov DX,offset pcjr
    jmp _end_
    
  _pcconv_:
    mov DX,offset pcconv
    jmp _end_
    
  _end_:
    call _print
    ret

print_PC_type ENDP

print_dos_version PROC NEAR

    mov AH,30H
    int 21H
    mov SI,offset dos_vers + 17
    call byte_to_dec
    mov AL,AH
    add SI,3
    call byte_to_dec
    mov DX,offset dos_vers
    call _print
    ret

print_dos_version ENDP   

print_oem_number PROC NEAR

    mov AH,30H
    int 21H
    mov AL,BH
    mov SI,offset oem_numb + 15
    call byte_to_dec
    mov DX,offset oem_numb
    call _print
    ret

print_oem_number ENDP

print_user_number PROC NEAR

    mov AH,30H
    int 21H
    mov AX,CX
    mov DI,offset user_numb + 19
    call wrd_to_hex
    mov AL,BL
    call byte_to_hex
    dec DI
    mov [DI],AH
    dec DI
    mov [DI],AL
    mov DX,offset user_numb
    call _print
    ret

print_user_number ENDP
    
main PROC NEAR
    
    call print_PC_type
    call print_dos_version
    call print_oem_number
    call print_user_number
    ret
    
main ENDP

MainSeg ENDS
END start

