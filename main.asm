  .386
.model flat, stdcall
option casemap :none

include			paint.inc

LoadFile PROTO path:DWORD, DC:DWORD
SaveImage PROTO path:DWORD, SaveBitmap:DWORD
_OpenFile PROTO hParent:DWORD, DC:DWORD
SaveFile PROTO hParent:DWORD, SaveBitmap:DWORD
ResizeImage PROTO DC:DWORD, Mode:DWORD, Ratio:WORD
FlipImage PROTO DC:DWORD, Mode:DWORD

.const
;============================================
; 定义各种资源常量
IDI_ICON1            equ  101
IDR_MENU1         equ 102
IDM_NEW            equ  40000
IDM_OPEN          equ   40001
IDM_SAVE           equ  40002
IDM_PEN             equ  40003
IDM_ERASE          equ  40004
IDM_WIDTH         equ  40005
IDM_COLOR         equ  40006
IDM_PATTERN      equ  40007
IDI_ICON_ERASE   equ  40008
IDB_BUTTON        equ  40009
IDM_HELP            equ  40010
IDM_EXIT             equ  40011
IDM_TEXT             equ  40012
IDM_BIG               equ 40013
IDM_SMALL          equ  40014
IDM_CW			     equ 40015
IDM_AW		         equ	40016
IDM_H				     equ	40017
IDM_V				     equ	40018
IDM_S                   equ 40019

ID_TOOLBAR        equ  1
ID_EDIT                equ  2

IDD_COLORDLG                 equ     103
IDC_BACKCOLORBOX         equ     1000
IDC_FORECOLORBOX          equ    1001

IDD_PATTERNDLG  equ  104
IDI_LINE				 equ	2001
IDI_CIRCLE			 equ	2002
IDI_CIRTANG		 equ	2003
IDI_RECT				 equ	2004
IDC_LINEBOX                      equ     2005
IDC_CIRCLEBOX                  equ     2006
IDC_CIRTANGBOX              equ     2007
IDC_RECTBOX                     equ     2008
IDC_PATTERNEDIT              equ      2009
IDC_FULLBOX					 equ      2010
IDC_EMPTYBOX                 equ     2011
IDC_TYPEEDIT                   equ       2012

IDD_WIDTHDLG     equ      105
IDI_ONE				 equ		3001
IDI_TWO			     equ		3002
IDI_FOUR				 equ		3003
IDI_EIGHT				 equ		3004
IDC_ONEBOX        equ		3005
IDC_TWOBOX       equ      3006
IDC_FOURBOX      equ     3007
IDC_EIGHTBOX     equ     3008
IDC_WIDTHEDIT   equ     3009

MAX_FILE equ 260
;============================================
_point               equ 1
_erase               equ 0
_text                 equ 6
_circle               equ 5
_line                 equ 2
_cirTang            equ 4
_rect                 equ 3
_empty             equ 0
_full                  equ 1

.data
ofn   OPENFILENAME <>
ofn_lpFilter db "Bmp Files",0,"*.bmp*",0,0
ofn_fileName db MAX_FILE dup(0)
ofn_openDialogTitle db "Choose the file to open",0
ofn_saveDialogTitle db "Choose the place to save",0
BytePerPixel dd 3

.data?
hInstance         dd       ?	;程序句柄
hWinMain        dd       ?	;主窗口句柄
hMenu             dd       ?	;菜单句柄
hWinToolbar    dd       ?	;工具栏句柄
hWinEdit          dd       ?	
hbmp               dd       ?	;工具栏位图句柄
CustomColors dd 16 dup(?)

hBmp dd ?
hDc dd ?
tempcDc dd ?
FileHeader BITMAPFILEHEADER <>
InfoHeader BITMAPINFOHEADER <>
;============================================
; 定义绘图关键变量
BackgroundColor dd 0FFFFFFh
ForegroundColor dd 0FFFFFFh	
LineWidth            dd 1
DrawType            dd _point ;详见.const定义 
FillType                dd _empty
;============================================

.const
;============================================
; 定义消息相应
full                db '实心',0
empty           db '空心',0
line               db '直线',0
circle            db '圆形',0
cirTang         db '圆角矩形',0
rect              db '矩形',0
one              db '1px',0
two              db '2px',0
four             db '4px',0
eight            db '8px',0
szFileName  db MAX_PATH dup(?)
szClass         db "EDIT",0
szClassName     db       "PAINT",0
szCaptionMain   db       '画图',0
;============================================

;============================================
; 定义工具栏按钮
stToolbar         equ     this byte
TBBUTTON        <0,IDM_PEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <1,IDM_ERASE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <2,IDM_PATTERN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <3,IDM_TEXT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,-1>
TBBUTTON        <4,IDM_WIDTH,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <5,IDM_COLOR,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0,-1>
TBBUTTON        <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0,-1>
NUM_BUTTONS          equ  8
;============================================

.code
;============================================
; 调节子窗口位置
_Resize         proc
;============================================
       LOCAL    @stRect:RECT,@stRect1:RECT
       invoke   SendMessage,hWinToolbar,TB_AUTOSIZE,0,0
       invoke   GetClientRect,hWinMain,addr @stRect
       invoke   GetWindowRect,hWinToolbar,addr @stRect1
       mov      eax,@stRect1.bottom
       sub      eax,@stRect1.top
       mov      ecx,@stRect.bottom
       sub      ecx,eax
       invoke   MoveWindow,hWinEdit,0,eax,@stRect.right,ecx,TRUE       
       ret
_Resize endp 

;============================================
; 处理对话框事件，包括颜色选择、线宽选择以及图案选择
OptionProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
;============================================
	LOCAL clr:CHOOSECOLOR
	.if uMsg==WM_INITDIALOG
	.elseif uMsg==WM_COMMAND
		mov eax,wParam
		shr eax,16
		.if ax==BN_CLICKED
			mov eax,wParam
			.endif
			.if ax==IDC_BACKCOLORBOX
				invoke RtlZeroMemory,addr clr,sizeof clr
				mov clr.lStructSize,sizeof clr
				push hWnd
				pop clr.hwndOwner
				push hInstance
				pop clr.hInstance
				push BackgroundColor
				pop clr.rgbResult
				mov clr.lpCustColors,offset CustomColors
				mov clr.Flags,CC_ANYCOLOR or CC_RGBINIT
				invoke ChooseColor,addr clr
				.if eax!=0
					push clr.rgbResult
					pop BackgroundColor
					invoke GetDlgItem,hWnd,IDC_BACKCOLORBOX
					invoke InvalidateRect,eax,0,TRUE
				.endif
			.elseif ax==IDC_FORECOLORBOX
				invoke RtlZeroMemory,addr clr,sizeof clr
				mov clr.lStructSize,sizeof clr
				push hWnd
				pop clr.hwndOwner
				invoke GetModuleHandle,NULL
				mov hInstance,eax
				push hInstance
				pop clr.hInstance
				push ForegroundColor
				pop clr.rgbResult
				mov clr.lpCustColors,offset CustomColors
				mov clr.Flags,CC_ANYCOLOR or CC_RGBINIT
				invoke ChooseColor,addr clr
				.if eax!=0
					push clr.rgbResult
					pop ForegroundColor
					invoke GetDlgItem,hWnd,IDC_FORECOLORBOX
					invoke InvalidateRect,eax,0,TRUE
				.endif
			.elseif ax==IDOK
				invoke EndDialog,hWnd,0
			.elseif ax ==IDC_ONEBOX
				invoke SetDlgItemText,hWnd,IDC_WIDTHEDIT,ADDR one
				mov LineWidth, 1
			.elseif ax ==IDC_TWOBOX
				invoke SetDlgItemText,hWnd,IDC_WIDTHEDIT,ADDR two
				mov LineWidth, 2
			.elseif ax ==IDC_FOURBOX
				invoke SetDlgItemText,hWnd,IDC_WIDTHEDIT,ADDR four
				mov LineWidth, 4
			.elseif ax ==IDC_EIGHTBOX
				invoke SetDlgItemText,hWnd,IDC_WIDTHEDIT,ADDR eight
				mov LineWidth, 8
			.elseif ax ==IDC_LINEBOX
				invoke SetDlgItemText,hWnd,IDC_PATTERNEDIT,ADDR line
				mov DrawType, _line
			.elseif ax ==IDC_CIRCLEBOX
				invoke SetDlgItemText,hWnd,IDC_PATTERNEDIT,ADDR circle
				mov DrawType, _circle
			.elseif ax ==IDC_CIRTANGBOX
				invoke SetDlgItemText,hWnd,IDC_PATTERNEDIT,ADDR cirTang
				mov DrawType, _cirTang
			.elseif ax ==IDC_RECTBOX
				invoke SetDlgItemText,hWnd,IDC_PATTERNEDIT,ADDR rect
				mov DrawType, _rect
			.elseif ax == IDC_FULLBOX
				invoke SetDlgItemText,hWnd,IDC_TYPEEDIT,ADDR full
				mov FillType, _full
			.elseif ax == IDC_EMPTYBOX
				invoke SetDlgItemText,hWnd,IDC_TYPEEDIT,ADDR empty
				mov FillType, _empty
			.endif
	.elseif uMsg==WM_CTLCOLORSTATIC
		invoke GetDlgItem,hWnd,IDC_BACKCOLORBOX
		.if eax==lParam
			invoke CreateSolidBrush,BackgroundColor			
			ret
		.else
			invoke GetDlgItem,hWnd,IDC_FORECOLORBOX
			.if eax==lParam
				invoke CreateSolidBrush,ForegroundColor
				ret
			.endif
		.endif
		mov eax,FALSE
		ret
	.elseif uMsg==WM_CLOSE
		invoke EndDialog,hWnd,0
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret
OptionProc endp

_InterfacePainting proc
	mov edx, DrawType
	mov PaintType, edx

	mov edx, ForegroundColor
	mov gBrushColor, edx
	mov gPenColor, edx

	mov edx, LineWidth
	mov gPenWidth, edx
	mov gEraserWidth, edx

	mov edx, FillType
	mov gFillType, edx

	ret
_InterfacePainting endp

;============================

LoadFile proc path:DWORD, DC:DWORD

    local @bitmap:BITMAP
	local @tempDc:dword
    invoke LoadImage, hInstance, path, IMAGE_BITMAP,0,0,LR_LOADFROMFILE	
    mov hBmp,eax
	invoke GetObject, hBmp, sizeof BITMAP, addr @bitmap
	invoke CreateCompatibleDC, hDc
    mov @tempDc,eax
	invoke SelectObject, @tempDc, hBmp
	invoke BitBlt, DC, 0, 0, SCREENWIDTH, SCREENHEIGHT, @tempDc, 0, 0, WHITENESS 
	invoke BitBlt,DC,0,50,@bitmap.bmWidth,@bitmap.bmHeight,@tempDc,0,0,SRCCOPY
	invoke DeleteDC, @tempDc

	invoke _SetLastDc, hWinMain
	
    ret
LoadFile endp

SaveImage proc path:DWORD, SaveBitmap:DWORD
	local @bitmap:BITMAP
	local @imgData:dword
	local @FileHandler:dword, @byteWritten:dword
	invoke GetObject, SaveBitmap, sizeof BITMAP, addr @bitmap

    ;BITMAPINFOHEADER
    mov eax, sizeof BITMAPINFOHEADER 
    mov InfoHeader.biSize,eax
	mov eax, @bitmap.bmWidth
    mov InfoHeader.biWidth,eax
	mov eax, @bitmap.bmHeight
    mov InfoHeader.biHeight,eax
    mov InfoHeader.biPlanes,1
    mov InfoHeader.biBitCount,24
	
    ;BITMAPFILEHEADER
    mov FileHeader.bfType, 4d42h 
    mov eax,sizeof BITMAPFILEHEADER
    add eax,sizeof BITMAPINFOHEADER
    mov FileHeader.bfOffBits, eax
	;Get BMP Size
	invoke GetDIBits, hDc, SaveBitmap, 0, InfoHeader.biHeight, NULL ,addr InfoHeader, DIB_RGB_COLORS
	;Alloc Memory for BMP Bits
	invoke VirtualAlloc, NULL, InfoHeader.biSizeImage, MEM_COMMIT, PAGE_READWRITE
	mov @imgData, eax
	;Get BMP Bits
	invoke GetDIBits, hDc, SaveBitmap, 0, InfoHeader.biHeight, @imgData ,addr InfoHeader, DIB_RGB_COLORS
	;CreateFile
    invoke CreateFile, path, GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,NULL
    mov @FileHandler,eax
    .if @FileHandler == INVALID_HANDLE_VALUE
        ret
    .endif
	;WriteFile
    invoke WriteFile, @FileHandler, addr FileHeader, sizeof BITMAPFILEHEADER,addr @byteWritten,NULL
    invoke WriteFile, @FileHandler, addr InfoHeader, sizeof BITMAPINFOHEADER,addr @byteWritten,NULL
    invoke WriteFile,@FileHandler, @imgData, InfoHeader.biSizeImage, addr @byteWritten, NULL
	;invoke DeleteDC, @tempDc
	;invoke DeleteObject, @tempBmp
	invoke VirtualFree, @imgData, InfoHeader.biSizeImage, MEM_COMMIT
	invoke CloseHandle, @FileHandler
    ret

SaveImage endp

_OpenFile proc hParent:DWORD, DC:DWORD
    mov ofn.lStructSize,		sizeof ofn 
    mov ofn.lStructSize,        sizeof ofn
    mov eax, hParent
    mov ofn.hWndOwner,          eax
    mov eax, hInstance
    mov ofn.hInstance,          eax
    mov ofn.lpstrFilter,        offset ofn_lpFilter
    mov ofn.lpstrFile,          offset ofn_fileName
    mov ofn.nMaxFile,           MAX_FILE
    mov ofn.lpstrTitle,         offset ofn_openDialogTitle
    mov ofn.Flags, OFN_EXPLORER or OFN_HIDEREADONLY or OFN_ENABLEHOOK or OFN_FILEMUSTEXIST or OFN_LONGNAMES
    invoke GetOpenFileName, addr ofn
    .if eax == TRUE
        invoke LoadFile, addr ofn_fileName, DC
    .endif
    ret
_OpenFile endp

SaveFile proc hParent:DWORD, SaveBitmap:DWORD
	mov ofn.lStructSize,        SIZEOF ofn 
	mov ofn.lStructSize,        sizeof ofn
	mov eax, hParent
	mov ofn.hWndOwner,          eax
	mov eax, hInstance
	mov ofn.hInstance,          eax
	mov ofn.lpstrFilter,        offset ofn_lpFilter
	mov ofn.lpstrFile,          offset ofn_fileName
	mov ofn.nMaxFile,           MAX_FILE
	mov ofn.lpstrTitle,         offset ofn_saveDialogTitle
	mov ofn.Flags, OFN_EXPLORER or OFN_HIDEREADONLY or OFN_LONGNAMES
	invoke GetSaveFileName, ADDR ofn
	.if eax == TRUE
		invoke SaveImage, addr ofn_fileName, SaveBitmap
	.endif
    ret

SaveFile endp

ResizeImage proc DC:DWORD, Mode:DWORD, Ratio:WORD
	local @bitmap:BITMAP
	local @tempDc:dword
	local @printWidth:dword, @printHeight:dword
	invoke GetObject, hBmp, sizeof BITMAP, addr @bitmap
	push eax
	push edx
	mov eax,@bitmap.bmWidth
	;Mode = 0: Smaller, Mode = 1: Larger
	.if Mode == 0
		div Ratio
	.else
		mul Ratio
	.endif 
	mov @printWidth, eax
	xor eax,eax
	xor edx,edx
	mov eax,@bitmap.bmHeight
	;Mode = 0: Smaller, Mode = 1: Larger
	.if Mode == 0
		div Ratio
	.else
		mul Ratio
	.endif 
	mov @printHeight, eax
	pop eax
	pop edx
	invoke CreateCompatibleDC, hDc
    mov @tempDc,eax
	invoke SelectObject, @tempDc, hBmp

	invoke BitBlt, DC, 0, 0, SCREENWIDTH, SCREENHEIGHT, @tempDc, 0, 0, WHITENESS 
	invoke StretchBlt,DC,0,50,@printWidth,@printHeight,@tempDc,0,0,@bitmap.bmWidth,@bitmap.bmHeight,SRCCOPY
	
	invoke DeleteDC, @tempDc

	invoke _SetLastDc, hWinMain

    ret

ResizeImage endp

FlipImage proc DC:DWORD, Mode:DWORD

	local @bitmap:BITMAP
	local @tempDc:dword
	local @printWidth:dword, @printHeight:dword
	local @WidthNeg:dword, @HeightNeg:dword
	invoke GetObject, hBmp, sizeof BITMAP, addr @bitmap
	mov eax, @bitmap.bmWidth
	neg eax
	mov @WidthNeg,eax
	mov eax, @bitmap.bmHeight
	neg eax
	mov @HeightNeg,eax
	invoke CreateCompatibleDC, hDc
    mov @tempDc,eax
	invoke SelectObject, @tempDc, hBmp
	.if Mode == 1
		invoke BitBlt, DC, 0, 0, SCREENWIDTH, SCREENHEIGHT, @tempDc, 0, 0, WHITENESS 
		invoke StretchBlt,DC,@bitmap.bmWidth,50,@WidthNeg,@bitmap.bmHeight,@tempDc,0,0,@bitmap.bmWidth,@bitmap.bmHeight,SRCCOPY
	.elseif Mode == 2
		mov eax, @bitmap.bmHeight
		add eax,50
		invoke BitBlt, DC, 0, 0, SCREENWIDTH, SCREENHEIGHT, @tempDc, 0, 0, WHITENESS 
		invoke StretchBlt,DC,0,eax,@bitmap.bmWidth,@HeightNeg,@tempDc,0,0,@bitmap.bmWidth,@bitmap.bmHeight,SRCCOPY
	.elseif Mode == 3
		invoke BitBlt, DC, 0, 0, SCREENWIDTH, SCREENHEIGHT, @tempDc, 0, 0, WHITENESS 
		invoke StretchBlt,DC,0,50,@bitmap.bmWidth,@bitmap.bmHeight,@tempDc,0,0,@bitmap.bmWidth,@bitmap.bmHeight,SRCCOPY
	.endif
	invoke DeleteDC, @tempDc

	invoke _SetLastDc, hWinMain

    ret

FlipImage endp
;============================

;============================================
; 处理主窗口事件循环，包括绘制以及菜单栏的点击
_ProcWinMain    proc     uses ebx edi esi hWnd ,uMsg,wParam,lParam
;============================================
       LOCAL    @szBuffer[128]:byte
       mov      eax,uMsg
       .if      uMsg  ==  WM_CLOSE
                invoke   PostMessage,hWnd,WM_COMMAND,IDM_EXIT,0
       .elseif  uMsg  ==  WM_CREATE
				mov      eax,hWnd
				mov      hWinMain,eax
				invoke   CreateWindowEx,WS_EX_CLIENTEDGE,addr szClass,NULL,WS_DISABLED or WS_CHILD or WS_VISIBLE or ES_MULTILINE,0,0,0,0,hWnd,ID_EDIT,hInstance,NULL
				mov      hWinEdit,eax
				invoke GetModuleHandle,NULL
				mov hInstance,eax
				invoke  LoadBitmap, hInstance, IDB_BUTTON
				.if eax
					mov hbmp,eax
				.endif
				invoke   CreateToolbarEx,hWnd,WS_VISIBLE or WS_CHILD or TBSTYLE_FLAT or TBSTYLE_TOOLTIPS or\
						 CCS_ADJUSTABLE,ID_TOOLBAR,6,0,hbmp,offset stToolbar,\
						 NUM_BUTTONS,26,25,150,25,sizeof TBBUTTON
				mov      hWinToolbar,eax
				call     _Resize
       .elseif  uMsg  ==  WM_COMMAND
				invoke GetModuleHandle,NULL
				mov hInstance,eax
                mov      eax,wParam
                .if      ax  ==  IDM_EXIT
					 invoke  DestroyWindow,hWinMain
					 invoke  PostQuitMessage,NULL
				.elseif      ax  ==  IDM_COLOR
					invoke DialogBoxParam,hInstance,IDD_COLORDLG,hWnd,addr OptionProc,0
				.elseif      ax  ==  IDM_PATTERN
					invoke DialogBoxParam,hInstance,IDD_PATTERNDLG,hWnd,addr OptionProc,0
				.elseif    ax == IDM_WIDTH
					invoke DialogBoxParam,hInstance,IDD_WIDTHDLG,hWnd,addr OptionProc,0
				.elseif    ax == IDM_PEN
					mov DrawType, _point
				.elseif    ax == IDM_ERASE
					mov DrawType, _erase
				.elseif    ax == IDM_TEXT
					mov DrawType, _text
				.elseif    ax == IDM_BIG
					invoke ResizeImage,hDc, 1, 2
				.elseif    ax == IDM_SMALL
					invoke ResizeImage,hDc, 0, 2
				.elseif    ax == IDM_H
					invoke FlipImage,hDc, 1
				.elseif    ax == IDM_V
					invoke FlipImage,hDc, 2
				.elseif ax == IDM_S
					invoke FlipImage,hDc, 3
				.elseif    ax == IDM_NEW
					; TO DO
				.elseif    ax == IDM_SAVE
					invoke SaveFile, hWinMain, lastBmp
				.elseif    ax == IDM_OPEN
					invoke GetDC, hWinMain
					mov hDc, eax
					invoke _OpenFile, hWinMain, hDc
				.elseif    ax == IDM_HELP
					; TO DO
				.endif
		.elseif  uMsg  ==  WM_SIZE
				call     _Resize
				invoke _SetScreenWH, hWnd
				invoke _ReDraw, hWnd
				invoke UpdateWindow, hWnd
        .elseif  uMsg  ==  WM_NOTIFY
					mov      ebx,lParam
			.if      [ebx + NMHDR.code] == TTN_NEEDTEXT
					 assume   ebx:ptr TOOLTIPTEXT
					 mov      eax,[ebx].hdr.idFrom
					 mov      [ebx].lpszText,eax
					 push     hInstance
					 pop      [ebx].hInst
					 assume  ebx:nothing
			.elseif  ([ebx + NMHDR.code] == TBN_QUERYINSERT) || ([ebx + NMHDR.code] == TBN_QUERYDELETE)
					 mov      eax,TRUE
					 ret
			.elseif  [ebx + NMHDR.code] ==  TBN_GETBUTTONINFO
					 assume   ebx:ptr TBNOTIFY
					 mov      eax,[ebx].iItem
					 .if      eax < NUM_BUTTONS
							mov     ecx,sizeof TBBUTTON
							mul     ecx
							add     eax,offset stToolbar
							invoke  RtlMoveMemory,addr [ebx].tbButton,eax,sizeof TBBUTTON
							invoke  LoadString,hInstance,[ebx].tbButton.idCommand,addr @szBuffer,sizeof @szBuffer
							lea     eax,@szBuffer
							mov     [ebx].pszText,eax
							invoke  lstrlen,addr @szBuffer
							mov     [ebx].cchText,eax
							assume  ebx:nothing
							mov     eax,TRUE
							ret
					 .endif
			.endif
		.ELSEIF uMsg==WM_DESTROY
			invoke PostQuitMessage,NULL
		.ELSEIF uMsg==WM_LBUTTONDOWN
			invoke _LeftButtonDown, hWnd, lParam
		.ELSEIF uMsg==WM_MOUSEMOVE
			invoke _InterfacePainting
			invoke _MouseMove, hWnd, lParam
		.ELSEIF uMsg==WM_LBUTTONUP || uMsg==WM_MOUSELEAVE
			invoke _LeftButtonUp, hWnd, lParam
		.elseif uMsg==WM_PAINT
			invoke UpdateWindow, hWnd
		.ELSEIF uMsg==WM_ERASEBKGND
			call     _Resize
			invoke _SetScreenWH, hWnd
			invoke UpdateWindow, hWnd
			invoke _ReDraw, hWnd
			
		.else
			invoke    DefWindowProc,hWnd,uMsg,wParam,lParam
			ret
        .endif
	    xor     eax,eax
	    ret
_ProcWinMain    endp

;============================================
; 创建窗口
_WinMain proc
;============================================
	local @stWndClass:WNDCLASSEX
	local @stMsg:MSG
	invoke InitCommonControls
	invoke GetModuleHandle,NULL
	mov hInstance,eax
	invoke LoadMenu,hInstance,IDR_MENU1
	mov hMenu,eax
	invoke RtlZeroMemory,addr @stWndClass,sizeof @stWndClass
	invoke LoadIcon,hInstance,IDI_ICON1
	mov @stWndClass.hIcon,eax
	mov @stWndClass.hIconSm,eax
	invoke LoadCursor,0,IDC_ARROW
	mov @stWndClass.hCursor,eax
	push hInstance
	pop @stWndClass.hInstance
	mov @stWndClass.cbSize,sizeof WNDCLASSEX
	mov @stWndClass.style,CS_HREDRAW or CS_VREDRAW
	mov @stWndClass.lpfnWndProc,offset _ProcWinMain
	mov @stWndClass.hbrBackground,COLOR_WINDOW+1
	mov @stWndClass.lpszClassName,offset szClassName
	invoke RegisterClassEx,addr @stWndClass
	invoke CreateWindowEx,NULL,\
	offset szClassName,offset szCaptionMain,\
	WS_OVERLAPPEDWINDOW or WS_POPUPWINDOW,\
	CW_USEDEFAULT,CW_USEDEFAULT,700,500,\
	NULL,hMenu,hInstance,NULL
	mov hWinMain,eax
	invoke ShowWindow,hWinMain,SW_SHOWNORMAL
	invoke UpdateWindow,hWinMain
	;Initialization
	invoke _Initialization, hWinMain

	.while TRUE
	invoke GetMessage,addr @stMsg,NULL,0,0
	.break .if eax == 0
	invoke TranslateMessage,addr @stMsg
	invoke DispatchMessage,addr @stMsg
.endw
ret
_WinMain endp

main proc
call _WinMain
invoke ExitProcess,NULL
main endp
end main
 

