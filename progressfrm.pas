unit progressfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls;

type
  TfProgress = class(TForm)
    Panel1: TPanel;
    lStatus: TLabel;
    pProgress: TPanel;
    pbProgress: TProgressBar;
    Label1: TLabel;
    Panel3: TPanel;
    pbOverallProgress: TProgressBar;
    bCancel: TButton;
    procedure bCancelClick(Sender: TObject);
  public
    Cancelled : boolean;
    lastUpdate : integer;
    lastOverall : Int64;

    procedure setStatus(s:string);
    procedure setValue(n:Int64);
    procedure setMax(n:Int64);
    procedure setOverallMax(n:Int64);
    procedure setOverallValue(n:Int64);
    procedure UpdateDisplay;
  end;

function beginProgress(title:string; multi:boolean):TfProgress;

implementation

{$R *.dfm}

procedure TfProgress.UpdateDisplay;
var
  l:integer;
begin
  l := GetTickCount;
  if l-lastUpdate > 500 then begin
    lastUpdate := l;
    Application.ProcessMessages;
  end;
end;

function beginProgress;
begin
  Application.CreateForm(TfProgress,Result);
  with Result do begin
    pProgress.Visible := multi;
    Caption := title;
    Show;
    UpdateDisplay;
  end;
end;

procedure TfProgress.bCancelClick(Sender: TObject);
begin
  Cancelled := true;
end;

procedure TfProgress.setMax(n: Int64);
begin
  pbProgress.Max := n;
end;

procedure TfProgress.setOverallMax(n: Int64);
begin
  pbOverallProgress.Max := n;
end;

procedure TfProgress.setOverallValue(n: Int64);
begin
  pbOverallProgress.Position := n;
end;

procedure TfProgress.setStatus(s: string);
begin
  lStatus.Caption := s;
end;

procedure TfProgress.setValue(n: Int64);
begin
  pbProgress.Position := n;
end;

end.
