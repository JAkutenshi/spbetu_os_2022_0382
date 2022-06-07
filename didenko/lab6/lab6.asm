AStack    SEGMENT  STACK
          DW 64 DUP(?)   
AStack    ENDS

DATA  SEGMENT
   PARAMETR_BLOCK dw 0 ;сегментный адрес среды
                  dd 0 ;сегмент и смещение командной строки
                  dd 0 ;сегмент и смещение FCB 
                  dd 0 ;сегмент и смещение FCB 
                  
   KEEP_SS dw 0
   KEEP_SP dw 0
   
   STR_FILE_NAME db 'lab2.COM$'
   STR_PATCH_NAME db 50 dup (0)
   
   STR_MEMORY_7 db 'Сontrol memory block destroyed',13,10,'$'
   STR_MEMORY_8 db 'Low memory size for function',13,10,'$'
   STR_MEMORY_9 db 'Invalid memory address',13,10,'$'
   
   STR_ERROR_1 db 'Finction number isnt correct',13,10,'$'
   STR_ERROR_2 db 'File not found',13,10,'$'
   STR_ERROR_5 db 'Disk errror',13,10,'$'
   STR_ERROR_8 db 'Low memory size',13,10,'$'
   STR_ERROR_10 db 'Bad string enviroment',13,10,'$'
   STR_ERROR_11 db 'Incorrect format',13,10,'$'
   
   STR_COMPLETION_0 db 'Normal completion. Code =    ',13,10,'$'

   STR_COMPLETION_1 db 'Ctrl-Break completion',13,10,'$'
   STR_COMPLETION_2 db 'Device error completion',13,10,'$'
   STR_COMPLETION_3 db '31h completion',13,10,'$'

DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack
   ; Процедуры
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
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
;-------------------------------
WRITESTRING PROC near
   mov AH,09h
   int 21h
   ret
WRITESTRING ENDP

FREE_MEMORY PROC
   push ax
   push bx
   
   lea bx, m_end_program
   mov ax,es
   sub bx,ax
   mov ax,bx
   shr bx,4
   inc bx
   mov ah,4ah
   int 21h
   jnc m_end_memory
   
   lea dx, STR_MEMORY_7
   cmp ax,7
   je m_memory_write
   lea dx, STR_MEMORY_8
   cmp ax,7
   je m_memory_write
   lea dx,STR_MEMORY_9
   cmp ax,7
   je m_memory_write
   jmp m_end_memory
   
m_memory_write:
   call WRITESTRING
   
m_end_memory:   
   pop bx
   pop ax
   ret
FREE_MEMORY ENDP

SET_PARAMETERS PROC NEAR
   mov ax,es:[2ch]
   mov PARAMETR_BLOCK,ax
   mov PARAMETR_BLOCK+2,es
   mov PARAMETR_BLOCK+4,80h
   ret
SET_PARAMETERS ENDP

SET_FULL_FILE_NAME PROC NEAR
   push dx
   push di
   push si
   push es
   
   xor di,di
   mov es,es:[2ch]
   
m_skip_content:
   mov dl,es:[di]
   cmp dl,0h
   je m_last_content
   inc di
   jmp m_skip_content
      
m_last_content:
   inc di
   mov dl,es:[di]
   cmp dl,0h
   jne m_skip_content
   
   add di,3h
   mov si,0
   
m_write_patch:
   mov dl,es:[di]
   cmp dl,0h
   je m_delete_file_name
   mov STR_PATCH_NAME[si],dl
   inc di
   inc si
   jmp m_write_patch

m_delete_file_name:
   dec si
   cmp STR_PATCH_NAME[si],'\'
   je m_ready_add_file_name
   jmp m_delete_file_name
   
m_ready_add_file_name:
   mov di,-1

m_add_file_name:
   inc si
   inc di
   mov dl,STR_FILE_NAME[di]
   cmp dl,'$'
   je m_set_patch_end
   mov STR_PATCH_NAME[si],dl
   jmp m_add_file_name
   
m_set_patch_end:
   pop es
   pop si
   pop di
   pop dx
   ret
SET_FULL_FILE_NAME ENDP

START_LAB2 PROC NEAR
   push ds
   push es
   
   mov KEEP_SP,sp
   mov KEEP_SS,ss
   mov ax,ds
   mov es,ax
   
   lea dx, STR_PATCH_NAME
   lea bx, PARAMETR_BLOCK
   mov ax,4B00h
   int 21h
   
   mov ss,KEEP_SS
   mov sp,KEEP_SP
   
   pop es
   pop ds  
   call NEW_LINE
   
   call COMMENT_LOAD
   ret
START_LAB2 ENDP


COMMENT_LOAD PROC
   push dx
   push ax
   push si
   
   jc m_uncorrect_launch
 
   mov ax, 4D00h
   int 21h

   lea dx, STR_COMPLETION_1
   cmp ah,1
   je m_write_comment
   lea dx, STR_COMPLETION_2
   cmp ah,2
   je m_write_comment
   lea dx, STR_COMPLETION_3
   cmp ah,3
   je m_write_comment
   cmp ah,0
   jne m_comment_end
   
   lea dx, STR_COMPLETION_0
   mov si, dx
   add si, 28  
   call BYTE_TO_DEC
 
   jmp m_write_comment
   
m_uncorrect_launch: 
   
   lea dx, STR_ERROR_1
   cmp ax,1
   je m_write_comment
   lea dx, STR_ERROR_2
   cmp ax,2
   je m_write_comment   
   lea dx, STR_ERROR_5
   cmp ax,5
   je m_write_comment   
   lea dx, STR_ERROR_8
   cmp ax,8
   je m_write_comment   
   lea dx, STR_ERROR_10
   cmp ax,10
   je m_write_comment
   lea dx, STR_ERROR_11
   cmp ax,11
   je m_write_comment
   
m_write_comment:
   call WRITESTRING
m_comment_end:   
   pop si
   pop ax
   pop si
   ret
COMMENT_LOAD ENDP

NEW_LINE PROC NEAR
   push dx
   push ax
   
   mov dl,10
   mov ah,02h
   int 21h
   mov dl,13
   mov ah,02h
   int 21h  
   
   pop ax
   pop dx
   ret
NEW_LINE ENDP

Main PROC FAR
   sub   AX,AX
   push  AX
   mov   AX,DATA
   mov   DS,AX
   
   call FREE_MEMORY
   call PARAMETR_BLOCK
   call SET_FULL_FILE_NAME
   call START_LAB2
   
   xor AL,AL
   mov AH,4Ch
   int 21H
Main ENDP
m_end_program:
CODE ENDS
      END Main