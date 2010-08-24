object fProgress: TfProgress
  Left = 396
  Top = 391
  AlphaBlendValue = 50
  BorderStyle = bsSingle
  Caption = 'Progress Status'
  ClientHeight = 119
  ClientWidth = 308
  Color = clBtnFace
  Font.Charset = TURKISH_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 308
    Height = 20
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      308
      20)
    object lStatus: TLabel
      Left = 7
      Top = 4
      Width = 296
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Doing something'
    end
  end
  object pProgress: TPanel
    Left = 0
    Top = 20
    Width = 308
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      308
      41)
    object Label1: TLabel
      Left = 6
      Top = 25
      Width = 296
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Overall progress'
    end
    object pbProgress: TProgressBar
      Left = 6
      Top = 3
      Width = 296
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Min = 0
      Max = 100
      Smooth = True
      Step = 1
      TabOrder = 0
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 61
    Width = 308
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      308
      60)
    object pbOverallProgress: TProgressBar
      Left = 6
      Top = 3
      Width = 296
      Height = 17
      Anchors = [akLeft, akTop, akRight]
      Min = 0
      Max = 100
      Smooth = True
      Step = 1
      TabOrder = 0
    end
    object bCancel: TButton
      Left = 114
      Top = 27
      Width = 75
      Height = 25
      Caption = '&Cancel'
      TabOrder = 1
      OnClick = bCancelClick
    end
  end
end
