{
archive handler

c:\windows\hene\hede.zip\hene.dir\hede

openfs called with url of archive name and directories are added as needed

this way parents should work better
}

unit fsarchive;

interface

uses

  fs,

  SysUtils, Classes;

type

  TArchiveFSHandler = class(TFSHandler)
  protected
    Base : string;
    Stream : TStream;

    function getSubPath:string;
  public
    procedure OpenFS(const url:string);override;
    procedure CloseFS;override;

    function contentsChanged:boolean;override;
    procedure setParent;override;
  end;

implementation

{ TArchiveFSHandler }

function TArchiveFSHandler.getSubPath;
begin
  with Info do
    if pos(UpperCase(Base),UpperCase(Path)) = 0 then
      Result := System.copy(Path,length(Base)+1,length(Path))
    else
      raise EFSException.Create(Format('Path<->Base inconsistent "%s"/"%s"',
        [Path,Base]));
end;

procedure TArchiveFSHandler.OpenFS(const url: string);
begin
  Base := url;
  Stream := TFileStream.Create(url,fmOpenRead);
  setPath(IncludeTrailingPathDelimiter(url));
end;

procedure TArchiveFSHandler.CloseFS;
begin
  Stream.Free;
end;

function TArchiveFSHandler.contentsChanged: boolean;
begin
  Result := false;
end;

procedure TArchiveFSHandler.setParent;
var
  pnew:string;
begin
  pnew := ExtractFilePath(ExcludeTrailingPathDelimiter(Info.Path));
  if length(pnew) < length(Base) then
    raise EFSChangeRequired.Create(pnew)
  else
    setPath(pnew);
end;

end.
