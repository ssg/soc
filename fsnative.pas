{
Win32 FS Implementation
}

{$WARN SYMBOL_PLATFORM OFF}

unit fsnative;

interface

uses

  Classes, fs;

type

  TChangeMonitor = class;

  TFileBuildMode = (fbmCopy, fbmMove, fbmDelete);

  TNativeFSHandler = class(TFSHandler)
  private
    Root : string;
    procedure CopyExplorer(const dest: string);
    procedure MoveExplorer(const dest: string);
    procedure MoveNative(const dest: string);
    procedure DeleteExplorer;
    procedure DeleteNative;
  public
    hNotif : THandle;
    hWait : THandle;
    Changed : boolean;
    Monitor : TChangeMonitor;

    destructor Destroy;override;
    procedure OpenFS(const url:string);override;
    procedure readVolumeInfo;override;
    procedure readItems;override;
    procedure setParent;override;
    procedure setPath(const url:string);override;
    procedure ContextPopup(item:TFSItem; x,y:integer);override;
    procedure readItemSize(item:TFSItem);override;
    function ContentsChanged:boolean;override;

    procedure Rename(item:TFSItem; const newname:string);override;
    procedure Delete;override;
    procedure Copy(const dest:string);override;
    procedure Move(const dest:string);override;
    procedure MkDir(const dir:string);override;
    procedure Execute(item:TFSItem);override;
    function getStream(item:TFSItem):TStream;override;
    procedure SetDate(item:TFSItem; newdate:TDateTime);override;
    procedure setAttributes(item:TFSItem; newattr:integer);override;
    function supportedAttributes:integer;override;

    class procedure fillVolumes(list:TList);
    class function canHandle(const url:string):boolean;override;
    class function getName:string;override;

    procedure InitChangeDetection;
    procedure DoneChangeDetection;

    function BuildFiles(const dest:string; var count:integer;
      var totalSize:Int64; buildMode:TFileBuildMode):PFileItem;
  end;

  TChangeMonitor = class(TThread)
  public
    Path : string;
    Changed : boolean;
    hNotif : THandle;
    constructor Create(const APath:string);
  protected
    procedure Execute;override;
  end;

implementation

uses

  progressfrm, procs,

  Controls, Dialogs, ShellApi, Windows, SysUtils;

const

  kernel32 = 'kernel32.dll';

  COPY_ABORTED        = 1235;
  COPY_ALREADY_EXISTS = 80;
  COPY_ALREADY_EXISTS_FAIL = 183;

  FINDFIRST_EMPTY = 6;

type
  WAITORTIMERCALLBACK = procedure(lpParameter:Pointer; TimerOrWaitFired:boolean);stdcall;
  TWaitOrTimerCallback = WAITORTIMERCALLBACK;

  TRegisterWaitForSingleObject = function(phNewWaitObject:PHandle;
  hObject:THandle; Callback:TWaitOrTimerCallback; Context:Pointer;
  dwMilliseconds:Cardinal; dwFlags:Cardinal):boolean;stdcall;

  TUnregisterWait = function(WaitHandle:THandle):boolean;stdcall;

  TCopyFileEx = function(lpExistingFileName,lpNewFileName:PChar;
    lpProgressRoutine,lpData:Pointer; pbCancel:PBOOL;
    dwCopyFlags:DWORD):boolean;stdcall;

const
  RegisterWaitForSingleObject : TRegisterWaitForSingleObject=NIL;
  UnregisterWait : TUnregisterWait=NIL;
  CopyFileEx : TCopyFileEx = NIL;

procedure NotifCallBack(lpParameter:Pointer; TimeOrWaitFired:boolean);stdcall;
begin
  if not TimeOrWaitFired then
    with TNativeFSHandler(lpParameter) do begin
      Changed := true;
      FindNextChangeNotification(hNotif);
    end;
end;

{ TNativeFSHandler }

function TNativeFSHandler.BuildFiles;
var
  n:integer;
  l:TList;
  item:TFSItem;
  root,tail:PFileItem;
  function createItem(const src,dst:string; size:integer):PFileItem;
  begin
    New(Result);
    Result.Source := src;
    Result.Dest := dst;
    Result.Size := size;
    Result.Next := NIL;
  end;

  procedure addf(const sfn,dfn:string; size:integer);
  var
    P:PFileItem;
  begin
    P := createItem(sfn,dfn,size);
    if root = NIL then begin
      root := P;
      tail := P;
    end else begin
      tail.Next := P;
      tail := P;
    end;
    inc(count);
  end;

  procedure addd(const srcpath,dstpath:string);
  var
    rec:TSearchRec;
  begin
    if buildMode in [fbmCopy,fbmMove] then addf('',dstpath,0);

    if FindFirst(srcpath+'\*.*',faAnyFile,rec) = 0 then repeat
      if rec.Attr and faDirectory <> 0 then begin
        if (rec.Name[1] <> '.') and (rec.Name <> '..') then begin
          addd(srcpath+'\'+rec.Name,dstpath+'\'+rec.Name);
        end;
      end else begin
        if buildMode = fbmDelete then
          addf(PChar(srcpath+'\'+rec.Name),'',rec.Size)
        else
          addf(PChar(srcpath+'\'+rec.Name),dstpath+'\'+rec.Name,rec.Size);
        inc(totalSize,(rec.FindData.nFileSizeLow) or (rec.FindData.nFileSizeHigh shl 32));
      end;
    until FindNext(rec) <> 0;
    FindClose(rec);
    case buildMode of
      fbmMove : addf(srcpath,'',0);
      fbmDelete : addf('',srcpath,0);
    end;
  end;

begin
  l := Info.Items.LockList;
  root := NIL;
  tail := NIL;
  totalSize := 0;
  count := 0;
  for n:=0 to l.Count-1 do begin
    item := l[n];
    if item.Selected then begin
      if item.Flags and faDirectory <> 0 then begin
        addd(Info.Path+item.Name,dest+item.Name);
      end else begin
        if buildMode = fbmDelete then
          addf(Info.Path+item.Name,'',item.Size)
        else
          addf(Info.Path+item.Name,dest+item.Name,item.Size);
        inc(totalSize,item.Size);
      end;
    end;
  end;
  Result := root;
  Info.Items.UnlockList;
end;

class function TNativeFSHandler.canHandle;
begin
  Result := true;
end;

class function TNativeFSHandler.getName;
begin
  Result := 'Win32';
end;

function TNativeFSHandler.getStream;
begin
  try
    Result := TFileStream.Create(Info.Path+Item.Name,fmOpenRead);
  except
    Result := NIL;
  end;
end;

procedure TNativeFSHandler.InitChangeDetection;
begin
  if w2k then begin
    hNotif := FindFirstChangeNotification(PChar(ExcludeTrailingPathDelimiter(Info.Path)),false,
      FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_DIR_NAME or
      FILE_NOTIFY_CHANGE_ATTRIBUTES or FILE_NOTIFY_CHANGE_SIZE or
      FILE_NOTIFY_CHANGE_LAST_WRITE);
    if hNotif <> INVALID_HANDLE_VALUE then
      RegisterWaitForSingleObject(@hWait,hNotif,NotifCallBack,Self,INFINITE,0);
  end else begin
    Monitor := TChangeMonitor.Create(ExcludeTrailingPathDelimiter(Info.Path));
  end;
end;

procedure TNativeFSHandler.DoneChangeDetection;
begin
  if w2k then begin
    if hWait <> 0 then begin
      UnRegisterWait(hWait);
      hWait := 0;
      FindCloseChangeNotification(hNotif);
    end;
  end else begin
    if Monitor <> NIL then begin
      TerminateThread(Monitor.Handle,0);
      Monitor.Free;
      Monitor := NIL;
    end;
  end;
end;

procedure TNativeFSHandler.Execute;
var
  sh:TShellExecuteInfo;
begin
  FillChar(sh,SizeOf(sh),0);
  sh.cbSize := SizeOf(sh);
  sh.lpVerb := 'open';
  sh.nShow := SW_SHOW;
  sh.lpFile := PChar(Info.Path+Item.Name);
  ShellExecuteEx(@sh);
end;

function TNativeFSHandler.ContentsChanged;
begin
  if w2k then
    Result := Changed
  else begin
    if Monitor <> NIL then Result := Monitor.Changed else Result := false;
  end;
end;

procedure TNativeFSHandler.MkDir;
begin
  if not CreateDirectory(PChar(Info.Path+dir),NIL) then
    raise EFSException.Create('MkDir error: '+SysErrorMessage(GetLastError));
end;

function CopyHandler(TotalFileSize,TotalBytesTransferred,StreamSize,
  StreamBytesTransferred:Int64; dwStreamNumber,dwCallbackReason:DWORD;
  hSourceFile,hDestinationFile:THandle; lpData:Pointer):DWORD;stdcall;
begin
  with TfProgress(lpData) do begin
    if Cancelled then begin
      Result := PROGRESS_CANCEL;
      exit;
    end;

    setMax(TotalFileSize);
    setValue(TotalBytesTransferred);
    setOverallValue(lastOverall+(TotalBytesTransferred shr 16));

    UpdateDisplay;

    Result := PROGRESS_CONTINUE;
  end;
end;

function Win32Copy(const src,dst:string; flags:integer; data:Pointer; var cancel:boolean):boolean;
const
  defaultBufferSize = 65536;
var
  hin,hout:THandle;
  rec:TByHandleFileInformation;
  buf:array[0..defaultBufferSize-1] of char;
  bufsize:Cardinal;
  cf:integer;
  trans:Int64;

begin
  if w2k then
    Result := CopyFileEx(PChar(src),PChar(dst),@CopyHandler,data,
                @cancel,flags)
  else begin
    Result := false;
    hin := CreateFile(PChar(src),GENERIC_READ,FILE_SHARE_READ,NIL,OPEN_EXISTING,
      FILE_FLAG_SEQUENTIAL_SCAN,0);
    if hin = INVALID_HANDLE_VALUE then exit;
    if not GetFileInformationByHandle(hin,rec) then exit;
    if flags and COPY_FILE_FAIL_IF_EXISTS <> 0 then
      cf := CREATE_NEW
    else
      cf := CREATE_ALWAYS;
    hout := CreateFile(PChar(dst),GENERIC_WRITE,FILE_SHARE_READ,NIL,cf,
     rec.dwFileAttributes,0);
    try
      if hout = INVALID_HANDLE_VALUE then exit;
      trans := 0;
      repeat
        if cancel then begin
          SetLastError(COPY_ABORTED);
          exit;
        end;
        if not ReadFile(hin,buf,defaultBufferSize,bufsize,NIL) then
          if GetLastError = ERROR_HANDLE_EOF then break else exit;
        if bufsize = 0 then break;
        if not WriteFile(hout,buf,bufsize,bufsize,NIL) then exit;
        inc(trans,bufsize);
        CopyHandler(rec.nFileSizeLow or (rec.nFileSizeHigh shl 32),trans,0,0,0,0,
          hin,hout,data);
      until false;
      SetFileTime(hout,@rec.ftCreationTime,@rec.ftLastAccessTime,
        @rec.ftLastWriteTime);
      Result := true;
    finally
      CloseHandle(hin);
      CloseHandle(hout);
    end;
  end;
end;

function Win32Move(const src,dst:string; flags:integer; data:Pointer; var cancel:boolean):boolean;
begin
  if w2k then
    Result := MoveFileWithProgress(PChar(src),PChar(dst),@CopyHandler,data,flags)
  else begin
    Result := MoveFile(PChar(src),PChar(dst));
    if Result then exit;

    Result := Win32Copy(src,dst,flags,data,cancel);
    if Result then Result := Windows.DeleteFile(PChar(src)); 
  end;
end;

procedure TNativeFSHandler.Copy(const dest: string);
var
  root,P:PFileItem;
  f:TfProgress;
  count:integer;
  err:DWORD;
  flags:integer;
  totalSize:Int64;
  baseflags:integer;
  skipOverwriteAlways:boolean;
  value:Int64;
begin
  case getCfgInt('CopyMethod',0) of
    1 : CopyExplorer(dest);
    0 : begin
      root := BuildFiles(dest,count,totalSize,fbmCopy);
      if root <> NIL then begin
        f := beginProgress('Copying files to '+dest,true);
        baseflags := COPY_FILE_RESTARTABLE or COPY_FILE_FAIL_IF_EXISTS;
        skipOverwriteAlways := false;
        try
          f.setOverallMax(totalSize shr 16);
          value := 0;
          P := root;
          while P <> NIL do begin
            if P.Source = '' then begin
              CreateDirectory(PChar(P.Dest),NIL);
            end else begin
              f.setStatus(P.Source);
              flags := baseflags;
              repeat
                if not Win32Copy(P.Source,P.Dest,flags,f,f.Cancelled) then begin
                  err := GetLastError;
                  case err of
                    COPY_ALREADY_EXISTS_FAIL : break;
                    COPY_ALREADY_EXISTS :
                      if not skipOverwriteAlways then
                        case MessageDlg('"'+P.Dest+'" already exists.'#13'Do you want to overwrite it?',
                          mtConfirmation,[mbYes,mbYesToAll,mbNoToAll,mbNo,mbCancel],0) of
                          mrYesToAll : begin
                            baseflags := baseflags and not COPY_FILE_FAIL_IF_EXISTS;
                            flags := baseflags;
                            continue;
                          end;
                          mrNoToAll : begin
                            skipOverwriteAlways := true;
                            continue;
                          end;
                          mrYes : begin
                            flags := flags and not COPY_FILE_FAIL_IF_EXISTS;
                            continue;
                          end;
                          mrNo : break;
                          else exit;
                        end
                      else break; // do not overwrite - go to next file
                    COPY_ABORTED : exit;
                    else begin
                      if debugging then ShowMessage(IntToStr(GetLastError));
                      case MessageDlg('There has been an error while copying'#13+'"'+P.Source+'" to "'+P.Dest+'"'#13+SysErrorMessage(GetLastError),mtError,[mbRetry,mbIgnore,mbAbort],0) of
                        mrRetry : continue;
                        mrIgnore : break;
                        else exit;
                      end;
                    end;
                  end;
                end else break;
              until false;
            end;
            inc(value,P.Size shr 16);
            f.setOverallValue(value);
            f.lastOverall := value;
            P := P.Next;
          end;
          Info.clearSelection;
        finally
          f.Free;
          DisposeFiles(root);
        end;
      end;
    end;
  end; {case}
end;

procedure TNativeFSHandler.CopyExplorer(const dest:string);
var
  n:integer;
  op:TSHFileOpStruct;
  s:string;
  it:TFSItem;
  l:TList;
begin
  s := '';
  with Info do begin
    l := Items.LockList;
    for n:=0 to l.Count-1 do begin
      it := TFSItem(l[n]);
      if it.Selected then s := s + Path + it.Name + #0;
    end;
    Items.UnlockList;
    s := s + #0;
    FillChar(op,SizeOf(op),0);
    op.wFunc := FO_COPY;
    op.pFrom := PChar(s);
    op.pTo := PChar(dest);
    op.lpszProgressTitle := 'Copying files';
    SHFileOperation(op);
    if not op.fAnyOperationsAborted then Info.clearSelection;
  end;
end;

procedure TNativeFSHandler.MoveExplorer(const dest:string);
var
  n:integer;
  op:TSHFileOpStruct;
  s:string;
  it:TFSItem;
  l:TList;
begin
  s := '';
  with Info do begin
    l := Items.LockList;
    for n:=0 to l.Count-1 do begin
      it := TFSItem(l[n]);
      if it.Selected then s := s + Path + it.Name + #0;
    end;
    Items.UnlockList;
    s := s + #0;
    FillChar(op,SizeOf(op),0);
    op.wFunc := FO_MOVE;
    op.pFrom := PChar(s);
    op.pTo := PChar(dest);
    op.lpszProgressTitle := 'Moving files';
    SHFileOperation(op);
    if not op.fAnyOperationsAborted then Info.clearSelection;
  end;
end;

procedure TNativeFSHandler.MoveNative(const dest:string);
var
  root,P:PFileItem;
  f:TfProgress;
  count:integer;
  err:DWORD;
  flags:integer;
  totalSize:Int64;
  value:Int64;
  baseflags:integer;
  skipAllExisting:boolean;
begin
  root := BuildFiles(dest,count,totalSize,fbmMove);
  if root <> NIL then begin
    f := beginProgress('Moving files to '+dest,true);
    try
      f.setOverallMax(totalSize shr 16);
      value := 0;
      P := root;
      baseflags := MOVEFILE_COPY_ALLOWED;
      skipAllExisting := false;
      while P <> NIL do begin
        if P.Dest = '' then begin
          repeat
            if not RemoveDirectory(PChar(P.Source)) then
              case MessageDlg('There has been an error while deleting'#13+'"'+
                P.Source+'"'#13+SysErrorMessage(GetLastError),
                mtError,[mbRetry,mbIgnore,mbAbort],0) of
                mrRetry : continue;
                mrIgnore : break;
                else exit;
              end else break;
          until false;
        end else
        if P.Source = '' then begin
          CreateDirectory(PChar(P.Dest),NIL);
        end else begin
          f.setStatus(P.Source);
          flags := baseflags;
          repeat
            if not Win32Move(P.Source,P.Dest,flags,f,f.Cancelled) then begin
              err := GetLastError;
              case err of
                COPY_ALREADY_EXISTS_FAIL : break;
                COPY_ALREADY_EXISTS :
                  if not skipAllExisting then
                    case MessageDlg('"'+P.Dest+'" already exists.'#13+
                      'Do you want to overwrite it?',mtConfirmation,
                      [mbYes,mbNo,mbCancel,mbYesToAll,mbNoToAll],0) of
                      mrYes : begin
                        flags := flags or MOVEFILE_REPLACE_EXISTING;
                        continue;
                      end;
                      mrYesToAll : begin
                        baseflags := baseflags or MOVEFILE_REPLACE_EXISTING;
                        flags := baseflags;
                        continue;
                      end;
                      mrNoToAll : begin
                        skipAllExisting := true;
                        break;
                      end;
                      mrNo : break;
                      else exit;
                    end
                  else break; // skip all existing
                COPY_ABORTED : exit;
                else
                  case MessageDlg('There has been an error while moving'#13+'"'+
                    P.Source+'" to "'+P.Dest+'"'#13+SysErrorMessage(GetLastError),
                    mtError,[mbRetry,mbIgnore,mbAbort],0) of
                    mrRetry : continue;
                    mrIgnore : break;
                    else exit;
                  end;
              end;
            end else break;
          until false;
        end;
        inc(value,P.Size shr 16);
        f.setOverallValue(value);
        f.lastOverall := value;
        P := P.Next;
      end;
      Info.clearSelection;
    finally
      f.Free;
      DisposeFiles(root);
    end;
  end;
end;

procedure TNativeFSHandler.Move(const dest: string);
begin
  case getCfgInt('MoveMethod',0) of
    0 : MoveNative(dest);
    1 : MoveExplorer(dest);
  end;
end;

procedure TNativeFSHandler.DeleteNative;
var
  root,P:PFileItem;
  n,cnt:integer;
  totalSize:Int64;
  f:TfProgress;
  attr:DWORD;
  deleteAllRO,readonly,isro:boolean;
begin
  root := BuildFiles('',cnt,totalSize,fbmDelete);
  if root <> NIL then begin
    f := beginProgress('Deleting files',false);
    try
      f.setOverallMax(cnt);
      n := 0;
      P := root;
      deleteAllRO := false;
      while P <> NIL do begin
        readonly := false;
        if P.Source = '' then begin
          f.setStatus(P.Dest);
          repeat
            if not RemoveDirectory(PChar(P.Dest)) then
              case MessageDlg('There has been an error while deleting'#13+
                '"'+P.Dest+'"'#13+SysErrorMessage(GetLastError),
                mtError,[mbRetry,mbIgnore,mbAbort],0) of
                mrRetry : continue;
                mrIgnore : break;
                else exit;
              end else break;
          until false;
        end else begin
          f.setStatus(P.Source);
          attr := GetFileAttributes(PChar(P.Source));
          isro := (attr <> $FFFFFFFF) and
            (attr and (faReadOnly or faSysFile) <> 0);
          if isro then begin
            if deleteAllRO then readonly := true;
            if not (readonly or deleteAllRO) then
              if getCfgBool('ConfirmReadOnlyDelete',true) then
                case MessageDlg('"'+P.Source+'" is read-only or system file'#13+
                  'Do you want to delete it?',mtConfirmation,
                  [mbYes,mbNo,mbCancel,mbYesToAll],0) of
                  mrYes : readonly := true;
                  mrYesToAll : begin
                    deleteAllRO := true;
                    continue;
                  end;
                  mrCancel : exit;
                end else readonly := true;
            if readonly or deleteAllRO then setFileAttributes(PChar(P.Source),attr and not (faReadOnly or faSysFile));
          end;

          if (not isro) or (isro and readonly) then
          repeat
            if not Windows.DeleteFile(PChar(P.Source)) then
              case MessageDlg('There has been an error while deleting'#13+
                '"'+P.Source+'"'#13+SysErrorMessage(GetLastError),
                mtError,[mbRetry,mbIgnore,mbAbort],0) of
                mrRetry : continue;
                mrIgnore : break;
                else exit;
              end else break;
          until false;
        end;
        inc(n);
        f.setOverallValue(n);
        P := P.Next;
      end;
    finally
      f.Free;
      DisposeFiles(root);
    end;
  end;
end;

procedure TNativeFSHandler.DeleteExplorer;
var
  n:integer;
  it:TFSItem;
  op:TSHFileOpStruct;
  s:string;
  l:TList;
begin
  with Info do begin
    l := Items.LockList;
    for n:=0 to l.Count-1 do begin
      it := TFSItem(l[n]);
      if it.Selected then s := s + Path + it.Name + #0;
    end;
    Items.UnlockList;
    s := s + #0;
    FillChar(op,SizeOf(op),0);
    op.wFunc := FO_DELETE;
    op.pFrom := PChar(s);
    op.lpszProgressTitle := 'Deleting';
    op.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION;
    if SHFileOperation(op) = 0 then
      if not op.fAnyOperationsAborted then Info.clearSelection;
  end;
end;

procedure TNativeFSHandler.Delete;
begin
  if getCfgInt('DeleteMethod',0)=0 then DeleteNative else DeleteExplorer;
end;

procedure TNativeFSHandler.Rename(item: TFSItem; const newname: string);
begin
  with Info,Item do if RenameFile(Path+Name,Path+newname) then Item.Name := newname
    else raise Exception.Create('Rename error: '+SysErrorMessage(GetLastError));
end;

procedure TNativeFSHandler.ContextPopup(item:TFSItem; x,y:integer);
begin

end;

class procedure TNativeFSHandler.fillVolumes;
var
  ar:array[0..1023] of char;
  s:string;
  n,l:integer;
  d:DWORD;
  dt:UINT;
  item:TFSVolume;
  c:char;
begin
  list.Clear;
  GetLogicalDriveStrings(SizeOf(ar),@ar);
  s := '';
  l := 0;
  for n:=0 to SizeOf(ar)-1 do begin
    c := ar[n];
    if c = #0 then begin
      if l = 0 then break else begin
        item := TFSVolume.Create;
        item.Path := s;
        dt := GetDriveType(PChar(s));
        case dt of
          DRIVE_CDROM, DRIVE_REMOVABLE : Item.VolumeType := vtRemovable;
          DRIVE_RAMDISK, DRIVE_FIXED : Item.VolumeType := vtFixed;
          DRIVE_REMOTE : Item.VolumeType := vtRemote;
          else
            Item.VolumeType := vtUnknown;
        end; {case}
        if dt <> DRIVE_REMOVABLE then
          if GetVolumeInformation(PChar(s),@ar,SizeOf(ar),@D,D,D,NIL,0) then item.Name := string(@ar);

        list.Add(item);
        s := '';
        l := 0;
      end;
    end else begin
      s := s + c;
      inc(l);
    end;
  end;
end;

procedure TNativeFSHandler.OpenFS(const url: string);
var
  data:_WIN32_FIND_DATAA;
  h:THandle;
begin
  Root := ExtractFileDrive(url);
  if length(Root) = 1 then Root := Root + ':\' else Root := Root + '\';
  FillChar(data,SizeOf(data),0);
  h := FindFirstFileA(PAnsiChar(AnsiString(Root+'\*.*')),data);
  Windows.FindClose(h);
  if h = INVALID_HANDLE_VALUE then
    if GetLastError <> FINDFIRST_EMPTY then
      raise EFSException.Create('Access failure: '+SysErrorMessage(GetLastError));
  SetPath(url);
  Refresh;
end;

procedure TNativeFSHandler.readItems;
var
  item:TFSItem;
  data:_WIN32_FIND_DATAA;
  h:THandle;
  attr,time:DWORD;
  LocalFileTime:TFileTime;
  l:TList;
begin
  with Info,Info.Items do begin
    Clear;
    if w2k then Changed := false;
    h := FindFirstFileA(PAnsiChar(AnsiString(IncludeTrailingPathDelimiter(Info.Path)+'*.*')),data);
    if h <> INVALID_HANDLE_VALUE then begin
      repeat
        with data do begin
          try
            attr := dwFileAttributes;
            if attr and (faDirectory or faSysFile or faHidden or faReadOnly or faArchive) <> 0 then begin
              if attr and faDirectory > 0 then begin
                if string(cFileName) = '.' then continue;
                if string(cFileName) = '..' then attr := attr or faNonSelectable;
                attr := attr or faBrowseable;
              end;
              item := TFSItem.Create;
              with item do begin
                Name := cFileName;
                Size := (nFileSizeHigh shl 32) or nFileSizeLow;
                inc(TotalFileSizes,Size);
                FileTimeToLocalFileTime(ftLastWriteTime, LocalFileTime);
                FileTimeToDosDateTime(LocalFileTime, LongRec(time).Hi,
                  LongRec(time).Lo);
                try
                  Date := FileDateToDateTime(time);
                except
                  Date := Now;
                end;
                Flags := attr;
              end;
              Add(item);
            end;
          except
            raise EFSException.Create('Processing error: '+SysErrorMessage(GetLastError));
          end;
        end;
      until not FindNextFileA(h,data);
      Windows.FindClose(h);
    end;
    l := LockList;
    l.Pack;
    UnlockList;
  end;
end;

procedure TNativeFSHandler.readVolumeInfo;
var
  ar:array[0..255] of char;
  fs:array[0..255] of char;
  proot:array[0..255] of char;
  serial:DWORD;
  maxFNLen:DWORD;
  flags:DWORD;
begin
  StrPCopy(@proot,Root);

  with Info do begin
    if GetVolumeInformation(@proot,@ar,SizeOf(ar),@serial,maxFNLen,flags,@fs,
      SizeOf(fs)) then begin
      VolumeName := ExcludeTrailingPathDelimiter(Root);
      VolumeLabel := string(@ar);
      FileSystem := string(@fs);
      SerialNumber := IntToHex(serial,8);
    end;
    case GetDriveType(@proot) of
      DRIVE_CDROM, DRIVE_REMOVABLE : VolumeType := vtRemovable;
      DRIVE_RAMDISK, DRIVE_FIXED : VolumeType := vtFixed;
      DRIVE_REMOTE : VolumeType := vtRemote;
      else
        VolumeType := vtUnknown;
    end; {case}
    if not GetDiskFreeSpaceEx(@proot,FreeSpace,VolumeSize,NIL) then begin
      FreeSpace := 0;
      VolumeSize := 0;
    end;
  end;
end;

procedure TNativeFSHandler.setParent;
begin
  if Info.Path = Root then exit;
  ChDir(Info.Path+'..');
  SetPath(GetCurrentDir);
end;

procedure TNativeFSHandler.setPath;
var
  s:string;
begin
  DoneChangeDetection;
  if SetCurrentDirectory(PChar(url)) then begin
    s := IncludeTrailingPathDelimiter(GetCurrentDir);
    Root := IncludeTrailingPathDelimiter(ExtractFileDrive(s));
    inherited SetPath(s);
  end else raise EFSException.Create('Access failure: '+SysErrorMessage(GetLastError));
  InitChangeDetection;
end;

procedure TNativeFSHandler.readItemSize(item: TFSItem);
  function Recurse(path:string):Int64;
  var
    data:_WIN32_FIND_DATAA;
    h:THandle;
  begin
    Result := 0;
    h := FindFirstFileA(PAnsiChar(AnsiString(path+'*.*')),data);
    if h <> INVALID_HANDLE_VALUE then with data do repeat
      inc(Result,(nFileSizeHigh shl 32) or nFileSizeLow);
      if (dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0) and (cFileName[0] <> '.')
        then inc(Result,Recurse(path+cFileName+'\'));
    until not FindNextFileA(h,data);
    Windows.FindClose(h);
  end;
begin
  item.Size := Recurse(Info.Path+item.Name+'\');
  item.Flags := item.Flags or faCalculated;
end;

destructor TNativeFSHandler.Destroy;
begin
  DoneChangeDetection;
  inherited;
end;

function TNativeFSHandler.supportedAttributes: integer;
begin
  Result := faArchive or faReadOnly
end;

procedure TNativeFSHandler.setAttributes(item: TFSItem; newattr: integer);
begin
  if not SetFileAttributes(PChar(Info.Path+item.Name),newattr) then
    raise EFSException.Create('Attribute set failure: '+
      SysErrorMessage(GetLastError));
end;

procedure TNativeFSHandler.setDate(item: TFSItem; newdate: TDateTime);
var
  h:THandle;
  i:integer;
  T:TFileTime;
begin
  h := CreateFile(PChar(Info.Path+item.Name),GENERIC_WRITE,FILE_SHARE_READ or
    FILE_SHARE_WRITE,NIL,OPEN_EXISTING,0,0);
  if h = INVALID_HANDLE_VALUE then
    raise EFSException.Create('Couldn''t open '+item.Name);
  try
    i := DateTimeToFileDate(newdate);
    DosDateTimeToFileTime(Lo(i),Hi(i),T);
    if SetFileTime(h,NIL,NIL,@T) then begin
      item.Date := newdate;
    end else raise EFSException.Create('Cannot set date on '+item.Name);
  finally
    CloseHandle(h);
  end;
end;

{ TChangeMonitor }

constructor TChangeMonitor.Create;
begin
  inherited Create(true);
  Path := APath;
  Priority := tpNormal;
  Resume;
end;

procedure TChangeMonitor.Execute;
var
  w:DWORD;
begin
  hNotif := FindFirstChangeNotification(PChar(Path),false,
    FILE_NOTIFY_CHANGE_FILE_NAME or FILE_NOTIFY_CHANGE_DIR_NAME or
    FILE_NOTIFY_CHANGE_ATTRIBUTES or FILE_NOTIFY_CHANGE_SIZE or
    FILE_NOTIFY_CHANGE_LAST_WRITE);
  if hNotif = INVALID_HANDLE_VALUE then
    raise EFSException.Create('Notification control failure: '+SysErrorMessage(GetLastError));
  repeat
    repeat
      w := WaitForSingleObject(hNotif,500);
      if w = WAIT_TIMEOUT then if Terminated then break;
    until w = WAIT_OBJECT_0;
    if Terminated then break;
    Changed := true;
  until (not FindNextChangeNotification(hNotif));
  FindCloseChangeNotification(hNotif);
end;

procedure InitW2K;
var
  h:THandle;

  function p(const name:PChar):pointer;
  begin
    Result := GetProcAddress(h,name);
    if Result = NIL then begin
      ShowMessage(name+' binding failed');
      ExitProcess(0);
    end;
  end;

begin
  h := LoadLibrary(kernel32);
  if h = 0 then begin
    ShowMessage('Kernel32 bind failure. Turning off Windows 2000 extensions');
    w2k := false;
  end else begin
    RegisterWaitForSingleObject := p('RegisterWaitForSingleObject');
    UnregisterWait := p('UnregisterWait');
    CopyFileEx := p('CopyFileExA');
  end;
end;

begin
  if w2k then InitW2K;
end.
