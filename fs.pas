{ basic fs functions }

{$WARN SYMBOL_PLATFORM OFF}

unit fs;

interface

uses

  Classes, Windows, SysUtils, Contnrs;

const

  faBrowseable    = $10000000;
  faNonSelectable = $20000000;
  faCalculated    = $40000000;

  dirIndex : integer = -1;

  dateTimeFormatMask : string = 'mm/dd/yy hh:mm';

type

  EFSException = class(Exception);
  EFSChangeRequired = class(EFSException);

  TVolumeType = (vtUnknown, vtRemovable, vtFixed, vtRemote, vtArchive);

  TFSItemList = TThreadList;
  TFSVolumeList = TThreadList;
  TPanelList = TList;

  TFSItem = class(TObject)
    Name : string;
    Size : Int64;
    Date : TDateTime;
    Flags : integer;
    ImageIndex : integer;
    Selected : boolean;

    constructor Create;

    function SizeStr:string;
    function DateStr:string;
    function AttrStr:string;
  end;

  TFSInfo = class(TObject)
    Path : string;
    VolumeName : string;
    VolumeLabel : string;
    FileSystem : string;
    SerialNumber : string;
    VolumeType : TVolumeType;
    VolumeSize : Int64;
    FreeSpace : Int64;
    TotalFileSizes : Int64;
    Items : TFSItemList;

    constructor Create;
    destructor Destroy;override;

    procedure clearSelection;
  end;

  THandleWhat = (hNA,hFrom,hTo);
  THandleStatus = set of THandleWhat;

  PFileItem = ^TFileItem;
  TFileItem = packed record
    Source : string;
    Dest : string;
    Size : integer;
    Next : PFileItem;
  end;

  TFSHandlerClass = class of TFSHandler;
  TFSHandler = class(TObject)
    Info : TFSInfo;

    constructor Create;
    destructor Destroy;override;
    procedure OpenFS(const url:string);virtual;
    procedure setPath(const url:string);virtual;
    procedure setParent;virtual;
    procedure CloseFS;virtual;
    procedure ContextPopup(item:TFSItem; x,y:integer);virtual;abstract;
    function selectCopyDestination(var path:string):boolean;virtual;
    function selectMoveDestination(var path:string):boolean;virtual;

    procedure Rename(item:TFSItem; const newname:string);virtual;
    procedure Delete;virtual;
    procedure Copy(const dest:string);virtual;
    procedure Move(const dest:string);virtual;
    procedure MkDir(const dir:string);virtual;
    procedure Execute(item:TFSItem);virtual;
    procedure SetAttributes(item:TFSItem; newattr:integer);virtual;
    procedure SetDate(item:TFSItem; newdate:TDateTime);virtual;
    function SupportedAttributes:integer;virtual;
    function canHandleTransfer(afs:TFSHandler):THandleStatus;virtual;

    procedure readItemSize(item:TFSItem);virtual;
    procedure readVolumeInfo;virtual;
    procedure readItems;virtual;

    function getStream(item:TFSItem):TStream;virtual;abstract;

    procedure Refresh;virtual;

    function ContentsChanged : boolean;virtual;

    class function canHandle(const url:string):boolean;virtual;
    class function getName:string;virtual;
    procedure debug(s: string);

    procedure addParentDir;

    procedure DisposeFiles(root:PFileItem);
  end;

  TFSVolume = class(TObject)
    Path : string;
    Name : string;
    VolumeType : TVolumeType;
  end;

  TFSHandlerList = TClassList;

var
  VolumeList : TFSVolumeList;
  Panels : TPanelList;

  globSortColumn:integer;
  globSortOrder:boolean;

  FSHandlers : TFSHandlerList;

function readableSize(size:Int64):string;
function buildVolumeList(param:Pointer):integer;
function CompareItems(i1,i2:Pointer):integer;
function detectFSType(const url:string):TFSHandlerClass;

implementation

uses

  copytofrm, procs, fsnative,

  Forms, Controls, Dialogs, Math, DateUtils;

procedure TFSHandler.DisposeFiles;
var
  temp:PFileItem;
begin
  temp := root;
  while temp <> NIL do begin
    with temp^ do begin
      Source := EmptyStr;
      Dest := EmptyStr;
    end;
    root := temp;
    temp := temp.Next;
    Dispose(root);
  end;
end;

procedure TFSHandler.addParentDir;
var
  item:TFSItem;
begin
  item := TFSItem.Create;
  with item do begin
    item.Name := '..';
    item.Flags := faDirectory or faBrowseable or faNonSelectable;
  end;
  Info.Items.Add(item);
end;

class function TFSHandler.canHandle;
begin
  Result := true;
end;

class function TFSHandler.getName;
begin
  Result := '(null)';
end;

function detectFSType;
var
  n:integer;
  T:TFSHandlerClass;
begin
  for n:=0 to FSHandlers.Count-1 do begin
    TClass(T) := FSHandlers[n];
    if T.canHandle(url) then begin
      Result := T;
      exit;
    end;
  end;
  Result := NIL;
end;

function readableSize;
const
  kb = 1024;
  mb = kb*1024;
  gb = mb*1024;
  tb = gb*1024.0;
begin
  if size = 0 then Result := '' else
  if size < kb then Result := IntToStr(size) else
  if size < mb then Result := FloatToStrF(size/kb,ffFixed,3,1)+'k' else
  if size < gb then Result := FloatToStrF(size/mb,ffFixed,3,1)+'mb' else
  if size < tb then Result := FloatToStrF(size/gb,ffFixed,3,1)+'gb'
               else Result := FloatToStrF(size/tb,ffFixed,3,1)+'tb';
end;

function buildVolumeList;
begin
  try
    status('Reading volume information');
    VolumeList.Clear;
    TNativeFSHandler.fillVolumes(VolumeList.LockList);
    VolumeList.UnlockList;
    Result := 0;
    status('');
  except
    Result := -1;
  end;
end;

function CompareItems(i1,i2:Pointer):integer;
var
  it1,it2:TFSItem;
begin
  it1 := TFSItem(i1);
  it2 := TFSItem(i2);
  Result := CompareValue(it2.Flags and faDirectory,it1.Flags and faDirectory);
  if Result = 0 then begin
    if it1.Flags and faDirectory <> 0 then begin
      if it1.Name = '..' then begin
        if it2.Name = '..' then Result := 0 else Result := -1;
      end else if it2.Name = '..' then Result := 1;
    end;
    if Result = 0 then begin
      case globSortColumn of
        0 : Result := CompareText(it1.Name,it2.Name);
        else begin
          case globSortColumn of
            1 : begin
              if it1.Size < it2.Size then Result := -1 else
              if it1.Size = it2.Size then Result := 0 else Result := 1;
            end;
            2 : Result := CompareDateTime(it1.Date,it2.Date);
            else Result := 0;
          end;
          if Result = 0 then Result := CompareText(it1.Name,it2.Name);
        end;
      end; {case}
      if globSortOrder then Result := -Result;
    end;
  end;
end;

function TFSItem.DateStr;
begin
  if date <> 0 then Result := FormatDateTime(dateTimeFormatMask, Date) else Result := '';
end;

function TFSItem.SizeStr;
begin
  if (Size = 0) and (Flags and faDirectory > 0) then Result := '' else Result := FormatFloat('0,',size);
end;

function TFSItem.AttrStr;
  function g(c:char; attr:integer):char;
  begin
    if Flags and attr <> 0 then Result := c else Result := ' ';
  end;
begin
  Result := g('h',faHidden)+g('s',faSysFile)+g('r',faReadOnly)+g('a',faArchive);
end;

{ TFSInfo }

procedure TFSInfo.clearSelection;
var
  n:integer;
  l:TList;
begin
  with Items do begin
    l := LockList;
    for n:=0 to l.Count-1 do TFSItem(l[n]).Selected := false;
    UnlockList;
  end;
end;

constructor TFSInfo.Create;
begin
  inherited;
  Items := TFSItemList.Create;
end;

destructor TFSInfo.Destroy;
begin
  Items.Free;
  inherited;
end;

{ TFSHandler }

constructor TFSHandler.Create;
begin
  inherited;
  Info := TFSInfo.Create;
end;

destructor TFSHandler.Destroy;
begin
  if Info <> NIL then Info.Free;
  inherited;
end;

procedure TFSHandler.debug(s: string);
begin
  // TODO:
end;

procedure TFSHandler.setPath(const url: string);
begin
  Info.Path := url;
end;

procedure TFSHandler.Refresh;
begin
  readVolumeInfo;
  readItems;
  with Info.Items do begin
    LockList.Sort(CompareItems);
    UnlockList;
  end;
end;

procedure TFSHandler.CloseFS;
begin

end;

procedure TFSHandler.OpenFS(const url: string);
begin

end;

procedure TFSHandler.readItems;
begin

end;

procedure TFSHandler.readVolumeInfo;
begin

end;

procedure TFSHandler.setParent;
begin

end;

procedure TFSHandler.Rename(item: TFSItem; const newname: string);
begin

end;

procedure TFSHandler.Delete;
begin

end;

function TFSHandler.selectCopyDestination(var path: string): boolean;
var
  f:TfCopyTo;
begin
  Application.CreateForm(TfCopyTo,f);
  if f.ShowModal = mrOk then begin
    path := f.cbPath.Text;
    Result := true;
  end else Result := false;
  f.Free;
end;

function TFSHandler.selectMoveDestination(var path: string): boolean;
var
  f:TfCopyTo;
begin
  Application.CreateForm(TfCopyTo,f);
  f.Caption := 'Move to';
  if f.ShowModal = mrOk then begin
    path := f.cbPath.Text;
    Result := true;
  end else Result := false;
  f.Free;
end;

procedure TFSHandler.Copy(const dest: string);
begin

end;

procedure TFSHandler.readItemSize(item: TFSItem);
begin

end;

procedure TFSHandler.Move(const dest: string);
begin

end;

procedure TFSHandler.MkDir(const dir: string);
begin

end;

procedure TFSHandler.Execute;
begin
end;

function TFSHandler.canHandleTransfer;
begin
  if Self = afs then
    Result := [hFrom,hTo]
  else
    Result := [];
end;

function TFSHandler.ContentsChanged: boolean;
begin
  Result := false;
end;

constructor TFSItem.Create;
begin
  inherited;
  ImageIndex := -1;
end;

procedure TFSHandler.SetDate;
begin
end;

procedure TFSHandler.SetAttributes(item: TFSItem; newattr: integer);
begin

end;

function TFSHandler.SupportedAttributes: integer;
begin
  Result := 0;
end;

begin
  VolumeList := TFSVolumeList.Create;
  Panels := TPanelList.Create;
  FSHandlers := TFSHandlerList.Create;
end.
