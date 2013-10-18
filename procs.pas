{ common procedures}

unit procs;

interface

uses

  Forms, progressfrm;

const

  appVer : string = '0.1 alpha';
  defaultPanels : integer = 2;

  debugging : boolean = false;

  W2K : boolean = false;

  regPath = 'Software\FC';

function getCfgStr(const key,default:string):string;
procedure putCfgStr(const key:string; value:string);

function getCfgInt(const key:string; default:integer):integer;
procedure putCfgInt(const key:string; value:integer);

function getCfgBool(const key:string; default:boolean):boolean;
procedure putCfgBool(const key:string; value:boolean);

procedure CloseReg;
procedure ClearReg;

function matchWildcard(const wildcard:string; filename:string):boolean;

procedure status(s:string);

procedure readFormState(form:TForm);
procedure saveFormState(form:TForm);

function getEnv(const key:string):string;

implementation

uses

  Windows, mainfrm, SysUtils, Registry;

function getEnv;
var
  buf:array[0..1023] of char;
  res:DWORD;
begin
  res := GetEnvironmentVariable(PChar(key),@buf,SizeOf(buf));
  if res = 0 then Result := '' else begin
    buf[res] := #0;
    Result := string(@buf);
  end;
end;

procedure saveFormState;
var
  s:string;
begin
  with form do begin
    s := Name+'_';
    putCfgBool(s+'Maximized',WindowState=wsMaximized);
    putCfgInt(s+'Left',Left);
    putCfgInt(s+'Top',Top);
    putCfgInt(s+'Width',Width);
    putCfgInt(s+'Height',Height);
  end;
end;

procedure readFormState;
var
  s:string;
begin
  with form do begin
    s := Name+'_';
    Left := getCfgInt(s+'Left',Left);
    Top := getCfgInt(s+'Top',Top);
    Width := getCfgInt(s+'Width',Width);
    Height := getCfgInt(s+'Height',Height);
    if getCfgBool(s+'Maximized',false) then WindowState := wsMaximized;

    if Left > Screen.WorkAreaWidth then Left := 0;
    if Top > Screen.WorkAreaHeight then Top := 0;
  end;
end;

procedure status;
begin
  fMain.sbMain.SimpleText := s;
end;

const

  shlwapi = 'shlwapi.dll';

function PathMatchSpecA(pszFileParam,pszSpec:PChar):boolean;stdcall;external shlwapi;

function matchWildcard;
begin
  Result := PathMatchSpecA(PChar(filename),PChar(wildcard));
end;

{function matchWildcard;
var
  n,w,subn,fln,wln:integer;
  cw:char;
  b:boolean;
begin
  Result := false;
  wln := length(wildcard);
  if wln = 0 then exit;
  if pos('.',filename) = 0 then filename := filename+'.';
  fln := length(filename);
  if fln = 0 then exit;
  n := 1;
  for w:=1 to wln-1 do begin
    if n > fln then exit;
    cw := wildcard[w];
    case cw of
      '*' : begin
        cw := wildcard[w+1];
        b := false;
        for subn := n to fln do begin
          if cw = filename[subn] then begin
            b := true;
            n := subn;
            break;
          end;
        end;
        if not b then exit;
      end;
      '?' : inc(n);
      else begin
        if cw <> filename[n] then exit;
        inc(n);
      end;
    end;
  end;
  cw := wildcard[wln];
  if (cw <> '*') and (cw <> filename[fln]) then exit;
  Result := true;
end;}

function OpenReg:TRegistry;
begin
  Result := TRegistry.Create;
  Result.OpenKey(regPath,true);
end;

var
  reg:TRegistry;

procedure CloseReg;
begin
  reg.CloseKey;
  reg.Free;
end;

procedure ClearReg;
begin
  reg.CloseKey;
  reg.DeleteKey(regPath);
  reg.OpenKey(regPath,true);
end;

procedure putCfgStr;
begin
  reg.WriteString(key,value);
end;

function getCfgStr;
begin
  try
    Result := reg.ReadString(key);
    if Result = '' then Result := default;
  except
    Result := default;
  end;
end;

procedure putCfgInt;
begin
  reg.WriteInteger(key,value);
end;

function getCfgInt;
begin
  try
    Result := reg.ReadInteger(key);
  except
    Result := default;
  end;
end;

procedure putCfgBool;
begin
  reg.WriteBool(key,value);
end;

function getCfgBool;
begin
  try
    Result := reg.ReadBool(key);
  except
    Result := default;
  end;
end;

procedure InitOS;
var
  rec:TOSVersionInfo;
begin
  if getCfgBool('W2KExtensions',true) then begin
    rec.dwOSVersionInfoSize := SizeOf(rec);
    GetVersionEx(rec);
    w2k := (rec.dwMajorVersion >= 5) and (rec.dwPlatformId=VER_PLATFORM_WIN32_NT);
  end else w2k := false;
end;

initialization
begin
  reg := OpenReg;
  InitOS;
  defaultPanels := GetCfgInt('PanelCount',2);
  if defaultPanels < 2 then defaultPanels := 2;
end;

finalization
begin
  CloseReg;
end;

end.
 