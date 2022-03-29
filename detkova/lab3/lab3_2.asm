MainSeg SEGMENT
    ASSUME CS:MainSeg, DS:MainSeg, ES:NOTHING, SS:NOTHING
    ORG 100H
    
start:
    jmp begin
    
data:
    mem_size db "Size of available memory =       .", 0DH, 0AH, "$"
    ext_mem_size db "Size of extended memory =         .", 0DH, 0AH, "$"
    mcb db "MCB:   ; adress:     H; PSP:     H; size in bytes:       ; SC\SD:         ", 0DH, 0AH, "$"

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

    ; AL - number, SI - adress of last symbol

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

hex_to_dec PROC NEAR
    
    ; AX - size in paragraphs, SI - adress of last symbol in result string
    
    mov BX,0AH
    
    loop_wr:
    div BX
    add DX,30H
    mov [SI],DL
    xor DX,DX
    dec SI
    cmp AX,0000H
    jne loop_wr
    
    ret

hex_to_dec ENDP

par_to_dec PROC NEAR
    
    ; AX - size in paragraphs, SI - adress of last symbol in result string
    
    push AX
    push BX
    push DX
    push SI
    
    mov BX,10H
    mul BX     ; AX*16
    
    call hex_to_dec
    
    pop SI
    pop DX
    pop BX
    pop AX
    ret

par_to_dec ENDP

kbyte_to_byte PROC NEAR

    push AX
    push BX
    push DX
    push SI
    
    mov BX,10000 ; separated 4 chars from DX AX, AX = (DX AX) div BX,
    div BX ; DX = (DX AX) mod BX
    push AX 
    mov AX,DX ; explore DX AX - last 6 (in 10 numb syst) chars from DX AX
    xor DX,DX
    
    call hex_to_dec
    
    pop AX ; explore DX AX - first 5 (in 10 numb syst) chars
    
    call hex_to_dec
    
    pop SI
    pop DX
    pop BX
    pop AX
    ret

kbyte_to_byte ENDP

print_mem_size PROC NEAR

    mov AH,4AH
    mov BX,0FFFFH
    int 21H
    
    mov AX,BX
    mov SI,offset mem_size + 32
    call par_to_dec
    mov DX,offset mem_size
    call _print
    ret

print_mem_size ENDP

print_ext_mem_size PROC NEAR

    mov AL,30H
    out 70H,AL
    in AL,71H
    mov BL,AL
    mov AL,31H
    out 70H,AL
    in AL,71H
    mov AH,AL
    mov AL,BL
    
    mov SI,offset ext_mem_size + 33
    mov BX,400H ; multiply 1024
    mul BX
      
    call kbyte_to_byte
    
    mov DX,offset ext_mem_size
    call _print
    ret

print_ext_mem_size ENDP

one_mcb PROC NEAR

    push AX
    push ES
    push CX
    push DX
    push BX
    
    mov AX,CX
    mov SI,offset mcb + 6
    call byte_to_dec
    
    mov AX,ES
    mov DI,offset mcb + 20
    call wrd_to_hex
    
    mov AX,ES:[01H]
    mov DI,offset mcb + 32
    call wrd_to_hex
    
    mov AX,ES:[03H]
    mov SI,offset mcb + 56
    call par_to_dec
    
    mov BX,08H
    mov CX,7
    mov SI,offset mcb + 66
    one_mcb_lp:
      mov DX,ES:[BX]
      mov [SI],DX
      inc BX
      inc SI
      loop one_mcb_lp
    
    mov DX,offset mcb
    call _print
     
    pop BX 
    pop DX
    pop CX
    pop ES
    pop AX
    ret

one_mcb ENDP

print_table_mcb PROC NEAR

    mov AH,52H
    int 21H
    
    mov AX,ES:[BX-2]
    mov ES,AX
    
    xor CX,CX
    mov CX,1H
    
    mcb_lp:
      call one_mcb
      
      mov AL,ES:[00H]
      cmp AL,5AH
      je end_mcb
      
      mov BX,ES:[03H]
      mov AX,ES
      add AX,BX
      inc AX
      mov ES,AX
      inc CX
      jmp mcb_lp
    
    end_mcb:
      ret

print_table_mcb ENDP
  
freeup_mem PROC NEAR
    
    lea AX,end_progr
    mov BX,10H ; size of paragraph
    xor DX,DX
    div BX
    mov BX,AX
    mov AH,4AH
    int 21H
    
    ret
    
freeup_mem ENDP  
  
main PROC NEAR
    
    call print_mem_size
    call print_ext_mem_size
    call freeup_mem
    call print_table_mcb
    ret
    
main ENDP

end_progr:

MainSeg ENDS
END start

