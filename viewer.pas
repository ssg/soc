unit viewer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ToolWin, ComCtrls, StdCtrls;

const

  defaultBufferSize = 65536;  

type
  TfViewer = class(TForm)
    CoolBar1: TCoolBar;
    ToolBar1: TToolBar;
    tbWordWrap: TToolButton;
    pContainer: TPanel;
    memText: TMemo;
    sbText: TScrollBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    eFont: TEdit;
    bFontSelect: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    Stream : TStream;
    Buffer : PChar;
    BufferSize : integer;
    FileSize : integer;

    procedure setBuffer;
    procedure go(offset:integer);
  public
    procedure initFile(const path:string);
  end;

procedure ViewFile(const path:string);

implementation

{$R *.dfm}

procedure ViewFile;
var
  F:TfViewer;
begin
  Screen.Cursor := crHourGlass;
  Application.CreateForm(TfViewer,F);
  try
    F.Caption := 'Viewer - '+path;
    F.InitFile(path);
    F.Show;
  except
    F.Free;
  end;
  Screen.Cursor := crDefault;
end;

{ TfViewer }

procedure TfViewer.FormCreate(Sender: TObject);
begin
  pContainer.DoubleBuffered := true;
  eFont.Text := memText.Font.Name;
end;

procedure TfViewer.setBuffer;
var
  s:string;
begin
  SetLength(s,bufferSize);
  Move(Buffer^,s[1],BufferSize);
  memText.Text := s;
end;

procedure TfViewer.go;
begin
  Stream.Position := offset;
  BufferSize := defaultBufferSize;
  if BufferSize > FileSize-offset then BufferSize := FileSize-offset;
  Stream.Read(Buffer^,BufferSize);

  setBuffer;
end;

procedure TfViewer.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfViewer.FormDestroy(Sender: TObject);
begin
  if Stream <> NIL then Stream.Free;
  if Buffer <> NIL then FreeMem(buffer);
end;

procedure TfViewer.initFile(const path: string);
begin
  Stream := TFileStream.Create(path,fmOpenRead);
  GetMem(Buffer,defaultBufferSize);
  FileSize := Stream.Size;
  go(0);
end;

procedure TfViewer.ToolButton2Click(Sender: TObject);
begin
  Close;
end;

procedure TfViewer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

end.
