unit aboutfrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfAbout = class(TForm)
    lAppName: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    bClose: TButton;
    procedure FormShow(Sender: TObject);
  end;

var
  fAbout: TfAbout;

implementation

uses

  procs;

{$R *.dfm}

procedure TfAbout.FormShow(Sender: TObject);
begin
  lAppName.Caption := 'Yarrak Commander Version '+appVer;
end;

end.
