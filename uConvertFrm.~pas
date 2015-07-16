unit uConvertFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RzBmpBtn, StdCtrls, RzPrgres, Core, ExtCtrls, ComCtrls, uGlobVar, pscpLogger;

type
  TConvertFrm = class(TForm)
    lbl1: TLabel;
    lbl2: TLabel;
    edtSrc: TEdit;
    edtDest: TEdit;
    btnConvert: TRzBmpButton;
    btnCancel: TRzBmpButton;
    btnSelSrc: TRzBmpButton;
    btnSelDest: TRzBmpButton;
    rzprgrsbr1: TRzProgressBar;
    lblComplete: TLabel;
    dlgOpenConvertSrc: TOpenDialog;
    dlgSaveConvertDest: TSaveDialog;
    lblConvertTip: TLabel;
    procedure btnConvertClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSelSrcClick(Sender: TObject);
    procedure btnSelDestClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure UpdateProgressBar(progress: Integer);
  end;

var
  ConvertFrm : TConvertFrm;

implementation

{$R *.dfm}

procedure TConvertFrm.btnConvertClick(Sender: TObject);
var
  srcFile  : string;
  destFile : string;
begin
  lblComplete.Visible := False;
  srcFile := Trim(Self.edtSrc.Text);
  destFile := Trim(Self.edtDest.Text);

  if (not FileExists(srcFile)) or (destFile = '') then
  begin
    MessageBox(Self.handle, '原文件或输出文件路径有误！', '提示', MB_ICONINFORMATION + MB_OK);
    Exit;
  end;

  Self.lblConvertTip.Visible := True;
  Self.rzprgrsbr1.Percent := 0;

  Core.StartConvert(srcFile, destFile);
end;

procedure TConvertFrm.UpdateProgressBar(progress: Integer);
begin
  Self.rzprgrsbr1.Percent := progress;
  Self.rzprgrsbr1.Refresh;
  if progress = 100 then
  begin
    Self.lblComplete.Visible := True;
    Self.lblConvertTip.Visible := False;
  end;
end;

procedure TConvertFrm.btnCancelClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TConvertFrm.FormShow(Sender: TObject);
begin
  // 界面初始化
  Self.lblComplete.Visible := False;
  Self.rzprgrsbr1.Percent := 0;
  Self.edtSrc.Text := GlobVar.PlayFileName;
  Self.edtDest.Text := '';
  Self.lblConvertTip.Visible := False;
end;

procedure TConvertFrm.btnSelSrcClick(Sender: TObject);
begin
  with dlgOpenConvertSrc do
  begin
    Options:=Options-[ofAllowMultiSelect];
    if Execute then
      edtSrc.Text := dlgOpenConvertSrc.FileName;
  end;
end;

procedure TConvertFrm.btnSelDestClick(Sender: TObject);
var
  FileExt : string;
begin
  with dlgSaveConvertDest do
  begin
    Options:=Options-[ofAllowMultiSelect];
    if Execute then
      edtDest.Text := dlgSaveConvertDest.FileName;
    FileExt := ExtractFileExt(dlgSaveConvertDest.FileName);
    if SameText(FileExt, '.mp4') or SameText(FileExt, '.avi') or
    SameText(FileExt, '.flv') or SameText(FileExt, '.mpg') or SameText(FileExt, '.mov') then
      Exit
    else
    begin
      case dlgSaveConvertDest.FilterIndex of
        1:edtDest.Text := edtDest.Text + '.mp4';
        2:edtDest.Text := edtDest.Text + '.avi';
        3:edtDest.Text := edtDest.Text + '.flv';
        4:edtDest.Text := edtDest.Text + '.mpg';
        5:edtDest.Text := edtDest.Text + '.mov';
      end;
    end;
  end;
end;

end.
