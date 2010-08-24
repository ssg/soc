program soc;

uses
  Forms,
  mainfrm in 'mainfrm.pas' {fMain},
  panelfra in 'panelfra.pas' {FilePanel: TFrame},
  procs in 'procs.pas',
  fsnative in 'fsnative.pas',
  fs in 'fs.pas',
  copytofrm in 'copytofrm.pas' {fCopyTo},
  progressfrm in 'progressfrm.pas' {fProgress},
  aboutfrm in 'aboutfrm.pas' {fAbout},
  fsarchive in 'fsarchive.pas',
  viewer in 'viewer.pas' {fViewer},
  fszip in 'fszip.pas',
  settings in 'settings.pas' {fSettings};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'SSG''s Own Commander';
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
