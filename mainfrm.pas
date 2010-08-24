{
SSG's own commander

to do's
-------
- read-only overwrite attribute reset or confirmation
- confirmation on system file / read only overwrite (both copy/move and delete)
- enhance multi-threaded operations
- setPath & go should support EFSChangeRequired
- nativefs context popup explorer (sh pidl)
- implement drag&drop
- perfect file viewer
- perfect zip handler
- backup cleranup...
- file search
- change file attributes
- change filename casing
- compare directory
- synchronize dirs
- ftp handler
- http handler
- overwrite all older
- file list view filters (programs only / all files / custom)
- brief listing
- tree view
- alternate drive drop down list
- multiple file operation method options (explorer / native)
- import/export configuration..
}

{$WARN SYMBOL_PLATFORM OFF}

unit mainfrm;

interface

uses
  fs,

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Contnrs, ExtCtrls, Dialogs, Menus, ComCtrls, AppEvnts, StdCtrls;

type
  TfMain = class(TForm)
    mmMain: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    sbMain: TStatusBar;
    N1: TMenuItem;
    aeMain: TApplicationEvents;
    Options1: TMenuItem;
    Preferences1: TMenuItem;
    pCmdLine: TPanel;
    Panel1: TPanel;
    lCmdPrompt: TLabel;
    Panel2: TPanel;
    eCmdLine: TEdit;
    pmCmdLine: TPopupMenu;
    Hide1: TMenuItem;
    View1: TMenuItem;
    mViewCmdLine: TMenuItem;
    ChangeAttributes1: TMenuItem;
    tmListViewMonitor: TTimer;
    mDebug: TMenuItem;
    clTest: TMenuItem;
    NearestColor1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure aeMainActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Preferences1Click(Sender: TObject);
    procedure eCmdLineKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Hide1Click(Sender: TObject);
    procedure pCmdLineContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure mViewCmdLineClick(Sender: TObject);
    procedure tmListViewMonitorTimer(Sender: TObject);
    procedure clTestClick(Sender: TObject);
    procedure NearestColor1Click(Sender: TObject);
    procedure aeMainSettingChange(Sender: TObject; Flag: Integer;
      const Section: String; var Result: Integer);
  public
    activeDirectory : string;
    origWidth : integer;

    procedure DropFilesHandler(var Msg:TMessage);message WM_DROPFILES;
    procedure InitPanels;
    procedure addPanel;
    procedure removePanel;
    procedure adjustPanelSizes;
    procedure adjustNewPanelCount;
    procedure dropDriveList(panel:integer);
  end;

var
  fMain: TfMain;

implementation

uses

  fsnative, fszip,

  ShellAPI, procs, panelfra, settings;

{$R *.dfm}

procedure TfMain.removePanel;
var
  T:TFrame;
begin
  if Panels.Count = 2 then exit;
  T := Panels[Panels.Count-1];
  try
    Panels.Delete(Panels.Count-1);
    Panels.Pack;
  finally
    T.Free;
  end;
end;

procedure TfMain.adjustNewPanelCount;
var
  newcount:integer;
begin
  newcount := getCfgInt('PanelCount',2);
  if newcount = defaultPanels then exit;

  while defaultPanels > newcount do begin
    removePanel;
    dec(defaultPanels);
  end;

  if defaultPanels < newcount then begin
    while defaultPanels < newcount do begin
      addPanel;
      inc(defaultPanels);
    end;
  end;

  adjustPanelSizes;
end;

procedure TfMain.addPanel;
var
  T,F:TFilePanel;
  c:string;
  lw:integer;
begin
  c := IntToStr(Panels.Count+1);

  if Panels.Count > 0 then begin
    F := TFilePanel(Panels[Panels.Count-1]);
    if F.Align=alClient then F.Align := alLeft;
//    F.pSplitter.Visible := true;
    lw := F.Left+F.Width+5;
  end else lw := 5;

  T := TFilePanel.Create(Self);
  T.Name := 'p'+c;
  T.readSettings;
  T.Parent := Self;
  T.Left := lw+5;
  T.Align := alLeft;

  Panels.Add(T);

  try
    T.go(getCfgStr(T.Name+'_Path','C:\'));
  except
    try
      T.go('C:\');
    except
      on E:Exception do
        MessageDlg('Oha: '+E.Message,mtError,[mbOk],0);
    end;
  end;
end;

procedure TfMain.dropDriveList;
begin
  if (panel < panels.Count) and (TObject(panels[panel]) is TFilePanel) then
    TFilePanel(panels[panel]).dropDriveList;
end;

procedure TfMain.adjustPanelSizes;
var
  T:TFilePanel;
  n,pc:integer;
begin
  pc := Panels.Count;
  if pc < 2 then exit;
  T := TFilePanel(Panels[pc-1]);
  if T.Align <> alClient then T.Align := alClient;
  if origWidth <> Width then begin
    for n:=0 to pc-2 do begin
      T := TFilePanel(Panels[n]);
//      T.Width := MulDiv(T.Width,Width,origWidth);
      T.Width := ClientWidth div pc;
    end;
    origWidth := Width;
  end;
  tmListViewMonitor.Enabled := true;
end;

procedure TfMain.InitPanels;
var
  n:integer;
begin
  Panels.Capacity := defaultPanels;

  for n:=1 to defaultPanels do addPanel;

  adjustPanelSizes;
end;

procedure TfMain.FormCreate(Sender: TObject);
var
  id:Cardinal;

  procedure InitRegionalSettings;
  begin
{    DecimalSeparator := '.';
    ThousandSeparator := ',';
    DateSeparator := '/';
    ShortDateFormat := 'mm/dd/yyyy';}
  end;

  procedure InitHandlers;
  begin
    FSHandlers.Add(TZIPHandler);
    FSHandlers.Add(TNativeFSHandler);
  end;

  procedure LoadView;
  begin
    pCmdLine.Visible := getCfgBool('CmdLine',true);
    mViewCmdLine.Checked := pCmdLine.Visible;
  end;

  procedure InitCmdLine;
  begin
    pCmdLine.DoubleBuffered := true;
  end;

  procedure InitDebug;
  begin
    debugging := (ParamCount > 0) and (ParamStr(1) = 'debug');
    mDebug.Visible := debugging;
  end;

begin
  SetErrorMode(SEM_FAILCRITICALERRORS);
  InitDebug;
  InitColorArrays;
  InitRegionalSettings;
  InitHandlers;
  BeginThread(NIL,0,buildVolumeList,NIL,0,id);
  readFormState(Self);
  origWidth := Width;
  InitPanels;
  LoadView;
  InitCmdLine;
  DragAcceptFiles(Handle,true);
  sbMain.DoubleBuffered := true;
end;

procedure TfMain.FormResize(Sender: TObject);
begin
  adjustPanelSizes;
end;

procedure TfMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Shift=[ssAlt] then begin
    case Key of
      VK_F1 : dropDriveList(0);
      VK_F2 : dropDriveList(1);
      VK_F3 : dropDriveList(2);
      else exit;
    end
  end
  else
  if Shift=[ssCtrl] then begin
    case Key of
      byte('A') : begin
        addPanel;
        adjustPanelSizes;
      end;
      byte('D') : begin
        removePanel;
        adjustPanelSizes;
      end;
      else exit;
    end
  end
  else exit;
  Key := 0;
end;

procedure TfMain.aeMainActivate(Sender: TObject);
var
  n:integer;
begin
  for n:=0 to Panels.Count-1 do
    if TObject(Panels[n]) is TFilePanel then
      TFilePanel(Panels[n]).refreshContentsIfChanged;
end;

procedure TfMain.FormShow(Sender: TObject);
begin
//  if w2k then status('Windows 2000 extensions enabled');
end;

procedure TfMain.About1Click(Sender: TObject);
begin
  MessageBox(Handle,PChar('SSG''s Own Commander'#13'Version '+appVer+#13#13+
    'Coded by Sedat "SSG" Kapanoglu'#13#13+
    'Copyright © 2002 - All Rights Reserved'), 'About', MB_ICONINFORMATION);
end;

procedure TfMain.DropFilesHandler(var Msg: TMessage);
var
  T:TPoint;
  n,w,cnt,subn:integer;
  P:TFilePanel;
  buf:array[0..MAX_PATH-1] of char;
begin
  w := Msg.WParam;
  DragQueryPoint(w,T);
  for n:=0 to Panels.Count-1 do begin
    if TObject(Panels[n]) is TFilePanel then begin
      P := TFilePanel(Panels[n]);
      if PtInRect(P.BoundsRect,T) then begin
        cnt := DragQueryFile(w,$FFFFFFFF,NIL,0);
        for subn := 0 to cnt-1 do begin
          DragQueryFile(w,subn,@buf,SizeOf(buf));
          ShowMessage(StrPas(@buf));
        end;
        break;
      end;
    end;
  end;
  DragFinish(w);
end;

procedure TfMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  n:integer;

  procedure SaveView;
  begin
    putCfgBool('CmdLine',pCmdLine.Visible);
  end;
begin
  for n:=0 to Panels.Count-1 do
    if TObject(Panels[n]) is TFilePanel then TFilePanel(Panels[n]).saveSettings;
  SaveFormState(Self);
  SaveView;
end;

procedure TfMain.Preferences1Click(Sender: TObject);
begin
  Application.CreateForm(TfSettings,fSettings);
  if fSettings.ShowModal = mrOK then begin
    adjustNewPanelCount;
  end;
  fSettings.Free;
end;

procedure TfMain.eCmdLineKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  si:TStartupInfo;
  pi:TProcessInformation;
begin
  if (Key = VK_RETURN) and (Shift=[]) then begin
    FillChar(si,SizeOf(si),0);
    si.cb := SizeOf(si);
    si.wShowWindow := SW_SHOW;
    if not CreateProcess(PChar(getEnv('COMSPEC')),PChar('/C '+eCmdLine.Text),
      NIL,NIL,false,CREATE_DEFAULT_ERROR_MODE,NIL,PChar(activeDirectory),si,pi) then
      raiseLastOSError
    else
      eCmdLine.Text := '';
  end;
end;

procedure TfMain.Hide1Click(Sender: TObject);
begin
  pCmdLine.Hide;
  mViewCmdLine.Checked := false;
end;

procedure TfMain.pCmdLineContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
begin
  with pCmdLine.ClientToScreen(MousePos) do begin
    pmCmdLine.Popup(X,Y);
    Handled := true;
  end;
end;

procedure TfMain.mViewCmdLineClick(Sender: TObject);
begin
  pCmdLine.Visible := not mViewCmdLine.Checked;
  mViewCmdLine.Checked := pCmdLine.Visible;
end;

procedure TfMain.tmListViewMonitorTimer(Sender: TObject);
var
  n:integer;
begin
  tmListViewMonitor.Enabled := false;
  for n:=0 to Panels.Count-1 do if TObject(Panels[n]) is TFilePanel then
    TFilePanel(Panels[n]).adjustListViewColumns;
end;

procedure TfMain.clTestClick(Sender: TObject);
begin
  TFilePanel(Panels[Panels.Count-1]).Align := alClient;
end;

procedure TfMain.NearestColor1Click(Sender: TObject);
var
  T:TColor;
begin
  T := GetSysColor(COLOR_WINDOW);
  ShowMessage('$'+IntToHex(DWORD(T),8));
end;

procedure TfMain.aeMainSettingChange(Sender: TObject; Flag: Integer;
  const Section: String; var Result: Integer);
begin
  InitColorArrays;
  Result := 0;
end;

end.
