MYSTACK SEGMENT STACK
   DW 256 DUP(?)
MYSTACK ENDS

DATA SEGMENT
    adr_overlay dd 0
    file_name_overlay_1 db 'overlay1.ovl', 0h
    file_name_overlay_2 db 'overlay2.ovl', 0h
    file_path_overlay db 128 DUP(0)

    keep_SS dw 0
    keep_SP dw 0

    mem_error db 0
    free_memory_mcb_str db 'Error: MCB  crashed', 0DH, 0AH, '$'
    free_memory_need_more_str db 'Error: It needs more memory', 0DH, 0AH, '$'
    free_memory_address_str db 'Erorr: Wrong address', 0DH, 0AH, '$'
    free_memory_success_str db 'Memory is freed', 0DH, 0AH, '$'

    overlay_load_function_str db 'Error: function is not exist', 0DH, 0AH, '$'
    overlay_load_file_not_found_str db 'Error(load): file is not found', 0DH, 0AH, '$'
    overlay_load_route_not_found_str db 'Error(load): route is not found', 0DH, 0AH, '$'
    overlay_load_too_many_files_str db 'Error: too many files are opened', 0DH, 0AH, '$'
    overlay_load_no_access_str db 'Error: no access', 0DH, 0AH, '$'
    overlay_load_need_more_str db 'Error(load): It needs more memory', 0DH, 0AH, '$'
    overlay_load_wrong_enviroment_str db 'Error: wrong environment', 0DH, 0AH, '$'
    overlay_load_success_str db 'Overlay is loaded', 0DH, 0AH, '$'
	
	size_overlay_file_not_found_str db 'Error: file is not found', 0DH, 0AH, '$'
    size_overlay_route_not_found_str db 'Error: route is not found', 0DH, 0AH, '$'
    size_overlay_success_str db 'Overlay size is defined', 0DH, 0AH, '$'
	
	DTA_buffer db 43 DUP(0)

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

        mov BX, offset file_path_overlay
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
			mov DI, SI
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

    GET_PATH PROC near; имя файла находится в SI
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

	OVERLAY_MEMORY PROC far
        push AX
        push BX
        push CX
        push DX
        push DI

        mov DX, offset DTA_buffer
        mov AH, 1ah
        int 21h
        mov DX, offset file_path_overlay
        mov CX, 0
        mov AH, 4eh
        int 21h
        jnc size_success

        cmp AX, 2
        jne route_2
        mov DX, offset size_overlay_file_not_found_str
        call WRITE_MESSAGE_WORD
        jmp overlay_memory_end

		route_2:
			cmp AX, 3
			jne overlay_memory_end
			mov DX, offset size_overlay_route_not_found_str
			call WRITE_MESSAGE_WORD
			jmp overlay_memory_end

		size_success:
			mov DI, offset DTA_buffer
			mov DX, [DI+1ch]
			mov AX, [DI+1ah]
			mov BX, 10h
			div BX
			add AX, 1h
			mov BX, AX
			mov AH, 48h
			int 21h
			mov BX, offset adr_overlay
			mov CX, 0000h
			mov [BX], AX
			mov [BX+2], CX

			mov DX, offset size_overlay_success_str
			call WRITE_MESSAGE_WORD

		overlay_memory_end:
			pop DI
			pop DX
			pop CX
			pop BX
			pop AX
        ret
    OVERLAY_MEMORY ENDP

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
        push ES
        push DS
        push ES
		
        mov keep_SP, SP
        mov keep_SS, SS

        mov AX, DATA
        mov ES, AX
        mov BX, offset adr_overlay
        mov DX, offset file_path_overlay
        
        mov AX, 4b03h 
        int 21h 
        
        mov SS, keep_SS
        mov SP, keep_SP
        pop ES
        pop DS

        jnc success_load

        cmp AX, 1
	    jne load_file_not_found
		
	    mov DX, offset overlay_load_function_str
	    call WRITE_MESSAGE_WORD
	    jmp load_end
    
		load_file_not_found:
			cmp AX, 2
			jne load_route
			mov DX, offset overlay_load_file_not_found_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		load_route:
			cmp AX, 3
			jne load_too_many_files
			mov DX, offset overlay_load_route_not_found_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		load_too_many_files:
			cmp AX, 4
			jne load_no_access
			mov DX, offset overlay_load_too_many_files_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		load_no_access:
			cmp AX, 5
			jne load_need_more
			mov DX, offset overlay_load_no_access_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		load_need_more:
			cmp AX, 8
			jne load_wrong_enviroment
			mov DX, offset overlay_load_need_more_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		load_wrong_enviroment:
			cmp AX, 10
			jne load_end
			mov DX, offset overlay_load_wrong_enviroment_str
			call WRITE_MESSAGE_WORD
			jmp load_end

		success_load:
			mov DX, offset overlay_load_success_str
			call WRITE_MESSAGE_WORD

        mov BX, offset adr_overlay
        mov AX, [BX]
        mov CX, [BX+2]
        mov [BX], CX
        mov [BX+2], AX
        call adr_overlay
        mov ES, AX
        mov AH, 49h
        int 21h

		load_end:
			pop ES
			pop DX
			pop CX
			pop BX
			pop AX
        ret
    LOAD ENDP
	
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

    MAIN PROC far
        mov AX, data
        mov DS, AX

        call FREE
        cmp mem_error, 0h
        jne main_end

        call NEXT_LINE
        mov SI, offset file_name_overlay_1
        call GET_PATH
        call OVERLAY_MEMORY
        call LOAD

        call NEXT_LINE
        mov SI, offset file_name_overlay_2
        call GET_PATH
        call OVERLAY_MEMORY
        call LOAD

    main_end:
        xor AL, AL
        mov AH, 4ch
        int 21h

    MAIN ENDP

main_fin:
CODE ENDS

END MAIN