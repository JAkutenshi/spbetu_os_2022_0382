ASSUME CS:CODE, DS:DATA, SS:ASTACK

ASTACK SEGMENT STACK
	DW 1024 DUP(?)
ASTACK ENDS

DATA SEGMENT
   PC db 		'IBM PC Type: PC',0DH, 0AH,'$'
   PCXT db 		'IBM PC Type: PC/XT', 0DH, 0AH,'$'
   AT db 		'IBM PC Type: AT', 0DH, 0AH,'$'
   PS230 db 		'IBM PC Type: PS2 model 30', 0DH, 0AH,'$'
   PS25060 db 		'IBM PC Type: PS2 model 50 or 60', 0DH, 0AH,'$'
   PS280 db 		'IBM PC Type: PS2 model 80', 0DH, 0AH,'$'
   PCjr db 		'IBM PC Type: P?jr', 0DH, 0AH,'$'
   PCC db 		'IBM PC Type: PC Convertible', 0DH, 0AH,'$'
   DOSV db 		'DOS version:  .  ', 0DH, 0AH,'$'
   OEM db 		'OEM number:   ', 0DH, 0AH, '$'
   USERNAME db 		'User number:       ', 0DH, 0AH, '$'

DATA ENDS

CODE SEGMENT
	print PROC NEAR
 mov ah, 09h
 int 21h
 ret
print ENDP


tetr_to_hex PROC near
 and AL,0Fh
 cmp AL,09
 jbe next
 add AL,07
next:
 add AL,30h
 ret
tetr_to_hex ENDP


byte_to_hex PROC near
 push CX
 mov AH,AL
 call tetr_to_hex
 xchg AL,AH
 mov CL,4
 shr AL,CL
 call tetr_to_hex
 pop CX
 ret
byte_to_hex ENDP


wrd_to_hex PROC near
 push BX
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
 pop BX
 ret
wrd_to_hex ENDP


byte_to_dec PROC near
   push CX
   push DX
   push ax
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
   pop ax
   pop DX
   pop CX
   ret
byte_to_dec ENDP


print_pc_type PROC NEAR
   mov ax, 0F000h
   mov es, ax
   mov al, es:[0FFFEh]

 
   cmp al, 0ffh
   je _pc

   cmp al, 0feh
   je pc_xt

   cmp al, 0fbh
   je pc_xt

   cmp al, 0fch
   je _at

   cmp al, 0fah
   je ps2_30

   cmp al, 0f8h
   je ps2_80

   cmp al, 0fdh
   je pc_jr

   cmp al, 0f9h
   je pc_conv
_pc:
   mov dx, offset PC
   jmp _out
pc_xt:
   mov dx, offset PC_XT
   jmp _out
_at:
   mov dx, offset AT
   jmp _out
ps2_30:
   mov dx, offset PS230
   jmp _out
ps2_80:
   mov dx, offset PS280
   jmp _out
pc_jr:
   mov dx, offset PCjr
   jmp _out
pc_conv:
   mov dx, offset PCC
   jmp _out
_out:
   call print
   ret
print_pc_type ENDP


print_dos_version PROC NEAR
   mov ah, 30h
   int 21h

   mov si, offset DOSV + 13
   call byte_to_dec

   mov al, ah
   add si, 3
   call byte_to_dec
   mov dx, offset DOSV
   call print
   ret
print_dos_version ENDP


print_oem_serial_number PROC NEAR
   mov si, offset OEM + 13
   mov al, bh
   call byte_to_dec
   mov dx, offset OEM
   call print
   ret
print_oem_serial_number ENDP


print_user_serial_number PROC NEAR
   mov di, offset USERNAME
   add di, 17
   mov ax, cx
   call wrd_to_hex
   mov al, bl
   call byte_to_hex
   mov di, offset USERNAME + 13
   mov [di], ax
   mov dx, offset USERNAME
   call print
   ret
print_user_serial_number ENDP
	

main PROC FAR
   mov ax, data
   mov ds, ax
   call print_pc_type
   call print_dos_version
   call print_oem_serial_number
   call print_user_serial_number
   xor al, al
   mov ah, 4Ch
   int 21h
main ENDP
CODE ENDS
END main