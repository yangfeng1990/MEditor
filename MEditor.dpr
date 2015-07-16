program MEditor;

uses
  Forms,
  SysUtils,
  Main in 'Main.pas' {MainForm},
  Log in 'Log.pas' {LogForm},
  Core in 'Core.pas',
  URL in 'URL.pas',
  Help in 'Help.pas' {HelpForm},
  About in 'About.pas' {AboutForm},
  Locale in 'Locale.pas',
  Options in 'Options.pas' {OptionsForm},
  Config in 'Config.pas',
  mo_zh_cn in 'mo_zh_cn.pas',
  plist in 'plist.pas' {PlaylistForm},
  Info in 'Info.pas' {InfoForm},
  mo_en in 'mo_en.pas',
  uConvertFrm in 'uConvertFrm.pas' {ConvertFrm},
  uCutFrm in 'uCutFrm.pas' {CutFrm},
  uGlobVar in 'uGlobVar.pas',
  pscpLogger in 'pscpLogger.pas',
  uHelp in 'uHelp.pas' {HelpFrm};

{$R *.res}
{$R XPStyle.res}

begin
  Application.Initialize;
  Log_Open('MEditor.log', False, '', 0);
  GlobVar := TGlobVar.Create(ExtractFileDir(Application.ExeName));
  Application.Title := 'MPUI';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TLogForm, LogForm);
  Application.CreateForm(THelpForm, HelpForm);
  Application.CreateForm(TAboutForm, AboutForm);
  Application.CreateForm(TOptionsForm, OptionsForm);
  Application.CreateForm(TPlaylistForm, PlaylistForm);
  Application.CreateForm(TInfoForm, InfoForm);
  Application.CreateForm(TConvertFrm, ConvertFrm);
  Application.CreateForm(TCutFrm, CutFrm);
  Application.CreateForm(THelpFrm, HelpFrm);
  Application.Run;

  Log_Close;
end.
