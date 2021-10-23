IDEAL
MODEL small
STACK 100h

MAX_BMP_WIDTH = 320
MAX_BMP_HEIGHT = 200
SMALL_BMP_HEIGHT = 40
SMALL_BMP_WIDTH = 40

DATASEG
aliensX dw 16,32,48,64,80,16,32,48,64,80,16,32,48,64,80,16,32,48,64,80
aliensY dw 36,36,36,36,36,52,52,52,52,52,68,68,68,68,68,84,84,84,84,84
resetX dw 16,32,48,64,80,16,32,48,64,80,16,32,48,64,80,16,32,48,64,80
resetY dw 36,36,36,36,36,52,52,52,52,52,68,68,68,68,68,84,84,84,84,84
aliensShotOrder dw 6,2,10,4,8
aliensShotOrderOff dw ?
aliensShots dw 200,0,200,0,200,0
shotX dw ?
shotY dw ?
AddArray dw 0
MaxX dw ?
MinX dw ?
FirstAlienX dw 18
ExplosionX dw 0 
ExplosionY dw 0
Explosion2X dw 0 
Explosion2Y dw 0
BiggestAlienX dw ?
SmallestAlienX dw ?
LowestAlien dw ?
SaveCX dw ?
SaveDX dw ?
SaveDI dw ?
SaveAL db ?
PixelAmount db ?
SubCx dw ?
SubDx dw ?
speed dw 100
changedDirection db 1
counter db 0
counter1 db 0
counterForAShotsFrequency db 100
spaceHold db 0
MoveAlienDecider dw 100
alienForm db 0
score db 0,0,0

; ------ data for Moodle code for Image Manipulation
ScreenLineMax db MAX_BMP_WIDTH dup (0)  ; One Color line read buffer
;BMP File data
FileHandle dw ?
Header db 54 dup (0)
Palette db 400h dup (0)
SmallPicName db 'Menu.bmp', 0
SmallPicName1 db 'GameOver.bmp', 0
SmallPicName2 db 'Inst.bmp', 0
num0 db 'num0.bmp', 0
num1 db 'num1.bmp', 0
num2 db 'num2.bmp', 0
num3 db 'num3.bmp', 0
num4 db 'num4.bmp', 0
num5 db 'num5.bmp', 0
num6 db 'num6.bmp', 0
num7 db 'num7.bmp', 0
num8 db 'num8.bmp', 0
num9 db 'num9.bmp', 0
BmpLeft dw ?
BmpTop dw ?
BmpColSize dw ?
BmpRowSize dw ?	 

CODESEG
; ------ Code taken from Moodle for Image Manipulation 
proc OpenShowBmp near
	push cx
	push bx
	call OpenBmpFile
	call ReadBmpHeader
	; from  here assume bx is global param with file handle. 
	call ReadBmpPalette
	call CopyBmpPalette
	call ShowBMP 
	call CloseBmpFile
@@ExitProc:
	pop bx
	pop cx
	ret
endp OpenShowBmp
; ------	
proc OpenBmpFile near ; input dx filename to open						 
	mov ah, 3Dh
	xor al, al
	int 21h
	mov [FileHandle], ax
	ret
endp OpenBmpFile
; ------
proc CloseBmpFile near
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile
; ------
proc ReadBmpHeader near ; Read 54 bytes the Header					
	push cx
	push dx
	
	mov ah,3fh
	mov bx, [FileHandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	
	pop dx
	pop cx
	ret
endp ReadBmpHeader
; ------
proc ReadBmpPalette near ; Read BMP file color palette, 256 colors * 4 bytes (400h)
						 ; 4 bytes for each color BGR + null)			
	push cx
	push dx
	
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	
	pop dx
	pop cx
	ret
endp ReadBmpPalette
; ------
proc CopyBmpPalette near ; Will move out to screen memory the colors
			 ; video ports are 3C8h for number of first color
			 ; and 3C9h for all rest															
	push cx
	push dx
	
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0  ; black first							
	out dx,al ;3C8h
	inc dx	  ;3C9h
CopyNextColor:
	mov al,[si+2] 		; Red				
	shr al,2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution).				
	out dx,al 						
	mov al,[si+1] 		; Green.				
	shr al,2            
	out dx,al 							
	mov al,[si] 		; Blue.				
	shr al,2            
	out dx,al 							
	add si,4 			; Point to next color.  (4 bytes for each color BGR + null)				
								
	loop CopyNextColor
	
	pop dx
	pop cx
	
	ret
endp CopyBmpPalette
; ------
proc ShowBMP 
; BMP graphics are saved upside-down.
; Read the graphic line by line (BmpRowSize lines in VGA format),
; displaying the lines from bottom to top.
	push cx
	
	mov ax, 0A000h
	mov es, ax
	
	mov cx,[BmpRowSize]
	
	mov ax,[BmpColSize] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
	xor dx,dx
	mov si,4
	div si
	mov bp,dx
	
	mov dx,[BmpLeft]
	
@@NextLine:
	push cx
	push dx
	
	mov di,cx  ; Current Row at the small bmp (each time -1)
	add di,[BmpTop] ; add the Y on entire screen
	
 
	; next 5 lines  di will be  = cx*320 + dx , point to the correct screen line
	mov cx,di
	shl cx,6
	shl di,8
	add di,cx
	add di,dx
	
	; small Read one line
	mov ah,3fh
	mov cx,[BmpColSize]  
	add cx,bp  ; extra  bytes to each row must be divided by 4
	mov dx,offset ScreenLineMax
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,[BmpColSize]  
	mov si,offset ScreenLineMax
	rep movsb ; Copy line to the screen
	
	pop dx
	pop cx
	 
	loop @@NextLine
	
	pop cx
	ret
endp ShowBMP 
; ------ end of code from Moodle

proc moveLeft   ; procedure which moves the ship one pixel left
	mov dx, 170
	mov al,0
	call DrawShip

	push cx
	push dx
	; --- this code segment is to deal with a bug that causes some pixels on the edges of the ship to not be deleted
	mov [SaveCX], cx
	mov cx, 10
deleteAll:
	push cx
	mov cx, [SaveCX]
	call DrawShip
	inc [saveCX]
	pop cx
	loop deleteAll
	mov cx, 160
	call DrawShip

	pop dx
	pop cx

	dec cx
	mov al, 15
	call DrawShip
	ret
endp moveLeft
; ------
proc moveRight   ; procedure which moves the ship one pixel right
	mov dx, 170
	mov al,0
	call DrawShip

	push cx
	push dx
	; --- same as above
	mov [SaveCX], cx
	mov cx, 10
deleteAll1:
	push cx
	mov cx, [SaveCX]
	call DrawShip
	dec [saveCX]
	pop cx
	loop deleteAll1
	mov cx, 160
	call DrawShip

	pop dx
	pop cx

	inc cx
	mov al, 15 
	call DrawShip
	ret
endp moveRight
; ------
proc DrawLine       ;simple procedure which draws a line accordingly to the the parameters she gets
	sub cx, [SubCX]
	sub dx, [SubDX]
drawLine1:
	int 10h
	add cx, 1
	cmp [PixelAmount], 0
	sub [PixelAmount], 1
	jne drawLine1
	mov cx, [SaveCX]
	mov dx, [SaveDX]
	ret
endp DrawLine
; ------
proc DrawShip      ;procedure which draws the ship using the DrawLine function
	mov [SaveCX], cx
	mov [SaveDX], dx
	int 10h
	mov [SubCx], 3
	mov [SubDX], -1
	mov [PixelAmount], 7
	call DrawLine
	mov [SubCx], 5
	mov [SubDX], -2
	mov [PixelAmount], 11
	call DrawLine
	mov [SubDX], -3
	mov [PixelAmount], 11
	call DrawLine
	ret
endp DrawShip
; ------
proc DrawAlien    ;procedure which draws a single alien using the DrawLine function
	mov [SaveCX], cx
	mov [SaveDX], dx

	mov [SubCx], 5
	mov [SubDX], 1
	mov [PixelAmount], 11
	call DrawLine

	mov [SubCx], 4
	mov [SubDX], 2
	mov [PixelAmount], 2
	call DrawLine

	mov [SubCx], 1
	mov [SubDX], 2
	mov [PixelAmount], 3
	call DrawLine

	mov [SubCx], -3
	mov [SubDX], 2
	mov [PixelAmount], 2
	call DrawLine

	mov [SubCx], 3
	mov [SubDX], 3
	mov [PixelAmount], 7
	call DrawLine

	mov [SubCx], 2
	mov [SubDX], 4
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -2
	mov [SubDX], 4
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], 3
	mov [SubDX], 5
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -3
	mov [SubDX], 5
	mov [PixelAmount], 1
	call DrawLine

	cmp [alienForm], 0
	jne AlienForm2Station

	; --------------------------- alien form 1

	mov [SubCx], 2
	mov [SubDX], -2
	mov [PixelAmount], 2
	call DrawLine

	mov [SubCx], -1
	mov [SubDX], -2
	mov [PixelAmount], 2
	call DrawLine

	mov [SubCx], 5
	mov [SubDX], -1
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -5
	mov [SubDX], -1
	mov [PixelAmount], 1
	call DrawLine
	jmp JumpOverIt

; ---- code jump station
AlienForm2Station:
	jmp AlienForm2
; ----

JumpOverIt:
	mov [SubCx], 3
	mov [SubDX], -1
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -3
	mov [SubDX], -1
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], 3
	mov [SubDX], 0
	mov [PixelAmount], 7
	call DrawLine

	mov [SubCx], 5
	mov [SubDX], 0
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -5
	mov [SubDX], 0
	mov [PixelAmount], 1
	call DrawLine
	jmp AlienDone

	; ----------------------------- alien form 2

AlienForm2:
	mov [SubCx], 4
	mov [SubDX], 0
	mov [PixelAmount], 9
	call DrawLine

	mov [SubCx], 4
	mov [SubDX], -2
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -4
	mov [SubDX], -2
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], 3
	mov [SubDX], -1
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -3
	mov [SubDX], -1
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], 5
	mov [SubDX], 2
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -5
	mov [SubDX], 2
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], 5
	mov [SubDX], 3
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -5
	mov [SubDX], 3
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], 5
	mov [SubDX], 4
	mov [PixelAmount], 1
	call DrawLine

	mov [SubCx], -5
	mov [SubDX], 4
	mov [PixelAmount], 1
	call DrawLine

AlienDone:
	ret
endp DrawAlien
; ------
proc DrawAliens   ;procedure which draws the aliens according to his coordinates saved in the array
	push cx
	mov cx, 20
	push di
	push si
DrawAliens2:
	cmp [word ptr di], 0
	je NextAlien
	push cx
	mov bh, 0h
	mov cx, [di]
	mov dx, [si]
	mov ah, 0ch
	call DrawAlien
	pop cx
NextAlien:
	add di, 2
	add si, 2
	loop DrawAliens2
	pop si
	pop di
	pop cx
	ret
endp DrawAliens
; ------
proc DrawObstacle   ; procedure that draws one obstacle on the x and y it gets in cx and dx
	mov [SaveCX], cx
	mov [SaveDX], dx

    mov [SubCx], 4
	mov [SubDX], 4
	mov [PixelAmount], 9
	call DrawLine

	mov [SubDX], 3
	mov [PixelAmount], 9
	call DrawLine

	mov [SubCx], 6
	mov [SubDX], 2
	mov [PixelAmount], 13
	call DrawLine

	mov [SubDX], 1
	mov [PixelAmount], 13
	call DrawLine

	mov [SubDX], 0
	mov [PixelAmount], 13
	call DrawLine

	mov [SubDX], -1
	mov [PixelAmount], 13
	call DrawLine

	mov [SubDX], -2
	mov [PixelAmount], 13
	call DrawLine

	mov [SubDX], -3
	mov [PixelAmount], 13
	call DrawLine

	mov [SubDX], -4
	mov [PixelAmount], 13
	call DrawLine

	mov [SubCx], 8
	mov [SubDX], -5
	mov [PixelAmount], 17
	call DrawLine

	mov [SubDX], -6
	mov [PixelAmount], 17
	call DrawLine

	mov [SubDX], -7
	mov [PixelAmount], 17
	call DrawLine

	mov [SubDX], -8
	mov [PixelAmount], 17
	call DrawLine

	mov [SubDX], -9
	mov [PixelAmount], 17
	call DrawLine

	mov [SubDX], -10
	mov [PixelAmount], 17
	call DrawLine

	mov [SubDX], -11
	mov [PixelAmount], 5
	call DrawLine

	mov [SubDX], -12
	mov [PixelAmount], 5
	call DrawLine

	mov [SubCX], -4
	mov [SubDX], -11
	mov [PixelAmount], 5
	call DrawLine

	mov [SubDX], -12
	mov [PixelAmount], 5
	call DrawLine
	ret
endp DrawObstacle
; ------
proc DrawObstacles   ; procedure that draws all the obstacles
	mov cx, 70
  	mov dx, 140
    call DrawObstacle

    mov cx, 130
    call DrawObstacle

    mov cx, 190
    call DrawObstacle

    mov cx, 250
    call DrawObstacle
	ret
endp DrawObstacles
; ------
proc DrawExplosion   ; procedure that draws the little explosion when an alien dies
	mov [SaveCX], cx
	mov [SaveDX], dx

    inc dx
    inc cx
    int 10h

    inc dx
    inc cx
    int 10h

	mov cx, [SaveCX]
	mov dx, [SaveDX]

	inc dx
	dec cx
	int 10h

	inc dx
	dec cx
	int 10h

	mov cx, [SaveCX]
	mov dx, [SaveDX]

	add cx, 3
	int 10h
	
	inc dx
    inc cx
    int 10h

    inc dx
    inc cx
    int 10h

    mov cx, [SaveCX]
	mov dx, [SaveDX]

	sub cx, 3
	int 10h

	inc dx
	dec cx
	int 10h

	inc dx
	dec cx
	int 10h	

	mov cx, [SaveCX]
	mov dx, [SaveDX]

	dec dx
	add cx, 5
	int 10h

	sub cx, 10
	int 10h

	mov cx, [SaveCX]
	mov dx, [SaveDX]

	sub dx, 2
	add cx, 3
	int 10h

	inc cx
	dec dx
	int 10h

	inc cx
	dec dx
	int 10h

	mov cx, [SaveCX]
	mov dx, [SaveDX]

	sub dx, 2
	sub cx, 3
	int 10h

	dec cx
	dec dx
	int 10h

	dec cx
	dec dx
	int 10h		

	add cx, 4
	int 10h

	dec cx
	dec dx
	int 10h

	add cx, 4
	int 10h

	inc dx
	dec cx
	int 10h

	mov cx, [SaveCX]
	mov dx, [SaveDX]
	ret
endp DrawExplosion
; ------
proc MoveAliens2   ;procedure that moves the aliens according to the value of the bl register
	mov al, 0
	call DrawAliens
	push cx
; deletes the explosion that happens when the player hits an alien
	mov cx, [ExplosionX]
	mov dx, [ExplosionY]
	call DrawExplosion
	mov [ExplosionX], 0  ; this is to show that there are no explosions on screen currently
	mov cx, [Explosion2X]
	mov dx, [Explosion2Y]
	call DrawExplosion
	mov [Explosion2X], 0
	mov cx, 20
	; --- change the form of the aliens
	cmp [alienForm], 0
	jne ChangeToZero
	mov [alienForm], 1
	jmp doneChanging
ChangeToZero:
	mov [alienForm], 0
doneChanging:
	cmp bl, 0
	je AddTo
	jne SubFrom
AddTo:
	call AddToArray
	jmp continue2
SubFrom:
	call SubToArray
continue2:
	pop cx
	mov al, 2
	call DrawAliens
	ret
endp MoveAliens2
; ------
proc MoveAliens  ;this procedure decides how the aliens will move
	cmp [MoveAlienDecider], 0
	jne dontMoveAliensStation
	push ax
	mov ax, [speed]
	mov [MoveAlienDecider], ax
	pop ax
	call reset ;check if there are still aliens alive
; ----- this code segment finds the most right alien most left alien and the lowest alien to know when to make the aliens change direction and when to stop them from descending
	push cx
	push ax
	push bx
	push dx
	mov cx, 20
ZeroXCoordinate:
	mov ax, [di]
 	mov bx, [di]
 	cmp ax, 0
 	jne continue4
 	add di, 2
 	loop ZeroXCoordinate
 continue4:
 	mov di, offset aliensX
 	mov cx, 20
 ZeroYCoordinate:
 	mov dx, [si]
 	cmp dx, 0
 	jne continue5
 	add si, 2
 	loop ZeroYCoordinate
continue5:
	mov si, offset aliensY
	mov cx, 20
FindBiggestX:
	cmp [word ptr di], 0
	je done
	cmp [di], ax
	jle FindSmallestX
	mov ax, [di]
FindSmallestX:
	cmp [di], bx
	jge FindLowestAlien
	mov bx, [di]
FindLowestAlien:
	cmp [si], dx
	jle done
	mov dx, [si]
done:
	add di, 2
	add si, 2
	loop FindBiggestX
	mov [BiggestAlienX], ax
	mov [SmallestAlienX], bx
	mov [LowestAlien], dx
	pop dx
	pop bx
	pop ax
	pop cx
	mov di, offset aliensX
	mov si, offset aliensY
	; ---------
	cmp [FirstAlienX], 122 ;keep this divisible by the jump of the aliens
	jne next
	mov [changedDirection], 0 ;this saves if the aliens changed directions so they don't get stuck only descending
	jmp next
; ------ code metro
dontMoveAliensStation:
	jmp dontMoveAliens
; ------
next:
	cmp [BiggestAlienX], 304 ;those are the coordinates when the aliens stop moving in one direction and move the other
	je left
	cmp [SmallestAlienX], 16 ;same as above
	je right
	jmp continue
right:
	cmp [changedDirection], 0
	jne continueStation
	mov [changedDirection], 1
	mov bl, 0
	mov al, 0
	call DrawAliens
	cmp [LowestAlien], 124
	jne DontDeleteObstacles
	push cx
	mov al, 0
	call DrawObstacles
	pop cx
DontDeleteObstacles:
	cmp [LowestAlien], 156 ;this is the y when the aliens stop moving down
	je continue
	; --- change the form of the aliens
	cmp [alienForm], 0
	jne ChangeToZero1
	mov [alienForm], 1
	jmp doneChanging1
ChangeToZero1:
	mov [alienForm], 0
doneChanging1:
	push cx
	mov cx, 20
	call LowerAliens
	mov al, 2
	call DrawAliens
	mov cx, 30000
	jmp return
; ---- code jump station
continueStation:
	jmp continue
; ----
left:
	cmp [changedDirection], 0
	jne continue
	mov [changedDirection], 1
	mov bl, 1
	mov al, 0
	call DrawAliens
	cmp [LowestAlien], 156 ;same as above
	je continue
	; --- change the form of the aliens
	cmp [alienForm], 0
	jne ChangeToZero2
	mov [alienForm], 1
	jmp doneChanging2
ChangeToZero2:
	mov [alienForm], 0
doneChanging2:
	push cx
	mov cx, 20
	call LowerAliens
	mov al, 2
	call DrawAliens
	mov cx, 30000    ;this is for a loop in place so the code won't be running too fast
	jmp return
continue:
	call MoveAliens2
	push cx
	mov cx, 30000
	jmp return
dontMoveAliens:
	sub [MoveAlienDecider], 1    ;subbing from the counter that needs to be 0 for the aliens to move
	push cx
	mov cx, 30000
return:
	loop return
	pop cx
	ret
endp MoveAliens
; ------
proc AddToArray
	push di
	add [FirstAlienX], 8
AddToArray2:
	cmp [word ptr di], 0
	je DontAddToArray
	add [word ptr di], 8
DontAddToArray:
	add di, 2
	loop AddToArray2
	pop di
	ret
endp AddToArray
; ------
proc SubToArray
	push di
	sub [FirstAlienX], 8
SubToArray2:
	cmp [word ptr di], 0
	je DontSub
	sub [word ptr di], 8
DontSub:
	add di, 2
	loop SubToArray2
	pop di
	ret
endp SubToArray
; ------
proc LowerAliens
	push si
LowerAliens2:
	add [word ptr si], 8
	add si, 2
	loop LowerAliens2
	pop si
	ret
endp LowerAliens
; ------
proc reset   ;this procedure resets the position of the aliens if they all died or the game is restarting
	push cx
	mov cx, 20
CheckAllDead:
	cmp [word ptr di], 0
	jne NoReset
	add di, 2
	loop CheckAllDead
; reset aliens
	push ax
	push bx
	push dx
	mov ax, offset resetX
	mov bx, offset resetY
	mov di, offset aliensX
	mov si, offset aliensY
	mov cx, 20
resetAliens:
	push bx
	mov bx, ax
	mov dx, [bx]
	pop bx
	mov [di], dx
	mov dx, [bx]
	mov [si], dx
	add ax, 2
	add bx, 2
	add di, 2
	add si, 2
	loop resetAliens
	pop dx
	pop bx
	pop ax
	mov si, offset aliensY
	mov [changedDirection], 1                ; so they won't jump down right from the beginning
	mov [alienForm], 1                       ; so they will start in their original form
	mov [speed], 100                         ; resets their speed
	mov [MoveAlienDecider], 100              ; makes them wait do they don't start moving immediately
	mov [counterForAShotsFrequency], 100
	mov bl, 0
	mov [FirstAlienX], 18
NoReset:
	mov di, offset aliensX
	pop cx
	ret
endp reset
; ------
proc shots  ; procedure which manages the shots of the player
	push bp
	mov bp, sp
	mov al, 0
	cmp [word ptr bp + 4], 0FFFFh  ; checks if there is at least a single shot in the stack
	je noShotsStation
	push cx
	mov si, 4
DeleteNextShot:
	mov dx, [bp + si]
	add si, 2
	mov cx, [bp + si]
	add si, 2
	cmp dx, 0CCCCh   ; check if it's a shot that hit an alien
	je DeleteNextShot2
	int 10h
	inc dx
	int 10h
	inc dx
	int 10h
	inc dx
	int 10h
DeleteNextShot2:
	cmp [word ptr bp + si], 0FFFFh
	jne DeleteNextShot
	; ----- redraw what the shot has deleted from the ship
	mov dx, 170
	pop cx
	mov al, 15
	int 10h
	inc dx
	int 10h
	inc dx
	int 10h
	inc dx
	int 10h
	push cx
	; -----
	mov si, 4
AdvanceNextShot:
	cmp [word ptr bp + si], 0 ; check if the shot got to the end
	jne keepAdvancing
	mov [word ptr bp + si], 0FFFFh ; "erase" it
	cmp [word ptr bp + 4], 0FFFFh ; check if it was the last shot
	je noShotsMiddleStation
	cmp [word ptr bp + 4], 0CCCCh
	je noShotsMiddleStation
	mov si, 4
	mov al, 255
	jmp DrawNextShot
noShotsStation:
	jmp noShots
keepAdvancing:
	cmp [word ptr bp + si], 0CCCCh
	je AdvanceNextShot2Station
	sub [word ptr bp + si], 2
	push ax
	mov ax, [word ptr bp + si]
	mov [shotY], ax   ; saving the y of the shot for checks
	add si, 2
	mov ax, [word ptr bp + si]
	mov [shotX], ax   ; saving the x of the shot for checks
	pop ax
	; ------ check if it hit an alien
	push si
	mov di, offset aliensX
	mov si, offset aliensY
	mov cx, 4
CheckNextRowAliens:
	push ax
	push cx
	mov cx, 4
	mov ax, [si]
checkHigherY:      ; checking if any part of the shot touched the the alien
	cmp [shotY], ax
	je CheckHitAlien
	add [shotY], 1
	loop checkHigherY
	sub [shotY], 4
	pop cx
	pop ax
	add [AddArray], 10
	add si, 10
	loop CheckNextRowAliens
	jmp NoAliensHit

; ----- jump station
noShotsMiddleStation:
	jmp noShotsMiddle
AdvanceNextShot2Station:
	jmp AdvanceNextShot2
; ----- 

CheckHitAlien:
	pop cx
	pop ax
	add di, [AddArray]  ; adding to the offset of the x coordinate the index of the alien we are checking
	mov cx, 5
CheckNextAlien:
	push ax
	mov ax, [word ptr di]
	mov [MaxX], ax
	mov [MinX], ax
	pop ax
	add [MaxX], 5
	sub [MinX], 5
CheckAlien:
	push ax
	mov ax, [MaxX]
	cmp [shotX], ax  ; check if the X of the shot is between the maximum x of the alien and the minimum x of the alien to check if it hit
	jle AlienHit
NotRightX:
	pop ax
	add di, 2
	loop CheckNextAlien
	jmp NoAliensHit

; ----- jump station
AdvanceNextShotStation:
	jmp AdvanceNextShot
; -----

AlienHit:
	mov ax, [MinX]
	cmp [shotX], ax
	jl NotRightX
	pop ax ;pop ax that we pushed in CheckAlien
	mov cx, [word ptr di]
	mov dx, [word ptr si]
	mov al, 0
	call DrawAlien
; draws the explosion that happens when the player hits an alien
	cmp [ExplosionX], 0  ; if those variables are taken use the other ones
	jne taken
	mov [ExplosionX], cx
	mov [ExplosionY], dx
	mov al, 2
	call DrawExplosion
	jmp DrawnExplosion
taken:
	mov [Explosion2X], cx
	mov [Explosion2Y], dx
	mov al, 2
	call DrawExplosion
DrawnExplosion:

	mov [word ptr di], 0
	sub [speed], 5 ;make the aliens move faster as they die
	pop si
	sub si, 2 ;because si is pointing on the x and not the y
	mov [word ptr bp + si], 0CCCCh
	add si, 2
	push si
	call AddToScore
	call DrawScore

	pop si
	jmp ObstacleNotHit

; ---- jump station
AdvanceNextShotStation2:
	jmp AdvanceNextShotStation
; ----

NoAliensHit:
	pop si
	; check to not let the shots delete the score
	cmp [shotY], 22
	jg ScoreNotHit
	cmp [shotX], 212
	jl ScoreNotHit
	sub si, 2 ;because si is pointing on the x and not the y
	mov [word ptr bp + si], 0CCCCh
	add si, 2
ScoreNotHit:

	; ---- check if it hit an obstacle
	mov cx, [shotX] ; x position
    mov dx, [shotY] ; y position
    
    push ax
    mov ah, 0Dh
    int 10h
    mov [SaveAL], al
    pop ax
    
    cmp [SaveAL], 30
    jne ObstacleNotHit
    sub si, 2 ;because si is pointing on the x and not the y
	mov [word ptr bp + si], 0CCCCh
	add si, 2
	mov al, 0
	inc dx
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h

ObstacleNotHit:
	
	mov [AddArray], 0
	jmp continue3

AdvanceNextShot2:
	add si, 2
continue3:
	add si, 2
	cmp [word ptr bp + si], 0FFFFh
	jne AdvanceNextShotStation2
	mov si, 4
	mov al, 255
DrawNextShot:
	mov dx, [bp + si]
	add si, 2
	mov cx, [bp + si]
	add si, 2
	cmp dx, 0CCCCh
	je DrawNextShot2
	int 10h
	inc dx
	int 10h
	inc dx
	int 10h
	inc dx
	int 10h
DrawNextShot2:
	cmp [word ptr bp + si], 0FFFFh
	jne DrawNextShot
noShotsMiddle:
	pop cx
	mov si, offset aliensY
	mov di, offset aliensX
noShots:
	cmp [counter], 0
	jz zero
	sub [counter], 1
zero:
	pop bp
	ret
endp shots
; ------
proc AliensShoot   ; procedure which manages the shots of the aliens
	push di
	push bx
	mov di, offset aliensShots ;di - offset of the alien shots currently on screen
	mov [SaveCX], cx
	mov cx, 3
DeleteAlienShots:
	cmp [word ptr di], 200  ; check if the shot got to the end of the screen
	jl Delete
	add di, 4
	jmp DeleteNextAlienShot
Delete:
	mov dx, [di]
	push cx
	mov cx, [di + 2]
	add di, 4
	mov al, 0
	mov bh, 0h
	mov ah, 0ch
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h
	pop cx
DeleteNextAlienShot:
	loop DeleteAlienShots
	mov di, offset aliensShots
	mov cx, 3
CheckForVacantShot:
	cmp [word ptr di], 200  ; check if there is any shot that got to the end and if yes change it to a new shot
	je AddAlienShot
	add di, 4
back:
	loop CheckForVacantShot
	mov di, offset aliensShots
	mov cx, 3
	jmp AdvanceAliensShot
AddAlienShot:
	cmp [counterForAShotsFrequency], 0  ; check if an alien didn't shot recently
	jne dontAdd
	mov [counterForAShotsFrequency], 100
	mov bx, [aliensShotOrderOff]
	; ------ y coordinate
	add si, [bx]
	add si, 28 ;adding 28 to take the coordinates of the lowest row of aliens instead of the highest
	push cx
	; ------ check which alien in the column is alive to make him shoot
	push di
	mov di, offset aliensX
	add di, [bx]
	add di, 28
	mov cx, 4
CheckAlienAlive:  ; checks if there is an alien alive in the column so it can shoot
	cmp [word ptr di], 0
	jne AlienAlive
	sub si, 10
	add [AddArray], 10
	sub di, 10
	loop CheckAlienAlive
	pop di
	jmp ColumnDead
AlienAlive:
	pop di
	mov cx, [si]
	mov [di], cx
	pop cx
	; ------ x coordinate
	add di, 2
	mov [SaveDI], di
	mov di, offset aliensX
	add di, [bx]
	add di, 28 ;same as in x coordinate
	sub di, [AddArray]
	push cx
	mov cx, [di] ;cx saves the x coordinate of the new shot
	mov di, [SaveDI] ;di now points to the location in the array for the x of the new shot
	mov [di], cx ;move the x coordinate to the location in the array for the x of the new shot
	; ------
ColumnDead:    ; if every alien from a column is dead make another column shoot
	pop cx
	mov [AddArray], 0
	add di, 2
	cmp [counter1], 4
	je dontAddToOff
	add [aliensShotOrderOff], 2
	add [counter1], 1
	mov si, offset aliensY
dontAdd:
	sub [counterForAShotsFrequency], 1
	jmp back
dontAddToOff:
	mov [aliensShotOrderOff], offset aliensShotOrder
	mov [counter1], 0 
	mov si, offset aliensY
	jmp back

AdvanceAliensShot:
	cmp [word ptr di], 200
	jl Advance
	jmp AdvanceNextAlienShot
Advance:
	add [word ptr di], 1

	; ---- check if it hit an obstacle
	push cx
	mov dx, [word ptr di] ; y position
	add di, 2
	mov cx, [word ptr di] ; x position
	sub di, 2
   
    push ax
    mov ah, 0Dh
    int 10h
    mov [SaveAL], al
    pop ax
    
    cmp [SaveAL], 30
    jne ObstacleNotHit2
	mov [word ptr di], 200
	mov al, 0
	int 10h

	dec cx
	int 10h
	add cx, 2
	int 10h
	dec cx

	inc dx
	int 10h

	dec cx
	int 10h
	add cx, 2
	int 10h
	dec cx

ObstacleNotHit2:
	pop cx

	; ------- checks if the player got hit
	push cx
	mov cx, [SaveCX]
	cmp [word ptr di], 171
	jne PlayerNotHit1Station
	add di, 2
	mov [MaxX], cx
	mov [MinX], cx
	add [MaxX], 5
	sub [MinX], 5
	mov dx, [MaxX]
	cmp [word ptr di], dx  ; checks if the shot is between the extreme x's of the ship. if yes then it got hit
	jg PlayerNotHitStation
	mov dx, [MinX]
	cmp [word ptr di], dx
	jl PlayerNotHitStation

	; makes the ship flash a bit so the player understands that he got hit

	mov bh, 0h
	mov dx, 170
	mov al, 0
	call DrawShip

	call waitABit

	mov al, 15
	mov cx, [SaveCX]
	call DrawShip

	call waitABit

	mov al, 0
	mov cx, [SaveCX]
	call DrawShip

	call waitABit

	jmp passStation

; ------ code jump station
PlayerNotHit1Station:
	jmp PlayerNotHit1
PlayerNotHitStation:
	jmp PlayerNotHit
AdvanceAliensShotStation:
	jmp AdvanceAliensShot
; ------

passStation:
	mov al, 15
	mov cx, [SaveCX]
	call DrawShip

	call waitABit

	mov al, 0
	mov cx, [SaveCX]
	call DrawShip

	call waitABit

	mov al, 15
	mov cx, [SaveCX]
	call DrawShip

	call waitABit

	mov al, 0
	mov cx, [SaveCX]
	call DrawShip

	call waitABit

	mov al, 15
	mov cx, [SaveCX]
	call DrawShip

	call waitABit

	mov al, 0
	mov cx, [SaveCX]
	call DrawShip

	mov [BmpLeft],0
	mov [BmpTop],-1
	mov [BmpColSize], 320
	mov [BmpRowSize], 200
	mov dx, offset SmallPicName1
	call OpenShowBmp 

	; show the score on the game over screen
	push di
	mov di, offset score
	mov [BmpColSize], 40
	mov [BmpRowSize], 40
	mov [BmpTop], 106
	mov [BmpLeft], 140
	call DrawNumber

	inc di

	mov [BmpLeft], 160
	call DrawNumber

	inc di

	mov [BmpLeft], 180
	call DrawNumber

	mov [BmpLeft], 200
	mov dx,offset num0
	call OpenShowBmp
	pop di

StayInGameOverMenu:
	in al, 60h
	cmp al, 0Fh
	jne NoInst
	call InstructionsMenu
NoInst:
	cmp al, 1h
	je exitMetro2
	cmp al, 39h
	jne StayInGameOverMenu

	; resets some variables for a restart of the game

	call reset
	mov [spaceHold], 0
	mov di, offset aliensShots
	mov [word ptr di], 200
	mov [word ptr di + 4], 200
	mov [word ptr di + 8], 200

	mov di, offset score ;reset the score
	mov [byte ptr di], 0
	inc di
	mov [byte ptr di], 0
	inc di
	mov [byte ptr di], 0

	jmp restart

AdvanceAliensShotStation1:
	jmp AdvanceAliensShotStation

PlayerNotHit:
	sub di, 2
PlayerNotHit1:
	pop cx

AdvanceNextAlienShot:
	add di, 4
	loop AdvanceAliensShotStation1

	mov di, offset aliensShots
	mov cx, 3
DrawAlienShot:
	cmp [word ptr di], 200  ; check if a shot got to the end and if yes don't draw it
	jl Draw
	add di, 4
	jmp DrawNextAlienShot
Draw:
	mov dx, [di]
	push cx
	mov cx, [di + 2]
	add di, 4
	mov al, 6
	mov bh, 0h
	mov ah, 0ch
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h
	pop cx
DrawNextAlienShot:
	loop DrawAlienShot
	; ------ redraws what the shot has deleted from the alien
	mov di, offset aliensX
	mov si, offset aliensY
	mov al, 2
	mov cx, 20
	jmp RepairNextAlien

; ------ code jump station
exitMetro2:
	jmp exitMetro1
; ------

RepairNextAlien:
	push cx
	mov cx, [di]
	mov dx, [si]
	cmp cx, 0
	je DontRepair
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h
	dec dx
	int 10h
DontRepair:
	add di, 2
	add si, 2
	pop cx
	loop RepairNextAlien 
	; ------
	mov cx, [SaveCX]
	pop bx
	pop di
	mov si, offset aliensY
	ret
endp AliensShoot
; ------
proc waitABit  ; procedure which makes the code stay in place for about half a second
	push cx
	mov cx, 12
wait0:
	push cx
	mov cx, 65535
wait1:
	loop wait1
	pop cx
	loop wait0
	pop cx
	ret
endp waitABit
; ------
proc InstructionsMenu
	mov ax, 13h
	int 10h
	mov [BmpLeft],0
	mov [BmpTop],-1
	mov [BmpColSize], 320
	mov [BmpRowSize], 200
	mov dx, offset SmallPicName2
	call OpenShowBmp 
	ret
endp InstructionsMenu
; ------
proc AddToScore   ; increments the score by 1
	push di
	mov di, offset score
	add di, 2
	cmp [byte ptr di], 9
	je AddTo10
	add [byte ptr di], 1
	jmp finished
AddTo10:
	mov [byte ptr di], 0
	sub di, 1
	cmp [byte ptr di], 9
	je AddTo100
	add [byte ptr di], 1
	jmp finished
AddTo100:
	mov [byte ptr di], 0
	sub di, 1
	add [byte ptr di], 1
finished:
	pop di
	ret
endp AddToScore
; ------
proc DrawScore  ; draws the score
	push di
	mov di, offset score
	mov [BmpColSize], 40
	mov [BmpRowSize], 40
	mov [BmpTop], -14
	mov [BmpLeft], 210
	call DrawNumber

	inc di

	mov [BmpLeft], 230
	call DrawNumber

	inc di

	mov [BmpLeft], 250
	call DrawNumber

	mov [BmpLeft], 270
	mov dx,offset num0
	call OpenShowBmp

	pop di
	ret
endp DrawScore
; ------
proc DrawNumber  ; draws each number of the score
	push di
	cmp [byte ptr di], 0
	je Print0
	cmp [byte ptr di], 1
	je Print1
	cmp [byte ptr di], 2
	je Print2
	cmp [byte ptr di], 3
	je Print3
	cmp [byte ptr di], 4
	je Print4
	cmp [byte ptr di], 5
	je Print5
	cmp [byte ptr di], 6
	je Print6
	cmp [byte ptr di], 7
	je Print7
	cmp [byte ptr di], 8
	je Print8
	cmp [byte ptr di], 9
	je Print9
	jmp stop
Print0:
	mov dx,offset num0
	call OpenShowBmp
	jmp stop
Print1:
	mov dx,offset num1
	call OpenShowBmp
	jmp stop
Print2:
	mov dx,offset num2
	call OpenShowBmp
	jmp stop
Print3:
	mov dx,offset num3
	call OpenShowBmp
	jmp stop
Print4:
	mov dx,offset num4
	call OpenShowBmp  
	jmp stop
Print5:
	mov dx,offset num5
	call OpenShowBmp
	jmp stop
Print6:
	mov dx,offset num6
	call OpenShowBmp 
	jmp stop
Print7:
	mov dx,offset num7
	call OpenShowBmp 
	jmp stop
Print8:
	mov dx,offset num8
	call OpenShowBmp 
	jmp stop
Print9:
	mov dx,offset num9
	call OpenShowBmp 

stop:
	pop di
	ret
endp DrawNumber
; ------

start:
	mov ax, @data
	mov ds, ax
	; ------ enter graphic mode
	mov ax, 13h
	int 10h
	; ------ starting menu
	mov [BmpLeft],0
	mov [BmpTop],-1
	mov [BmpColSize], 320
	mov [BmpRowSize], 200
	mov dx,offset SmallPicName
	call OpenShowBmp 
StayInStartMenu:
	in al, 60h
	cmp al, 0Fh
	jne NoInst2
	call InstructionsMenu
NoInst2:
	cmp al, 1h
	je exitMetro1
	cmp al, 39h
	jne StayInStartMenu
restart:
	mov ax, 13h
	int 10h
	; ------ draw the obstacles
	mov bh, 0h
	mov ah, 0ch
	mov al, 30
	call DrawObstacles
	; ------ draw the character
	mov cx, 160
	mov dx, 170
	mov al, 15
	call DrawShip
	; initialize starting point of arrays
	mov di, offset aliensX
	mov si, offset aliensY
	mov [aliensShotOrderOff], offset aliensShotOrder
	; define the starting point for shots coordinates
	push 0FFFFh
	push 0FFFFh
	; drawing aliens
	mov [alienForm], 0
	mov al, 2
	call DrawAliens
	call DrawScore
	call waitABit
	mov [ExplosionX], 0
	mov [Explosion2X], 0
	jmp WaitForData 
	; ------ code station
exitMetro1:
	jmp exitMetro
	; ------ gets keyboard data
WaitForData:
	call MoveAliens
	call AliensShoot
	call shots
	in al, 60h
	; ------ check if player shot
	cmp al, 39h
	je SpacePressed
	jmp check
SpacePressed:
	mov [spaceHold], 1
	jmp checkShoot
check:
	cmp al, 0b9h
	je SpaceReleased
	jmp checkShoot
SpaceReleased:
	mov [spaceHold], 0
checkShoot:
	cmp [spaceHold], 1
	jne Dontfire
	cmp [counter], 0
	jne Dontfire
	push cx
	push 170
	mov [counter], 70
	; ------
Dontfire:
	cmp al, 1h
	je exitStation
	cmp al, 1eh
	je Apress
	cmp al, 20h
	je Dpress
	jmp WaitForData
; ------ code jump station
exitMetro:
	jmp exitStation
; ------ a pressed
Apress:
	call MoveAliens
	call AliensShoot
	call shots
	cmp cx, 25  ; defines the left movement limit
	je pass
	call moveLeft
pass:
	in al, 60h
	; ------ check if player shot
	cmp al, 39h
	je SpacePressedA
	jmp checkA
SpacePressedA:
	mov [spaceHold], 1
	jmp checkShootA
checkA:
	cmp al, 0b9h
	je SpaceReleasedA
	jmp checkShootA
SpaceReleasedA:
	mov [spaceHold], 0
checkShootA:
	cmp [spaceHold], 1
	jne DontfireA
	cmp [counter], 0  ; the counter creates a cool down for the player shots
	jne DontfireA
	push cx
	push 170
	mov [counter], 70
	; ------  
DontfireA:
	cmp al, 20h
	je Dpress
	cmp al, 9eh
	jne Apress
	jmp WaitForData
; ------ jump to exit
exitStation:
	jmp exit
; ------ jump to Apress
ApressStation:
	jmp Apress
; ------ d pressed
Dpress:
	call MoveAliens
	call AliensShoot
	call shots
	cmp cx, 295  ; defines the right movement limit
	je pass2
	call moveRight
pass2:
	in al, 60h
	; ------ check if player shot
	cmp al, 39h
	je SpacePressedD
	jmp checkD
SpacePressedD:
	mov [spaceHold], 1
	jmp checkShootD
checkD:
	cmp al, 0b9h
	je SpaceReleasedD
	jmp checkShootD
SpaceReleasedD:
	mov [spaceHold], 0
checkShootD:
	cmp [spaceHold], 1
	jne DontfireD
	cmp [counter], 0
	jne DontfireD
	push cx
	push 170
	mov [counter], 70
	; ------ 
DontfireD:
	cmp al, 1eh
	je ApressStation
	cmp al, 0a0h
	jne Dpress
	jmp WaitForData
exit:
;Return to text mode
mov ah, 0
mov al, 2
int 10h
mov ax, 4c00h
int 21h
END start