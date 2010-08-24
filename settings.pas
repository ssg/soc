unit settings;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TfSettings = class(TForm)
    bOK: TButton;
    bCancel: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    lPanelCount: TLabel;
    tbPanelCount: TTrackBar;
    cbW2K: TCheckBox;
    cbAutoDirSize: TCheckBox;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    cbCopyMethod: TComboBox;
    cbMoveMethod: TComboBox;
    cbDeleteMethod: TComboBox;
    procedure bOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tbPanelCountChange(Sender: TObject);
  public
    procedure readSettings;
    procedure saveSettings;
  end;

var
  fSettings: TfSettings;

implementation

uses

  procs;

{$R *.dfm}

{ TfSettings }

procedure TfSettings.readSettings;
begin
  cbW2K.Checked := getCfgBool('W2KExtensions',true);
  cbAutoDirSize.Checked := getCfgBool('AutoDirSize',true);
  tbPanelCount.Position := getCfgInt('PanelCount',2);
  lPanelCount.Caption := IntToStr(tbPanelCount.Position);

  cbCopyMethod.ItemIndex := getCfgInt('CopyMethod',0);
  cbMoveMethod.ItemIndex := getCfgInt('MoveMethod',0);
  cbDeleteMethod.ItemIndex := getCfgInt('DeleteMethod',0);
end;

procedure TfSettings.saveSettings;
begin
  putCfgBool('W2KExtensions',cbW2K.Checked);
  putCfgBool('AutoDirSize',cbAutoDirSize.Checked);
  putCfgInt('PanelCount',tbPanelCount.Position);
end;

procedure TfSettings.bOKClick(Sender: TObject);
begin
  saveSettings;
  ModalResult := mrOK;
end;

procedure TfSettings.FormCreate(Sender: TObject);
begin
  readSettings;
end;

procedure TfSettings.tbPanelCountChange(Sender: TObject);
begin
  lPanelCount.Caption := IntToStr(tbPanelCount.Position);
end;

end.
