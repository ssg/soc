object FilePanel: TFilePanel
  Left = 0
  Top = 0
  Width = 325
  Height = 360
  Constraints.MinWidth = 50
  TabOrder = 0
  OnEnter = FrameEnter
  OnExit = FrameExit
  object pOuter: TPanel
    Left = 0
    Top = 0
    Width = 321
    Height = 360
    Align = alClient
    BevelOuter = bvNone
    Caption = 'pOuter'
    TabOrder = 0
    object pBottom: TPanel
      Left = 0
      Top = 326
      Width = 321
      Height = 34
      Align = alBottom
      BevelInner = bvLowered
      BevelOuter = bvNone
      TabOrder = 0
      DesignSize = (
        321
        34)
      object lFree: TLabel
        Left = 4
        Top = 18
        Width = 313
        Height = 13
        Alignment = taRightJustify
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
      end
      object lVolume: TLabel
        Left = 5
        Top = 18
        Width = 3
        Height = 13
      end
      object lSelection: TLabel
        Left = 5
        Top = 3
        Width = 3
        Height = 13
      end
    end
    object hcFiles: THeaderControl
      Left = 0
      Top = 26
      Width = 321
      Height = 17
      Sections = <
        item
          BiDiMode = bdLeftToRight
          ImageIndex = -1
          MinWidth = 30
          ParentBiDiMode = False
          Text = 'Name'
          Width = 100
        end
        item
          Alignment = taRightJustify
          ImageIndex = -1
          Text = 'Size'
          Width = 100
        end
        item
          ImageIndex = -1
          Text = 'Date'
          Width = 80
        end
        item
          ImageIndex = -1
          Text = 'Attr'
          Width = 40
        end>
      OnSectionClick = hcFilesSectionClick
      OnSectionResize = hcFilesSectionResize
      OnMouseDown = hcFilesMouseDown
      OnMouseUp = hcFilesMouseUp
    end
    object lvFiles: TListView
      Left = 0
      Top = 43
      Width = 321
      Height = 283
      Align = alClient
      BevelInner = bvNone
      BevelOuter = bvNone
      Columns = <
        item
          Caption = 'Name'
          Width = 130
        end
        item
          Alignment = taRightJustify
          Caption = 'Size'
          Width = 80
        end
        item
          Caption = 'Date'
          Width = 66
        end
        item
          Caption = 'Attr'
          Width = 40
        end>
      OwnerData = True
      OwnerDraw = True
      RowSelect = True
      ShowColumnHeaders = False
      TabOrder = 2
      ViewStyle = vsReport
      OnContextPopup = lvFilesContextPopup
      OnData = lvFilesData
      OnDataHint = lvFilesDataHint
      OnDblClick = lvFilesDblClick
      OnDeletion = lvFilesDeletion
      OnDrawItem = lvFilesDrawItem
      OnEdited = lvFilesEdited
      OnEditing = lvFilesEditing
      OnKeyDown = lvFilesKeyDown
      OnKeyPress = lvFilesKeyPress
      OnMouseDown = lvFilesMouseDown
      OnMouseMove = lvFilesMouseMove
    end
    object pTop: TPanel
      Left = 0
      Top = 0
      Width = 321
      Height = 26
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 3
      object sbDropDown: TSpeedButton
        Left = 3
        Top = 3
        Width = 18
        Height = 20
        Flat = True
        Glyph.Data = {
          F6000000424DF600000000000000760000002800000010000000100000000100
          0400000000008000000000000000000000001000000000000000000000000000
          8000008000000080800080000000800080008080000080808000C0C0C0000000
          FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00DDDDDDDDDDDD
          DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
          DDDDDDDDDDDDDDDDDDDDDDDDDDDDFDDDDDDDDDDDDDD7DFDDDDDDDDDDDD7DDDFD
          DDDDDDDDD7DDDDDFDDDDDDDD77777777FDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
          DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD}
        OnClick = sbDropDownClick
      end
      object cbPath: TComboBox
        Left = 24
        Top = 2
        Width = 293
        Height = 21
        Style = csDropDownList
        TabOrder = 0
      end
    end
  end
  object pSplitter: TPanel
    Left = 321
    Top = 0
    Width = 4
    Height = 360
    Cursor = crHSplit
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 1
    Visible = False
    OnMouseDown = pSplitterMouseDown
    OnMouseMove = pSplitterMouseMove
    OnMouseUp = pSplitterMouseUp
  end
  object pmDropDown: TPopupMenu
    OnPopup = pmDropDownPopup
    Left = 280
    Top = 48
  end
end
