;+--------------------------------------------------------------------------
; Эта TSR программа запрещает доступ к файлу, если на диске меньше 100 кб свободной памяти
; выгрузка:
; имя программы /off
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
	cmp ah,3ch   ;сравниваем с функцией создания файла
	je ban1
	cmp ah,3Dh	 ;сравниваем с функцией открытия файла
	je ban1
	oldInt:  	 ;если не наша функция - прыгаем на старый обработчик
		popa
		popf
		jmp dword ptr cs:[old_21h] ;если не функция для файла то в обычный обработчик	
	ban1:
	
	push ds	;настраиваем DS
	push cs
	pop ds
	
	mov     AH,4Eh    ;ищем первый файл
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
		jmp dword ptr cs:[old_21h] ;если не функция для файла то в обычный обработчи 
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
    cmp     AH,0C7h         ; Наш номер?
    jne     Pass_2Fh        ; Нет, на выход
    cmp     AL,00h          ; Подфункция проверки на повторную установку?
    je      inst            ; Программа уже установлена
    cmp     AL,01h          ; Подфункция выгрузки?
    je      unins           ; Да, на выгрузку
    jmp     short Pass_2Fh  ; Неизвестная подфункция - на выход
inst:
    mov     AL,0FFh         ; не устанавливаем повторно
    iret
Pass_2Fh:
    jmp dword PTR CS:[int_2Fh_vector]
;
; -------------- Проверка - возможна ли выгрузка программы из памяти ? ------
unins:
    push    BX
    push    CX
    push    DX
    push    ES
;
    mov     CX,CS   ; Пригодится для сравнения, т.к. с CS сравнивать нельзя
    mov     AX,3521h    ; Проверить вектор 09h
    int     21h ; Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:new_21h
    jne     Not_remove
;
    mov     AX,352Fh    ; Проверить вектор 2Fh
    int     21h ; Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
;
    mov     DX,ES
    cmp     CX,DX
    jne     Not_remove
;
    cmp     BX, offset CS:int_2Fh
    jne     Not_remove
; ---------------------- Выгрузка программы из памяти ---------------------
;
    push    DS
;
    lds     DX, CS:old_21h   ; Эта команда эквивалентна следующим двум
;    mov     DX, word ptr old_09h
;    mov     DS, word ptr old_09h+2
    mov     AX,2521h        ; Заполнение вектора старым содержимым
    int     21h
;
    lds     DX, CS:int_2Fh_vector   ; Эта команда эквивалентна следующим двум
;    mov     DX, word ptr int_2Fh_vector
;    mov     DS, word ptr int_2Fh_vector+2
    mov     AX,252Fh
    int     21h
;
    pop     DS
;
    mov     ES,CS:2Ch       ; ES -> окружение
    mov     AH, 49h         ; Функция освобождения блока памяти
    int     21h
;
    mov     AX, CS
    mov     ES, AX          ; ES -> PSP выгрузим саму программу
    mov     AH, 49h         ; Функция освобождения блока памяти
    int     21h
;
    mov     AL,0Fh          ; Признак успешной выгрузки
    jmp     short pop_ret
Not_remove:
    mov     AL,0F0h          ; Признак - выгружать нельзя
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
        mov CL,ES:80h       ; Длина хвоста в PSP
        cmp CL,0            ; Длина хвоста=0?
        je  check_install   ; Да, программа запущена без параметров,
                            ; попробуем установить
        xor CH,CH       ; CX=CL= длина хвоста
        cld             ; DF=0 - флаг направления вперед
        mov DI, 81h     ; ES:DI-> начало хвоста в PSP
        mov SI,offset key   ; DS:SI-> поле key
        mov AL,' '          ; Уберем пробелы из начала хвоста
repe    scasb   ; Сканируем хвост пока пробелы
                ; AL - (ES:DI) -> флаги процессора
                ; повторять пока элементы равны
        dec DI          ; DI-> на первый символ после пробелов
        mov CX, 4       ; ожидаемая длина команды
repe    cmpsb   ; Сравниваем введенный хвост с ожидаемым
                ; (DS:DI)-(ES:DI) -> флаги процессора
        jne check_install ; Неизвестная команда - попробуем установить
        inc flag_off
; Проверим, не установлена ли уже эта программа
check_install:
        mov AX,0C700h   ; AH=0C7h номер процесса C7h
                        ; AL=00h -дать статус установки процесса
        int 2Fh         ; мультиплексное прерывание
        cmp AL,0FFh
        je  already_ins ; возвращает AL=0FFh если установлена
;****************************************************************************
    cmp flag_off,1
    je  unknown_
;****************************************************************************
    mov AX,352Fh                      ;   получить
                                      ;   вектор
    int 21h                           ;   прерывания  2Fh
    mov word ptr int_2Fh_vector,BX    ;   ES:BX - вектор
    mov word ptr int_2Fh_vector+2,ES  ;
;
    mov DX,offset int_2Fh           ;   получить смещение точки входа в новый
                                    ;   обработчик на DX
    mov AX,252Fh                    ;   функция установки прерывания
                                    ;   изменить вектор 2Fh
    int 21h  ; AL - номер прерыв. DS:DX - указатель программы обработки прер.
;============================================================================
    mov AX,3521h                        ;   получить
                                        ;   вектор
    int 21h                             ;   прерывания  09h
    mov word ptr old_21h,BX    ;   ES:BX - вектор
    mov word ptr old_21h+2,ES  ;
    mov DX,offset new_21h           ;   получить смещение точки входа в новый
;                                   ;   обработчик на DX
    mov AX,2521h                        ;   функция установки прерывания
                                        ;   изменить вектор 09h
    int 21h ;   AL - номер прерыв. DS:DX - указатель программы обработки прер.
;
        mov DX,offset msg1  ; Сообщение об установке
        call    print
;----------------------------------------------------------------------------
    mov DX,offset   begin           ;   оставить программу ...
    int 27h                         ;   ... резидентной и выйти
;============================================================================
already_ins:
        cmp flag_off,1      ; Запрос на выгрузку установлен?
        je  uninstall       ; Да, на выгрузку
        lea DX,msg          ; Вывод на экран сообщения: already installed!
        call    print
        int 20h
; ------------------ Выгрузка -----------------------------------------------
 uninstall:
        mov AX,0C701h  ; AH=0C7h номер процесса C7h, подфункция 01h-выгрузка
        int 2Fh             ; мультиплексное прерывание
        cmp AL,0F0h
        je  not_sucsess
        cmp AL,0Fh
        jne not_sucsess
        mov DX,offset msg2  ; Сообщение о выгрузке
        call    print
        int 20h
not_sucsess:
        mov DX,offset msg3  ; Сообщение, что выгрузка невозможна
        call    print
        int 20h
unknown_:
        mov DX,offset msg4  ; Сообщение, программы нет, а пользователь
        call    print       ; дает команду выгрузки
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
