CODE_SEG	SEGMENT
		ASSUME	CS:CODE_SEG,DS:CODE_SEG,SS:CODE_SEG
		ORG	100H
START:
	JMP	BEGIN
	CR	EQU	13
	LF	EQU	10
;=============================macro=================================
print_letter	macro	letter
	push	AX
	push	DX
	mov	DL, letter
	mov	AH,	02
	int	21h
	pop	DX
	pop	AX
endm
;===================================================================
print_mes	macro	message
	local	msg, nxt
	push	AX
	push	DX
	mov	DX, offset msg
	mov	AH,	09h
	int	21h
	pop	DX
	pop	AX
	jmp nxt
	msg	DB message,13,10,'$'
	nxt:
endm

FilenameIn DB 'D:\vl.txt',0
HandlerIn DW ?
FilenameOut DB 'D:\out.txt',0
HandlerOut DW ?
BufIn DB 80 dup (‘ ‘) ; буфер ввода
;dogCount DW 0,'$'
BK DB 13,10,'$'
MesB DB 13,10,'New Buffer',13,10,'$'
BKF DB 13,10
email DB 40 dup ('$')     ;здесь хранится текущее слово(которое после определённых сравнений может быть или не быть email'ом)
emailLen DW 0              ;показывает, куда записывать следующий символ в email
flag@ DB 0 ;показывает, была ли в слове собачка
flagDot DB 0 ;показывает, была ли в слове точка
;dogCountMes DB dogCount,'$'
;===================================================================
	BEGIN:

    ;открываем файл для парсинга
	MOV  AH, 3Dh 
	MOV  AL, 2 
	MOV  DX, OFFSET FilenameIn 
	INT  21h
	jc errorMes1
	mov HandlerIn, AX
	
	;создаём(или открываем) файл для записи почтовых ящиков
	MOV  AH, 3Ch   
	MOV  CX, 0
	MOV  DX, OFFSET FilenameOut
	INT  21h
	jc errorMes2
	Mov  HandlerOut, AX
	
	jmp noFileErrors
		errorMes1:
			print_mes 'Input file was not opened'
			jmp exit
		errorMes2:
			print_mes 'Output file was not opened'
			jmp exit
	noFileErrors:
	readingNewBuffer:	
		MOV  AH, 3Fh
		MOV  BX, HandlerIn
		MOV  CX, 80
		MOV  DX, OFFSET BufIn
		INT  21h 
		MOV  CX, AX   ;сколько реально прочитано
		push CX
		mov SI, 0
		bufferParser:
			;print_mes 'NB'
			cmp BufIn[SI], 20h		;сравниваем с пробелом, возвратом каретки или переносом строки - если
			je end_of_word			;текущий символ один из этих, то слово закончилось, анализируем это слово
			cmp BufIn[SI], 0Ah		;по метке 'end_of_word' и происходит проверка на то, было ли текущее слово ящиком или нет
			je end_of_word
			cmp BufIn[SI], 09h
			je end_of_word		
			;прибавляем следующий символ слова в массив email			
			mov DL, BufIn[SI]
			mov BX, emailLen 
			mov email[BX], DL
			inc emailLen			
			;если текущий символ - собачка, то прибавляем счётчик собачек
			cmp BufIn[SI], 40h
			je raise_flagD
			cmp BufIn[SI], 2Eh
			je raise_dot_flag
			jmp exitParser
			
			;сюда прыгаем, если встретилась собачка, увеличиваем счётчик собачек и устанавливаем флаг собачек в 1
			raise_flagD:
				;inc dogCount[0]
				mov flag@, 1
				jmp exitParser
			;сюда прыгаем, если встретилась точка, увеличиваем счётчик точек и устанавливаем флаг точек в 1
			raise_dot_flag:
				cmp flag@, 1
				je raise
				jmp exitParser
				raise:
					mov flagDot, 1
					jmp exitParser
			;здесь мы проверяем слово на то, было ли оно почтой
			;если флажок flag@ == 1, то это была почта - печатаем на экран 
			;если слово не было почтой - записываем в email '$', обнуляем флажок и переменную emailLen
			;и выходим из цикла обработки символа
			end_of_word:
				cmp flagDOT, 1
				je printEmail
				cmp emailLen, 0
				je exitParser
				
				push CX
				mov CX, emailLen
				mov DL, '$'
				z_email:
					mov BX, CX
					mov email[BX], DL
				loop z_email
				pop CX
				mov flag@, 0
				mov flagDOT, 0
				mov emailLen, 0				
				jmp exitParser
				
				;здесь печатаем почту на экран и записываем в email '$', 
				;обнуляем флажок и переменную emailLen и выходим из цикла обработки символа
				printEmail:
					mov AH, 09h
					lea DX, email
					int 21h
					mov AH, 09h
					lea DX, BK
					int 21h
					
					;push CX
					;push BX
					
					;MOV CX, 0
					;MOV  AH, 40h
					;MOV  BX, HandlerOut
					;MOV  CL, emailLen
					;MOV  DX, OFFSET email
					;INT  21h	
					;MOV  AH, 40h
					;MOV  BX, HandlerOut
					;MOV  CX, 2
					;MOV  DX, OFFSET BKF
					;INT  21h
					;pop BX
					;pop CX
					
					
				push CX
				mov CX, emailLen
				mov DL, '$'
				z_email_in_printing:
					mov BX, CX
					mov email[BX], DL
				loop z_email_in_printing
				pop CX		
				mov flag@, 0
				mov flagDOT, 0
				mov emailLen, 0							
				jmp exitParser		
		;выход из обработки символа - инкрементируем BX - индекс текущего символа в буфере, смотрим, весь ли буфер считали
		exitParser:
			inc SI
			dec CX
			;если считали весь буфер, то пригаем на конец обработки буфера
			cmp CX, 0
			je endOfBufferParsing
		;если не весь, парсим дальше
		jmp bufferParser
		;если буфер кончился, то смотрим, не считали ли мы весь файл, если да, то выходим из парсинга файла
		endOfBufferParsing:
			pop CX
			cmp CX, 80
			jne exitReadingNewBuffer
	jmp readingNewBuffer
	
	exitReadingNewBuffer:
		mov AH, 09h
		mov DX, offset BK
		int 21h
		cmp flagDOT, 1
		je printFinalWord
		jmp closingFile
		printFinalWord:
			mov AH, 09h
			lea DX, email
			int 21h
			mov AH, 09h
			lea DX, BK
			int 21h
		;jmp closingFile
	closingFile:		
		;закрываем оба файла
		mov  AH, 3Eh
		mov  BX, HandlerIn
		int 21h
		mov  AH, 3Eh
		mov  BX, HandlerOut 
		int 21h
	exit:
	mov		AX,	4C00h
	INT	21H
return:
CODE_SEG    ENDS
		END START