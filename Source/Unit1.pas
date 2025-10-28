unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, XPMan, ShellAPI, ComCtrls, MMDevApi, ActiveX, IniFiles,
  Menus;

type
  TMain = class(TForm)
    Panel: TPanel;
    XPManifest: TXPManifest;
    NotifyLbl: TLabel;
    HideTimer: TTimer;
    PopupMenuApp: TPopupMenu;
    CloseBtn: TMenuItem;
    N1: TMenuItem;
    AboutBtn: TMenuItem;
    N2: TMenuItem;
    HotKeyOnBtn: TMenuItem;
    HotKeyOffBtn: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure HideTimerTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure HotKeyOnBtnClick(Sender: TObject);
    procedure HotKeyOffBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
  private
    procedure ExecuteAndNotify(Title, Path, Params: string);
    procedure Notify(Title: string);
    procedure WMHotKey(var Msg: TWMHotKey); message WM_HOTKEY;
    procedure DefaultHandler(var Message); override;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure IconMouse(var Msg: TMessage); message WM_USER + 1;
    procedure WMActivate(var Msg: TMessage); message WM_ACTIVATE;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  //HotKeyModifier: integer;
  VolumeLevel: Single;
  EndPointVolume: IAudioEndpointVolume = nil;
  WM_TASKBARCREATED: Cardinal;

  //Translation / Перевод
  IDS_VOLUME, IDS_APP_NOT_FOUND, IDS_LAST_UPDATE: string;

  //Apps
  AppTitle_0, AppTitle_1, AppTitle_2, AppTitle_3, AppTitle_4, AppTitle_5, AppTitle_6,
  AppTitle_7, AppTitle_8, AppTitle_9, AppTitle_10, AppTitle_11, AppTitle_12: string;

  AppPath_0, AppPath_1, AppPath_2, AppPath_3, AppPath_4, AppPath_5, AppPath_6,
  AppPath_7, AppPath_8, AppPath_9, AppPath_10, AppPath_11, AppPath_12: string;

  AppParams_0, AppParams_1, AppParams_2, AppParams_3, AppParams_4, AppParams_5, AppParams_6,
  AppParams_7, AppParams_8, AppParams_9, AppParams_10, AppParams_11, AppParams_12: string;

  HotKeyVolUp, HotKeyVolDown, HotKey0, HotKey1, HotKey2, HotKey3, HotKey4,
  HotKey5, HotKey6, HotKey7, HotKey8, HotKey9, HotKey10, HotKey11, HotKey12: integer;

implementation

{$R *.dfm}

procedure RegisterKeys;
begin
  RegisterHotKey(Main.Handle, HotKey0, MOD_ALT, HotKey0);
  RegisterHotKey(Main.Handle, HotKey1, MOD_ALT, HotKey1);
  RegisterHotKey(Main.Handle, HotKey2, MOD_ALT, HotKey2);
  RegisterHotKey(Main.Handle, HotKey3, MOD_ALT, HotKey3);
  RegisterHotKey(Main.Handle, HotKey4, MOD_ALT, HotKey4);
  RegisterHotKey(Main.Handle, HotKey5, MOD_ALT, HotKey5);
  RegisterHotKey(Main.Handle, HotKey6, MOD_ALT, HotKey6);
  RegisterHotKey(Main.Handle, HotKey7, MOD_ALT, HotKey7);
  RegisterHotKey(Main.Handle, HotKey8, MOD_ALT, HotKey8);
  RegisterHotKey(Main.Handle, HotKey9, MOD_ALT, HotKey9);
  RegisterHotKey(Main.Handle, HotkeyVolUp, MOD_ALT, HotKeyVolUp);
  RegisterHotKey(Main.Handle, HotKeyVolDown, MOD_ALT, HotKeyVolDown);
  RegisterHotKey(Main.Handle, HotKey10, MOD_ALT, HotKey10);
  RegisterHotKey(Main.Handle, HotKey11, MOD_ALT, HotKey11);
  RegisterHotKey(Main.Handle, HotKey12, MOD_ALT, HotKey12);
end;

procedure UnRegisterKeys;
begin
  UnRegisterHotKey(Main.Handle, HotKey0);
  UnRegisterHotKey(Main.Handle, HotKey1);
  UnRegisterHotKey(Main.Handle, HotKey2);
  UnRegisterHotKey(Main.Handle, HotKey3);
  UnRegisterHotKey(Main.Handle, HotKey4);
  UnRegisterHotKey(Main.Handle, HotKey5);
  UnRegisterHotKey(Main.Handle, HotKey6);
  UnRegisterHotKey(Main.Handle, HotKey7);
  UnRegisterHotKey(Main.Handle, HotKey8);
  UnRegisterHotKey(Main.Handle, HotKeyVolUp);
  UnRegisterHotKey(Main.Handle, HotKeyVolDown);
  UnRegisterHotKey(Main.Handle, HotKey9);
  UnRegisterHotKey(Main.Handle, HotKey10);
  UnRegisterHotKey(Main.Handle, HotKey11);
  UnRegisterHotKey(Main.Handle, HotKey12);
end;

type TTrayAction = (TrayAdd, TrayUpdate, TrayDelete);
procedure Tray(TrayAction: TTrayAction);
var
  NIM: TNotifyIconData;
begin
  with NIM do begin
    cbSize:=SizeOf(NIM);
    Wnd:=Main.Handle;
    uId:=1;
    uFlags:=NIF_MESSAGE or NIF_ICON or NIF_TIP;
    hIcon:=SendMessage(Main.Handle, WM_GETICON, ICON_SMALL2, 0);
    uCallBackMessage:=WM_USER + 1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case TrayAction of
    TrayAdd: Shell_NotifyIcon(NIM_ADD, @NIM);
    TrayUpdate: Shell_NotifyIcon(NIM_MODIFY, @NIM);
    TrayDelete: Shell_NotifyIcon(NIM_DELETE, @NIM);
  end;
end;

procedure UpdateVolumeLevel;
begin
  EndPointVolume.GetMasterVolumeLevelScaler(VolumeLevel);
  VolumeLevel:=VolumeLevel * 100;
end;

function GetLocaleInformation(flag: integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, flag, pcLCA, 19) <= 0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

function KeyNameToKeyCode(KeyName: string): Integer;
begin
  KeyName:=UpperCase(KeyName);

  if KeyName = 'NONE' then Result := 0

  else if KeyName = 'ESCAPE' then Result := VK_ESCAPE
  else if KeyName = 'F1' then Result := VK_F1
  else if KeyName = 'F2' then Result := VK_F2
  else if KeyName = 'F3' then Result := VK_F3
  else if KeyName = 'F4' then Result := VK_F4
  else if KeyName = 'F5' then Result := VK_F5
  else if KeyName = 'F6' then Result := VK_F6
  else if KeyName = 'F7' then Result := VK_F7
  else if KeyName = 'F8' then Result := VK_F8
  else if KeyName = 'F9' then Result := VK_F9
  else if KeyName = 'F10' then Result := VK_F10
  else if KeyName = 'F11' then Result := VK_F11
  else if KeyName = 'F12' then Result := VK_F12

  else if KeyName = '~' then Result := 192
  else if KeyName = '1' then Result := Ord('1')
  else if KeyName = '2' then Result := Ord('2')
  else if KeyName = '3' then Result := Ord('3')
  else if KeyName = '4' then Result := Ord('4')
  else if KeyName = '5' then Result := Ord('5')
  else if KeyName = '6' then Result := Ord('6')
  else if KeyName = '7' then Result := Ord('7')
  else if KeyName = '8' then Result := Ord('8')
  else if KeyName = '9' then Result := Ord('9')
  else if KeyName = '0' then Result := Ord('0')
  else if KeyName = '-' then Result := 189
  else if KeyName = '=' then Result := 187
  else if KeyName = '+' then Result := 187

  else if KeyName = 'TAB' then Result := VK_TAB
  else if KeyName = 'CAPS-LOCK' then Result := VK_CAPITAL
  else if KeyName = 'SHIFT' then Result := VK_SHIFT
  else if KeyName = 'LSHIFT' then Result := VK_LSHIFT
  else if KeyName = 'RSHIFT' then Result := VK_RSHIFT
  else if KeyName = 'CTRL' then Result := VK_CONTROL
  else if KeyName = 'LCTRL' then Result := VK_LCONTROL
  else if KeyName = 'RCTRL' then Result := VK_RCONTROL
  else if KeyName = 'WIN' then Result := VK_LWIN
  else if KeyName = 'ALT' then Result := VK_MENU
  else if KeyName = 'LALT' then Result := VK_LMENU
  else if KeyName = 'RALT' then Result := VK_RMENU
  else if KeyName = 'SPACE' then Result := VK_SPACE
  else if KeyName = 'ENTER' then Result := VK_RETURN
  else if KeyName = 'BACKSPACE' then Result := VK_BACK

  else if KeyName = 'Q' then Result := Ord('Q')
  else if KeyName = 'W' then Result := Ord('W')
  else if KeyName = 'E' then Result := Ord('E')
  else if KeyName = 'R' then Result := Ord('R')
  else if KeyName = 'T' then Result := Ord('T')
  else if KeyName = 'Y' then Result := Ord('Y')
  else if KeyName = 'U' then Result := Ord('U')
  else if KeyName = 'I' then Result := Ord('I')
  else if KeyName = 'O' then Result := Ord('O')
  else if KeyName = 'P' then Result := Ord('P')
  else if KeyName = '[' then Result := 219
  else if KeyName = ']' then Result := 221
  else if KeyName = 'A' then Result := Ord('A')
  else if KeyName = 'S' then Result := Ord('S')
  else if KeyName = 'D' then Result := Ord('D')
  else if KeyName = 'F' then Result := Ord('F')
  else if KeyName = 'G' then Result := Ord('G')
  else if KeyName = 'H' then Result := Ord('H')
  else if KeyName = 'J' then Result := Ord('J')
  else if KeyName = 'K' then Result := Ord('K')
  else if KeyName = 'L' then Result := Ord('L')
  else if KeyName = ':' then Result := 186
  else if KeyName = 'APOSTROPHE' then Result := 222
  else if KeyName = '\' then Result := 220
  else if KeyName = 'Z' then Result := Ord('Z')
  else if KeyName = 'X' then Result := Ord('X')
  else if KeyName = 'C' then Result := Ord('C')
  else if KeyName = 'V' then Result := Ord('V')
  else if KeyName = 'B' then Result := Ord('B')
  else if KeyName = 'N' then Result := Ord('N')
  else if KeyName = 'M' then Result := Ord('M')
  else if KeyName = '<' then Result := 188
  else if KeyName = '>' then Result := 190
  else if KeyName = '?' then Result := 191

  else if KeyName = 'PRINTSCREEN' then Result := VK_SNAPSHOT
  else if KeyName = 'SCROLL-LOCK' then Result := VK_SCROLL
  else if KeyName = 'PAUSE' then Result := VK_PAUSE
  else if KeyName = 'INSERT' then Result := VK_INSERT
  else if KeyName = 'HOME' then Result := VK_HOME
  else if KeyName = 'DELETE' then Result := VK_DELETE
  else if KeyName = 'END' then Result := VK_END
  else if KeyName = 'PAGE-UP' then Result := VK_PRIOR
  else if KeyName = 'PAGE-DOWN' then Result := VK_NEXT

  else if KeyName = 'UP' then Result := VK_UP
  else if KeyName = 'DOWN' then Result := VK_DOWN
  else if KeyName = 'LEFT' then Result := VK_LEFT
  else if KeyName = 'RIGHT' then Result := VK_RIGHT

  else if KeyName = 'NUM-LOCK' then Result := VK_NUMLOCK
  else if KeyName = 'NUMPAD0' then Result := VK_NUMPAD0
  else if KeyName = 'NUMPAD1' then Result := VK_NUMPAD1
  else if KeyName = 'NUMPAD2' then Result := VK_NUMPAD2
  else if KeyName = 'NUMPAD3' then Result := VK_NUMPAD3
  else if KeyName = 'NUMPAD4' then Result := VK_NUMPAD4
  else if KeyName = 'NUMPAD5' then Result := VK_NUMPAD5
  else if KeyName = 'NUMPAD6' then Result := VK_NUMPAD6
  else if KeyName = 'NUMPAD7' then Result := VK_NUMPAD7
  else if KeyName = 'NUMPAD8' then Result := VK_NUMPAD8
  else if KeyName = 'NUMPAD9' then Result := VK_NUMPAD9

  else if KeyName = 'NUMPAD-DIVIDE' then Result := VK_DIVIDE
  else if KeyName = 'NUMPAD-MULTIPLY' then Result := VK_MULTIPLY
  else if KeyName = 'NUMPAD-MINUS' then Result := VK_SUBTRACT
  else if KeyName = 'NUMPAD-PLUS' then Result := VK_ADD
  else if KeyName = 'NUMPAD-DEL' then Result := VK_DECIMAL
  else if KeyName = 'NUMPAD-ENTER' then Result := VK_RETURN

  else
    Result := 0; // если не нашли
end;

procedure TMain.FormCreate(Sender: TObject);
var
  DeviceEnumerator: IMMDeviceEnumerator;
  DefaultDevice: IMMDevice;
  Ini: TIniFile;
  StartupVolume: integer;
begin
  if (GetLocaleInformation(LOCALE_SENGLANGUAGE) = 'Russian') then begin
    IDS_VOLUME:='Громкость';
    IDS_APP_NOT_FOUND:='Приложение не найдено';
     IDS_LAST_UPDATE:='Последнее обновление';
  end else begin //English and other
    IDS_VOLUME:='Volume';
    IDS_APP_NOT_FOUND:='App not found';
    IDS_LAST_UPDATE:='Last update';
    HotKeyOnBtn.Caption:='HotKeys on';
    HotKeyOffBtn.Caption:='HotKeys off';
    AboutBtn.Caption:='About...';
    CloseBtn.Caption:='Close';
  end;

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  StartupVolume:=Ini.ReadInteger('Main', 'StartupVolume', 11);
  AppTitle_0:=Ini.ReadString('Key_0', 'Name', '');
  AppPath_0:=Ini.ReadString('Key_0', 'App', '');
  AppParams_0:=Ini.ReadString('Key_0', 'Params', '');
  AppTitle_1:=Ini.ReadString('Key_1', 'Name', '');
  AppPath_1:=Ini.ReadString('Key_1', 'App', '');
  AppParams_1:=Ini.ReadString('Key_1', 'Params', '');
  AppTitle_2:=Ini.ReadString('Key_2', 'Name', '');
  AppPath_2:=Ini.ReadString('Key_2', 'App', '');
  AppParams_2:=Ini.ReadString('Key_2', 'Params', '');
  AppTitle_3:=Ini.ReadString('Key_3', 'Name', '');
  AppPath_3:=Ini.ReadString('Key_3', 'App', '');
  AppParams_3:=Ini.ReadString('Key_3', 'Params', '');
  AppTitle_4:=Ini.ReadString('Key_4', 'Name', '');
  AppPath_4:=Ini.ReadString('Key_4', 'App', '');
  AppParams_4:=Ini.ReadString('Key_4', 'Params', '');
  AppTitle_5:=Ini.ReadString('Key_5', 'Name', '');
  AppPath_5:=Ini.ReadString('Key_5', 'App', '');
  AppParams_5:=Ini.ReadString('Key_5', 'Params', '');
  AppTitle_6:=Ini.ReadString('Key_6', 'Name', '');
  AppPath_6:=Ini.ReadString('Key_6', 'App', '');
  AppParams_6:=Ini.ReadString('Key_6', 'Params', '');
  AppTitle_7:=Ini.ReadString('Key_7', 'Name', '');
  AppPath_7:=Ini.ReadString('Key_7', 'App', '');
  AppParams_7:=Ini.ReadString('Key_7', 'Params', '');
  AppTitle_8:=Ini.ReadString('Key_8', 'Name', '');
  AppPath_8:=Ini.ReadString('Key_8', 'App', '');
  AppParams_8:=Ini.ReadString('Key_8', 'Params', '');
  AppTitle_9:=Ini.ReadString('Key_9', 'Name', '');
  AppPath_9:=Ini.ReadString('Key_9', 'App', '');
  AppParams_9:=Ini.ReadString('Key_9', 'Params', '');
  AppTitle_10:=Ini.ReadString('Key_10', 'Name', '');
  AppPath_10:=Ini.ReadString('Key_10', 'App', '');
  AppParams_10:=Ini.ReadString('Key_10', 'Params', '');
  AppTitle_11:=Ini.ReadString('Key_11', 'Name', '');
  AppPath_11:=Ini.ReadString('Key_11', 'App', '');
  AppParams_11:=Ini.ReadString('Key_11', 'Params', '');
  AppTitle_12:=Ini.ReadString('Key_12', 'Name', '');
  AppPath_12:=Ini.ReadString('Key_12', 'App', '');
  AppParams_12:=Ini.ReadString('Key_12', 'Params', '');

  HotkeyVolUp:=KeyNameToKeyCode(Ini.ReadString('Main', 'VolumeUpHotkey', 'NUMPPAD0'));
  HotKeyVolDown:=KeyNameToKeyCode(Ini.ReadString('Main', 'VolumeDownHotkey', 'NUMPPAD0'));
  HotKey0:=KeyNameToKeyCode(Ini.ReadString('Key_0', 'Hotkey', 'NUMPPAD0'));
  HotKey1:=KeyNameToKeyCode(Ini.ReadString('Key_1', 'Hotkey', 'NUMPPAD1'));
  HotKey2:=KeyNameToKeyCode(Ini.ReadString('Key_2', 'Hotkey', 'NUMPPAD2'));
  HotKey3:=KeyNameToKeyCode(Ini.ReadString('Key_3', 'Hotkey', 'NUMPPAD3'));
  HotKey4:=KeyNameToKeyCode(Ini.ReadString('Key_4', 'Hotkey', 'NUMPPAD4'));
  HotKey5:=KeyNameToKeyCode(Ini.ReadString('Key_5', 'Hotkey', 'NUMPPAD5'));
  HotKey6:=KeyNameToKeyCode(Ini.ReadString('Key_6', 'Hotkey', 'NUMPPAD6'));
  HotKey7:=KeyNameToKeyCode(Ini.ReadString('Key_7', 'Hotkey', 'NUMPPAD7'));
  HotKey8:=KeyNameToKeyCode(Ini.ReadString('Key_8', 'Hotkey', 'NUMPPAD8'));
  HotKey9:=KeyNameToKeyCode(Ini.ReadString('Key_9', 'Hotkey', 'NUMPPAD9'));
  HotKey10:=KeyNameToKeyCode(Ini.ReadString('Key_10', 'Hotkey', 'NUMPAD-DIVIDE'));
  HotKey11:=KeyNameToKeyCode(Ini.ReadString('Key_11', 'Hotkey', 'NUMPAD-MULTIPLY'));
  HotKey12:=KeyNameToKeyCode(Ini.ReadString('Key_12', 'Hotkey', 'NUMPAD-DEL'));

  Ini.Free;

  Application.Title:=Caption;
  WM_TaskBarCreated:=RegisterWindowMessage('TaskbarCreated');
  
  CoCreateInstance(CLASS_IMMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER, IID_IMMDeviceEnumerator, DeviceEnumerator);
  DeviceEnumerator.GetDefaultAudioEndpoint(eRender, eConsole, DefaultDevice);
  DefaultDevice.Activate(IID_IAudioEndpointVolume, CLSCTX_INPROC_SERVER, nil, EndPointVolume);
  if EndPointVolume = nil then
    Halt;

  RegisterKeys();
  //Startup volume
  UpdateVolumeLevel();
  if StartupVolume <> 0 then
    EndPointVolume.SetMasterVolumeLevelScalar(StartupVolume / 100, nil);

  Tray(TrayAdd);
  SetWindowLong(Application.Handle, GWL_EXSTYLE, GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);
end;

procedure TMain.ExecuteAndNotify(Title, Path, Params: string);
begin
  ShowWindow(Handle, SW_NORMAL);
  if Title = '' then
    Title:=ExtractFileName(Path);
  NotifyLbl.Caption:=Title;
  Main.Left:=Screen.Width - Main.Width - 15;
  Main.Top:=Screen.Height - Main.Height - 57;

  //WinExec(Pchar(Path), SW_SHOWNORMAL);
  if FileExists(Path) then
    ShellExecute(0, 'open', PChar(Path), PChar(Params), nil, SW_SHOWNORMAL)
  else
    Application.MessageBox(PChar(IDS_APP_NOT_FOUND), PChar(Caption), MB_ICONWARNING);
  HideTimer.Enabled:=true;
end;

procedure TMain.Notify(Title: string);
begin
  ShowWindow(Main.Handle, SW_NORMAL);
  NotifyLbl.Caption:=Title;
  Left:=Screen.Width - Main.Width - 15;
  Top:=Screen.Height - Main.Height - 57;
  HideTimer.Enabled:=true;
end;

procedure TMain.WMHotKey(var Msg: TWMHotKey);
begin
  if Msg.HotKey = HotKey0 then ExecuteAndNotify(AppTitle_0, AppPath_0, AppParams_0)
  else if Msg.HotKey = Hotkey1 then ExecuteAndNotify(AppTitle_1, AppPath_1, AppParams_1)
  else if Msg.HotKey = Hotkey2 then ExecuteAndNotify(AppTitle_2, AppPath_2, AppParams_2)
  else if Msg.HotKey = Hotkey3 then ExecuteAndNotify(AppTitle_3, AppPath_3, AppParams_3)
  else if Msg.HotKey = Hotkey4 then ExecuteAndNotify(AppTitle_4, AppPath_4, AppParams_4)
  else if Msg.HotKey = Hotkey5 then ExecuteAndNotify(AppTitle_5, AppPath_5, AppParams_5)
  else if Msg.HotKey = Hotkey6 then ExecuteAndNotify(AppTitle_6, AppPath_6, AppParams_6)
  else if Msg.HotKey = Hotkey7 then ExecuteAndNotify(AppTitle_7, AppPath_7, AppParams_7)
  else if Msg.HotKey = Hotkey8 then ExecuteAndNotify(AppTitle_8, AppPath_8, AppParams_8)
  else if Msg.HotKey = Hotkey9 then ExecuteAndNotify(AppTitle_9, AppPath_9, AppParams_9)
  else if Msg.HotKey = Hotkey10 then ExecuteAndNotify(AppTitle_10, AppPath_10, AppParams_10)
  else if Msg.HotKey = Hotkey11 then ExecuteAndNotify(AppTitle_11, AppPath_11, AppParams_11)
  else if Msg.HotKey = Hotkey12 then ExecuteAndNotify(AppTitle_12, AppPath_12, AppParams_12)
  else if Msg.HotKey = HotkeyVolUp then begin
    UpdateVolumeLevel();
    if VolumeLevel < 99 then begin
      VolumeLevel:=VolumeLevel + 1;
      EndPointVolume.SetMasterVolumeLevelScalar(VolumeLevel / 100, nil);
      Notify(IDS_VOLUME + ': ' + IntToStr(Round(VolumeLevel)));
    end;
  end else if Msg.HotKey = HotKeyVolDown then begin
    UpdateVolumeLevel();
    if VolumeLevel > 1 then begin
      VolumeLevel:=VolumeLevel - 1;
      EndPointVolume.SetMasterVolumeLevelScalar(VolumeLevel / 100, nil);
      Notify(IDS_VOLUME + ': ' + IntToStr(Round(VolumeLevel)));
    end;
  end;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  UnRegisterKeys();
  Tray(TrayDelete);
end;

procedure TMain.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style:=WS_POPUP or WS_THICKFRAME;
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.lParam of
    WM_LBUTTONDOWN: begin
      PostMessage(Handle, WM_LBUTTONDOWN, MK_LBUTTON, 0);
      PostMessage(Handle, WM_LBUTTONUP, MK_LBUTTON, 0);
    end;
    WM_RBUTTONDOWN:
      PopupMenuApp.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TMain.HideTimerTimer(Sender: TObject);
begin
  ShowWindow(Handle, SW_HIDE);
  HideTimer.Enabled:=false;
end;

procedure TMain.WMActivate(var Msg: TMessage);
begin
  if Msg.WParam = WA_INACTIVE then
    ShowWindow(Handle, SW_HIDE);
end;

procedure TMain.DefaultHandler(var Message);
begin
  if TMessage(Message).Msg = WM_TASKBARCREATED then
    Tray(TrayAdd);
  inherited;
end;

procedure TMain.FormActivate(Sender: TObject);
begin
  if Main.AlphaBlend then begin
    ShowWindow(Handle, SW_HIDE);
    Main.AlphaBlendValue:=255;
    Main.AlphaBlend:=false;
  end;
end;

procedure TMain.HotKeyOnBtnClick(Sender: TObject);
begin
  RegisterKeys;
end;

procedure TMain.HotKeyOffBtnClick(Sender: TObject);
begin
  UnregisterKeys;
end;

procedure TMain.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar(Caption + ' 0.5.2' + #13#10 +
  IDS_LAST_UPDATE + ': 28.10.25' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(AboutBtn.Caption), MB_ICONINFORMATION);
end;

end.
