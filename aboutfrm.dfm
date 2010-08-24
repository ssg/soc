object fAbout: TfAbout
  Left = 365
  Top = 427
  BorderStyle = bsDialog
  Caption = 'About'
  ClientHeight = 134
  ClientWidth = 322
  Color = clBtnFace
  Font.Charset = TURKISH_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  DesignSize = (
    322
    134)
  PixelsPerInch = 96
  TextHeight = 13
  object lAppName: TLabel
    Left = 8
    Top = 8
    Width = 305
    Height = 13
    Alignment = taCenter
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Allah Belani Versin Commander'
  end
  object Label1: TLabel
    Left = 8
    Top = 32
    Width = 305
    Height = 13
    Alignment = taCenter
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 'Coded by Sedat "SSG" Kapanoglu'
  end
  object Label2: TLabel
    Left = 8
    Top = 56
    Width = 305
    Height = 33
    Alignment = taCenter
    Anchors = [akLeft, akTop, akRight]
    AutoSize = False
    Caption = 
      'Dedicated to those who believed in me. Thanks for pen and papers' +
      '. Thanks for letting me in.'
    WordWrap = True
  end
  object bClose: TButton
    Left = 128
    Top = 104
    Width = 75
    Height = 25
    Caption = '&Ok'
    ModalResult = 1
    TabOrder = 0
  end
end
