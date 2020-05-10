object Main: TMain
  Left = 192
  Top = 124
  BorderStyle = bsNone
  Caption = 'NumPad Plus'
  ClientHeight = 34
  ClientWidth = 146
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel: TPanel
    Left = 8
    Top = 6
    Width = 130
    Height = 20
    BevelOuter = bvNone
    TabOrder = 0
    object NotifyLbl: TLabel
      Left = 0
      Top = 0
      Width = 130
      Height = 20
      Align = alClient
      Alignment = taCenter
      Caption = #1059#1074#1077#1076#1086#1084#1083#1077#1085#1080#1077
      Color = clWhite
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
  end
  object XPManifest: TXPManifest
    Left = 80
    Top = 8
  end
  object HideTimer: TTimer
    Enabled = False
    Interval = 700
    OnTimer = HideTimerTimer
    Left = 104
    Top = 8
  end
  object PopupMenu: TPopupMenu
    Left = 8
    Top = 6
    object HotKeyOnBtn: TMenuItem
      Caption = #1042#1082#1083'. '#1075#1086#1088#1103#1095'. '#1082#1083#1072#1074'.'
      OnClick = HotKeyOnBtnClick
    end
    object HotKeyOffBtn: TMenuItem
      Caption = #1042#1099#1082#1083'. '#1075#1086#1088#1103#1095'. '#1082#1083#1072#1074'.'
      OnClick = HotKeyOffBtnClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object AboutBtn: TMenuItem
      Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
      OnClick = AboutBtnClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object CloseBtn: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = CloseBtnClick
    end
  end
end
