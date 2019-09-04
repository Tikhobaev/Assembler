code_seg segment  
    assume cs:code_seg,ds:code_seg,ss:code_seg  
	org 100h
	.286
start:  
	jmp begin
	StartMes db 13,10,'It is psp:',13,10,'$'
	BK db 13,10,'$'
	dname       DB      'D:\*.*',0 
	nolableMes db 13,10,'No lable',13,10,'$'
	moreThanMes db 13,10,'More than 117mb',13,10,'$'
	lessThanMes db 13,10,'Less than 117mb',13,10,'$'
begin:
    mov     AH,4Eh
	mov     CX, 0
	mov     DX,offset dname
	int     21h
	jc nolabel
	mov DX, 0
	mov BX, 0
	jmp addBLFromPsp
	addNewFileSizeToDXBX:
		push DX
		mov     AH,4Fh
		mov     DX, ES:[80h]
		int     21h
		jc nolabel
		pop DX
		addBLFromPsp:
			call printFileSizeFromPsp
			add BL, ES:[9Ah] ;input next operand from psp
			jc addBH
			jmp addBHFromPsp
			addBH:
				inc BH
				jc addDX
		addBHFromPsp:
			add BH, ES:[9Bh] ;input next operand from psp
			jc addDX
			jmp addDLFromPsp
			addDX:
				inc DX
		addDLFromPsp:
			add DL, ES:[9Ch] ;input next operand from psp
			jc addDH
			jmp addDHFromPsp
			addDH:
				inc DH   
		addDHFromPsp:
			add DH, ES:[9Dh] ;input next operand from psp
	cmp DX, 0640h
	jge moreThan
	jmp addNewFileSizeToDXBX
	
	nolabel:
		mov AH, 09h
		lea DX, nolableMes
		int 21h
		mov AH, 09h
		lea DX, lessThanMes
		int 21h
		jmp return
	moreThan:
		mov AH, 09h
		lea DX, moreThanMes
		int 21h
   jmp return
   
   
   
   
   print proc
		pusha
        mov AH, 02h
        and DL, 0fh
        cmp DL, 09h
        jle _print
        add DL, 07h
        _print:
            add DL, 30h
        int 21h
		popa
        ret
   print endp
   
   
   
   
   printFileSizeFromPsp proc
	pusha
    mov SI, 9Dh
    mov CX, 04h
    loopSpace:  ;new line & carriage return                
                mov DL,ES:[SI] ;input next operand from psp
                push DX
                rcr DL, 4   ;print
                call print  
                pop DX    
                call print
                mov AH, 02h ;print space
                mov DL, 020h
                int 21h
                dec SI   ;inc 'smeshenie'    
    loop loopSpace
		
		mov AH, 09h ;every 16 collumns print newl & cret
		lea DX, BK
		int 21h
	popa
        ret
   printFileSizeFromPsp endp
   
   
   
   
    printFullPsp proc
	pusha
	mov AH, 09h
    lea DX, StartMes
    int 21h
    mov SI, 80h
    mov CX, 80h
    loopSpace1:  ;new line & carriage return 
        push CX
        mov CX, 10h
        loopPrint1:   ;work with PSP                
                mov DL,ES:[SI] ;input next operand from psp
                push DX
                rcr DL, 4   ;print
                call print  
                pop DX    
                call print
                mov AH, 02h ;print space
                mov DL, 020h
                int 21h
                inc SI   ;inc 'smeshenie'    
            loop loopPrint1     
            mov AH, 09h ;every 16 collumns print newl & cret
            lea DX, BK
            int 21h
            pop CX
            sub CX, 0Fh
        loop loopSpace1
		mov AH, 09h ;every 16 collumns print newl & cret
		lea DX, BK
		int 21h
	popa
        ret
   printFullPsp endp
   
return:
    int 20h
    code_seg ends          
	end start




