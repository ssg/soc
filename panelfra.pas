{$WARN SYMBOL_PLATFORM OFF}
{$WARN UNIT_PLATFORM OFF}

unit panelfra;

interface

uses
  fs,

  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, ExtCtrls, ImgList, Buttons, ToolWin, Menus;

type
  TFilePanel = class(TFrame)
    pOuter: TPanel;
    pBottom: TPanel;
    lVolume: TLabel;
    lSelection: TLabel;
    lFree: TLabel;
    pSplitter: TPanel;
    hcFiles: THeaderControl;
    lvFiles: TListView;
    pTop: TPanel;
    sbDropDown: TSpeedButton;
    cbPath: TComboBox;
    pmDropDown: TPopupMenu;
    procedure lvFilesData(Sender: TObject; Item: TListItem);
    procedure lvFilesKeyPress(Sender: TObject; var Key: Char);
    procedure lvFilesDblClick(Sender: TObject);
    procedure lvFilesKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure lvFilesDataHint(Sender: TObject; StartIndex,
      EndIndex: Integer);
    procedure lvFilesContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure lvFilesEdited(Sender: TObject; Item: TListItem;
      var S: String);
    procedure lvFilesEditing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure FrameEnter(Sender: TObject);
    procedure lvFilesDeletion(Sender: TObject; Item: TListItem);
    procedure lvFilesMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FrameExit(Sender: TObject);
    procedure lvFilesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pSplitterMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pSplitterMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pSplitterMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure hcFilesSectionResize(HeaderControl: THeaderControl;
      Section: THeaderSection);
    procedure hcFilesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure hcFilesMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure hcFilesSectionClick(HeaderControl: THeaderControl;
      Section: THeaderSection);
    procedure lvFilesDrawItem(Sender: TCustomListView; Item: TListItem;
      Rect: TRect; State: TOwnerDrawState);
    procedure pmDropDownPopup(Sender: TObject);
    procedure DropDownClick(Sender: TObject);
    procedure sbDropDownClick(Sender: TObject);
  public
    Handler : TFSHandler;
    ilFiles : TImageList;
    Inspector : TThread;
    SortColumn : integer;
    SortOrder : boolean;
    notFirstSelect : boolean;
    selectValue : boolean;
    lastListViewWidth : integer;

    dragging:boolean;

    lockColResize:boolean;

    clix,cliy,clitime : integer;

    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;

    procedure readSettings;
    procedure saveSettings;

    procedure executeCurrent;
    procedure runCurrent;
    procedure browseCurrent;
    procedure doCopy;
    procedure doDelete;
    procedure doMove;
    procedure doMakeDir;
    procedure pickDirectory;
    procedure doView;
    procedure changeAttributes;

    procedure go(path:string);
    procedure goParent;
    procedure updateNewPath(ix:integer);

    procedure selectCurrent(movenext:boolean);
    procedure selectWild;
    procedure deselectWild;
    procedure selectAll;
    procedure deselectAll;
    function ensureSelection:boolean;
    procedure refreshVolumeList;
    procedure refreshVolumeInfo;
    procedure refreshSelectionInfo;
    procedure renameInPlace;
    procedure refreshContents;
    procedure refreshContentsIfChanged;
    procedure refreshCmdLine;
    procedure dropDriveList;

    function confirmDelete:boolean;

    function getCurrentItem:TFSItem;
    function getCurrentIndex:integer;
    function findIndex(const name:string):integer;
    procedure setFocused(ix:integer);

    procedure updateItem(item:TListItem);
    procedure refreshAllPanels;

    procedure stopInspector;
    procedure startInspector;

    procedure createHandler(fstype:TFSHandlerClass; const path:string);
    procedure fileSystemOverloadFunctionMichaelJackson(const path:string);

    procedure adjustListViewColumns;
    procedure adjustAllListViewColumns;

    procedure updateColumns;
  end;

  TInspector = class(TThread)
  public
    Owner : TFilePanel;

    constructor Create(AOwner:TFilePanel);
  protected
    procedure Execute;override;
  end;

  TRGB = packed record
    r,g,b,x:byte;
  end;

const

  activePanel : TFilePanel = NIL;
  maxColors = 8;

type

  TColorArray = array[1..maxColors] of TRGB;

var

  caNormal:TColorArray;
  caSelected:TColorArray;

procedure initColorArrays;

implementation

uses

  viewer, mainfrm, Procs, fsnative,

  UITypes, Types, FileCtrl, CommCtrl, ShellApi, ListActns;

{$R *.dfm}

procedure initColorArrays;

  procedure initPal(var ar:TColorArray; stc,etc:integer);
  var
    sta,eta:TRGB;
    n:integer;
  begin
    sta := TRGB(GetSysColor(stc));
    eta := TRGB(GetSysColor(etc));
    for n:=0 to maxColors-1 do begin
      with ar[n+1] do begin
  //      if sta.r < eta.r then
          R := sta.r+((n*(eta.r-sta.r)) div maxColors);
  //      else
  //        R := eta.r+((n*(sta.r-eta.r)) div mc);
  //      if sta.g < eta.g then
          G := sta.g+((n*(eta.g-sta.g)) div maxColors);
  //      else
  //        G := eta.g+((n*(sta.g-eta.g)) div mc);
  //      if sta.b < eta.b then
          B := sta.b+((n*(eta.b-sta.b)) div maxColors)
  //      else
  //        B := eta.b+((n*(sta.b-eta.b)) div mc);
      end;
    end;
  end;
begin
  initPal(caNormal,COLOR_WINDOWTEXT,COLOR_WINDOW);
  initPal(caSelected,COLOR_HIGHLIGHTTEXT,COLOR_HIGHLIGHT);
end;

{ TFilePanel }

procedure TFilePanel.updateColumns;
var
  n:integer;
begin
  with hcFiles,lvFiles do begin
    for n:=0 to Sections.Count-1 do begin
      Columns[n].Width := Sections[n].Width;
      if SortColumn = n then begin
        if SortOrder then
          Sections[n].ImageIndex := 0
        else
          Sections[n].ImageIndex := 1;
      end else Sections[n].ImageIndex := -1;
    end;
  end;
end;

procedure TFilePanel.createHandler;
begin
  Handler := fstype.Create;
  Handler.OpenFS(path);
end;

procedure TFilePanel.dropDriveList;
var
  T:TPoint;
begin
  T := ClientToScreen(Point(hcFiles.Left,hcFiles.Top));
  pmDropDown.Popup(T.X,T.Y);
end;

procedure TFilePanel.startInspector;
begin
  if getCfgBool('AutoDirSize',true) then begin
    if Inspector = NIL then begin
      Inspector := TInspector.Create(Self);
      Inspector.FreeOnTerminate := true;
    end;
  end;
end;

procedure TFilePanel.stopInspector;
begin
  if Inspector <> NIL then begin
    Inspector.Terminate;
    Inspector := NIL;
  end;
end;

procedure TFilePanel.doView;
var
  item:TFSItem;
begin
  item := GetCurrentItem;
  if item.Flags and faDirectory = 0 then
    ViewFile(Handler.Info.Path+item.Name);
end;

procedure TFilePanel.refreshContentsIfChanged;
begin
  if Handler.ContentsChanged then refreshContents;
end;

procedure TFilePanel.refreshAllPanels;
var
  n:integer;
begin
  for n:=0 to Panels.Count-1 do if TObject(Panels[n]) is TFilePanel then
    TFilePanel(Panels[n]).refreshContents;
end;

procedure TFilePanel.doMakeDir;
var
  dir:string;
begin
  dir := '';
  if InputQuery('Create Directory','Directory name',dir) then begin
    Handler.MkDir(dir);
    refreshAllPanels;
  end;
end;

procedure TFilePanel.doMove;
var
  dest:string;
begin
  if ensureSelection then begin
    if Handler.selectMoveDestination(dest) then begin
      try
        Handler.Move(dest);
      finally
        refreshAllPanels;
      end;
    end;
  end;
end;

procedure TFilePanel.doCopy;
var
  dest:string;
begin
  if ensureSelection then begin
    if Handler.selectCopyDestination(dest) then begin
      try
        Handler.Copy(dest);
      finally
        refreshAllPanels;
      end;
    end;
  end;
end;

function TFilePanel.findIndex;
var
  n:integer;
  it:TFSItem;
  l:TList;
begin
  Result := -1;
  with Handler.Info do begin
    l := Items.LockList;
    for n:=0 to l.Count-1 do begin
      it := TFSItem(l[n]);
      if AnsiCompareText(it.Name,name) = 0 then begin
        Items.UnlockList;
        Result := n;
        exit;
      end;
    end;
    Items.UnlockList;
  end;
end;

function TFilePanel.confirmDelete;
begin
  Result := MessageDlg('Are you sure to delete selected items?',mtConfirmation,[mbYes,mbNo],0) = mrYes;
end;

procedure TFilePanel.refreshSelectionInfo;
var
  n,count:integer;
  total:Int64;
  it:TFSItem;
  l:TList;
begin
  count := 0;
  total := 0;
  with Handler.Info do begin
    l := Items.LockList;
    for n:=0 to l.Count-1 do begin
      it := l[n];
      if it.Selected then begin
        inc(count);
        inc(total,it.Size);
      end;
    end;
    Items.UnlockList;
  end;
  if count = 0 then lSelection.Caption := '' else lSelection.Caption := IntToStr(count)+' item(s) selected ('+readableSize(total)+')';
end;

procedure TFilePanel.doDelete;
begin
  if ensureSelection then begin
    if confirmDelete then begin
      Handler.Delete;
      refreshAllPanels;
    end;
  end;
end;

procedure TFilePanel.refreshVolumeInfo;
var
  s:string;
begin
  with Handler.Info do begin
    if VolumeLabel <> '' then s := ' ['+VolumeLabel+']' else s := '';
    lVolume.Caption := VolumeName+s+' ['+FileSystem+'] '+ReadableSize(VolumeSize);
    s := ReadableSize(FreeSpace);
    if s <> '' then lFree.Caption := s+' free';
  end;
end;

procedure TFilePanel.refreshContents;
var
  i:integer;
begin
  i := GetCurrentIndex;
  go(Handler.Info.Path);
  if i >= 0 then
    with lvFiles do
      if i < Items.Count then setFocused(i);
end;

procedure TFilePanel.renameInPlace;
var
  item:TListItem;
begin
  with lvFiles do begin
    item := ItemFocused;
    lvFiles.Perform(LVM_EDITLABEL,item.Index,0);
  end;
end;

function TFilePanel.ensureSelection;
var
  n:integer;
  it:TFSItem;
  l:TList;
begin
  Result := true;
  with Handler.Info do begin
    l := Items.LockList;
    for n:=0 to l.Count-1 do begin
      if TFSItem(l[n]).Selected then exit;
    end;
    Items.UnlockList;
  end;
  Result := false;
  it := getCurrentItem;
  if (it <> NIL) and (it.Flags and faNonSelectable = 0) then begin
    it.Selected := true;
    n := lvFiles.ItemFocused.Index;
    lvFiles.UpdateItems(n,n);
    Result := true;
  end;
end;

procedure TFilePanel.selectWild;
var
  wild:string;
  it:TFSItem;
  n:integer;
  l:TList;
begin
  wild := '*.*';
  if InputQuery('Select Files','Files to select',wild) then
    with Handler.Info do begin
      l := Items.LockList;
      for n:=0 to l.Count-1 do begin
        it := l[n];
        if it.Flags and faNonSelectable = 0 then
          if matchWildcard(wild,it.Name) then it.Selected := true;
      end;
      Items.UnlockList;
      refreshSelectionInfo;
      lvFiles.Refresh;
    end;
end;

procedure TFilePanel.deselectWild;
var
  wild:string;
  it:TFSItem;
  n:integer;
  l:TList;
begin
  wild := '*.*';
  if InputQuery('De-select Files','Files to de-select',wild) then
    with Handler.Info do begin
      l := Items.LockList;
      for n:=0 to l.Count-1 do begin
        it := l[n];
        if it.Flags and faNonSelectable = 0 then
          if matchWildcard(wild,it.Name) then it.Selected := false;
      end;
      items.UnlockList;
      refreshSelectionInfo;
      lvFiles.Refresh;
    end;
end;

procedure TFilePanel.selectAll;
var
  n:integer;
  it:TFSItem;
  l:TList;
begin
  with Handler.Info do begin
    l := Items.LockList;
    for n:=0 to l.Count-1 do begin
      it := l[n];
      if it.Flags and faNonSelectable = 0 then
        it.Selected := not it.Selected;
    end;
    Items.UnlockList;
    refreshSelectionInfo;
    lvFiles.Refresh;
  end;
end;

procedure TFilePanel.deselectAll;
var
  n:integer;
  it:TFSItem;
  l:TList;
begin
  with Handler.Info do begin
    l := Items.LockList;
    for n:=0 to l.Count-1 do begin
      it := l[n];
      if it.Flags and faNonSelectable = 0 then
        it.Selected := false;
    end;
    Items.UnlockList;
    refreshSelectionInfo;
    lvFiles.Refresh;
  end;
end;

constructor TFilePanel.Create(AOwner: TComponent);
var
  sfi:TSHFileInfo;
begin
  inherited Create(AOwner);

  ilFiles := TImageList.Create(Self);
  ilFiles.Handle := SHGetFileInfo('C:\', 0, sfi,
      sizeof(TSHFileInfo), SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
  ilFiles.ShareImages := true;
  lvFiles.SmallImages := ilFiles;
  pmDropDown.Images := ilFiles;

  lvFiles.DoubleBuffered := true;
  hcFiles.DoubleBuffered := true;
  pBottom.DoubleBuffered := true;
  pTop.DoubleBuffered := true;
end;

procedure TFilePanel.readSettings;
var
  n:integer;
begin
  SortColumn := getCfgInt(Name+'_SortColumn',0);
  SortOrder := getCfgBool(Name+'_SortOrder',true);
  Width := getCfgInt(Name+'_Width',Width);

  with hcFiles do
    for n:=0 to Sections.Count-1 do
      Sections[n].Width := getCfgInt(Name+'_Col'+IntToStr(n)+'_Width',Sections[n].Width);

  updateColumns;
end;

procedure TFilePanel.saveSettings;
var
  n:integer;
begin
  putCfgInt(Name+'_SortColumn',SortColumn);
  putCfgBool(Name+'_SortOrder',SortOrder);
  putCfgInt(Name+'_Width',Width);

  putCfgStr(Name+'_Path',Handler.Info.Path);

  with hcFiles do
    for n:=0 to Sections.Count-1 do
      putCfgInt(Name+'_Col'+IntToStr(n)+'_Width',Sections[n].Width);
end;

procedure TFilePanel.refreshVolumeList;
var
  n:integer;
  it:TFSVolume;
  mi:TMenuItem;
  sfi:TSHFileInfo;
  s:string;
  l:TList;
begin
  with pmDropDown,pmDropDown.Items do begin
    Clear;
    l := VolumeList.LockList;
    for n:=0 to l.Count-1 do begin
      it := l[n];
      mi := TMenuItem.Create(Self);
      s := '&'+ExcludeTrailingPathDelimiter(it.Path);
      if it.Name <> '' then s := s + #9 +it.Name;
      mi.Caption := s;
      mi.OnClick := DropDownClick;
      if SHGetFileInfo(PChar(it.Path),0,sfi,SizeOf(sfi),
        SHGFI_SMALLICON or SHGFI_SYSICONINDEX) <> 0 then mi.ImageIndex := sfi.iIcon;
      Add(mi);
    end;
    VolumeList.UnlockList;
  end;
end;

function TFilePanel.getCurrentItem;
var
  it:TListItem;
begin
  it := lvFiles.ItemFocused;
  if it = NIL then Result := NIL
    else with Handler.Info.Items do begin
      Result := LockList[it.Index];
      UnlockList;
    end;
end;

function TFilePanel.getCurrentIndex;
var
  it:TListItem;
begin
  it := lvFiles.ItemFocused;
  if it = NIL then Result := -1 else Result := it.Index;
end;

procedure TFilePanel.executeCurrent;
var
  item:TFSItem;
begin
  item := getCurrentItem;
  if item = NIL then exit;
  if item.Flags and faBrowseable > 0 then browseCurrent else begin
    runCurrent;
    exit;
    if detectFSType(Handler.Info.Path+item.Name) = NIL
      then runCurrent
      else browseCurrent;
  end;
end;

procedure TFilePanel.browseCurrent;
var
  item:TFSItem;
begin
  item := getCurrentItem;
  if item = NIL then exit;
  with Item do if Name='..' then goParent else go(Handler.Info.Path+Name);
end;

procedure TFilePanel.runCurrent;
var
  item:TFSItem;
begin
  item := getCurrentItem;
  if item <> NIL then try
    Screen.Cursor := crHourGlass;
    Handler.Execute(item);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TFilePanel.lvFilesData(Sender: TObject; Item: TListItem);
begin
  if Handler = NIL then exit;
  updateItem(item);
end;

procedure TFilePanel.lvFilesKeyPress(Sender: TObject; var Key: Char);
begin
  case Key of
    #13 : executeCurrent;
{    'a'..'z','A'..'Z' : with fMain.eCmdLine do begin
      SetFocus;
      Text := Text + Key;
      SelStart := length(Text);
    end;}
  end;
end;

procedure TFilePanel.lvFilesDblClick(Sender: TObject);
begin
  executeCurrent;
end;

procedure TFilePanel.updateNewPath;
var
  cnt:integer;
begin
  with Handler.Info, Handler.Info.Items,lvFiles do begin
//    cbPath.Text := Path;
    cnt := LockList.Count;
    UnlockList;
    Items.Count := cnt;
    lvFiles.Invalidate;
    refreshVolumeInfo;
    refreshSelectionInfo;
    if Focused then refreshCmdLine;
    if (ix >= 0) and (ix < cnt) then setFocused(ix);
  end;
end;

procedure TFilePanel.go(path: string);
begin
  fileSystemOverloadFunctionMichaelJackson(path);
  with Handler do begin
    Screen.Cursor := crHourGlass;
    try
      stopInspector;
      setPath(path);
      Refresh;
      updateNewPath(0);
      startInspector;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TFilePanel.goParent;
var
  name:string;
begin
  with Handler do begin
    Screen.Cursor := crHourGlass;
    try
      stopInspector;
      name := ExtractFileName(ExcludeTrailingPathDelimiter(Info.Path));
      setParent;
    except
      on E:EFSChangeRequired do begin
        FileSystemOverloadFunctionMichaelJackson(E.Message);
        Handler.setPath(E.Message);
      end;
    end;
    try
      Handler.Refresh;
      updateNewPath(findIndex(name));
      startInspector;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TFilePanel.selectCurrent;
var
  item:TFSItem;
  i:integer;
begin
  item := getCurrentItem;
  if item <> NIL then if item.Flags and faNonSelectable = 0 then with lvFiles do begin
    item.Selected := not item.Selected;
    i := ItemFocused.Index;
    if moveNext then begin
      if i < Items.Count-1 then setFocused(i+1);
      UpdateItems(i,i+1);
    end else UpdateItems(i,i);
    refreshSelectionInfo;
  end;
end;

procedure TFilePanel.lvFilesKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if [ssCtrl]=Shift then begin
    // CTRL

    case Key of
      VK_PRIOR : goParent;
      VK_NEXT : browseCurrent;
      VK_F2 : changeAttributes;
      byte('R') : refreshContents;
      byte('G') : pickDirectory;
      else exit;
    end;
  end
  else if [ssShift]=Shift then begin
    // SHIFT

    case Key of
      VK_F6 : renameInPlace;
      else exit;
    end;
  end
  else begin
    // OTHER

    case Key of
      VK_INSERT : selectCurrent(true);
      VK_SPACE : selectCurrent(false);
      VK_F2 : renameInPlace;
      VK_F5 : doCopy;
      VK_F6 : doMove;
      VK_F3 : doView;
      VK_F7 : doMakeDir;
      VK_ADD : selectWild;
      VK_DELETE : doDelete;
      VK_SUBTRACT : deselectWild;
      VK_MULTIPLY : selectAll;
      VK_DIVIDE : deselectAll;
      else exit;
    end;
  end;
  Key := 0;
end;

procedure TFilePanel.lvFilesDataHint(Sender: TObject; StartIndex,
  EndIndex: Integer);
var
  n:integer;
begin
  if Handler = NIL then exit;
  for n:=StartIndex to EndIndex do updateItem(lvFiles.Items[n]);
end;

procedure TFilePanel.updateItem(item: TListItem);
var
  it:TFSItem;
  sfi:TSHFileInfo;
  l:TList;
begin
  with Handler,Item do begin
    l := Info.Items.LockList;
    if Index < l.Count then begin
      it := l[Index];
      Caption := it.Name;
      Selected := false;
      with SubItems,it do begin
        Add(SizeStr);
        Add(DateStr);
        Add(AttrStr);
        Cut := (Flags and (faSysFile or faHidden)) <> 0;
      end;
      if it.ImageIndex = -1 then begin
        if (dirIndex <> -1) and (it.Flags and faDirectory <> 0) then
          it.ImageIndex := dirIndex
        else begin
          if SHGetFileInfo(PChar(Info.Path+it.Name),0,sfi,SizeOf(sfi),
            SHGFI_SMALLICON or SHGFI_SYSICONINDEX) <> 0 then begin
            it.ImageIndex := sfi.iIcon;
            if it.Flags and faDirectory <> 0 then dirIndex := it.ImageIndex;
          end;
        end;
      end;
      ImageIndex := it.ImageIndex;
    end;
    Info.Items.UnlockList;
  end;
end;

procedure TFilePanel.lvFilesContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  item:TListItem;
  it:TFSItem;
begin
  item := lvFiles.GetItemAt(MousePos.X,MousePos.Y);
  if item = NIL then exit;
  with Handler,Handler.Info.Items do begin
    it := LockList[item.index];
    ContextPopup(it,MousePos.X,MousePos.Y);
    UnlockList;
  end;
end;

procedure TFilePanel.lvFilesEdited(Sender: TObject; Item: TListItem;
  var S: String);
begin
  with Handler,Handler.Info.Items do begin
    Rename(LockList[Item.Index],s);
    UnlockList;
  end;
end;

procedure TFilePanel.lvFilesEditing(Sender: TObject; Item: TListItem;
  var AllowEdit: Boolean);
begin
  AllowEdit := GetCurrentItem.Flags and faReadOnly = 0;
end;

procedure TFilePanel.FrameEnter(Sender: TObject);
begin
  activePanel := Self;
  refreshCmdLine;
end;

destructor TFilePanel.Destroy;
begin
  if Handler <> NIL then Handler.Free;
  inherited;
end;

procedure TFilePanel.pickDirectory;
var
  dir:string;
begin
  dir := Handler.Info.Path;
  if SelectDirectory('Go to Directory','',dir) then go(dir);
end;

procedure TFilePanel.setFocused(ix: integer);
begin
  with lvFiles do begin
    Items[ix].Focused := true;
    ItemFocused.MakeVisible(false);
  end;
end;

procedure TFilePanel.fileSystemOverloadFunctionMichaelJackson(
  const path: string);
var
  fstype:TFSHandlerClass;
begin
  fstype := DetectFSType(path);
  if Handler = NIL then begin
    createHandler(fstype,path);
  end else begin
    if fstype <> Handler.ClassType then begin
      Handler.CloseFS;
      Handler.Free;
      createHandler(fstype,path);
    end;
  end;
end;

procedure TFilePanel.adjustListViewColumns;
var
  n,tow:integer;
begin
  with hcFiles do begin
    tow := 0;
    for n:=1 to Sections.Count-1 do begin
      inc(tow,Sections[n].Width);
    end;
    Sections[0].Width := Width-tow-22;
  end;
  updateColumns;
end;

procedure TFilePanel.adjustAllListViewColumns;
var
  n:integer;
begin
  for n:=0 to Panels.Count-1 do if TObject(Panels[n]) is TFilePanel then
    TFilePanel(Panels[n]).adjustListViewColumns;
end;

procedure TFilePanel.lvFilesDeletion(Sender: TObject; Item: TListItem);
begin
  doDelete;
end;

procedure TFilePanel.lvFilesMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  item:TListItem;
  it:TFSItem;
begin
  if [ssLeft]=Shift then BeginDrag(false,5)
  else if [ssLeft,ssCtrl]=Shift then begin
    item := lvFiles.GetItemAt(X,Y);
    if item <> NIL then with Handler.Info.Items do begin
      it := LockList[item.Index];
      if it.Flags and faNonSelectable = 0 then begin
        if not notFirstSelect then begin
          notFirstSelect := true;
          selectValue := not it.Selected;
        end;
        it.Selected := selectValue;
      end;
      UnlockList;
      lvFiles.UpdateItems(item.Index,item.Index);
    end;
  end;
end;

procedure TFilePanel.FrameExit(Sender: TObject);
begin
//  cbPath.Color := clBtnFace;
end;

procedure TFilePanel.lvFilesMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  notFirstSelect := false;
end;

procedure TFilePanel.refreshCmdLine;
begin
  if Handler is TNativeFSHandler then
    with fMain,fMain.lCmdPrompt,Handler.Info do begin
      Caption := MinimizeName(Path,Canvas,200)+'>';
      activeDirectory := ExcludeTrailingPathDelimiter(Path);
    end;
end;

procedure TFilePanel.changeAttributes;
begin
  if ensureSelection then begin
  
  end;
end;

procedure TFilePanel.DropDownClick(Sender: TObject);
var
  n:integer;
  s:string;
begin
  with Sender as TMenuItem do begin
    s := Caption;
    n := pos(#9,s);
    if n > 0 then s := copy(s,1,n-1);
    System.Delete(s,1,1); // remove leading &
    go(IncludeTrailingPathDelimiter(s));
  end;
end;

{ TInspector }

constructor TInspector.Create(AOwner: TFilePanel);
begin
  inherited Create(true);
  Owner := AOwner;
  Priority := tpIdle;
  Resume;
end;

procedure TInspector.Execute;
var
  n:integer;
  it:TFSitem;
  l:TList;
begin
  with Owner.Handler,Owner.Handler.Info.Items do begin
    n := 0;
    repeat
      l := LockList;
      if l.Count = 0 then begin
        UnlockList;
      end else begin
        if n >= l.Count then n := 0;
        it := l[n];
        UnlockList;
        if it.Selected and (it.Size=0) and (it.Flags and (faDirectory or faCalculated) = faDirectory) and (it.Name<>'..') then begin
          status('Calculating directory size: '+it.Name);
          readItemSize(it);
          Owner.lvFiles.UpdateItems(n,n);
          status('');
        end;
        inc(n);
      end;
      Sleep(10);
    until Terminated;
  end;
end;

procedure TFilePanel.pSplitterMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Screen.Cursor := crHSplit;
  dragging := true;
  SetFocus;
end;

procedure TFilePanel.pSplitterMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  dragging := false;
  Screen.Cursor := crDefault;
  adjustAllListViewColumns;
end;

procedure TFilePanel.pSplitterMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if ([ssLeft]=Shift) and dragging then begin
    Width := pSplitter.ClientToScreen(Point(X,Y)).X-Parent.ClientToScreen(Point(Left,0)).X;
  end;
end;

procedure TFilePanel.hcFilesSectionResize(HeaderControl: THeaderControl;
  Section: THeaderSection);
begin
  if not lockColResize then begin
    lvFiles.Columns[Section.Index].Width := Section.Width;
    lvFiles.Invalidate;
  end else
    Section.Width := lvFiles.Columns[Section.Index].Width;
end;

procedure TFilePanel.hcFilesMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  t,d,n,maxw:integer;
  it:TFSItem;
  l:TList;
begin
  if [ssLeft]=Shift then begin
    t := GetTickCount;
    d := GetDoubleClickTime;
    if (abs(X-clix) < 5) and (abs(Y-cliy) < 5) and (t-clitime < d) then begin
      with Handler.Info.Items do begin
        maxw := 0;
        l := LockList;
        for n := 0 to l.Count-1 do with lvFiles.Canvas do begin
          it := TFSItem(l[n]);
          t := TextWidth(it.Name);
          if t > maxw then maxw := t;
        end;
        UnlockList;
        if maxw > 0 then begin
          lockColResize := true;
          hcFiles.Sections[0].Width := maxw + 30;
          updateColumns;      
        end;
      end;
    end else begin
      clitime := t;
      clix := X;
      cliy := Y;
    end;
  end;
end;

procedure TFilePanel.hcFilesMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  lockColResize := false;
end;

procedure TFilePanel.hcFilesSectionClick(HeaderControl: THeaderControl;
  Section: THeaderSection);
begin
  if SortColumn <> Section.Index then SortOrder := true else SortOrder := not SortOrder;
  SortColumn := Section.Index;
  globSortColumn := SortColumn;
  globSortOrder := SortOrder;
  with Handler.Info.Items do begin
    LockList.Sort(CompareItems);
    UnlockList;
  end;
  lvFiles.Invalidate;
  updateColumns;
end;

procedure TFilePanel.lvFilesDrawItem(Sender: TCustomListView;
  Item: TListItem; Rect: TRect; State: TOwnerDrawState);
var
  l:TList;
  ii,tw,cw,siw:integer;
  style:TDrawingStyle;
  sel:boolean;
  tr:TRect;
  s,si0:string;
  fc:TColor;
  n:integer;
const
  partsize = 4;
begin
  with Handler.Info.Items do begin
    l := LockList;
    sel := TFSItem(l[Item.Index]).Selected;
    UnlockList;
  end;
  with lvFiles,lvFiles.Canvas,Item do begin
    if sel then begin
      Brush.Color := clHighlight;
      Font.Color := clHighlightText;
      fc := clHighlightText;
      FillRect(Rect);
    end else fc := clWindowText;

    ii := ImageIndex;
    if ii >= 0 then begin
      if Cut then style := dsSelected
        else if sel then style := dsFocus
        else style := dsNormal;
      SmallImages.Draw(lvFiles.Canvas,Rect.Left,Rect.Top,ii,style,itImage);
    end;

    s := Caption;
    tw := TextWidth(s);
    si0 := SubItems[0];
    siw := TextWidth(si0);
    cw := (Columns[0].Width-16)+(Columns[1].Width-siw);

    tr := Rect;
    inc(tr.Left,16);

    if tw > cw then begin
      tr.Right := tr.Left+cw;
{      if tr.Right < 16 then tr.Right := 16;
      TextRect(tr,tr.Left+2,tr.Top+2,s);
      for n:=1 to maxColors do begin
        tr.Left := tr.Right;
        tr.Right := tr.Left+partsize;
        if sel then
          Font.Color := TColor(caSelected[n])
        else
          Font.Color := TColor(caNormal[n]);
        TextRect(tr,Rect.Left+18,Rect.Top+2,s);
      end;}
    end else begin
      tr.Right := tr.Left+tw+2;
    end;
    TextRect(tr,tr.Left+2,tr.Top+2,s);

    Font.Color := fc;
    tr.Left := cw+14;
    tr.Right := cw+14+siw;
    TextOut(cw+10,tr.Top+2,si0);

    for n:=1 to SubItems.Count-1 do begin
      tr.Left := tr.Right;
      tr.Right := tr.Left + Columns[n+1].Width;
      TextRect(tr,tr.Left,tr.Top+2,SubItems[n]);
    end;

    if Sender.Focused then begin
      if (odFocused in State) then DrawFocusRect(Rect);
    end;
  end;
end;

procedure TFilePanel.pmDropDownPopup(Sender: TObject);
begin
  refreshVolumeList;
end;

procedure TFilePanel.sbDropDownClick(Sender: TObject);
begin
  dropDriveList;
end;

end.
