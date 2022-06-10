MainSeg SEGMENT
    ASSUME CS:MainSeg, DS:MainSeg, ES:NOTHING, SS:NOTHING
    ORG 100H
    
START:
    jmp BEGIN
    
DATA:
    memorySize db "Size of available memory =       ", 0DH, 0AH, "$"
    extMemorySize db "Size of extended memory =         ", 0DH, 0AH, "$"
    MCB db "MCB:   ; adress:     H; PSP:     H; size in bytes:       ; SC\SD:         ", 0DH, 0AH, "$"
   

BYTE_TO_DEC PROC NEAR
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
BYTE_TO_DEC ENDP

TETR_TO_HEX PROC NEAR
    and AL,0FH    ; save only last part of byte
    cmp AL,09
    jbe next
    add AL,07
  next:
    add AL,30H
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC NEAR
    ; AL - number -> 2 symbols in 16 numb. syst. in AX

    push CX
    
    mov AH,AL    ; save AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX    ; AL - high numb ascii, AH - low numb ascii
    
    pop CX
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC NEAR
    ; AX - number, DI - last symbol adress

    push BX
    push AX
    
    mov BH,AH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    
    pop AX
    pop BX
    ret
WRD_TO_HEX ENDP

PRINT PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
PRINT ENDP

HEX_TO_DEC PROC NEAR
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
HEX_TO_DEC ENDP

PAR_TO_DEC PROC NEAR
    ; AX - size in paragraphs, SI - adress of last symbol in result string
    
    push AX
    push BX
    push DX
    push SI
    
    mov BX,10H
    mul BX     ; AX*16
    
    call HEX_TO_DEC
    
    pop SI
    pop DX
    pop BX
    pop AX
    ret
PAR_TO_DEC ENDP

kByteToByte PROC NEAR
    push AX
    push BX
    push DX
    push SI
    
    mov BX,10000 ; separated 4 chars from DX AX, AX = (DX AX) div BX,
    div BX ; DX = (DX AX) mod BX
    push AX 
    mov AX,DX ; explore DX AX - last 6 (in 10 numb syst) chars from DX AX
    xor DX,DX
    
    call HEX_TO_DEC
    
    pop AX ; explore DX AX - first 5 (in 10 numb syst) chars
    
    call HEX_TO_DEC
    
    pop SI
    pop DX
    pop BX
    pop AX
    ret
kByteToByte ENDP

printMemorySize PROC NEAR
    mov AH,4AH
    mov BX,0FFFFH
    int 21H
    
    mov AX,BX
    mov SI,offset memorySize + 32
    call PAR_TO_DEC
    mov DX,offset memorySize
    call PRINT
    ret
printMemorySize ENDP

printExtMemorySize PROC NEAR
    mov AL,30H
    out 70H,AL
    in AL,71H
    mov BL,AL
    mov AL,31H
    out 70H,AL
    in AL,71H
    mov AH,AL
    mov AL,BL
    
    mov SI,offset extMemorySize + 33
    mov BX,400H ; multiply 1024
    mul BX
      
    call kByteToByte
    
    mov DX,offset extMemorySize
    call PRINT
    ret
printExtMemorySize ENDP

nextMCB PROC NEAR

    push AX
    push ES
    push CX
    push DX
    push BX
    
    mov AX,CX
    mov SI,offset mcb + 6
    call BYTE_TO_DEC
    
    mov AX,ES
    mov DI,offset mcb + 20
    call WRD_TO_HEX
    
    mov AX,ES:[01H]
    mov DI,offset mcb + 32
    call WRD_TO_HEX
    
    mov AX,ES:[03H]
    mov SI,offset mcb + 56
    call PAR_TO_DEC
    
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
    call PRINT
     
    pop BX 
    pop DX
    pop CX
    pop ES
    pop AX
    ret
nextMCB ENDP

printMCB PROC NEAR
    mov AH,52H
    int 21H
    
    mov AX,ES:[BX-2]
    mov ES,AX
    
    xor CX,CX
    mov CX,1H
    
    mcb_lp:
      call nextMCB
      
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
printMCB ENDP
    
BEGIN:   
    call printMemorySize
    call printExtMemorySize
    call printMCB
    xor AL,AL
	mov AH,4Ch
	int 21H

MainSeg ENDS
END START 