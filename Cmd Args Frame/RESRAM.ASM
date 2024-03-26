.model tiny
.286
.code
org 100h

RamochkaStart	equ 500     ; Position of the upper left corner of the frame.
ScreenWidth	    equ 160		; Algebraic difference in VRAM between some position and position below.
ShadowColor		equ 71h		; Shadow of the frame color code.

; virtual VideoMem
VramStart   equ 0b800h      ; Start of the video random access memory.
FrameWidth 	equ ds:[82h]	; Width of frame. Input from cmd line.
FrameHeight	equ ds:[85h]	; Height of frame. Input from cmd line.
FrameColor 	equ ds:[88h]	; Main color of frame. Input from cmd line.
FrameStyle	equ ds:[8bh]	; Type of frame. Input from cmd line.
FrameText	equ		8dh 	; Text under frame. Input from cmd line.
;
;
;
;
;

Start:
    mov bx, VramStart
	mov es, bx

    mov bx, 0
    add bx, (ScreenWidth - FrameWidth * 2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Overwriting the data entered in the cmd line
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov dl, FrameWidth
    mov dh, FrameWidth + 1
    call GetNumberD
    mov word ptr FrameWidth, bx

    mov dl, FrameHeight
    mov dh, FrameHeight + 1
    call GetNumberD
    mov word ptr FrameHeight, bx

    mov dl, FrameColor
    mov dh, FrameColor + 1
    call GetNumberH;ex
    mov word ptr FrameColor, bx

    sub FrameStyle, '0' ; ....

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing underframe text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov di, RamochkaStart - ScreenWidth
	mov si, FrameText
TextPutCycle: ;@@
	movsb
	inc di
	cmp byte ptr ds:[si], 0dh
	je TextCheckExit
	cmp byte ptr ds:[si], 3ah
	jne TextPutCycle
	inc si
	push si
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
    call DrawBackgroundStr;row
    add bx, ScreenWidth
    mov al, FrameWidth
    mul NB ;????
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
	mul NB
	mov dx, ax
	mov di, RamochkaStart
    mov ch, FrameHeight ;FrameHeight
ShellDrawStart:
    lodsb
    stosb
    inc di
    lodsb

    mov cl, 0
    mov cl, FrameWidth ;FrameWidth
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
    sub di, dx   ;Frame width * 2

    cmp ch, FrameHeight ;Frame height
    je ShellNextIteration
    cmp ch, 2
    je ShellNextIteration
    sub si, 3
ShellNextIteration:
    dec ch
    cmp ch, 0
    ja ShellDrawStart

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Drawing shadow of the frame.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov di, RamochkaStart
	mov al, FrameWidth
	mul NB
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Writing inframe text.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	pop si
	mov di, RamochkaStart
	mov ax, FrameHeight
	div NB
	mov bh, ScreenWidth
	mul bh
	add di, ax
	mov ax, FrameWidth
	mov bh, 3
	div bh
	mul NB
	add di, ax

InframeTextCycle:
	movsb
	inc di
	cmp byte ptr ds:[si], 0dh
	jne InframeTextCycle

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Terminating the program.
; thelp ---> DOS Interrupts ---> INT 21H
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov ax, 4c00h
	int 21h

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
	mul ND
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
	mul NH
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
; Assumes:		es = 0b800h (VramStart)
;				bx = 'start of the frame line'.
; Entry:		Left line position.
; Destroys:		cl.
; Returns:		bx = 'End of the frame line'.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DrawBackGroundStr  proc
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
    NB db 2
    ND db 10
	NH db 16
	ControlStrArray1	db	'�ͻ����ͼ'
	ControlStrArray2	db	'+-++ ++-+'
	ControlStrArray3	db	'/-\| |\-/'

End Start
