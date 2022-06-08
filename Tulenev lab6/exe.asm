MYSTACK SEGMENT STACK
   DW 256 DUP(?)
MYSTACK ENDS

DATA SEGMENT
    block_param dw 0
    com_off dw 0
    com_seg dw 0
    fcb1 dd 0
    fcb2 dd 0

    next_com_line db 1h, 0dh
    file_name db 'LB2.com', 0h
    file_path db 128 DUP(0)

    keep_SS dw 0
    keep_SP dw 0

    mem_error db 0
    free_memory_mcb_str db 'Error: MCB  crashed', 0DH, 0AH, '$'
    free_memory_need_more_str db 'Error: It needs more memory', 0DH, 0AH, '$'
    free_memory_address_str db 'Erorr: Wrong address', 0DH, 0AH, '$'
    free_memory_success_str db 'Memory is freed', 0DH, 0AH, '$'

    load_function_str db 'Error: Function number is incorrect', 0DH, 0AH, '$'
    load_file_not_found_str db 'Error: file is not found', 0DH, 0AH, '$'
    load_disk_str db 'Error: Disk_problem', 0DH, 0AH, '$'
    load_need_more_str db 'Error(load): It needs more memory', 0DH, 0AH, '$'
    load_path_str db 'Error: Wrong path', 0DH, 0AH, '$'
    load_format_str db 'Error: Wrong format', 0DH, 0AH, '$'

    exit_str db 'Programm was finished: exit with code:     ', 0DH, 0AH, '$'
    exit_ctrl_c_str db 'Exit with Ctrl+Break', 0DH, 0AH, '$'
    exit_error_str db 'Exit with device error', 0DH, 0AH, '$'
    exit_int_31h_str db 'Exit with int 31h', 0DH, 0AH, '$'


    end_of_data db 0
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:MYSTACK

	MODULE_PATH PROC near
        push AX
        push BX
        push BP
        push DX
        push ES
        push DI

        mov BX, offset file_path
        add DI, 3

		loop1:
			mov DL, ES:[DI]
			mov [BX], DL
			cmp DL, '.'
			je slash
			inc DI
			inc BX
			jmp loop1

		slash:
			mov DL, [BX]
			cmp DL, '\'
			je module_name
			mov DL, 0h
			mov [BX], DL
			dec BX
			jmp slash
    
		module_name:
			mov DI, offset file_name
			inc BX

		add_name:
			mov DL, [DI]
			cmp DL, 0h
			je module_path_end
			mov [BX], DL
			inc BX
			inc DI
			jmp add_name

		module_path_end:
			mov [BX], DL
			pop DI
			pop ES
			pop DX
			pop BP
			pop BX
			pop AX
        ret
    MODULE_PATH ENDP

	GET_PATH PROC near
        push AX
        push DX
        push ES
        push DI

        xor DI, DI
        mov AX, ES:[2ch]
        mov ES, AX

		loop2:
			mov DL, ES:[DI]
			cmp DL, 0
			je end1
			inc DI
			jmp loop2

		end1:
			inc DI
			mov DL, ES:[DI]
			cmp DL, 0
			jne loop2

        call MODULE_PATH

        pop DI
        pop ES
        pop DX
        pop AX
        ret
    GET_PATH ENDP

    FREE PROC far
        push AX
        push BX
        push CX
        push DX
        push ES

        xor DX, DX
		mov mem_error, 0h

        mov AX, offset end_of_data
        mov BX, offset main_fin
        add AX, BX
        mov BX, 10h
        div BX
        add AX, 100h
        mov BX, AX
        xor AX, AX

        mov AH, 4ah
        int 21h 

        jnc free_memory_success
	    mov mem_error, 1h
        cmp AX, 7
        jne free_memory_need_more

        mov DX, offset free_memory_mcb_str
        call WRITE_MESSAGE_WORD
        jmp free_end

    free_memory_need_more:
        cmp AX, 8
        jne free_memory_address

        mov DX, offset free_memory_need_more_str
        call WRITE_MESSAGE_WORD
        jmp free_end	

    free_memory_address:
        cmp AX, 9
        jne free_end

        mov DX, offset free_memory_address_str
        call WRITE_MESSAGE_WORD
        jmp free_end

    free_memory_success:
        mov DX, offset free_memory_success_str
        call WRITE_MESSAGE_WORD
        
    free_end:
        pop ES
        pop DX
        pop CX
        pop BX
        pop AX
		ret
    FREE ENDP
    

    LOAD PROC far
        push AX
        push BX
        push CX
        push DX
        push DS
        push ES
		
        mov keep_SP, SP
        mov keep_SS, SS
        
        call GET_PATH

        mov AX, DATA
        mov ES, AX
        mov BX, offset block_param
        mov DX, offset next_com_line
        mov com_off, DX
        mov com_seg, DS 
        mov DX, offset file_path
      
        mov AX, 4b00h 
        int 21h 
        
        mov SS, keep_SS
        mov SP, keep_SP
        pop ES
        pop DS

        call NEXT_LINE

		jnc success_load

        cmp AX, 1
	    jne load_file_not_found
		
	    mov DX, offset load_function_str
	    call WRITE_MESSAGE_WORD
	    jmp load_end
    
		load_file_not_found:
			cmp AX, 2
			jne load_disk
			mov DX, offset load_file_not_found_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		load_disk:
			cmp AX, 5
			jne load_need_more
			mov DX, offset load_disk_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		load_need_more:
			cmp AX, 8
			jne load_path
			mov DX, offset load_need_more_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		load_path:
			cmp AX, 10
			jne load_format
			mov DX, offset load_path_str
			call WRITE_MESSAGE_WORD
			jmp load_end
			
		load_format:
			cmp AX, 11
			jne load_end
			mov DX, offset load_format_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		success_load:
			mov ax, 4d00h 
			int 21h

        cmp AH, 0
	    jne ctrl_exit
	    mov DI, offset exit_str

        add DI, 41
        mov [DI], AL
        mov DX, offset exit_str
	    call WRITE_MESSAGE_WORD
	    jmp load_end

		ctrl_exit:
			cmp AH, 1
			jne exit_error
			mov DX, offset exit_ctrl_c_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		exit_error:
			cmp AH, 2
			jne exit_int_31h
			mov DX, offset exit_error_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		exit_int_31h:
			cmp AH, 3
			jne load_end
			mov DX, offset exit_int_31h_str
			call WRITE_MESSAGE_WORD
			jmp load_end


		load_end:
			pop DX
			pop CX
			pop BX
			pop AX
        ret
    LOAD ENDP

	WRITE_MESSAGE_WORD  PROC  near
        push AX
		
        mov AH, 9
        int 21h
		
        pop AX
        ret
    WRITE_MESSAGE_WORD  ENDP

    WRITE_MESSAGE_BYTE  PROC  near
        push AX
		
        mov AH, 02h
        int 21h
		
        pop AX
        ret
    WRITE_MESSAGE_BYTE  ENDP

    NEXT_LINE PROC near
        push AX
        push DX

        mov DL, 0DH
        call WRITE_MESSAGE_BYTE

        mov DL, 0AH
        call WRITE_MESSAGE_BYTE

        pop DX
        pop AX
        ret
    NEXT_LINE ENDP

    MAIN PROC far
        mov AX, DATA
        mov DS, AX

        call FREE

        cmp mem_error, 0h
        jne main_end

        call GET_PATH
        call LOAD

		main_end:
			xor AL, AL
			mov AH, 4ch
			int 21h
    MAIN ENDP

main_fin:
CODE ENDS

END MAIN