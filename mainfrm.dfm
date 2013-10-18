object fMain: TfMain
  Left = 291
  Top = 178
  HorzScrollBar.Smooth = True
  HorzScrollBar.Tracking = True
  Caption = 'SSG'#39's Own Commander'
  ClientHeight = 355
  ClientWidth = 528
  Color = clBtnFace
  Font.Charset = TURKISH_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  Menu = mmMain
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object sbMain: TStatusBar
    Left = 0
    Top = 336
    Width = 528
    Height = 19
    Panels = <>
    SimplePanel = True
    ExplicitTop = 326
    ExplicitWidth = 536
  end
  object pCmdLine: TPanel
    Left = 0
    Top = 309
    Width = 528
    Height = 27
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    OnContextPopup = pCmdLineContextPopup
    ExplicitTop = 299
    ExplicitWidth = 536
    object Panel1: TPanel
      Left = 0
      Top = 0
      Width = 200
      Height = 27
      Align = alLeft
      AutoSize = True
      BevelOuter = bvNone
      BorderWidth = 2
      Constraints.MaxWidth = 200
      TabOrder = 0
      object lCmdPrompt: TLabel
        Left = 2
        Top = 5
        Width = 395
        Height = 13
        Caption = 
          'C:\Documents and Settings\Administrator\Application Data\Connect' +
          'ix\Virtual PC\>'
      end
    end
    object Panel2: TPanel
      Left = 200
      Top = 0
      Width = 336
      Height = 27
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      DesignSize = (
        328
        27)
      object eCmdLine: TEdit
        Left = 8
        Top = 2
        Width = 316
        Height = 21
        TabStop = False
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
        OnKeyDown = eCmdLineKeyDown
        ExplicitWidth = 324
      end
    end
  end
  object mmMain: TMainMenu
    Left = 40
    Top = 8
    object File1: TMenuItem
      Caption = '&File'
      object ChangeAttributes1: TMenuItem
        Caption = '&Change Attributes...'
        ShortCut = 16497
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'E&xit'
      end
    end
    object View1: TMenuItem
      Caption = '&View'
      object mViewCmdLine: TMenuItem
        Caption = '&Command Line'
        Checked = True
        OnClick = mViewCmdLineClick
      end
    end
    object Options1: TMenuItem
      Caption = '&Options'
      object Preferences1: TMenuItem
        Caption = '&Preferences...'
        OnClick = Preferences1Click
      end
    end
    object mDebug: TMenuItem
      Caption = '&Debug'
      object clTest: TMenuItem
        Caption = '&Test Alignment'
        OnClick = clTestClick
      end
      object NearestColor1: TMenuItem
        Caption = '&Nearest Color'
        OnClick = NearestColor1Click
      end
    end
    object Help1: TMenuItem
      Caption = '&Help'
      object About1: TMenuItem
        Caption = '&About...'
        OnClick = About1Click
      end
    end
  end
  object aeMain: TApplicationEvents
    OnActivate = aeMainActivate
    OnSettingChange = aeMainSettingChange
    Left = 8
    Top = 8
  end
  object pmCmdLine: TPopupMenu
    Left = 72
    Top = 8
    object Hide1: TMenuItem
      Caption = '&Hide Command Line'
      OnClick = Hide1Click
    end
  end
  object tmListViewMonitor: TTimer
    Enabled = False
    Interval = 250
    OnTimer = tmListViewMonitorTimer
    Left = 104
    Top = 8
  end
end
