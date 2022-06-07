CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:ASTACK

;-------------------------------
          
MY_ITERRUPT PROC far
   jmp m_start_my_iterrupt
   
   PSP dw ?
   KEEP_IP dw 0
   KEEP_CS dw 0
   ITERRUPT_ID dw 8f17h
   
   STR_ITERRUPT db 'SUCCESS WORK LAB! $'
   
	KEEP_SS dw ?
	KEEP_SP dw ?
	KEEP_AX dw ?
   REQ_KEY db 3Bh ; f1
   STR_INDEX db 0
	ITERRUPT_STACK dw 32 dup (?)
	END_IT_STACK dw ?
   
m_start_my_iterrupt:
   mov KEEP_SS,ss
   mov KEEP_SP,sp
   mov KEEP_AX,ax

   mov ax,cs
   mov ss,ax
   mov sp,offset END_IT_STACK

   push bx
   push cx
   push dx
   
   in al,60h
   cmp al,REQ_KEY
   je m_do_req
   call dword ptr cs:KEEP_IP
   jmp m_iter_end
   
m_do_req:
   in al,61h
	mov ah, al    
	or al, 80h    
	out 61h, al  
	xchg ah, al    
	out 61h, al    
	mov al, 20h     
	out 20h, al  

   xor bx,bx
   mov bl,STR_INDEX
   
m_write_s:
   mov ah,05h
   mov cl,STR_ITERRUPT[bx]
   cmp cl,'$'
   je m_str_end
   mov ch,00h
   int 16h
   or al,al
   jnz m_skip
   inc bl
   mov STR_INDEX,bl
   jmp m_iter_end
   
m_skip:
   mov ax,0C00h
   int 21h
   jmp m_write_s

m_str_end:
   mov STR_INDEX,0

m_iter_end:
   
	pop dx
	pop cx
	pop bx
   
	mov ax, KEEP_SS
	mov ss, ax
	mov ax, KEEP_AX
	mov sp, KEEP_SP

   iret
m_iterrapt_end:
MY_ITERRUPT ENDP          

;-------------------------------          

WRITE_STRING PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
WRITE_STRING ENDP
;-------------------------------

LOAD_FLAG PROC near
   push ax
   
   mov PSP,es
   mov al,es:[81h+1]
   cmp al,'/'
   jne m_load_flag_end
   mov al,es:[81h+2]
   cmp al, 'u'
   jne m_load_flag_end
   mov al,es:[81h+3]
   cmp al, 'n'
   jne m_load_flag_end
   mov flag,1h
  
m_load_flag_end:
   pop ax
   ret
LOAD_FLAG ENDP

;-------------------------------

IS_LOAD PROC near
   push ax
   push si
   
   mov ah,35h
   mov al,1Ch
   int 21h
   mov si,offset ITERRUPT_ID
   sub si,offset MY_ITERRUPT
   mov dx,es:[bx+si]
   cmp dx, 8f17h
   jne m_is_load_end
   mov flag_load,1h
m_is_load_end:   
   pop si
   pop ax
   ret
IS_LOAD ENDP

;-------------------------------

LOAD_ITERRAPT PROC near
   push ax
   push dx
   
   call IS_LOAD
   cmp flag_load,1h
   je m_already_load
   jmp m_start_load
   
m_already_load:
   lea dx,STR_ALR_LOAD
   call WRITE_STRING
   jmp m_end_load
  
m_start_load:
   mov AH,35h
	mov AL,1Ch
	int 21h 
	mov KEEP_CS, ES
	mov KEEP_IP, BX
   
   push ds
   lea dx, MY_ITERRUPT
   mov ax, seg MY_ITERRUPT
   mov ds,ax
   mov ah,25h
   mov al, 1Ch
   int 21h
   pop ds
   lea dx, STR_SUC_LOAD
   call WRITE_STRING
   
   lea dx, m_iterrapt_end
   mov CL, 4h
   shr DX,CL
   inc DX
   mov ax,cs
   sub ax,PSP
   add dx,ax
   xor ax,ax
   mov AH,31h
   int 21h
     
m_end_load:  
   pop dx
   pop ax
   ret
LOAD_ITERRAPT ENDP

;-------------------------------

UNLOAD_ITERRAPT PROC near
   push ax
   push si
   
   call IS_LOAD
   cmp flag_load,1h
   jne m_cant_unload
   jmp m_start_unload
   
m_cant_unload:
   lea dx,STR_IST_LOAD
   call WRITE_STRING
   jmp m_unload_end
   
   
m_start_unload:
   CLI
   PUSH DS
   mov ah,35h
	mov al,1Ch
	int 21h 
   mov si,offset KEEP_IP
	sub si,offset MY_ITERRUPT
	mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
   MOV DS,AX
   MOV AH,25H
   MOV AL, 1CH
   INT 21H
   POP DS
   STI
   
   lea dx,STR_IS_UNLOAD
   call WRITE_STRING
   
   mov ax,es:[bx+si-2]
   mov es,ax
   mov ax,es:[2ch]
   push es
   mov es,ax
   mov ah,49h
   int 21h
   pop es
   int 21h
   
m_unload_end:   
   pop si
   pop ax
   ret
UNLOAD_ITERRAPT ENDP

;-------------------------------
; Головная процедура
Main      PROC  FAR
   push  DS       
   xor   AX,AX    
   push  AX       
   mov   AX,DATA             
   mov   DS,AX

   call LOAD_FLAG
   cmp flag, 1h
   je m_unload_iterrapt
   call LOAD_ITERRAPT
   jmp m_end
   
m_unload_iterrapt:
   call UNLOAD_ITERRAPT
   
m_end:  
   mov ah,4ch
   int 21h    
Main      ENDP
CODE      ENDS

ASTACK    SEGMENT  STACK
   DW 64 DUP(?)   
ASTACK    ENDS

DATA      SEGMENT
   flag db 0
   flag_load db 0

   STR_IST_LOAD  DB 'Iterrapt is not load', 0AH, 0DH,'$'
   STR_ALR_LOAD  DB 'Iterrapt is already loaded', 0AH, 0DH,'$'
   STR_SUC_LOAD  DB 'Iterrapt has been loaded', 0AH, 0DH,'$'
   STR_IS_UNLOAD  DB 'Iterrapt is unloaded', 0AH, 0DH,'$'
DATA      ENDS
          END Main