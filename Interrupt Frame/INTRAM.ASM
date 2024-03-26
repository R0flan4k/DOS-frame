.model tiny
.386
.code
org 100h

RamochkaStart	equ 2100    ; Position of the upper left corner of the frame.
ScreenWidth	    equ 160		; Algebraic difference in VRAM between some position and position below.
ShadowColor		equ 71h		; Shadow of the frame color code.

VideoMemStart   equ 0b800h  ; Start of the video random access memory.
FrameWidth 	equ 40			; Width of frame. Input from cmd line.
FrameHeight	equ 6			; Height of frame. Input from cmd line.
FrameColor 	equ 1eh			; Main color of frame. Input from cmd line.

ShiftScanCode	equ 02ah	; Scan code of Left Shift press.

Start:
	mov ax, 3509h			; Get addres of old 09h interrupt to es:bx.
	int 21h
	mov Old09ofs, bx		; Saving addres of old 09h interrupt.
	mov bx, es
	mov Old09seg, bx

    push 0
    pop es
    mov bx, 4 * 09h

    cli						; Setting 09h interrupt vector.
    mov es:[bx], offset New09
    push cs
    pop ax
    mov es:[bx + 2], ax
    sti

	mov ax, 3100h			; Terminate and stay resident.
    mov dx, offset EOP
    shr dx, 4				; Make memory size to keep resident, in 16-byte paragraphs.
    inc dx
    int 21h

New09	proc
	push ax
	in al, 60h
	cmp al, ShiftScanCode

	jne New09Exit

	pusha					; Saving registers values.
	push es

	call FrameDraw

	pop es
	popa

New09Exit:
	nop
	pop ax
	db 0EAh					; Far jump to Old09seg:Old09ofs.
Old09ofs	dw 0
Old09seg	dw 0

	iret
	endp

FrameDraw	proc
	push dx			; Saving registers values to
	push cx			; print it later.
	push bx
	push ax
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Drawing frame part.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push cs
	pop ds
	mov bx, VideoMemStart
	mov es, bx

	mov di, RamochkaStart - ScreenWidth
	mov si, offset FrameText
TextPutCycle:
	movsb
	inc di
	cmp byte ptr ds:[si], 3ah
	jne TextPutCycle
	inc si
TextCheckExit:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Drawing a background of the frame.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov cx, 0
    mov bx, RamochkaStart + 1
    mov ax, 0
    mov dl, FrameColor
    mov ch, FrameHeight
DrawingBackCycle:
    call DrawBackgroundRow
    add bx, ScreenWidth
    mov al, FrameWidth
    mul TwoD
    sub bx, ax
    dec ch
    cmp ch, 0
    ja DrawingBackCycle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Choose type of the frame.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp byte ptr FrameStyle, 1
	je ChooseFirstType
	cmp byte ptr FrameStyle, 2
	je ChooseSecondType
	cmp byte ptr FrameStyle, 3
	je ChooseThirdType

ChooseFirstType:
    mov si, offset ControlStrArray1
	jmp ChooseTypeExit
ChooseSecondType:
    mov si, offset ControlStrArray2
	jmp ChooseTypeExit
ChooseThirdType:
    mov si, offset ControlStrArray3
	jmp ChooseTypeExit
ChooseTypeExit:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Draw shell of the frame.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov al, FrameWidth
	mul TwoD
	mov dx, ax
	mov di, RamochkaStart
    mov ch, FrameHeight
ShellDrawStart:
    lodsb
    stosb
    inc di
    lodsb

    mov cl, 0
    mov cl, FrameWidth
    sub cl, 2
TmpSymDraw:
    stosb
    inc di
    dec cl
    cmp cl, 0
    ja TmpSymDraw

    lodsb
    stosb
    inc di

    add di, ScreenWidth
    sub di, dx

    cmp ch, FrameHeight
    je ShellNextIteration
    cmp ch, 2
    je ShellNextIteration
    sub si, 3
ShellNextIteration:
    dec ch
    cmp ch, 0
    ja ShellDrawStart

	call ShadowDrawing
	call RegistersOutput
	call ValuesOutput

FrameDrawExit:
	ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:	Prints values of ax, bx, cx and dx.
; Assunes:		es:[bx] = *registers position in videomem*.
; Entry:		Values of register.
; Destroys:		di.
; Returns:		nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ValuesOutput	proc
	mov cx, 4
	mov di, (RamochkaStart + 40)
	; push dx
	; push cx
	; push bx
	; push ax
	pop RetOffset

ValuesOutputcycle:
	pop RegisterValue
	add di, (ScreenWidth + 2) ;;;;;;;
	call PrintValue
	dec cx
	cmp cx, 0
	ja ValuesOutputcycle

	push RetOffset

	ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:	Print value of one register.
; Assunes:		RegisterValue = *value of register*.
;				es:[bx] = *register position in videomem*.
; Entry:		Value of register.
; Destroys:		di.
; Returns:		nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintValue	proc
	push ax
	push bx
	push cx
	add di, 8
	mov cx, 0

	push 0F000h
	push  0F00h
	push  00F0h
	push  000Fh

DigitsPrint:
	mov ax, RegisterValue
	pop bx
	and ax, bx
	shr ax, cl
	call PrintHex
	sub di, 2
	add cl, 4

	cmp bx, 00F0h
	jne GoNextIteration
	sub di, 2

GoNextIteration:
	cmp bx, 0F000h
	jne DigitsPrint



	; and ax, 000Fh
	; call PrintHex
	; sub di, 2
	; mov ax, RegisterValue
	; and ax, 00F0h
	; call PrintHex
	; sub di, 4
	; mov ax, RegisterValue
	; and ax, 0F00h
	; call PrintHex
	; sub di, 2
	; mov ax, RegisterValue
	; and ax, 0F000h
	; call PrintHex
	; sub di, 2

; 	div SixtD ; baad TODO change
; 	call PrintHex
; 	sub di, 2
; 	mov ah, al
; 	call PrintHex
; 	sub di, 4
;
; 	mov al, bl
;     mov ah, 0
; 	div SixtD
; 	call PrintHex
; 	sub di, 2
; 	mov ah, al
; 	call PrintHex
; 	sub di, 2

	pop cx
	pop bx
	pop ax							;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:	Prints one hexadecimal digit.
; Assunes:		ah = digit number.
;				es:[bx] = *register position in videomem*.
; Entry:		hexadecimal digit.
; Destroys:		nothing.
; Returns:		nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PrintHex	proc
	mov si, offset HexChar
	add si, ax
	movsb
	dec di
	ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:	Prints words "ax =, bx =..." in frame.
; Assunes:		es:[bx] = *register position in videomem*.
; Returns:		nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RegistersOutput	proc
	mov di, (ScreenWidth + RamochkaStart + 30)
	push cs
	pop ds
	mov si, offset InFrameText

RowRegistersPrint:
	movsb
	inc di
	cmp byte ptr ds:[si], 3ah
	jne RowRegistersPrint
	inc si

	add di, (ScreenWidth - 10)
	cmp byte ptr ds:[si], 21h
	jne RowRegistersPrint

	ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:	Draws shadow of frame.
; Assunes:		es = *VideoMem*.
; Destroys:		ax, cx, di
; Returns:		nothing.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ShadowDrawing	proc
	mov di, RamochkaStart
	mov al, FrameWidth
	mul TwoD
	add di, ax
	inc di
	push ax
	mov al, ShadowColor
	mov cx, FrameHeight
VertShadowDraw:
	add di, ScreenWidth
	mov byte ptr es:[di], al
	dec cx
	cmp cx, 0
	ja VertShadowDraw

	pop ax
	sub di, ax
	add di, 2
	mov cx, FrameWidth
	mov al, ShadowColor
GorShadowDraw:
	mov byte ptr es:[di], al
	add di, 2
	dec cx
	cmp cx, 0
	ja GorShadowDraw

	ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:	Writes to the bx the quantitative equivalent
;				of the decimal number which digit codes are written to the
;				dl and dh.
; Entry:		ASCII codes of two digiths.
; Destroys:		ax, dx
; Returns:		bx = atoi(dl, dh) (decimal)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetNumberD	proc
	mov ax, 0
	mov bx, 0
	mov al, dl
	sub al, 30h
	mul TenD
	add bx, ax
	mov al, dh
	sub al, 30h
	add bx, ax
	ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:	Writes to the bx the quantitative equivalent
;				of the hexadecimal number which digit codes are written to the
;				dl and dh.
; Entry:		ASCII codes of two digiths.
; Destroys:		ax, dx
; Returns:		bx = atoi(dl, dh) (hexadecimal)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetNumberH	proc
	mov ax, 0
	mov bx, 0
	mov al, dl
	sub al, 30h

	cmp al, 9d
	ja HGetSym
	jmp HGetSymExit

HGetSym:
	sub al, 27h
HGetSymExit:
	mul SixtD
	add bx, ax
	mov al, dh
	sub al, 30h

	cmp al, 9d
	ja HGetSym1
	jmp HgetSym1Exit

HGetSym1:
	sub al, 27h
HGetSym1Exit:
	add bx, ax

	ret
	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description:	Draw one line of frame background.
; Assumes:		es = 0b800h (VideoMemStart)
;				bx = 'start of the frame line'.
; Entry:		Left line position.
; Destroys:		cl.
; Returns:		bx = 'End of the frame line'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DrawBackGroundRow  proc
    mov cl, FrameWidth
DrawOneBack:
    mov byte ptr es:[bx], dl
    inc bx
    inc bx
    dec cl
    cmp cl, 0
    ja DrawOneBack
    ret
    endp


.data
    TwoD db 2
    TenD db 10
	SixtD db 16
	SixtDW dw 16
	HexChar db "0123456789ABCDEF"
	ControlStrArray1	db	'�ͻ����ͼ'
	ControlStrArray2	db	'+-++ ++-+'
	ControlStrArray3	db	'/-\| |\-/'
	FrameText	db 'Registers Values:'
	InFrameText db 'ax = :bx = :cx = :dx = :!'
	FrameStyle	db 3

	RetOffset		dw 0
	RegisterValue	dw 0

EOP:
End Start
