AStack SEGMENT  STACK
          DB 100H DUP('!')
AStack ENDS


DATA SEGMENT

    flag DB 0
    msg_is_load DB 'Interruption was loaded.$'
    msg_is_in_memory DB 'Interruption has already been loaded.$'
    msg_is_unload DB 'Interruption was unloaded.$'
    msg_is_not_load DB 'Interruption was not loaded.$'

DATA ENDS


CODE SEGMENT

ASSUME CS:CODE, SS:AStack, DS:DATA


my_interuption  PROC FAR

    jmp handle
        
    PSP DW ?
    keep_CS DW 0
    keep_IP DW 0
    keep_SS DW 0
    keep_SP DW 0
    keep_AX DW 0
        
    int_indicator DW 0AAAAH
    counter DB 'Counter:    0000'
    counter_len = $ - counter
    int_stack DB 100H dup (?)
   end_stack:
    
  handle:
    mov keep_SS,SS
    mov keep_SP,SP
    mov keep_AX,AX
    mov AX,CS
    mov SS,AX
    mov SP,offset end_stack
    push BX
    push CX
    push DX
    push DS
    push ES
    push SI
    push DI
    push BP
    
    mov AH,03H
    mov BH,0
    int 10H
    push DX
    
    mov AH,02H
    mov BH,0
    mov DX,0
    int 10H
    
    push BP
    push DS
    push SI
    mov DX,seg counter
    mov DS,DX
    mov SI,offset counter
    mov CX,5
    
  lp:
    mov BP,CX
    dec BP
    mov AL,[SI+BP+11]
    inc AL
    mov [SI+BP+11],AL
    cmp AL,3AH
    jne end_int
    mov AL,30H
    mov [SI+BP+11],AL
    loop lp
    
  end_int:
    pop SI
    pop DS
    
    push ES
    mov DX,seg counter
    mov ES,DX
    mov BP,offset counter
    mov AH,13H
    mov AL,1
    mov BH,0
    mov CX,counter_len
    mov DX,0
    int 10H
    pop ES
    pop BP
    
    mov AH,02H
    mov BH,0
    pop DX
    int 10H

    pop BP
    pop DI
    pop SI
    pop ES
    pop DS
    pop DX
    pop CX
    pop BX    
    
    mov AX,keep_SS
    mov SS,AX
    mov SP,keep_SP
    mov AX,keep_AX
    mov AL,20H
    out 20H,AL
    iret
    
  int_end:
    
my_interuption  ENDP


load_int PROC NEAR

    push AX
    push BX
    push CX
    push DX
    push ES
    
    mov AH,35H
    mov AL,1CH
    int 21H
    mov keep_IP,BX
    mov keep_CS,ES
    
    push DS
    mov DX,offset my_interuption
    mov AX,seg my_interuption
    mov DS,AX
    mov AH,25H
    mov AL,1CH
    int 21H
    pop DS
    
    mov DX,offset int_end
    mov CL,4
    shr DX,CL
    inc DX
    mov AX,CS
    sub AX,PSP
    add DX,AX
    xor AX,AX
    mov AH,31H
    int 21H
    
    pop ES
    pop DX
    pop CX
    pop BX
    pop AX
    ret

load_int ENDP


unload_int PROC NEAR

    push AX
    push BX
    push CX
    push DX
    push ES
    push DS
    
    cli
    mov AH,35H
    mov AL,1CH
    int 21H
    mov DX,ES:[offset keep_IP]
    mov AX,ES:[offset keep_CS]
    mov DS,AX
    mov AH,25H
    mov AL,1CH
    int 21H
    
    mov AX,ES:[offset PSP]
    mov ES,AX
    push ES
    mov AX,ES:[2CH]
    mov ES,AX
    mov AH,49H
    int 21H
    pop ES
    mov AH,49H
    int 21H
    sti
    
    pop DS
    pop ES
    pop DX
    pop CX
    pop BX
    pop AX
    ret

unload_int ENDP


find_cmd_key PROC NEAR

    push AX
    push SI
    
    mov SI,82H
    mov AL,ES:[SI]
    cmp AL,'/'
    jne end_check
    
    inc SI
    mov AL,ES:[SI]
    cmp AL,'u'
    jne end_check
    
    inc SI
    mov AL,ES:[SI]
    cmp AL,'n'
    jne end_check
    mov flag,1
    
  end_check:
    pop SI
    pop AX
    ret

find_cmd_key ENDP


is_loaded_int PROC NEAR

    push AX
    push DX
    push SI
    
    mov flag,1
    mov AH,35H
    mov AL,1CH
    int 21H
    
    mov SI,offset int_indicator
    sub SI,offset my_interuption
    mov DX,ES:[BX+SI]
    cmp DX,0AAAAH
    je is_loaded
    mov flag,0
    
  is_loaded:
    pop SI
    pop DX
    pop AX
    ret

is_loaded_int ENDP


_print PROC NEAR

    push AX
    
    mov AH,09H
    int 21H
    
    pop AX
    ret

_print ENDP


MAIN	  PROC  FAR
	  
    mov AX,DATA
    mov DS,AX
    mov PSP,ES
    mov flag,0
    call find_cmd_key
    cmp flag,1
    je unload
    
    call is_loaded_int
    cmp flag,0
    je not_loaded
    mov DX,offset msg_is_in_memory
    call _print
    jmp final
    
  not_loaded:
    mov DX,offset msg_is_load
    call _print
    call load_int
    jmp final
 
  unload:
    call is_loaded_int
    cmp flag,0
    jne already_loaded
    mov DX,offset msg_is_not_load
    call _print
    jmp final
    
  already_loaded:
    call unload_int
    mov DX,offset msg_is_unload
    call _print
    
  final:
    mov AH,4CH
    xor AL,AL
    int 21H             
                                            
Main      ENDP
CODE      ENDS
          END MAIN
