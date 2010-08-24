object fViewer: TfViewer
  Left = 352
  Top = 295
  Width = 491
  Height = 390
  Caption = 'FC Viewer'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object CoolBar1: TCoolBar
    Left = 0
    Top = 0
    Width = 483
    Height = 29
    AutoSize = True
    Bands = <
      item
        Control = ToolBar1
        ImageIndex = -1
        Width = 479
      end>
    object ToolBar1: TToolBar
      Left = 9
      Top = 0
      Width = 466
      Height = 25
      ButtonHeight = 21
      ButtonWidth = 39
      Caption = 'ToolBar1'
      EdgeBorders = []
      Flat = True
      ShowCaptions = True
      TabOrder = 0
      object tbWordWrap: TToolButton
        Left = 0
        Top = 0
        Caption = '&Wrap'
        ImageIndex = 0
        Style = tbsCheck
      end
      object ToolButton1: TToolButton
        Left = 39
        Top = 0
        Width = 8
        Caption = 'ToolButton1'
        ImageIndex = 1
        Style = tbsSeparator
      end
      object ToolButton2: TToolButton
        Left = 47
        Top = 0
        Caption = '&Close'
        ImageIndex = 1
        OnClick = ToolButton2Click
      end
      object ToolButton3: TToolButton
        Left = 86
        Top = 0
        Width = 8
        Caption = 'ToolButton3'
        ImageIndex = 2
        Style = tbsSeparator
      end
      object eFont: TEdit
        Left = 94
        Top = 0
        Width = 121
        Height = 21
        TabStop = False
        Color = clBtnFace
        ReadOnly = True
        TabOrder = 0
      end
      object bFontSelect: TButton
        Left = 215
        Top = 0
        Width = 18
        Height = 21
        Caption = '...'
        TabOrder = 1
      end
    end
  end
  object pContainer: TPanel
    Left = 0
    Top = 29
    Width = 483
    Height = 332
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object memText: TMemo
      Left = 0
      Top = 0
      Width = 466
      Height = 332
      Align = alClient
      Font.Charset = TURKISH_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Fixedsys'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
    end
    object sbText: TScrollBar
      Left = 466
      Top = 0
      Width = 17
      Height = 332
      Align = alRight
      Kind = sbVertical
      PageSize = 0
      TabOrder = 1
    end
  end
end
