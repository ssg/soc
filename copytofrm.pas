unit copytofrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfCopyTo = class(TForm)
    Label1: TLabel;
    cbPath: TComboBox;
    bOK: TButton;
    bCancel: TButton;
    procedure FormCreate(Sender: TObject);
  end;

var
  fCopyTo: TfCopyTo;

implementation

uses

  panelfra, fs;

{$R *.dfm}

procedure TfCopyTo.FormCreate(Sender: TObject);
var
  p,pi:TFilePanel;
  n:integer;
begin
  pi := NIL;
  cbPath.Items.BeginUpdate;
  for n:=0 to Panels.Count-1 do begin
    p := TFilePanel(Panels[n]);
    if cbPath.Items.IndexOf(p.Handler.Info.Path) = -1 then
      cbPath.Items.Add(p.Handler.Info.Path);
    if (pi=NIL) and (p <> activePanel) then pi := p;
  end;
  cbPath.Items.EndUpdate;
  if pi <> NIL then cbPath.Text := pi.Handler.Info.Path;
end;

end.
