object fSettings: TfSettings
  Left = 383
  Top = 372
  BorderStyle = bsDialog
  Caption = 'Preferences'
  ClientHeight = 305
  ClientWidth = 459
  Color = clBtnFace
  Font.Charset = TURKISH_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object bOK: TButton
    Left = 8
    Top = 272
    Width = 75
    Height = 25
    Caption = '&OK'
    Default = True
    TabOrder = 0
    OnClick = bOKClick
  end
  object bCancel: TButton
    Left = 88
    Top = 272
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object PageControl1: TPageControl
    Left = 8
    Top = 8
    Width = 441
    Height = 257
    ActivePage = TabSheet1
    TabIndex = 0
    TabOrder = 2
    object TabSheet1: TTabSheet
      Caption = '&General'
      object cbW2K: TCheckBox
        Left = 16
        Top = 16
        Width = 233
        Height = 17
        Caption = 'Use Windows 2000/&XP advanced features '
        TabOrder = 0
      end
      object cbAutoDirSize: TCheckBox
        Left = 16
        Top = 40
        Width = 233
        Height = 17
        Caption = 'Auto-calculate directory sizes on selection'
        TabOrder = 1
      end
      object GroupBox1: TGroupBox
        Left = 32
        Top = 72
        Width = 177
        Height = 105
        Caption = 'File Operations'
        TabOrder = 2
        object Label2: TLabel
          Left = 16
          Top = 24
          Width = 25
          Height = 13
          Caption = '&Copy'
        end
        object Label3: TLabel
          Left = 16
          Top = 48
          Width = 26
          Height = 13
          Caption = '&Move'
        end
        object Label4: TLabel
          Left = 16
          Top = 72
          Width = 31
          Height = 13
          Caption = '&Delete'
        end
        object cbCopyMethod: TComboBox
          Left = 64
          Top = 22
          Width = 97
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 0
          Text = 'Native (faster)'
          Items.Strings = (
            'Native (faster)'
            'Explorer')
        end
        object cbMoveMethod: TComboBox
          Left = 64
          Top = 46
          Width = 97
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 1
          Text = 'Native'
          Items.Strings = (
            'Native'
            'Explorer (faster)')
        end
        object cbDeleteMethod: TComboBox
          Left = 64
          Top = 70
          Width = 97
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          ItemIndex = 0
          TabOrder = 2
          Text = 'Native (faster)'
          Items.Strings = (
            'Native (faster)'
            'Recycle Bin')
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = '&Panels'
      ImageIndex = 1
      object Label1: TLabel
        Left = 16
        Top = 16
        Width = 84
        Height = 13
        Caption = 'Number of panels'
      end
      object lPanelCount: TLabel
        Left = 340
        Top = 16
        Width = 6
        Height = 13
        Caption = '2'
      end
      object tbPanelCount: TTrackBar
        Left = 112
        Top = 14
        Width = 225
        Height = 25
        Ctl3D = True
        Min = 2
        Orientation = trHorizontal
        ParentCtl3D = False
        Frequency = 1
        Position = 2
        SelEnd = 0
        SelStart = 0
        TabOrder = 0
        ThumbLength = 15
        TickMarks = tmBottomRight
        TickStyle = tsAuto
        OnChange = tbPanelCountChange
      end
    end
  end
end
