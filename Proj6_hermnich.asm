TITLE CS271 Proj 6     (Proj6_hermnich.asm)

; Author: Nick Herman
; Last Modified: 2023/06/11
; OSU email address: hermnich@oregonstate.edu
; Course number/section:   CS271 Section 404
; Project Number: 6        Due Date: 2023/06/11
; Description: Sample program to get 10 signed integers from the user, and calculate their sum and average 

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Gets a string input from the user and store it in a specified memory buffer
;
; Preconditions: Modifies and restores ECX, EDX
;
; Receives:
;	prompt = Reference to a prompt string to display to the user
;	output = Reference to a byte array to store the user input
;	size = The size of the output buffer
;
; returns: output = user input string
; ---------------------------------------------------------------------------------
mGetString MACRO prompt, output, size
	PUSH	EDX
	PUSH	ECX

	; Display the prompt
	mDisplayString prompt

	; Read the user input
	MOV		EDX, output
	MOV		ECX, size
	call	ReadString
	
	POP		ECX
	POP		EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints a string stored in the specified memory location to the console
;
; Preconditions: Modifies and restores EDX
;
; Receives:
;	string = Reference to the string to display
;
; returns: none
; ---------------------------------------------------------------------------------
mDisplayString MACRO string
	PUSH	EDX

	MOV		EDX, string
	call	WriteString

	POP		EDX
ENDM



.data

progTitle		BYTE	"Low-level procedures by Nick Herman",0
instructions	BYTE	"Please enter 10 signed integers. Each integer must be able to fit into a 32 bit register",10,
						"Once 10 integers have been provided, they will be displayed to the terminal, along with their sum and average.",0
goodbye			BYTE	"Goodbye",0

userPrompt		BYTE	"Please enter a signed integer: ",0
errorMsg		BYTE	"Error: Input was not a valid number or was too large, please try again.",0

intsEnteredMsg	BYTE	"The following numbers were entered: ",0
sumMsg			BYTE	"The sum of the numbers is: ",0
avgMsg			BYTE	"The truncated average of the numbers is: ",0
commaSpace		BYTE	", ",0

integers		SDWORD	10	dup(?)	; Stores the 10 valid user entered integers
sumInts			SDWORD	0			; Sum of the valid user entered integers
avgInts			SDWORD	0			; Average of the valid user entered integers

.code
main PROC
	
	; Display the title and program instructions
	mDisplayString OFFSET progTitle
	call	Crlf
	call	Crlf
	mDisplayString	OFFSET instructions
	call	Crlf
	call	Crlf

	; Get each of the 10 numbers from the user
	MOV		ECX, 10
	MOV		EDI, OFFSET integers

_getInput:
	PUSH	OFFSET errorMsg
	PUSH	OFFSET userPrompt
	PUSH	EDI
	call	ReadVal
	ADD		EDI, 4
	LOOP	_getInput


	; Display the list of valid numbers entered
	mDisplayString OFFSET intsEnteredMsg
	call	Crlf
	MOV		ECX, 9
	MOV		ESI, OFFSET integers	

_displayNums:
	; Write the current number to the console
	LODSD
	PUSH	EAX
	call	WriteVal

	; Add the comma and space separating the numbers
	mDisplayString OFFSET commaSpace

	LOOP	_displayNums

	; Write the last number to the console, skipping the comma
	LODSD
	PUSH	EAX
	call	WriteVal
	call	Crlf


	; Calculate the sum of all the numbers
	MOV		ECX, 10
	MOV		ESI, OFFSET integers
_sumNums:
	LODSD
	ADD		sumInts, EAX
	LOOP	_sumNums

	; Calculate the average from the sum
	MOV		EAX, sumInts
	CDQ
	MOV		EBX, 10
	IDIV	EBX
	MOV		avgInts, EAX

	; Display the sum
	mDisplayString	OFFSET sumMsg
	PUSH	sumInts
	call	WriteVal
	call	Crlf

	; Display the average
	mDisplayString	OFFSET avgMsg
	PUSH	avgInts
	call	WriteVal
	call	Crlf

	; Display goodbye
	call	Crlf
	mDisplayString	OFFSET goodbye

	Invoke ExitProcess,0	; exit to operating system
main ENDP



; (insert additional procedures here)
; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Reads a string input from the user, converts it to its integer value, and stores it to an output memory location.
; Inputs that are not a valid integer or will not fit into an SDWORD are discarded and the user is prompted 
; to enter a number again.
;
; Preconditions: output must be a reference to an SDWORD
;
; Postconditions: Modifies and restores EAX, EBX, ECX, EDX, ESI, EDI
;
; Receives: 
;		errorMsg	= [EBP+16], Reference to an error message that will be displayed on invalid entries
;		prompt		= [EBP+12], Reference to a prompt to display to the user
;		output		= [EBP+8], Reference to an output memory location to store the integer.
;
; Returns: The integer entered by the user is stored in output
; ---------------------------------------------------------------------------------
ReadVal PROC
	LOCAL buffer[20]:BYTE, sign:SDWORD
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
	PUSH	ESI
	PUSH	EDI

_prompt:
	MOV		sign, 1

	; Save the output register in EDI and clear the output before starting
	MOV		EDI, [EBP+8]
	MOV		SDWORD PTR [EDI], 0

	; call read string macro
	MOV		ESI, EBP
	SUB		ESI, 20			; Store the buffer offset in the source register
	mGetString [EBP+12], ESI, 20

	; Validate the first character is not '+' or '-' or ''
	MOV		EAX, 0
	LODSB

	; Check if the string is empty
	CMP		AL, 0
	JE		_error
	
	; Check for '+'
	CMP		AL, 43
	JE		_validate

	; Check for '-'
	CMP		AL, 45
	JE		_negative
	JMP		_numericCheck	; If the first character is not empty and is not '+' or '-' then continue the check as usual
	

	; Validate the rest of the characters
_validate:
	MOV		EAX, 0
	LODSB
	; Check that the end of the string has been reached
	CMP		AL, 0
	JE		_done

_numericCheck:
	; Check for ascii values below '0'
	CMP		AL, 48
	JB		_error

	; Check for ascii values above '9'
	CMP		AL, 57
	JA		_error

	; Character is a valid number, Subtract 48 to get the ascii codes equal to the numbers they represent
	SUB		EAX, 48
	IMUL	EAX, sign

	; Multiply the current value by 10
	MOV		ECX, EAX		; Preserve the current digit in ECX
	MOV		EAX, [EDI]		; Move the current value into EAX
	MOV		EBX, 10
	IMUL	EBX

	; Check for overflow
	JO		_error

	; then add the next digit to it
	ADD		EAX, ECX

	; Check again for overflow
	JO		_error

	; Save the current results
	MOV		[EDI], EAX

	JMP		_validate

_done:
	
	POP		EDI
	POP		ESI
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX
	RET		12

_negative:
	MOV		sign, -1
	JMP		_validate

_error:
	mDisplayString [EBP+16]
	call	Crlf
	JMP		_prompt

ReadVal ENDP



; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts an SDWORD to its string representation and writes it to the console
;
; Preconditions: input must be an SDWORD
;
; Postconditions: Modifies and restores EAX, EBX, EDX, EDI
;
; Receives: 
;		input = [EBP+8], the integer value to be written
;
; Returns: none
; ---------------------------------------------------------------------------------
WriteVal PROC
	LOCAL buffer[12]:BYTE
	PUSH	EAX
	PUSH	EBX
	PUSH	EDX
	PUSH	EDI

	; Move the local buffer into EDI and set the last bit as a null terminator
	MOV		EDI, EBP
	DEC		EDI
	STD					; Set the direction flag so that the numbers are written in the correct order
	MOV		EAX, 0
	STOSB

	; Check if the value is positive or negative
	MOV		EAX, [EBP+8]
	CMP		EAX, 0
	JL		_negative
	PUSH	0

_continue:
	MOV		EDX, 0
	MOV		EBX, 10
	DIV		EBX

	ADD		DL, 48
	PUSH	EAX
	MOV		AL, DL
	STOSB	
	POP		EAX

	; If EAX is not empty yet, continue
	CMP		EAX, 0
	JNE		_continue

	; Check if the value should be positive or negative
	POP		EAX
	CMP		EAX, 0
	JNE		_addNegative

_done:
	CLD
	INC		EDI
	mDisplayString EDI

	POP		EDI
	POP		EDX
	POP		EBX
	POP		EAX
	RET		4

	; Push a '-' character to add to the string later
_negative:
	PUSH	'-'
	NEG		EAX
	JMP		_continue

_addNegative:
	STOSB
	JMP		_done

	
WriteVal ENDP



END main
