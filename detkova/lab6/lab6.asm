AStack SEGMENT  STACK
          DB 100H DUP('!')
AStack ENDS


DATA SEGMENT

    ErrorMSG db 'Memory free up error: $'
    Err7MSG db 'Memory control block (MCB) is destroyed.', 0DH, 0AH, '$'
    Err8MSG db 'Not enought memory to execute the function.', 0DH, 0AH, '$'
    Err9MSG db 'Incorrect memory block address.', 0DH, 0AH, '$'
    SuccesFreeMSG db 'Memory was freed up successfuly.', 0DH, 0AH, '$'
    
    ParametrBlock dw 0 ;сегментный адрес среды
                  dd 0 ;сегмент и смещение командной строки
                  dd 0 ;сегмент и смещение FCB
                  dd 0 ;сегмент и смещение FCB
                  
    flag db 0
    
    FileName db 'lab2.com$'
    PathName db 50 dup (0)
    
    KEEP_SS dw 0
    KEEP_SP dw 0
    
    LoadErr1MSG db 'Incorrect function number.', 0DH, 0AH, '$'
    LoadErr2MSG db 'File is not found.', 0DH, 0AH, '$'
    LoadErr5MSG db 'Disk error.', 0DH, 0AH, '$'
    LoadErr8MSG db 'Insufficient memory.', 0DH, 0AH, '$'
    LoadErr10MSG db 'Incorrect environment string.', 0DH, 0AH, '$'
    LoadErr11MSG db 'Incorrect format.', 0DH, 0AH, '$'
    
    End0 db 0DH, 0AH, 'Normal completion. Code =    .', 0DH, 0AH, '$'
    End1 db 0DH, 0AH, 'CTRL-Break completion.', 0DH, 0AH, '$'
    End2 db 0DH, 0AH, 'Device error completion.', 0DH, 0AH, '$'
    End3 db 0DH, 0AH, '31H completion.', 0DH, 0AH, '$'
    
DATA ENDS


CODE SEGMENT

ASSUME CS:CODE, SS:AStack, DS:DATA


BYTE_TO_DEC PROC NEAR

    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
  loop_bd:
    div CX
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
  
  end_l:
    pop DX
    pop CX
    ret
    
BYTE_TO_DEC ENDP


_PRINT PROC NEAR

    push AX
    
    mov AH,09H
    int 21H
    
    pop AX
    ret

_PRINT ENDP


FREE_UP_MEMORY PROC NEAR

    push AX
    push BX
    push CX
    push DX
    
    lea BX,end_program
    mov AX,ES
    sub BX,AX
    shr BX,4
    inc BX
    mov AH,4AH
    int 21H
    jnc success_free_up
    mov flag,01H
    
    mov DX,offset ErrorMSG
    call _PRINT
    
    cmp AX,07H
    mov DX,offset Err7MSG
    je end_free_up
    
    cmp AX,08H
    mov DX,offset Err8MSG
    je end_free_up
    
    cmp AX,09H
    mov DX,offset Err9MSG
    je end_free_up
    
  success_free_up:
    mov DX,offset SuccesFreeMSG
    
  end_free_up:
    call _PRINT
    
    pop DX
    pop CX
    pop BX
    pop AX 
    ret  

FREE_UP_MEMORY ENDP


SET_PARAMETRS PROC NEAR

    push AX
    
    mov AX,ES:[2CH]
    mov ParametrBlock,AX
    mov ParametrBlock+2,ES
    mov ParametrBlock+4,80H
    
    pop AX
    ret

SET_PARAMETRS ENDP


GET_PATH PROC NEAR

    push AX
    push BX
    push DX
    push SI
    push DI
    push ES
    
    xor DI,DI
    mov ES,ES:[2CH]
   
  skip_content:
    mov DL,ES:[DI]
    cmp DL,0H
    je last_content
    inc DI
    jmp skip_content
      
  last_content:
    inc DI
    mov DL,ES:[DI]
    cmp DL,0H
    jne skip_content
   
    add DI,3H
    mov SI,0H
    
  write_path:
    mov DL,ES:[DI]
    cmp DL,0H
    je delete_file_name
    mov PathName[SI],DL
    inc DI
    inc SI
    jmp write_path

  delete_file_name:
    dec SI
    cmp PathName[SI],'\'
    je ready_add_file_name
    jmp delete_file_name
   
  ready_add_file_name:
    mov DI,-1

  add_file_name:
    inc SI
    inc DI
    mov DL,FileName[DI]
    cmp DL,'$'
    je path_end
    mov PathName[SI],DL
    jmp add_file_name
   
 path_end:
    
    pop ES
    pop DI
    pop SI
    pop DX
    pop BX
    pop AX
    ret

GET_PATH ENDP


RUN_LAB2 PROC NEAR

    push AX
    push BX
    push CX
    push DX
    push DS
    push ES
    
    mov KEEP_SP,SP
    mov KEEP_SS,SS
    
    mov AX,DATA
    mov ES,AX
    mov BX,offset ParametrBlock
    mov DX,offset PathName
    mov AX,4B00H
    int 21H
    
    mov SS,KEEP_SS
    mov SP,KEEP_SP
    pop ES
    pop DS
    
    jnc loading_successful
    
    cmp AX,01H
    mov DX,offset LoadErr1MSG
    je print_err
    cmp AX,02H
    mov DX,offset LoadErr2MSG
    je print_err
    cmp AX,05H
    mov DX,offset LoadErr5MSG
    je print_err
    cmp AX,08H
    mov DX,offset LoadErr8MSG
    je print_err
    cmp AX,10H
    mov DX,offset LoadErr10MSG
    je print_err
    cmp AX,11H
    mov DX,offset LoadErr11MSG
    je print_err
    
    
  loading_successful:
    
    mov AX,4D00H
    int 21H
    
    cmp AH,01H
    mov DX,offset End1
    je print_err
    cmp AH,02H
    mov DX,offset End2
    je print_err
    cmp AH,03H
    mov DX,offset End3
    je print_err
    cmp AH,00H
    jne end_run
    
    mov SI,offset End0+30
    call BYTE_TO_DEC 
    mov DX,offset End0
    
  print_err:
    call _PRINT
  
  end_run:
    pop DX
    pop CX
    pop BX
    pop AX
    
    ret

RUN_LAB2 ENDP



MAIN	  PROC  FAR

    sub AX,AX
    push AX  
    mov AX,DATA
    mov DS,AX
    
    call FREE_UP_MEMORY
    cmp flag,0
    jne final
    call SET_PARAMETRS
    call GET_PATH
    call RUN_LAB2
    
  final:  
    mov AH,4CH
    xor AL,AL
    int 21H             
                                            
Main      ENDP

end_program:
CODE      ENDS
          END MAIN
