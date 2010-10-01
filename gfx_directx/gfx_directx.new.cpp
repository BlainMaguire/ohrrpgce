#include "gfx_directx_TESTAPPconst.h"

#include "gfx_directx.new.h"
#include "gfx_msg.h"
#include "gfx_directx_cls_window.h"
#include "gfx_directx_cls.h"
#include "gfx_directx_cls_keyboard.h"
#include "gfx_directx_cls_mouse.h"
#include "gfx_directx_version.h"
using namespace gfx;

#include "resource.h"

//use common controls available on different windows OS'
#if defined _M_IX86
#pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='x86' publicKeyToken='6595b64144ccf1df' language='*'\"")
#elif defined _M_IA64
#pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='ia64' publicKeyToken='6595b64144ccf1df' language='*'\"")
#elif defined _M_X64
#pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='amd64' publicKeyToken='6595b64144ccf1df' language='*'\"")
#else
#pragma comment(linker,"/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")
#endif

Window g_Window;
HWND g_hWndDlg;
DirectX g_DirectX;
Keyboard g_Keyboard;
Mouse g_Mouse;

struct gfx_BackendState
{
	Tstring szWindowTitle;
	Tstring szWindowIcon;
	void (__cdecl *PostTerminateSignal)(void);
	void (__cdecl *OnCriticalError)(const char* szError);
	void (__cdecl *SendDebugString)(const char* szMessage);
	int (__cdecl *DefGfxMessageProc)(unsigned int msg, unsigned int dwParam, void* pvParam);
	bool bClosing; //flagged when shutting down
	bool bOhrMouseRequest; //true whenever the ohr needs mouse input
} g_State;

LRESULT CALLBACK OHRWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);
BOOL CALLBACK OHROptionsDlgModeless(HWND hWndDlg, UINT msg, WPARAM wParam, LPARAM lParam);
SIZE CalculateNativeResolutionMultiple(UINT width, UINT height, UINT targetWidth = 320, UINT targetHeight = 200);
bool IsNativeResolutionMultiple(UINT width, UINT height, UINT targetWidth = 320, UINT targetHeight = 200);

int gfx_Initialize(const GFX_INIT *pCreationData)
{
	if(pCreationData == NULL)
		return FALSE;

	TCHAR buffer[256] = TEXT("");
	g_State.szWindowIcon = StringToString(buffer, 256, pCreationData->szWindowIcon);
	g_State.PostTerminateSignal = pCreationData->PostTerminateSignal;
	g_State.OnCriticalError = pCreationData->OnCriticalError;
	g_State.SendDebugString = pCreationData->SendDebugString;
	g_State.DefGfxMessageProc = pCreationData->DefGfxMessageProc;

	if(g_State.PostTerminateSignal == NULL || g_State.OnCriticalError == NULL || g_State.SendDebugString == NULL || g_State.DefGfxMessageProc == NULL)
		return FALSE;

	g_State.SendDebugString("gfx_directx: Initializing...");

	if(S_OK != g_Window.Initialize(::GetModuleHandle(MODULENAME), 
								   (pCreationData->szWindowIcon ? g_State.szWindowIcon.c_str() : NULL), 
								   (WNDPROC)OHRWndProc))
	{
		g_State.SendDebugString("gfx_directx: Failed at window initialization! Fallback...");
		return FALSE;
	}

	g_State.SendDebugString("gfx_directx: Window Intialized!");

	if(DX_OK != g_DirectX.Initialize(&g_Window, MODULENAME))
	{
		g_Window.Shutdown();
		gfx_PumpMessages();
		g_State.SendDebugString("gfx_directx: Failed at d3d initialization! Fallback...");
		return FALSE;
	}

	g_State.SendDebugString("gfx_directx: D3D Initialized!");

	gfx_SetWindowTitle(pCreationData->szInitWindowTitle);

	g_Window.SetClientSize(640, 400);
	g_Window.CenterWindow();
	g_Window.ShowWindow();

	g_State.SendDebugString("gfx_directx: Initialization success!");
	return TRUE;
}

void gfx_Close()
{
	g_State.SendDebugString("gfx_directx: Closing backend...");
	g_DirectX.Shutdown();
	g_Window.Shutdown();
	gfx_PumpMessages();
	g_State.SendDebugString("gfx_directx: Close complete!");
}

int gfx_SendMessage(unsigned int msg, unsigned int dwParam, void *pvParam)
{
	switch(msg)
	{
	case OM_GFX_SETWIDTH:
		g_Window.SetClientSize(dwParam, g_Window.GetClientSize().cy);
		break;
	case OM_GFX_SETHEIGHT:
		g_Window.SetClientSize(g_Window.GetClientSize().cx, dwParam);
		break;
	case OM_GFX_SETCLIENTAREA:
		g_Window.SetClientSize(dwParam, (int)pvParam);
		break;
	case OM_GFX_SETLEFT:
		g_Window.SetWindowPosition(dwParam, g_Window.GetWindowSize().top);
		break;
	case OM_GFX_SETTOP:
		g_Window.SetWindowPosition(g_Window.GetWindowSize().left, dwParam);
		break;
	case OM_GFX_SETPOSITION:
		g_Window.SetWindowPosition(dwParam, (int)pvParam);
		break;
	case OM_GFX_SETARP:
		g_DirectX.SetAspectRatioPreservation(dwParam != FALSE);
		break;
	case OM_GFX_SETWINDOWED:
		g_DirectX.SetView(dwParam != FALSE);
		break;
	case OM_GFX_SETSMOOTH:
		g_DirectX.SetSmooth(dwParam != FALSE);
		break;
	case OM_GFX_SETVSYNC:
		g_DirectX.SetVSync(dwParam != FALSE);
		break;
	case OM_GFX_SETSSFORMAT:
		switch(dwParam)
		{
		case 0:
			g_DirectX.SetImageFileFormat(D3DXIFF_FORCE_DWORD);
			break;
		case 1:
			g_DirectX.SetImageFileFormat(D3DXIFF_JPG);
			break;
		case 2:
			g_DirectX.SetImageFileFormat(D3DXIFF_BMP);
			break;
		case 3:
			g_DirectX.SetImageFileFormat(D3DXIFF_PNG);
			break;
		case 4:
			g_DirectX.SetImageFileFormat(D3DXIFF_DDS);
			break;
		default:
			g_DirectX.SetImageFileFormat(D3DXIFF_FORCE_DWORD);
			break;
		}
		break;

	case OM_GFX_GETWIDTH:
		return g_Window.GetClientSize().cx;
	case OM_GFX_GETHEIGHT:
		return g_Window.GetClientSize().cy;
	case OM_GFX_GETCLIENTAREA:
		return (g_Window.GetClientSize().cx << 16) | g_Window.GetClientSize().cy;
	case OM_GFX_GETLEFT:
		return g_Window.GetWindowSize().left;
	case OM_GFX_GETTOP:
		return g_Window.GetWindowSize().top;
	case OM_GFX_GETPOSITION:
		return (g_Window.GetWindowSize().left << 16) | g_Window.GetWindowSize().top;
	case OM_GFX_GETARP:
		return g_DirectX.IsAspectRatioPreserved() ? TRUE : FALSE;
	case OM_GFX_GETWINDOWED:
		return g_DirectX.IsViewFullscreen() ? FALSE : TRUE;
	case OM_GFX_GETSMOOTH:
		return g_DirectX.IsSmooth() ? TRUE : FALSE;
	case OM_GFX_GETVSYNC:
		return g_DirectX.IsVsyncEnabled() ? TRUE : FALSE;
	case OM_GFX_GETSSFORMAT:
		switch(g_DirectX.GetImageFileFormat())
		{
		case D3DXIFF_JPG:
			return 1;
		case D3DXIFF_BMP:
			return 2;
		case D3DXIFF_PNG:
			return 3;
		case D3DXIFF_DDS:
			return 4;
		default:
			return 0;
		}
	default:
		return g_State.DefGfxMessageProc(msg, dwParam, pvParam);
	}
	return TRUE;
}

int gfx_GetVersion()
{
	return DX_VERSION_MAJOR;
}

void gfx_PumpMessages()
{
	static MSG msg;
	while(::PeekMessage(&msg, 0, 0, 0, PM_REMOVE))
	{
		if(!::IsWindow(g_hWndDlg) || !::IsDialogMessage(g_hWndDlg, &msg))
		{
			::TranslateMessage(&msg);
			::DispatchMessage(&msg);
		}
	}
}

void gfx_Present(unsigned char *pSurface, int nWidth, int nHeight, unsigned int *pPalette)
{
	if(pPalette)
		g_DirectX.SetPalette(&Palette<UINT>(pPalette, 256));
	g_DirectX.ShowPage(pSurface, nWidth, nHeight);
}

int gfx_ScreenShot(const char *szFileName)
{
	if(!g_DirectX.IsScreenShotsActive())
		return FALSE;
	if(szFileName == NULL)
		return FALSE;
	TCHAR buffer[256] = TEXT("");
	StringToString(buffer, 256, szFileName);
	switch(g_DirectX.GetImageFileFormat())
	{
	case D3DXIFF_JPG:
		::_tcscat_s<256>(buffer, TEXT(".jpg"));
		break;
	case D3DXIFF_BMP:
		::_tcscat_s<256>(buffer, TEXT(".bmp"));
		break;
	case D3DXIFF_PNG:
		::_tcscat_s<256>(buffer, TEXT(".png"));
		break;
	case D3DXIFF_DDS:
		::_tcscat_s<256>(buffer, TEXT(".dds"));
		break;
	default:
		return FALSE;
	}
	if(DX_OK != g_DirectX.ScreenShot(buffer))
		return FALSE;
	return TRUE;
}

void gfx_SetWindowTitle(const char *szTitle)
{
	TCHAR buffer[256] = TEXT("");
	if(szTitle == NULL)
		g_State.szWindowTitle = TEXT("");
	else
	{
		g_State.szWindowTitle = StringToString(buffer, 256, szTitle);
	}
	Tstring szTemp = g_State.szWindowTitle;
	if(g_State.bOhrMouseRequest && g_Mouse.IsInputLive())
		szTemp += TEXT(" Press 'Scroll Lock' to free mouse");
	else if(g_State.bOhrMouseRequest && !g_Mouse.IsInputLive())
		szTemp += TEXT(" Press 'Scroll Lock' to lock mouse");
	g_Window.SetWindowTitle(szTemp.c_str());
}

const char* gfx_GetWindowTitle()
{
	char buffer[256] = "";
	return StringToString(buffer, 256, g_State.szWindowTitle.c_str());
}

int gfx_AcquireKeyboard(int bEnable)
{
	return TRUE; //acquired by default
}

int gfx_AcquireMouse(int bEnable)
{
	g_State.bOhrMouseRequest = bEnable ? true : false;
	g_Mouse.SetInputState(bEnable ? gfx::Mouse::IS_LIVE : gfx::Mouse::IS_DEAD);
	char buffer[256] = "";
	gfx_SetWindowTitle( StringToString(buffer, 256, g_State.szWindowTitle.c_str()) );
	return TRUE;
}

int gfx_AcquireJoystick(int bEnable, int nDevice)
{
	return FALSE; //no joystick support yet
}

int gfx_GetKeyboard(int *pKeyboard)
{
	if(pKeyboard == NULL)
		return FALSE;
	g_Keyboard.GetOHRScans(pKeyboard);
	return TRUE;
}

int gfx_GetMouseMovement(int& dx, int& dy, int& dWheel, int& buttons)
{
	return FALSE;
}

int gfx_GetMousePosition(int& x, int& y, int& wheel, int& buttons)
{
	x = g_Mouse.GetCursorPos().x;
	y = g_Mouse.GetCursorPos().y;
	wheel = g_Mouse.GetWheel();
	buttons = g_Mouse.GetButtonState().GetData();
	return TRUE;
}

int gfx_SetMousePosition(int x, int y)
{
	DWORD xPos, yPos;
	RECT rClient;
	GetClientRect(g_Window.GetWindowHandle(), &rClient);
	POINT pos = {rClient.right * x/320.0f, rClient.bottom * y/200.0f};
	::ClientToScreen(g_Window.GetWindowHandle(), &pos);
	GetClientRect(GetDesktopWindow(), &rClient);
	xPos = (DWORD)((float)(rClient.right - pos.x) / (float)rClient.right * 65535.0f);
	yPos = (DWORD)((float)(rClient.bottom - pos.y) / (float)rClient.bottom * 65535.0f);

	mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE, xPos, yPos, 0, NULL);

	return TRUE;
}

int gfx_GetJoystickMovement(int nDevice, int& dx, int& dy, int& buttons)
{
	return FALSE; //no support
}

int gfx_GetJoystickPosition(int nDevice, int& x, int& y, int& buttons)
{
	return FALSE; //no support
}

int gfx_SetJoystickPosition(int nDevice, int x, int y)
{
	return FALSE; //no support
}

SIZE CalculateNativeResolutionMultiple(UINT width, UINT height, UINT targetWidth, UINT targetHeight)
{
	SIZE ret = {targetWidth, targetHeight};
	UINT targetArea = targetWidth * targetHeight;
	UINT area = width * height;
	UINT i = 1;
	while(area > targetArea * i * i)
		i++;
	if(i != 1)
	{
		float midArea = targetArea * (i-.5f) * (i-.5f);
		if(area < (UINT)midArea)
		{
			ret.cx = targetWidth * (i-1);
			ret.cy = targetHeight * (i-1);
		}
		else
		{
			ret.cx = targetWidth * i;
			ret.cy = targetHeight * i;
		}
	}
	return ret;
}

bool IsNativeResolutionMultiple(UINT width, UINT height, UINT targetWidth, UINT targetHeight)
{
	if(width * height < targetWidth * targetHeight)
		return false;
	UINT i = 1;
	while(width > targetWidth * i)
		i++;
	if(width != targetWidth * i)
		return false;
	if(height != targetHeight * i)
		return false;
	return true;
}

LRESULT CALLBACK OHRWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
	const UINT_PTR ID_MENU_OPTIONS = 101;
	
	if(g_Mouse.ProcessMessage(hWnd, msg, wParam, lParam))
		return 0;
	g_Keyboard.ProcessMessage(hWnd, msg, wParam, lParam);

	switch(msg)
	{
	case WM_KEYDOWN:
		{
			switch(wParam)
			{
			case VK_SCROLL:
				{
					if(!(lParam & 0x40000000)) //key was not pressed before
					{
						if(g_Mouse.IsInputLive())
						{
							g_Mouse.PushState();
							g_Mouse.SetInputState(gfx::Mouse::IS_DEAD);
						}
						else
							g_Mouse.PopState();
						char buffer[256] = "";
						gfx_SetWindowTitle(StringToString(buffer, 256, g_State.szWindowTitle.c_str()));
					}
				} break;
			default:
				return ::DefWindowProc(hWnd, msg, wParam, lParam);
			}
		} break;
	case WM_SYSCOMMAND:
		{
			switch(wParam)
			{
			case ID_MENU_OPTIONS:
				{//run dialog
					if(::IsWindow(g_hWndDlg))
						return 0;
					g_hWndDlg = ::CreateDialog(::GetModuleHandle(MODULENAME), TEXT("DialogOptions"), hWnd, (DLGPROC)OHROptionsDlgModeless);
					::ShowWindow(g_hWndDlg, SW_SHOWNORMAL);
					::UpdateWindow(g_hWndDlg);
				} break;
			case SC_KEYMENU:
				{
				} break;
			default:
				{
					return ::DefWindowProc(hWnd, msg, wParam, lParam);
				}
			}
		} break;
	case WM_SYSCHAR:
		{
			switch(wParam)
			{
			case VK_RETURN: //alt-enter
				{
					if(!(lParam & 0x40000000)) //key was not pressed before
					{
						g_DirectX.SetView(g_DirectX.IsViewFullscreen());
						g_Mouse.SetVideoMode(g_DirectX.IsViewFullscreen() ? gfx::Mouse::VM_FULLSCREEN : gfx::Mouse::VM_WINDOWED);
					}
				} break;
			default:
				return ::DefWindowProc(hWnd, msg, wParam, lParam);
			}
		} break;
	case WM_ACTIVATE:
		{
			if(LOWORD(wParam) == WA_INACTIVE)
			{
				g_Mouse.PushState();
				g_Mouse.SetInputState(gfx::Mouse::IS_DEAD);
				g_Mouse.SetVideoMode(gfx::Mouse::VM_WINDOWED);
			}
			else
				g_Mouse.PopState();
			return ::DefWindowProc(hWnd, msg, wParam, lParam);
		} break;
	case WM_SIZE:
		{
			::DefWindowProc(hWnd, msg, wParam, lParam);
			if(wParam == SIZE_MINIMIZED)
			{
				g_Mouse.PushState();
				g_Mouse.SetInputState(gfx::Mouse::IS_DEAD);
				g_Mouse.SetVideoMode(gfx::Mouse::VM_WINDOWED);
			}
			else
			{
				g_DirectX.SetResolution(LOWORD(lParam), HIWORD(lParam));
				g_Mouse.PopState();
			}
		} break;
	case WM_SIZING:
		{
			if(!g_DirectX.IsViewFullscreen())
			{
				static RECT rWindowTest = {0,0,400,400};
				static BOOL bRunOnce = FALSE;
				static SIZE sPadding = {0,0};
				if(bRunOnce == FALSE)
				{
					bRunOnce = TRUE;
					::AdjustWindowRectEx(&rWindowTest, WS_OVERLAPPEDWINDOW, FALSE, 0);
					sPadding.cx = rWindowTest.right - rWindowTest.left - 400;
					sPadding.cy = rWindowTest.bottom - rWindowTest.top - 400;
				}
				switch(wParam)
				{
				case WMSZ_BOTTOMLEFT:
					{
						RECT r = *(RECT*)lParam;
						if(!IsNativeResolutionMultiple(r.right - r.left - sPadding.cx, r.bottom - r.top - sPadding.cy))
						{
							SIZE resolution = CalculateNativeResolutionMultiple(r.right - r.left - sPadding.cx, r.bottom - r.top - sPadding.cy);
							r.bottom = r.top + (resolution.cy + sPadding.cy);
							r.left = r.right - (resolution.cx + sPadding.cx);
							*(RECT*)lParam = r;
						}
					} break;
				case WMSZ_BOTTOMRIGHT:
					{
						RECT r = *(RECT*)lParam;
						if(!IsNativeResolutionMultiple(r.right - r.left - sPadding.cx, r.bottom - r.top - sPadding.cy))
						{
							SIZE resolution = CalculateNativeResolutionMultiple(r.right - r.left - sPadding.cx, r.bottom - r.top - sPadding.cy);
							r.bottom = r.top + (resolution.cy + sPadding.cy);
							r.right = r.left + (resolution.cx + sPadding.cx);
							*(RECT*)lParam = r;
						}
					} break;
				case WMSZ_TOPLEFT:
					{
						RECT r = *(RECT*)lParam;
						if(!IsNativeResolutionMultiple(r.right - r.left - sPadding.cx, r.bottom - r.top - sPadding.cy))
						{
							SIZE resolution = CalculateNativeResolutionMultiple(r.right - r.left - sPadding.cx, r.bottom - r.top - sPadding.cy);
							r.top = r.bottom - (resolution.cy + sPadding.cy);
							r.left = r.right - (resolution.cx + sPadding.cx);
							*(RECT*)lParam = r;
						}
					} break;
				case WMSZ_TOPRIGHT:
					{
						RECT r = *(RECT*)lParam;
						if(!IsNativeResolutionMultiple(r.right - r.left - sPadding.cx, r.bottom - r.top - sPadding.cy))
						{
							SIZE resolution = CalculateNativeResolutionMultiple(r.right - r.left - sPadding.cx, r.bottom - r.top - sPadding.cy);
							r.top = r.bottom - (resolution.cy + sPadding.cy);
							r.right = r.left + (resolution.cx + sPadding.cx);
							*(RECT*)lParam = r;
						}
					} break;
				}
			}
			::DefWindowProc(hWnd, msg, wParam, lParam);
		} break;
	case WM_CLOSE:
		{
			if(g_State.bClosing)
				return ::DefWindowProc(hWnd, msg, wParam, lParam);
			g_Mouse.PushState();
			g_Mouse.SetInputState(gfx::Mouse::IS_DEAD);
			g_Mouse.SetVideoMode(gfx::Mouse::VM_WINDOWED);
			g_State.PostTerminateSignal();
			g_Mouse.PopState();
		} break;
	case WM_CREATE:
		{
			HMENU hSysMenu = ::GetSystemMenu(hWnd, false);
			::InsertMenu(hSysMenu, 0, MF_BYPOSITION | MF_STRING, ID_MENU_OPTIONS, TEXT("Options"));
			::InsertMenu(hSysMenu, 1, MF_BYPOSITION | MF_SEPARATOR, 0, 0);
		}//intentionally fall-through
	default:
		return ::DefWindowProc(hWnd, msg, wParam, lParam);
	}
	return 0;
}

BOOL CALLBACK OHROptionsDlgModeless(HWND hWndDlg, UINT msg, WPARAM wParam, LPARAM lParam)
{
	static BOOL bVsyncEnabled, bSmoothEnabled, bARPEnabled;

	switch(msg)
	{
	case WM_COMMAND:
		{
			switch(LOWORD(wParam))
			{//control id
			case IDC_OPTIONS_EnableVsync:
				{
					g_DirectX.SetVSync(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnableVsync));
				} break;
			case IDC_OPTIONS_EnableSmooth:
				{
					g_DirectX.SetSmooth(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnableSmooth));
				} break;
			case IDC_OPTIONS_EnablePreserveAspectRatio:
				{
					g_DirectX.SetAspectRatioPreservation(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnablePreserveAspectRatio));
				} break;
			case IDC_OPTIONS_SetDefaults:
				{//sets defaults
					::CheckDlgButton(hWndDlg, IDC_OPTIONS_EnableVsync, BST_CHECKED);
					::CheckDlgButton(hWndDlg, IDC_OPTIONS_EnableSmooth, BST_UNCHECKED);
					::CheckDlgButton(hWndDlg, IDC_OPTIONS_EnablePreserveAspectRatio, BST_CHECKED);

					g_DirectX.SetVSync(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnableVsync));
					g_DirectX.SetSmooth(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnableSmooth));
					g_DirectX.SetAspectRatioPreservation(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnablePreserveAspectRatio));

					if(g_DirectX.IsScreenShotsActive())
					{
						::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_JPG, BST_CHECKED);
						::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_BMP, BST_UNCHECKED);
						::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_PNG, BST_UNCHECKED);
						::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_DDS, BST_UNCHECKED);
						::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_OHR, BST_UNCHECKED);
					}
					return TRUE;
				} break;
			case IDOK:
				{//apply all changes and return
					g_DirectX.SetVSync(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnableVsync));
					g_DirectX.SetSmooth(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnableSmooth));
					g_DirectX.SetAspectRatioPreservation(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_EnablePreserveAspectRatio));
					if(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_ScrnShotFormats_JPG))
						g_DirectX.SetImageFileFormat(D3DXIFF_JPG);
					else if(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_ScrnShotFormats_BMP))
						g_DirectX.SetImageFileFormat(D3DXIFF_BMP);
					else if(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_ScrnShotFormats_PNG))
						g_DirectX.SetImageFileFormat(D3DXIFF_PNG);
					else if(BST_CHECKED == ::IsDlgButtonChecked(hWndDlg, IDC_OPTIONS_ScrnShotFormats_DDS))
						g_DirectX.SetImageFileFormat(D3DXIFF_DDS);
					else
						g_DirectX.SetImageFileFormat(D3DXIFF_FORCE_DWORD);
					g_Mouse.PopState();
					::DestroyWindow(hWndDlg);
					g_hWndDlg = NULL;
				} break;
			case IDCANCEL:
				{//revert all changes and return
					g_DirectX.SetVSync(bVsyncEnabled == TRUE);
					g_DirectX.SetSmooth(bSmoothEnabled == TRUE);
					g_DirectX.SetAspectRatioPreservation(bARPEnabled == TRUE);
					g_Mouse.PopState();
					::DestroyWindow(hWndDlg);
					g_hWndDlg = NULL;
				} break;
			default:
				return FALSE;
			}
		} break;
	case WM_INITDIALOG:
		{
			g_Mouse.PushState();
			g_Mouse.SetVideoMode(gfx::Mouse::VM_WINDOWED);
			g_Mouse.SetInputState(gfx::Mouse::IS_DEAD);

			bVsyncEnabled = g_DirectX.IsVsyncEnabled() ? TRUE : FALSE;
			bSmoothEnabled = g_DirectX.IsSmooth() ? TRUE : FALSE;
			bARPEnabled = g_DirectX.IsAspectRatioPreserved() ? TRUE : FALSE;

			::CheckDlgButton(hWndDlg, IDC_OPTIONS_EnableVsync, (g_DirectX.IsVsyncEnabled() ? BST_CHECKED : BST_UNCHECKED));
			::CheckDlgButton(hWndDlg, IDC_OPTIONS_EnableSmooth, (g_DirectX.IsSmooth() ? BST_CHECKED : BST_UNCHECKED));
			::CheckDlgButton(hWndDlg, IDC_OPTIONS_EnablePreserveAspectRatio, (g_DirectX.IsAspectRatioPreserved() ? BST_CHECKED : BST_UNCHECKED));
			::SendDlgItemMessage(hWndDlg, IDC_OPTIONS_Status, WM_SETTEXT, 0, (LPARAM)g_DirectX.GetLastErrorMessage());
			TCHAR strInfoBuffer[128] = TEXT("");
			::_stprintf_s<128>(strInfoBuffer, TEXT("DirectX Backend version: %d.%d.%d\r\nhttp://www.hamsterrepublic.com"), DX_VERSION_MAJOR, DX_VERSION_MINOR, DX_VERSION_BUILD);
			::SendDlgItemMessage(hWndDlg, IDC_OPTIONS_Info, WM_SETTEXT, 0, (LPARAM)strInfoBuffer);
			if(g_DirectX.IsScreenShotsActive())
			{
				switch(g_DirectX.GetImageFileFormat())
				{
				case D3DXIFF_JPG:
					::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_JPG, BST_CHECKED);
					break;
				case D3DXIFF_BMP:
					::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_BMP, BST_CHECKED);
					break;
				case D3DXIFF_PNG:
					::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_PNG, BST_CHECKED);
					break;
				case D3DXIFF_DDS:
					::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_DDS, BST_CHECKED);
					break;
				default:
					::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_OHR, BST_CHECKED);
				}
			}
			else
			{
				::CheckDlgButton(hWndDlg, IDC_OPTIONS_ScrnShotFormats_OHR, BST_CHECKED);
				::EnableWindow(::GetDlgItem(hWndDlg, IDC_OPTIONS_ScrnShotFormats_JPG), FALSE);
				::EnableWindow(::GetDlgItem(hWndDlg, IDC_OPTIONS_ScrnShotFormats_BMP), FALSE);
				::EnableWindow(::GetDlgItem(hWndDlg, IDC_OPTIONS_ScrnShotFormats_PNG), FALSE);
				::EnableWindow(::GetDlgItem(hWndDlg, IDC_OPTIONS_ScrnShotFormats_DDS), FALSE);
				::EnableWindow(::GetDlgItem(hWndDlg, IDC_OPTIONS_ScrnShotFormats_OHR), FALSE);
			}
		} break;
	default:
		return FALSE;
	}
	return TRUE;
}
