IFNDEF _PAINT_
.386
.model flat,stdcall
option casemap:none

include			paint.inc

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
.data
ReadyPaint		DWORD	0			; 0 -> no click yet
PaintOver		DWORD	0			; 0 -> not over
PaintType		DWORD	1			; 0 -> eraser; 1 -> pen; 2 -> draw line; 3 -> draw rectangle; 4 -> roundRectangle; 5 -> draw ellipse
gFillType		DWORD	0
_szText         LPCTSTR ?
_szTextLength     DWORD ?
lastPoint POINT <0, 0>
fixedPoint POINT <0, 0>
lastPointGraphics POINT <0, 0>
gBrushColor		DWORD	255		; »­Ë¢ÑÕÉ«
gPenWidth		DWORD	2		; »­±Ê¿í¶È
gPenColor		DWORD	0		; »­±ÊÑÕÉ«
gEraserWidth	DWORD	2		; ÏðÆ¤²Á¿í¶È
gEraserColor	DWORD	0		; ÏðÆ¤²ÁÑÕÉ«
gPaintPoint		POINT	<>	; left up point
SCREENWIDTH		DWORD	0
SCREENHEIGHT	DWORD	0

.data?
hitpoint 		POINT		<>			
lastHdc			HDC			?
lastBmp			HBITMAP		?

.code
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; set color with r, g, b
_SetColor PROC r:DWORD, g:DWORD, b:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	mov ebx, 0
	mov eax, 10000h
	mul b
	add ebx, eax
	mov eax, 100h
	mul g
	add ebx, eax
	mov eax, r
	add eax, ebx
	ret
_SetColor ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; set screen w and h
_SetScreenWH PROC hWnd:HWND
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

	LOCAL @rect:RECT

	; get the rect
	invoke GetClientRect, hWnd, ADDR @rect
	; get the width and height
	mov eax, @rect.right
	sub eax, @rect.left
	mov SCREENWIDTH, eax
	sub SCREENWIDTH, 5
	
	mov eax, @rect.bottom
	sub eax, @rect.top
	mov SCREENHEIGHT, eax
	sub SCREENHEIGHT, 5

	ret
_SetScreenWH ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; set the last dc
_SetLastDc PROC hWnd:HWND
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL hdc:HDC
	
	; clear the lastBmp
	invoke DeleteObject, lastBmp
	invoke DeleteDC, lastHdc
	
	; set the lastBmp
	invoke GetDC, hWnd
	mov hdc,eax
	
	invoke  CreateCompatibleDC, hdc
	mov lastHdc, eax
			
	invoke CreateCompatibleBitmap, hdc, SCREENWIDTH, SCREENHEIGHT
	mov lastBmp, eax	
	
	invoke SelectObject, lastHdc, lastBmp
	
	invoke BitBlt, lastHdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, hdc, 0, 0, SRCCOPY
	
	invoke ReleaseDC, hWnd, hdc
	
	ret
_SetLastDc ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; initialize everything
_Initialization PROC hWnd:HWND
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL hdc:HDC
	mov gPaintPoint.x, 20
	mov gPaintPoint.y, 20
	
	invoke _SetScreenWH, hWnd
	; init global brush, pen and eraser width and color	
	invoke _SetColor, 255, 255, 255
	mov gEraserColor, eax
	; init last dc and bmp
	invoke GetDC, hWnd
	mov hdc,eax
	
	invoke  CreateCompatibleDC, hdc
	mov lastHdc, eax
			
	invoke CreateCompatibleBitmap, hdc, SCREENWIDTH, SCREENHEIGHT
	mov lastBmp, eax	
	
	invoke SelectObject, lastHdc, lastBmp
	
	invoke BitBlt, lastHdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, hdc, 0, 0, WHITENESS
	
	invoke ReleaseDC, hWnd, hdc

	invoke _ReDraw, hWnd
	ret
_Initialization ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; re draw
_ReDraw PROC hWnd:HWND
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL hdc:HDC
	LOCAL memDc:HDC
	LOCAL memBmp:HBITMAP

	invoke GetDC, hWnd
	mov hdc, eax

	invoke  CreateCompatibleDC, hdc
	mov memDc, eax
				
	invoke CreateCompatibleBitmap, hdc, SCREENWIDTH, SCREENHEIGHT
	mov memBmp, eax	
				
	invoke SelectObject, memDc, memBmp

	invoke BitBlt, memDc, 0, 0, SCREENWIDTH, SCREENHEIGHT, lastHdc, 0, 0, WHITENESS 
	invoke BitBlt, memDc, 0, 0, SCREENWIDTH, SCREENHEIGHT, lastHdc, 0, 0, SRCCOPY
	invoke BitBlt, hdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, memDc, 0, 0, SRCCOPY 
	
	invoke DeleteObject, memBmp
	invoke DeleteDC, memDc
	
	invoke ReleaseDC, hWnd, hdc
	ret
_ReDraw ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; erase with gEraser
_Erase PROC hdc:HDC, x:DWORD, y:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL eraser
	
	invoke CreatePen, PS_SOLID, gEraserWidth, gEraserColor
	mov eraser, eax
	invoke SelectObject,hdc,eraser;
	invoke DeleteObject, eax
	invoke MoveToEx, hdc, lastPoint.x, lastPoint.y, NULL
	invoke LineTo, hdc, x, y	
	
	invoke DeleteObject, eraser
			
	mov eax, x
	mov lastPoint.x, eax
	mov eax, y
	mov lastPoint.y, eax
	ret
_Erase ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; draw anything
_Draw PROC hdc:HDC, x:DWORD, y:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL pen
	
	invoke CreatePen, PS_SOLID, gPenWidth, gPenColor
	mov pen, eax
	invoke SelectObject,hdc,pen;
	invoke DeleteObject, eax
	invoke MoveToEx, hdc, lastPoint.x, lastPoint.y, NULL
	invoke LineTo, hdc, x, y	
			
	invoke DeleteObject, pen
	
	mov eax, x
	mov lastPoint.x, eax
	mov eax, y
	mov lastPoint.y, eax
	ret
_Draw ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; draw line
_DrawLine PROC hWnd:HWND, hdc:HDC, x:DWORD, y:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL pen

	invoke BitBlt, hdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, lastHdc, 0, 0, SRCCOPY
	
	; paint
	invoke CreatePen, PS_SOLID, gPenWidth, gPenColor
	mov pen, eax
	invoke SelectObject, hdc, pen;
	invoke DeleteObject, eax
	invoke MoveToEx, hdc, fixedPoint.x, fixedPoint.y, NULL
	invoke LineTo, hdc, x, y
	
	invoke DeleteObject, pen
	
	mov eax, x
	mov lastPoint.x, eax
	mov eax, y
	mov lastPoint.y, eax
	
	ret
_DrawLine ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; draw text
_DrawText PROC hdc:HDC, text:LPCTSTR, textLen:DWORD, x:DWORD, y:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL pen
	LOCAL @rect:RECT

	invoke BitBlt, hdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, lastHdc, 0, 0, SRCCOPY
	
	; paint
	invoke CreatePen, PS_SOLID, gPenWidth, gPenColor
	mov pen, eax
	invoke SelectObject, hdc, pen;
	invoke DeleteObject, eax

	mov eax, x
	mov @rect.left, eax
	add eax, 40
	mov @rect.right, eax
	mov eax, y
	mov @rect.top, eax
	add eax, 20
	mov @rect.bottom, eax

	;invoke TextOut,hdc,hitpoint.x,hitpoint.y,text,textLen
	invoke DrawText, hdc, text, textLen,ADDR @rect, DT_CENTER
	invoke DeleteObject, pen
	
	mov eax, x
	mov lastPoint.x, eax
	mov eax, y
	mov lastPoint.y, eax
	
	ret
_DrawText ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; draw rectangle; fillFlag 0 -> null 1 -> fill
_DrawRect PROC hWnd:HWND, hdc:HDC, x:DWORD, y:DWORD, fillFlag:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL brush
	LOCAL pen
	
	invoke BitBlt, hdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, lastHdc, 0, 0, SRCCOPY
	
	; paint
	invoke CreatePen, PS_SOLID, gPenWidth, gPenColor
	mov pen, eax
	invoke SelectObject, hdc, pen
	.IF !fillFlag
		invoke GetStockObject, NULL_BRUSH
	.ELSE
		invoke CreateSolidBrush, gBrushColor
	.ENDIF
	mov brush, eax
	invoke SelectObject, hdc, brush;
	invoke DeleteObject, eax
	invoke Rectangle, hdc, fixedPoint.x, fixedPoint.y,  x, y
	
	invoke DeleteObject, brush
	invoke DeleteObject, pen
	
	mov eax, x
	mov lastPoint.x, eax
	mov eax, y
	mov lastPoint.y, eax
	
	ret
_DrawRect ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; draw roundRectangle; fillFlag 0 -> null 1 -> fill
_DrawRoundRect PROC hWnd:HWND, hdc:HDC, x:DWORD, y:DWORD, fillFlag:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL brush
	LOCAL pen
	LOCAL w
	LOCAL h
	
	mov w, 50
	mov h, 50
	
	invoke BitBlt, hdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, lastHdc, 0, 0, SRCCOPY
	
	; paint
	invoke CreatePen, PS_SOLID, gPenWidth, gPenColor
	mov pen, eax
	invoke SelectObject, hdc, pen
	.IF !fillFlag
		invoke GetStockObject, NULL_BRUSH
	.ELSE
		invoke CreateSolidBrush, gBrushColor
	.ENDIF
	mov brush, eax
	invoke SelectObject, hdc, brush;
	invoke DeleteObject, eax
	invoke RoundRect, hdc, fixedPoint.x, fixedPoint.y,  x, y, w, h
	
	invoke DeleteObject, brush
	invoke DeleteObject, pen
	
	mov eax, x
	mov lastPoint.x, eax
	mov eax, y
	mov lastPoint.y, eax
	
	ret
_DrawRoundRect ENDP

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; draw ellipse; fillFlag 0 -> null 1 -> fill
_DrawEllipse PROC hWnd:HWND, hdc:HDC, x:DWORD, y:DWORD, fillFlag:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	LOCAL brush
	LOCAL pen
	
	invoke BitBlt, hdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, lastHdc, 0, 0, SRCCOPY
	
	; paint
	invoke CreatePen, PS_SOLID, gPenWidth, gPenColor
	mov pen, eax
	invoke SelectObject, hdc, pen
	.IF !fillFlag
		invoke GetStockObject, NULL_BRUSH
	.ELSE
		invoke CreateSolidBrush, gBrushColor
	.ENDIF
	mov brush, eax
	invoke SelectObject, hdc, brush;
	invoke DeleteObject, eax
	invoke Ellipse, hdc, fixedPoint.x, fixedPoint.y,  x, y
	
	invoke DeleteObject, brush
	invoke DeleteObject, pen
	
	mov eax, x
	mov lastPoint.x, eax
	mov eax, y
	mov lastPoint.y, eax
	
	ret
_DrawEllipse ENDP

_GDIDraw PROC hWnd:HWND
	LOCAL hdc:HDC
	LOCAL memDc:HDC		; for double buffering
	LOCAL memBmp:HBITMAP
	LOCAL oldBmp:HBITMAP
	LOCAL eraser
	
	.IF ReadyPaint	
		
		invoke GetDC, hWnd
		mov hdc,eax
		
		invoke  CreateCompatibleDC, hdc
		mov memDc, eax
				
		invoke CreateCompatibleBitmap, hdc, SCREENWIDTH, SCREENHEIGHT
		mov memBmp, eax	
				
		invoke SelectObject, memDc, memBmp
		mov oldBmp, eax

		invoke BitBlt, memDc, 0, 0, SCREENWIDTH, SCREENHEIGHT, hdc, 0, 0, SRCCOPY
		
		.IF PaintType==0
			invoke _Erase, memDc, hitpoint.x, hitpoint.y
		.ELSEIF PaintType==1
			invoke _Draw, memDc, hitpoint.x, hitpoint.y
		.ELSEIF PaintType==2
			invoke _DrawLine, hWnd, memDc, hitpoint.x, hitpoint.y
		.ELSEIF PaintType==3
			invoke _DrawRect, hWnd, memDc, hitpoint.x, hitpoint.y, 1
		.ELSEIF PaintType==4
			invoke _DrawRoundRect, hWnd, memDc, hitpoint.x, hitpoint.y, 1
		.ELSEIF PaintType==5
			invoke _DrawEllipse, hWnd, memDc, hitpoint.x, hitpoint.y, 1
		.ELSEIF PaintType==6
			invoke _DrawText, hWnd, _szText, _szTextLength, hitpoint.x, hitpoint.y
		.ENDIF
		
		invoke BitBlt, hdc, 0, 0, SCREENWIDTH, SCREENHEIGHT, memDc, 0, 0, SRCCOPY	
		mov ebx, eax
		; invoke InvalidateRect,hWnd,NULL,TRUE
		invoke UpdateWindow, hWnd
		
		;invoke SelectObject, hdc, oldBmp
		invoke DeleteObject, memBmp
		invoke DeleteDC, memDc
		
		invoke ReleaseDC, hWnd, hdc
	.ENDIF
	ret
_GDIDraw ENDP

_LeftButtonDown PROC hWnd:HWND, lParam:LPARAM
	mov eax,lParam
	and eax,0ffffh
	mov hitpoint.x,eax
	mov lastPoint.x, eax	; last point
	mov fixedPoint.x, eax
	mov eax,lParam
	shr eax,16
	mov hitpoint.y,eax
	mov lastPoint.y, eax	; last point
	mov fixedPoint.y, eax
	
	mov ReadyPaint,TRUE
	
	invoke _ReDraw, hWnd
	
	invoke _SetLastDc, hWnd
	
	invoke InvalidateRect,hWnd,NULL,TRUE
	ret
_LeftButtonDown ENDP

_LeftButtonUp PROC hWnd:HWND, lParam:LPARAM
	
	invoke _SetLastDc, hWnd
	mov ReadyPaint,FALSE	
	ret
_LeftButtonUp ENDP

_MouseMove PROC hWnd:HWND, lParam:LPARAM
	LOCAL pt:POINT
	
	mov pt.x, 10
	mov pt.y, 50
	
	.IF ReadyPaint
	
		mov eax,lParam
		and eax,0ffffh
		mov hitpoint.x,eax
		mov eax,lParam
		shr eax,16
		mov hitpoint.y,eax
		
		mov eax, 0
		add eax, pt.x
		cmp hitpoint.x, eax
		jbe LeaveWindow
		
		mov eax, SCREENWIDTH
		cmp hitpoint.x, eax
		jae LeaveWindow
		
		mov eax, 0
		add eax, pt.y
		cmp hitpoint.y, eax
		jbe LeaveWindow
		
		mov eax, SCREENHEIGHT
		cmp hitpoint.y, eax
		jae LeaveWindow
		
		invoke _GDIDraw, hWnd
		ret
		
		LeaveWindow:
			invoke _LeftButtonUp, hWnd, lParam
			
	.ENDIF
	ret
_MouseMove ENDP
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
ENDIF
end