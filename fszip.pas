{
ZIP archive handler
}

unit fszip;

interface

uses

  fs, fsarchive,

  SysUtils, Classes;

type

  TEndOfCentralDir = packed record
    dwSignature : longword;
    wDiskNumber : word;
    wCentralDirDiskNumber : word;
    wTotalEntriesOnDisk : word;
    wTotalEntries : word;
    dwCentralDirSize : longword;
    dwCentralDirOffset : longword;
    wCommentLength : word;
    Comment : record end;
  end;

  TCentralFileHeader = packed record
    dwSignature : longword;
    wVersionMade : word;
    wVersionNeeded : word;
    wGeneralPurposeFlags : word;
    wCompressionMethod : word;
    dwLastModDateTime : longword;
    dwCRC32 : longword;
    dwCompressedSize : longword;
    dwUncompressedSize : longword;
    wFilenameLength : word;
    wExtraFieldLength : word;
    wFileCommentLength : word;
    wStartDiskNumber : word;
    wInternalFileAttributes : word;
    dwExternalFileAttributes : longword;
    dwLocalHeaderOffset : longword;
  end;

  TZIPHandler = class(TArchiveFSHandler)
  private
    eocdr:TEndOfCentralDir;
  public
    procedure OpenFS(const url:string);override;
    procedure readItems;override;
    procedure readVolumeInfo;override;
    class function canHandle(const url:string):boolean;override;
    class function getName:string;override;
  end;

implementation

uses

  Dialogs;

{ TFSZIPHandler }

const

  sigZIP   = $04034b50;
  sigEOCDR = $06054b50;
  sigCFH   = $02014b50;

procedure TZIPHandler.OpenFS;
begin
  inherited OpenFS(url);
  with Info do begin
    VolumeName := ExtractFileName(url);
    FileSystem := 'ZIP';
    VolumeType := vtArchive;
  end;
  Stream.Seek(-SizeOf(eocdr),soFromEnd);
  Stream.Read(eocdr,SizeOf(eocdr));
  with eocdr do begin
    if eocdr.dwSignature <> sigEOCDR then raise EFSException.Create('Invalid EOCDR sig');
    if eocdr.wDiskNumber <> eocdr.wCentralDirDiskNumber then
      raise EFSException.Create('Multiple volume ZIPs not supported');
  end;
end;

class function TZIPHandler.canHandle;
var
  T:TFileStream;
  dw:longword;
begin
  Result := false;
  if not FileExists(url) then exit;
  try
    T := TFileStream.Create(url,fmOpenRead);
  except
    exit;
  end;
  try
    T.Position := 0;
    T.Read(dw,SizeOf(dw));
    Result := dw = sigZIP;
  finally
    T.Free;
  end;
end;

procedure TZIPHandler.readItems;
var
  rec:TCentralFileHeader;
  item:TFSItem;
  sp:string;
  fn:string;
  n,attr:integer;
begin
  with Info,Info.Items do begin
    Clear;
    VolumeSize := 0;
    sp := UpperCase(StringReplace(System.copy(Path,length(Base)+2,length(Path)),'\','/',[rfReplaceAll]));
    Stream.Seek(eocdr.dwCentralDirOffset,soFromBeginning);
    repeat
      try
        Stream.Read(rec,SizeOf(rec));
      except
        break;
      end;
      if rec.dwSignature = sigCFH then begin
        SetLength(fn,rec.wFilenameLength);
        inc(VolumeSize,rec.dwUncompressedSize);
        Stream.Read(fn[1],length(fn));
        Stream.Seek(rec.wExtraFieldLength,soFromCurrent);
        if (sp = '') or (pos(sp,UpperCase(fn))=1) then begin
          n := pos('/',fn);
          if n > length(sp) then begin
            fn := System.copy(fn,length(sp)+1,n-length(sp)-1);
          end;
          item := TFSItem.Create;
          item.Name := ExtractFileName(StringReplace(fn,'/','\',[rfReplaceAll]));
          item.Date := FileDateToDateTime(rec.dwLastModDateTime);
          item.Size := rec.dwUncompressedSize;
          attr := Lo(rec.dwExternalFileAttributes);
          if attr and faDirectory > 0 then attr := attr or faBrowseable;
          item.Flags := attr;
          Add(item);
        end;
      end;
    until rec.dwSignature = sigEOCDR;
    addParentDir;
  end;
end;

procedure TZIPHandler.readVolumeInfo;
begin
//  inherited;

end;

class function TZIPHandler.getName: string;
begin
  Result := 'ZIP';
end;

end.
