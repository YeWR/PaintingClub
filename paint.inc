IFNDEF _PAINTINC_
.386
.model flat,stdcall
option casemap:none
include          windows.inc
include          user32.inc
includelib      user32.lib
include          kernel32.inc
includelib      kernel32.lib
include          comctl32.inc
includelib      comctl32.lib
include         Comdlg32.inc
includelib      Comdlg32.lib
include         gdi32.inc
includelib     gdi32.lib

	externdef 	ReadyPaint: DWORD,
						PaintOver: DWORD,	
						PaintType: DWORD,	
						gFillType: DWORD,
						lastPoint: POINT, 
						fixedPoint: POINT,
						lastPointGraphics: POINT,
						gBrushColor: DWORD,
						gPenWidth: DWORD,
						gPenColor: DWORD,
						gEraserWidth: DWORD,
						gEraserColor: DWORD,	
						gPaintPoint: POINT,
						SCREENWIDTH: DWORD,
						SCREENHEIGHT: DWORD,
						hitpoint: POINT,	
						lastHdc: HDC,			
						lastBmp: HBITMAP		


	.code
		_SetColor PROTO r:DWORD, g:DWORD, b:DWORD
		_SetLastDc PROTO hWnd:HWND
		_SetScreenWH PROTO hWnd:HWND
		_Initialization PROTO hWnd:HWND
		_ReDraw PROTO hWnd:HWND
		_Erase PROTO hdc:HDC, x:DWORD, y:DWORD
		_Draw PROTO hdc:HDC, x:DWORD, y:DWORD
		_DrawLine PROTO hWnd:HWND, hdc:HDC, x:DWORD, y:DWORD
		_DrawRect PROTO hWnd:HWND, hdc:HDC, x:DWORD, y:DWORD, fillFlag:DWORD
		_DrawRoundRect PROTO hWnd:HWND, hdc:HDC, x:DWORD, y:DWORD, fillFlag:DWORD
		_DrawEllipse PROTO hWnd:HWND, hdc:HDC, x:DWORD, y:DWORD, fillFlag:DWORD
		_GDIDraw PROTO hWnd:HWND
		_LeftButtonDown PROTO hWnd:HWND, lParam:LPARAM
		_LeftButtonUp PROTO hWnd:HWND, lParam:LPARAM
		_MouseMove PROTO hWnd:HWND, lParam:LPARAM
		_DrawText PROTO hdc:HDC, text:LPCTSTR, textLen:DWORD, x:DWORD, y:DWORD

	ENDIF