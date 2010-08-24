object fCopyTo: TfCopyTo
  Left = 438
  Top = 444
  BorderStyle = bsDialog
  Caption = 'Copy To...'
  ClientHeight = 95
  ClientWidth = 266
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 53
    Height = 13
    Caption = '&Destination'
  end
  object cbPath: TComboBox
    Left = 8
    Top = 24
    Width = 249
    Height = 21
    ItemHeight = 13
    TabOrder = 0
  end
  object bOK: TButton
    Left = 8
    Top = 64
    Width = 57
    Height = 25
    Caption = '&Ok'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object bCancel: TButton
    Left = 72
    Top = 64
    Width = 57
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
