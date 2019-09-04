;+--------------------------------------------------------------------------
; �� TSR �ணࠬ�� ����頥� ����� � 䠩��, �᫨ �� ��᪥ ����� 100 �� ᢮������ �����
; ���㧪�:
; ��� �ணࠬ�� /off
;****************************************************************************
code_seg segment
        ASSUME  CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
	.286
start:
    jmp begin
;****************************************************************************
int_2Fh_vector  DD  ?
old_21h         DD  ?
mes21			DB  13,10,'Access to the file is forbidden',13,10,'$'
BK db 13,10,'$'
dname       DB      'D:\*.*',0 
nofilesMes db 13,10,'No more files',13,10,'$'
moreThanMes db 13,10,'More than 100mb',13,10,'$'
lessThanMes db 13,10,'Less than 100mb',13,10,'$'
;****************************************************************************
new_21h proc far
	pushf
	pusha	
	cmp ah,3ch   ;�ࠢ������ � �㭪樥� ᮧ����� 䠩��
	je ban1
	cmp ah,3Dh	 ;�ࠢ������ � �㭪樥� ������ 䠩��
	je ban1
	oldInt:  	 ;�᫨ �� ��� �㭪�� - ��룠�� �� ���� ��ࠡ��稪
		popa
		popf
		jmp dword ptr cs:[old_21h] ;�᫨ �� �㭪�� ��� 䠩�� � � ����� ��ࠡ��稪	
	ban1:
	
	push ds	;����ࠨ���� DS
	push cs
	pop ds
	
	mov     AH,4Eh    ;�饬 ���� 䠩�
	mov     CX, 0
	mov     DX,offset dname
	int     21h
	push ES
	jc nofiles
	mov AH, 2Fh			;get a DTA (to ES)
	pushf
	call dword ptr cs:[old_21h]	
	mov SI, BX
	mov DX, 0 
	mov BX, 0
	jmp addBLFromPsp
	
	addNewFileSizeToDXBX:
		push DX
		mov     AH,4Fh
		mov     DX, ES:[SI]
		pushf
		call dword ptr cs:[old_21h]
		pop DX
		jc nofiles
		addBLFromPsp:
			add BL, ES:[SI+1Ah] ;input next operand from psp
			jc addBH
			jmp addBHFromPsp
			addBH:
				inc BH
				jc addDX
		addBHFromPsp:
			add BH, ES:[SI+1Bh] ;input next operand from psp
			jc addDX
			jmp addDLFromPsp
			addDX:
				inc DX
		addDLFromPsp:
			add DL, ES:[SI+1Ch] ;input next operand from psp
			jc addDH
			jmp addDHFromPsp
			addDH:
				inc DH   
		addDHFromPsp:
			add DH, ES:[9Dh] ;input next operand from psp
	cmp DX, 0640h
	jge moreThan
	jmp addNewFileSizeToDXBX
	
	nofiles:
		mov AH, 09h
		lea DX, nofilesMes
		pushf
		call dword ptr cs:[old_21h]
		
		mov AH, 09h
		lea DX, lessThanMes
		pushf
		call dword ptr cs:[old_21h]
		pop ES
		pop ds		
		popa
		popf
		jmp dword ptr cs:[old_21h] ;�᫨ �� �㭪�� ��� 䠩�� � � ����� ��ࠡ��� 
	moreThan:
		mov AH, 09h
		lea DX, moreThanMes
		pushf
		call dword ptr cs:[old_21h]
		
			mov AH,09h
			mov DX, offset mes21
			pushf
			call dword ptr cs:[old_21h]
		return:	
			pop ES
			pop ds			
			popa
			popf
			
			push BP
			mov BP, SP
			or byte ptr [BP]+6, 1h
			pop BP
			mov AX, 05h
			iret
new_21h  endp

;************************************************************************
int_2Fh proc far
    cmp     AH,0C7h         ; ��� �����?
    jne     Pass_2Fh        ; ���, �� ��室
    cmp     AL,00h          ; ����㭪�� �஢�ન �� ������� ��⠭����?
    je      inst            ; �ணࠬ�� 㦥 ��⠭������
    cmp     AL,01h          ; ����㭪�� ���㧪�?
    je      unins           ; ��, �� ���㧪�
    jmp     short Pass_2Fh  ; �������⭠� ����㭪�� - �� ��室
inst:
    mov     AL,0FFh         ; �� ��⠭�������� ����୮
    iret
Pass_2Fh:
    jmp dword PTR CS:[int_2Fh_vector]
;
; -------------- �஢�ઠ - �������� �� ���㧪� �ணࠬ�� �� ����� ? ------
unins:
    push    BX
    push    CX
    push    DX
    push    ES
;
    mov     CX,CS   ; �ਣ������ ��� �ࠢ�����, �.�. � CS �ࠢ������ �����
    mov     AX,3521h    ; �஢���� ����� 09h
    int     21h ; �㭪�� 35h � AL - ����� ���뢠���. ������-����� � ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:new_21h
    jne     Not_remove
;
    mov     AX,352Fh    ; �஢���� ����� 2Fh
    int     21h ; �㭪�� 35h � AL - ����� ���뢠���. ������-����� � ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:int_2Fh
    jne     Not_remove
; ---------------------- ���㧪� �ணࠬ�� �� ����� ---------------------
;
    push    DS
;
    lds     DX, CS:old_21h   ; �� ������� �������⭠ ᫥���騬 ���
;    mov     DX, word ptr old_09h
;    mov     DS, word ptr old_09h+2
    mov     AX,2521h        ; ���������� ����� ���� ᮤ�ন��
    int     21h
;
    lds     DX, CS:int_2Fh_vector   ; �� ������� �������⭠ ᫥���騬 ���
;    mov     DX, word ptr int_2Fh_vector
;    mov     DS, word ptr int_2Fh_vector+2
    mov     AX,252Fh
    int     21h
;
    pop     DS
;
    mov     ES,CS:2Ch       ; ES -> ���㦥���
    mov     AH, 49h         ; �㭪�� �᢮�������� ����� �����
    int     21h
;
    mov     AX, CS
    mov     ES, AX          ; ES -> PSP ���㧨� ᠬ� �ணࠬ��
    mov     AH, 49h         ; �㭪�� �᢮�������� ����� �����
    int     21h
;
    mov     AL,0Fh          ; �ਧ��� �ᯥ譮� ���㧪�
    jmp     short pop_ret
Not_remove:
    mov     AL,0F0h          ; �ਧ��� - ���㦠�� �����
pop_ret:
    pop     ES
    pop     DX
    pop     CX
    pop     BX
;
    iret
int_2Fh endp
;****************************************************************************
begin:
        mov CL,ES:80h       ; ����� 墮�� � PSP
        cmp CL,0            ; ����� 墮��=0?
        je  check_install   ; ��, �ணࠬ�� ����饭� ��� ��ࠬ��஢,
                            ; ���஡㥬 ��⠭�����
        xor CH,CH       ; CX=CL= ����� 墮��
        cld             ; DF=0 - 䫠� ���ࠢ����� ���।
        mov DI, 81h     ; ES:DI-> ��砫� 墮�� � PSP
        mov SI,offset key   ; DS:SI-> ���� key
        mov AL,' '          ; ���६ �஡��� �� ��砫� 墮��
repe    scasb   ; ������㥬 墮�� ���� �஡���
                ; AL - (ES:DI) -> 䫠�� ������
                ; �������� ���� ������ ࠢ��
        dec DI          ; DI-> �� ���� ᨬ��� ��᫥ �஡����
        mov CX, 4       ; ��������� ����� �������
repe    cmpsb   ; �ࠢ������ �������� 墮�� � ��������
                ; (DS:DI)-(ES:DI) -> 䫠�� ������
        jne check_install ; �������⭠� ������� - ���஡㥬 ��⠭�����
        inc flag_off
; �஢�ਬ, �� ��⠭������ �� 㦥 �� �ணࠬ��
check_install:
        mov AX,0C700h   ; AH=0C7h ����� ����� C7h
                        ; AL=00h -���� ����� ��⠭���� �����
        int 2Fh         ; ���⨯���᭮� ���뢠���
        cmp AL,0FFh
        je  already_ins ; �����頥� AL=0FFh �᫨ ��⠭������
;****************************************************************************
    cmp flag_off,1
    je  unknown_
;****************************************************************************
    mov AX,352Fh                      ;   �������
                                      ;   �����
    int 21h                           ;   ���뢠���  2Fh
    mov word ptr int_2Fh_vector,BX    ;   ES:BX - �����
    mov word ptr int_2Fh_vector+2,ES  ;
;
    mov DX,offset int_2Fh           ;   ������� ᬥ饭�� �窨 �室� � ����
                                    ;   ��ࠡ��稪 �� DX
    mov AX,252Fh                    ;   �㭪�� ��⠭���� ���뢠���
                                    ;   �������� ����� 2Fh
    int 21h  ; AL - ����� ����. DS:DX - 㪠��⥫� �ணࠬ�� ��ࠡ�⪨ ���.
;============================================================================
    mov AX,3521h                        ;   �������
                                        ;   �����
    int 21h                             ;   ���뢠���  09h
    mov word ptr old_21h,BX    ;   ES:BX - �����
    mov word ptr old_21h+2,ES  ;
    mov DX,offset new_21h           ;   ������� ᬥ饭�� �窨 �室� � ����
;                                   ;   ��ࠡ��稪 �� DX
    mov AX,2521h                        ;   �㭪�� ��⠭���� ���뢠���
                                        ;   �������� ����� 09h
    int 21h ;   AL - ����� ����. DS:DX - 㪠��⥫� �ணࠬ�� ��ࠡ�⪨ ���.
;
        mov DX,offset msg1  ; ����饭�� �� ��⠭����
        call    print
;----------------------------------------------------------------------------
    mov DX,offset   begin           ;   ��⠢��� �ணࠬ�� ...
    int 27h                         ;   ... १����⭮� � ���
;============================================================================
already_ins:
        cmp flag_off,1      ; ����� �� ���㧪� ��⠭�����?
        je  uninstall       ; ��, �� ���㧪�
        lea DX,msg          ; �뢮� �� �࠭ ᮮ�饭��: already installed!
        call    print
        int 20h
; ------------------ ���㧪� -----------------------------------------------
 uninstall:
        mov AX,0C701h  ; AH=0C7h ����� ����� C7h, ����㭪�� 01h-���㧪�
        int 2Fh             ; ���⨯���᭮� ���뢠���
        cmp AL,0F0h
        je  not_sucsess
        cmp AL,0Fh
        jne not_sucsess
        mov DX,offset msg2  ; ����饭�� � ���㧪�
        call    print
        int 20h
not_sucsess:
        mov DX,offset msg3  ; ����饭��, �� ���㧪� ����������
        call    print
        int 20h
unknown_:
        mov DX,offset msg4  ; ����饭��, �ணࠬ�� ���, � ���짮��⥫�
        call    print       ; ���� ������� ���㧪�
        int 20h
;----------------------------------------------------------------------------
key         DB  '/off'
flag_off    DB  0
msg         DB  'already '
msg1        DB  'installed',13,10,'$'
msg4        DB  'just '
msg3        DB  'not '
msg2        DB  'uninstalled',13,10,'$'
message     DB  'Okey',13,10,'$'
;============================================================================
PRINT       PROC NEAR
    MOV AH,09H
    INT 21H
    RET
PRINT       ENDP
;;============================================================================
code_seg ends
end start
