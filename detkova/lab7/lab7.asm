AStack SEGMENT  STACK
          DB 100H DUP('!')
AStack ENDS


DATA SEGMENT

    ErrorMSG db 'Memory free up error: $'
    Err7MSG db 'Memory control block (MCB) is destroyed.', 0DH, 0AH, '$'
    Err8MSG db 'Not enought memory to execute the function.', 0DH, 0AH, '$'
    Err9MSG db 'Incorrect memory block address.', 0DH, 0AH, '$'
    SuccesFreeMSG db 'Memory was freed up successfuly.', 0DH, 0AH, '$'
    flag db 0
    
    KEEP_SS dw 0
    KEEP_SP dw 0
    DTA db 43 dup(?)
    OverlayAdress dd 0
    
    FileName1 db 'overlay1.ovl$'
    FileName2 db 'overlay2.ovl$'
    PathName db 50 dup (0)
    NewLine db 0DH, 0AH, '$'
    
    AllocErr db 'Allocation error: $'
    AllocErr2 db 'File is not found.', 0DH, 0AH, '$'
    AllocErr3 db 'Path is not found.', 0DH, 0AH, '$'
    AllocSuccessful db 'Allocation is successful.', 0DH, 0AH, '$'
    
    LoadErr db 'Overlay loading error: $'
    LoadErr1MSG db 'Non-existent function.', 0DH, 0AH, '$'
    LoadErr2MSG db 'File is not found.', 0DH, 0AH, '$'
    LoadErr3MSG db 'Path is not found.', 0DH, 0AH, '$'
    LoadErr4MSG db 'Too many opened files.', 0DH, 0AH, '$'
    LoadErr5MSG db 'No access.', 0DH, 0AH, '$'
    LoadErr8MSG db 'Not enough memory.', 0DH, 0AH, '$'
    LoadErr10MSG db 'Incorrect environment.', 0DH, 0AH, '$'
    LoadSuccessful db 'Loading successful.', 0DH, 0AH, '$'
    
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


GET_PATH PROC NEAR

    ; BX - overlay file name
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
    mov DL,BX[DI]
    cmp DL,'$'
    je path_end
    mov PathName[SI],DL
    jmp add_file_name
   
 path_end:
    mov DL,BX[7]
    mov PathName[10],DL
    mov PathName[SI],'$'
    pop ES
    pop DI
    pop SI
    pop DX
    pop BX
    pop AX
    ret

GET_PATH ENDP


ALLOCATION PROC NEAR

    push AX
    push BX
    push CX
    push DX
    
    mov DX,offset DTA
    mov AH,1AH
    int 21H
    
    mov DX,offset PathName
    mov CX,0
    mov AH,4EH
    int 21H
    
    jnc success_alloc
    
    mov DX,offset AllocErr
    call _PRINT
    
    cmp AX,02H
    mov DX,offset AllocErr2
    je end_alloc
    
    mov DX,offset AllocErr3
    jmp end_alloc
    
  success_alloc:
    mov DI,offset DTA
    mov DX,[DI+1CH]
    mov AX,[DI+1AH]
    
    mov BX,10H
    div BX
    inc AX
    mov BX,AX
    mov AH,48H
    int 21H
    
    mov BX,offset OverlayAdress
    mov CX,0H
    mov [BX],AX
    mov [BX+2],CX
    
    mov DX,offset AllocSuccessful
    
  end_alloc:
    call _PRINT
    
    pop DX
    pop CX
    pop BX
    pop DX
    ret

ALLOCATION ENDP


LOAD_OVERLAY PROC NEAR

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
    mov BX,offset OverlayAdress
    mov DX,offset PathName
    mov AX,4B03H
    int 21h
    
    mov SP,KEEP_SP
    mov SS,KEEP_SS
    pop ES
    pop DS
    
    jnc loading_successful
    
    mov DX,offset LoadErr
    call _PRINT
    
    cmp AX,01H
    mov DX,offset LoadErr1MSG
    je print_err
    
    cmp AX,02H
    mov DX,offset LoadErr2MSG
    je print_err
    
    cmp AX,03H
    mov DX,offset LoadErr3MSG
    je print_err
    
    cmp AX,04H
    mov DX,offset LoadErr4MSG
    je print_err
    
    cmp AX,05H
    mov DX,offset LoadErr5MSG
    je print_err
    
    cmp AX,08H
    mov DX,offset LoadErr8MSG
    je print_err
    
    cmp AX,0AH
    mov DX,offset LoadErr10MSG
    je print_err
    
  print_err:
    call _PRINT
    jmp end_load
    
  loading_successful:
     mov DX,offset LoadSuccessful
     call _PRINT
     
     mov BX,offset OverlayAdress
     mov AX,[BX]
     mov CX,[BX+2]
     mov [BX],CX
     mov [BX+2],AX
     
     call OverlayAdress
     
     mov ES,AX
     mov AH,49H
     int 21H
    
  end_load:
    
    pop DX
    pop CX
    pop BX
    pop AX
    ret

LOAD_OVERLAY ENDP


MAIN	  PROC  FAR

    sub AX,AX
    push AX  
    mov AX,DATA
    mov DS,AX
    
    call FREE_UP_MEMORY
    cmp flag,0
    jne final
    
    mov DX,offset NewLine
    call _PRINT
    mov BX,offset FileName1
    call GET_PATH
    call ALLOCATION
    call LOAD_OVERLAY
    
    mov DX,offset NewLine
    call _PRINT
    mov BX,offset FileName2
    call GET_PATH
    call ALLOCATION
    call LOAD_OVERLAY
    
  final:  
    mov AH,4CH
    xor AL,AL
    int 21H             
                                            
Main      ENDP

end_program:
CODE      ENDS
          END MAIN
