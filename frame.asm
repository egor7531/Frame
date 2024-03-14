
.model tiny	
.386

;Consts
;--------------------------------------------------------------------------------------------
X					= 80 / 2		
Y					= 25 / 2		; coordinates of the center

VIDEO_MEM_ADDRESS	= 0b800h
CMD_ADDRESS			= 0080h
SPACE				= 20h			; ' '
COLOR  				= 70h			; background = gray; color_of_symbol = black 
;--------------------------------------------------------------------------------------------

.code	
org 100h

Start:		mov cl, es:[CMD_ADDRESS]			; es:[CMD_ADDRESS] = command line length

Get_Width:	call get_number
			mov myWidth, ah

Get_Height:	call get_number
			mov myHeight, ah

Get_Style:	call get_number
			mov myStyle, ah

Check_Data: cmp myWidth, 2
			jb Print_Error

			cmp myWidth, 78	
			ja Print_Error

			cmp myHeight, 2
			jb Print_Error

			cmp myHeight, 25
			ja Print_Error

			cmp myStyle, 1
			jne Set_Style_2

			Set_Style_1:	mov LEFT_UP,    0dah      	; '┌'      	<----------------------------    
							mov HOR_LINE,   0c4h    	; '─' 									|
							mov RIGHT_UP,   0bfh    	; '┐'									| Style 1
							mov VER_LINE,   0b3h      	; '│'									|
							mov RIGHT_DOWN, 0d9h	  	; '┘'									|
							mov LEFT_DOWN , 0c0h	  	; '└'		<----------------------------
				
							jmp Get_dx

			Set_Style_2:	cmp myStyle, 2
							jne Print_Error

							mov LEFT_UP,    0c9h      	; '╔'      	<----------------------------    
							mov HOR_LINE,   0cdh      	; '═' 									|
							mov RIGHT_UP,   0bbh      	; '╗'									| Style 2
							mov VER_LINE,   0bah      	; '║'									|
							mov RIGHT_DOWN, 0bch      	; '╝'									|
							mov LEFT_DOWN,  0c8h 		; '╚'		<----------------------------

							jmp Get_dx

Print_Error:	xor ax, ax
				mov ah, 09h
				mov dx, offset strError
				int 21h

				jmp Done

Get_dx:		mov bl, 2
			xor ax, ax

			mov al, myWidth
			div bl
			xor ah, ah
			mov dh, X
			sub dh, al

			mov al, myHeight
			div bl
			xor ah, ah
			mov dl, Y
			sub dl, al 

Frame:		mov ax,	VIDEO_MEM_ADDRESS		
			mov es, ax	

			call get_address

			mov ah, COLOR
			mov al, SPACE				
			
			mov bl, myHeight
			inc bl
			mov cl, myWidth
			inc cl

			mov si, 0000h

Weight:		stosw										
			loop Weight										; while(cx--) {es:[di] = ax; di += 2;}

Height:		mov cl, myWidth
			inc cl
			call get_location

			inc si
			cmp si, bx										; if(si != bx) Weight;
			jne Weight										; else 		   Return;


Corners:	call get_address_corner
			mov al, LEFT_UP 
			stosw 	

			add dh, myWidth
			call get_address_corner
			mov al, RIGHT_UP 											
			stosw 	

			sub dh, myWidth
			add dl, myHeight
			call get_address_corner
			mov al, LEFT_DOWN							
			stosw 	

			add dh, myWidth 
			call get_address_corner
			mov al, RIGHT_DOWN 								
			stosw 	

			sub dh, myWidth 
			add dh, 1
			sub dl, myHeight 
			call get_address_corner
			
			mov cl, myWidth
			sub cl, 1
			mov al, HOR_LINE								

Horizontal:	stosw

			mov ax, 00a0h
			mov bx, dx
			mul myHeight
			add di, ax
			sub di, 2
			mov dx, bx

			mov al, HOR_LINE
			mov	ah, COLOR

			stosw				
			
			mov ax, 00a0h
			mov bx, dx
			mul myHeight
			sub di, ax
			mov dx, bx
			mov al, HOR_LINE
			mov	ah, COLOR

			loop Horizontal

			sub dh, 1
			add dl, 1
			call get_address_corner

			mov cl, myHeight
			sub cl, 1
			mov al, VER_LINE								

Vertical:	stosw

			mov ax, 0002h
			mul myWidth
			sub ax, 2
			add di, ax 
			mov al, VER_LINE
			mov	ah, COLOR

			stosw				

			mov ax, 0002h
			mov bx, 0080d
			sub bl, myWidth
			mul bx
			sub ax, 2
			add di, ax
			mov al, VER_LINE
			mov	ah, COLOR
			
			loop Vertical

Print_Heart:mov di, (Y * 80 + X) * 2
			mov ah, 0f4h
			mov al, 03h
			stosw

Done:		mov ax, 4c00h								; return 0
			int 21h

;------------------------------------------------------------------------------
; Get a character from the command line
; Entry: 
; Assumes:	
; Returns: dl - cod of a character
;------------------------------------------------------------------------------

get_symbol proc
		inc bx
		mov dl, es:[CMD_ADDRESS] + bx
		
		cmp dl, ' '
		je Exit

		cmp dl, '9'
		ja Print_Error
		
		cmp dl, '0'
		jb Print_Error
		
		Exit: ret
get_symbol endp

;------------------------------------------------------------------------------
; Skip spaces
; Entry: 	
; Assumes:	
; Returns: 
;------------------------------------------------------------------------------

skip_spaces proc		
		Skip_Space:	call get_symbol
					cmp dl, SPACE
					loope Skip_Space

		ret
skip_spaces endp

;------------------------------------------------------------------------------
; Get a number from the command line
; Entry: 
; Assumes:	
; Returns: ah - number
;------------------------------------------------------------------------------

{
	int x = 1;
	int y = 0;

	if ( x == 0 )
	{
		y = 2;
	} 
	else
	{
		y = 3;
	}

	foo();
}

mov x, 1
mov y, 0
cmp x, 0
jne A
A: mov y, 2
jne B
mov y, 3
B: foo();

get_number proc
		call skip_spaces
		xor ax, ax
		A:	mov al, 10d
			sub dl, '0' 
			mul ah
			mov ah, al
			add ah, dl

			cmp cx, 0
			je Return
			call get_symbol
			cmp dl, SPACE
			loopne A
		
		Return: ret
get_number endp	

;------------------------------------------------------------------------------
; Get the address of the place where you need to draw
; Entry: 	dh - coordinate of x
;		 	dl - coordinate of y
; Assumes:	
; Returns: di - value of address
;------------------------------------------------------------------------------

get_address proc
		mov al, 80d
		mul dl
		mov bx, 0000h
		mov bl, dh
		add ax, bx
		mov di, ax
		mov ax, 2d
		mov cx, dx
		mul di	
		mov di, ax

		mov dx, cx
		mov cx, 0000h

		ret
get_address endp	


;------------------------------------------------------------------------------
; Get a location address of the place where you need to draw
; Entry: 	cl - location
; Assumes:	
; Returns: di - value of address
;------------------------------------------------------------------------------

get_location proc
		mov bx, 0080d
		sub bl, cl
		mov al, 2d
		mul bl
		add di, ax

		mov bl, myHeight
		inc bl
		mov ah, COLOR
		mov al, SPACE

		ret
get_location endp

;------------------------------------------------------------------------------
; Get the address of the corner character
; Entry: 	dh - coordinate of x
;		 	dl - coordinate of y
; Assumes:	
; Returns: di - value of address
;------------------------------------------------------------------------------

get_address_corner proc
		mov ax, 0080d
		mul dl
		mov bx, 0000h
		mov bl, dh
		add ax, bx
		mov di, ax
		mov ax, 0002d
		mov cx, dx
		mul di
		mov di, ax

		mov dx, cx
		mov cx, 0000h
		mov ah, COLOR

		ret
get_address_corner endp

;Variables
;--------------------------------------------------------------------------------------------
LEFT_UP     db		00h    
HOR_LINE    db		00h    	
RIGHT_UP    db		00h     
VER_LINE    db		00h     
RIGHT_DOWN  db		00h	   
LEFT_DOWN   db		00h

myWidth		db		00h
myHeight	db		00h
myStyle		db		00h

strError	db		"Data error$"
;--------------------------------------------------------------------------------------------

end 	Start