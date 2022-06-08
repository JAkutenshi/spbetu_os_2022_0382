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
    PSP dw 0
    KEEP_IP dw 0
    KEEP_CS dw 0
    KEEP_SS dw 0
    KEEP_SP dw 0
    KEEP_AX dw 0
    KEY_SYM db 0
    int_indicator DW 0AAAAH
    LocalStack db 50 dup(" ")

  handle:
    mov KEEP_AX, AX
    mov AX, SS
    mov KEEP_SS, AX
    mov KEEP_SP, SP
    mov AX, seg LocalStack
    mov SS, AX
    mov SP, offset handle

    push AX
    push BX
    push CX
    push DX

    in AL, 60h
    cmp AL, 1Dh
    je left_ctrl
    cmp AL, 21h
    je f_key
    cmp AL, 10h
    je q_key

    call dword ptr CS:KEEP_IP
    jmp exit_int

  left_ctrl:
    mov KEY_SYM, '*'
    jmp next_key
  f_key:
    mov KEY_SYM, 'a'
    jmp next_key
  q_key:
    mov KEY_SYM, 'N'
	
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
    mov CL, KEY_SYM
    mov CH, 00h
    int 16h
    or AL, AL
    jz exit_int
    mov AX, 40h
    mov ES, AX
    mov AX, ES:[1Ah]
    mov ES:[1Ch], AX
    jmp print_key

  exit_int:	
    pop DX
    pop CX
    pop BX
    pop AX

    mov SP, KEEP_SP
    mov AX, KEEP_SS
    mov SS, AX
    mov AX, KEEP_AX
    mov AL, 20h
    out 20h, AL
    
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
    mov AL,09H
    int 21H
    mov keep_IP,BX
    mov keep_CS,ES
    
    push DS
    mov DX,offset my_interuption
    mov AX,seg my_interuption
    mov DS,AX
    mov AH,25H
    mov AL,09H
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
    mov AL,09H
    int 21H
    mov DX,ES:[offset keep_IP]
    mov AX,ES:[offset keep_CS]
    mov DS,AX
    mov AH,25H
    mov AL,09H
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
    mov AL,09H
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
