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
    PopupMenu: TPopupMenu;
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
  VolumeLevel: Single;
  EndPointVolume: IAudioEndpointVolume = nil;
  WM_TaskBarCreated: Cardinal;
  RunOnce: boolean;

  //Translation / Перевод
  IDS_VOLUME, IDS_APP_NOT_FOUND, IDS_LAST_UPDATE: string;

  //Apps
  AppTitle_0, AppTitle_1, AppTitle_2, AppTitle_3, AppTitle_4, AppTitle_5, AppTitle_6,
  AppTitle_7, AppTitle_8, AppTitle_9, AppTitle_10, AppTitle_11, AppTitle_12: string;

  AppPath_0, AppPath_1, AppPath_2, AppPath_3, AppPath_4, AppPath_5, AppPath_6,
  AppPath_7, AppPath_8, AppPath_9, AppPath_10, AppPath_11, AppPath_12: string;

  AppParams_0, AppParams_1, AppParams_2, AppParams_3, AppParams_4, AppParams_5, AppParams_6,
  AppParams_7, AppParams_8, AppParams_9, AppParams_10, AppParams_11, AppParams_12: string;

implementation

{$R *.dfm}

procedure RegisterKeys;
begin
  RegisterHotKey(Main.Handle, VK_NUMPAD0, MOD_ALT, VK_NUMPAD0);
  RegisterHotKey(Main.Handle, VK_NUMPAD1, MOD_ALT, VK_NUMPAD1);
  RegisterHotKey(Main.Handle, VK_NUMPAD2, MOD_ALT, VK_NUMPAD2);
  RegisterHotKey(Main.Handle, VK_NUMPAD3, MOD_ALT, VK_NUMPAD3);
  RegisterHotKey(Main.Handle, VK_NUMPAD4, MOD_ALT, VK_NUMPAD4);
  RegisterHotKey(Main.Handle, VK_NUMPAD5, MOD_ALT, VK_NUMPAD5);
  RegisterHotKey(Main.Handle, VK_NUMPAD6, MOD_ALT, VK_NUMPAD6);
  RegisterHotKey(Main.Handle, VK_NUMPAD7, MOD_ALT, VK_NUMPAD7);
  RegisterHotKey(Main.Handle, VK_NUMPAD8, MOD_ALT, VK_NUMPAD8);
  RegisterHotKey(Main.Handle, VK_NUMPAD9, MOD_ALT, VK_NUMPAD9);
  RegisterHotKey(Main.Handle, VK_SUBTRACT, MOD_ALT, VK_SUBTRACT);
  RegisterHotKey(Main.Handle, VK_ADD, MOD_ALT, VK_ADD);
  RegisterHotKey(Main.Handle, VK_MULTIPLY, 0, VK_MULTIPLY);
  RegisterHotKey(Main.Handle, VK_DECIMAL, 0, VK_DECIMAL);
  RegisterHotKey(Main.Handle, VK_DIVIDE, 0, VK_DIVIDE);
end;

procedure UnRegisterKeys;
begin
  UnRegisterHotKey(Main.Handle, VK_NUMPAD0);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD1);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD2);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD3);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD4);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD5);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD6);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD7);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD8);
  UnRegisterHotKey(Main.Handle, VK_SUBTRACT);
  UnRegisterHotKey(Main.Handle, VK_ADD);
  UnRegisterHotKey(Main.Handle, VK_NUMPAD9);
  UnRegisterHotKey(Main.Handle, VK_MULTIPLY);
  UnRegisterHotKey(Main.Handle, VK_DECIMAL);
  UnRegisterHotKey(Main.Handle, VK_DIVIDE);
end;

procedure Tray(ActInd: integer);  //1 - add, 2 - remove, 3 - update
var
  NIM: TNotifyIconData;
begin
  with NIM do begin
    cbSize:=SizeOf(NIM);
    Wnd:=Main.Handle;
    uId:=1;
    uFlags:=NIF_MESSAGE or NIF_ICON or NIF_TIP;
    hIcon:=SendMessage(Application.Handle, WM_GETICON, ICON_SMALL2, 0);
    uCallBackMessage:=WM_USER + 1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case ActInd of
    1: Shell_NotifyIcon(NIM_ADD, @NIM);
    2: Shell_NotifyIcon(NIM_DELETE, @NIM);
    3: Shell_NotifyIcon(NIM_MODIFY, @NIM);
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
  AppTitle_0:=Ini.ReadString('Numpad_0', 'Name', '');
  AppPath_0:=Ini.ReadString('Numpad_0', 'App', '');
  AppParams_0:=Ini.ReadString('Numpad_0', 'Params', '');
  AppTitle_1:=Ini.ReadString('Numpad_1', 'Name', '');
  AppPath_1:=Ini.ReadString('Numpad_1', 'App', '');
  AppParams_1:=Ini.ReadString('Numpad_1', 'Params', '');
  AppTitle_2:=Ini.ReadString('Numpad_2', 'Name', '');
  AppPath_2:=Ini.ReadString('Numpad_2', 'App', '');
  AppParams_2:=Ini.ReadString('Numpad_2', 'Params', '');
  AppTitle_3:=Ini.ReadString('Numpad_3', 'Name', '');
  AppPath_3:=Ini.ReadString('Numpad_3', 'App', '');
  AppParams_3:=Ini.ReadString('Numpad_3', 'Params', '');
  AppTitle_4:=Ini.ReadString('Numpad_4', 'Name', '');
  AppPath_4:=Ini.ReadString('Numpad_4', 'App', '');
  AppParams_4:=Ini.ReadString('Numpad_4', 'Params', '');
  AppTitle_5:=Ini.ReadString('Numpad_5', 'Name', '');
  AppPath_5:=Ini.ReadString('Numpad_5', 'App', '');
  AppParams_5:=Ini.ReadString('Numpad_5', 'Params', '');
  AppTitle_6:=Ini.ReadString('Numpad_6', 'Name', '');
  AppPath_6:=Ini.ReadString('Numpad_6', 'App', '');
  AppParams_6:=Ini.ReadString('Numpad_6', 'Params', '');
  AppTitle_7:=Ini.ReadString('Numpad_7', 'Name', '');
  AppPath_7:=Ini.ReadString('Numpad_7', 'App', '');
  AppParams_7:=Ini.ReadString('Numpad_7', 'Params', '');
  AppTitle_8:=Ini.ReadString('Numpad_8', 'Name', '');
  AppPath_8:=Ini.ReadString('Numpad_8', 'App', '');
  AppParams_8:=Ini.ReadString('Numpad_8', 'Params', '');
  AppTitle_9:=Ini.ReadString('Numpad_9', 'Name', '');
  AppPath_9:=Ini.ReadString('Numpad_9', 'App', '');
  AppParams_9:=Ini.ReadString('Numpad_9', 'Params', '');
  AppTitle_10:=Ini.ReadString('Numpad_/', 'Name', '');
  AppPath_10:=Ini.ReadString('Numpad_/', 'App', '');
  AppParams_10:=Ini.ReadString('Numpad_/', 'Params', '');
  AppTitle_11:=Ini.ReadString('Numpad_*', 'Name', '');
  AppPath_11:=Ini.ReadString('Numpad_*', 'App', '');
  AppParams_11:=Ini.ReadString('Numpad_*', 'Params', '');
  AppTitle_12:=Ini.ReadString('Numpad_.', 'Name', '');
  AppPath_12:=Ini.ReadString('Numpad_.', 'App', '');
  AppParams_12:=Ini.ReadString('Numpad_.', 'Params', '');
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
  EndPointVolume.SetMasterVolumeLevelScalar(StartupVolume / 100, nil);

  Tray(1);
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
    Application.MessageBox(Pchar(IDS_APP_NOT_FOUND), PChar(Caption), MB_ICONWARNING);
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
  case Msg.HotKey of
    VK_NUMPAD0: ExecuteAndNotify(AppTitle_0, AppPath_0, AppParams_0);
    VK_NUMPAD1: ExecuteAndNotify(AppTitle_1, AppPath_1, AppParams_1);
    VK_NUMPAD2: ExecuteAndNotify(AppTitle_2, AppPath_2, AppParams_2);
    VK_NUMPAD3: ExecuteAndNotify(AppTitle_3, AppPath_3, AppParams_3);
    VK_NUMPAD4: ExecuteAndNotify(AppTitle_4, AppPath_4, AppParams_4);
    VK_NUMPAD5: ExecuteAndNotify(AppTitle_5, AppPath_5, AppParams_5);
    VK_NUMPAD6: ExecuteAndNotify(AppTitle_6, AppPath_6, AppParams_6);
    VK_NUMPAD7: ExecuteAndNotify(AppTitle_7, AppPath_7, AppParams_7);
    VK_NUMPAD8: ExecuteAndNotify(AppTitle_8, AppPath_8, AppParams_8);
    VK_NUMPAD9: ExecuteAndNotify(AppTitle_9, AppPath_9, AppParams_9);
    VK_DIVIDE: ExecuteAndNotify(AppTitle_10, AppPath_10, AppParams_10);
    VK_MULTIPLY: ExecuteAndNotify(AppTitle_11, AppPath_11, AppParams_11);
    VK_DECIMAL: ExecuteAndNotify(AppTitle_12, AppPath_12, AppParams_12);
    VK_SUBTRACT:
      begin
        UpdateVolumeLevel();
        if VolumeLevel > 1 then begin
          VolumeLevel:=VolumeLevel - 1;
          EndPointVolume.SetMasterVolumeLevelScalar(VolumeLevel / 100, nil);
          Notify(IDS_VOLUME + ': ' + IntToStr(Round(VolumeLevel)));
        end;
      end;
    VK_ADD:
      begin
        UpdateVolumeLevel();
        if VolumeLevel < 99 then begin
          VolumeLevel:=VolumeLevel + 1;
          EndPointVolume.SetMasterVolumeLevelScalar(VolumeLevel / 100, nil);
          Notify(IDS_VOLUME + ': ' + IntToStr(Round(VolumeLevel)));
        end;
      end;
  end;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  UnRegisterKeys();
  Tray(2);
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
      PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
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
    Tray(1);
  inherited;
end;

procedure TMain.FormActivate(Sender: TObject);
begin
  if RunOnce = false then begin
    RunOnce:=true;
    Main.AlphaBlend:=false;
    ShowWindow(Handle, SW_HIDE);
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
  Application.MessageBox(PChar(Caption + ' 0.5' + #13#10 +
  IDS_LAST_UPDATE + ': 10.05.2020' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(AboutBtn.Caption), MB_ICONINFORMATION);
end;

end.
