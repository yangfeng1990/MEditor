unit uCutFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, RzPrgres, uGlobVar, dateutils, ShellAPI, pscpLogger, Core,
  RzBmpBtn;

type
  TCutFrm = class(TForm)
    edtSaveFilePath: TEdit;
    rzprgrsbr2: TRzProgressBar;
    rzprgrsbr3: TRzProgressBar;
    lblCutTip: TLabel;
    btnConvert: TRzBmpButton;
    btnCancel: TRzBmpButton;
    btnSelSrc: TRzBmpButton;
    lbl1: TLabel;
    lblCutTip1: TLabel;
    lblComp: TLabel;
    dlgSaveCutDest: TSaveDialog;
    btnTransEncoding: TRzBmpButton;
    btnMerger: TRzBmpButton;
    rzprgrsbrMergecut1: TRzProgressBar;
    rzprgrsbrMergecut2: TRzProgressBar;
    rzprgrsbrMergecut3: TRzProgressBar;
    rzprgrsbrMergecut4: TRzProgressBar;
    rzprgrsbrMergecut5: TRzProgressBar;
    procedure btnCutClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSelSrcClick(Sender: TObject);
    procedure btnTransEncodingClick(Sender: TObject);
    procedure btnMergerClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure UpdateProgressBar(progress: Integer);
    procedure UpdateProgressBar2(progress: Integer);
    procedure UpdateProgressBarMergerCut1(progress: Integer);
    procedure UpdateProgressBarMergerCut2(progress: Integer);
    procedure UpdateProgressBarMergerCutTs1(progress: Integer);
    procedure UpdateProgressBarMergerCutTs2(progress: Integer);
    procedure UpdateProgressBarMerger(progress: Integer);
  end;

var
  CutFrm: TCutFrm;
  StrStartCutPoint, StrEndCutPoint : string;
  SourceFileName, DestFileName, TempFilename : string;

  // 合并视频所需的变量
  MergerStrStartCutPoint1, MergerStrEndCutPoint1 : string;
  MergerStrStartCutPoint2, MergerStrEndCutPoint2 : string;
  MergerSourceFileName, MergerDestFileName, MergerTempFilename : string;
  TempMergeFile1, TempMergeFile2 : string;
  TempMergeFileTs1, TempMergeFileTs2 : string;
  MergeResultFile : string;

implementation

{$R *.dfm}

procedure TCutFrm.btnCutClick(Sender: TObject);
begin
  // 界面设置
  Self.lblCutTip.Visible := False;
  Self.lblCutTip1.Visible := True;
  Self.lblCutTip1.Caption := '正在裁剪视频，请稍后...';
  Self.lblComp.Visible := False;
  Self.rzprgrsbr2.Visible := False;
  Self.rzprgrsbr3.Visible := True;
  Self.rzprgrsbr3.Percent := 0;
  Self.rzprgrsbrMergecut1.Visible := False;
  Self.rzprgrsbrMergecut2.Visible := False;
  Self.rzprgrsbrMergecut3.Visible := False;
  Self.rzprgrsbrMergecut4.Visible := False;
  Self.rzprgrsbrMergecut5.Visible := False;
  Self.btnMerger.Enabled := False;
  Self.btnTransEncoding.Enabled := False;

  Core.StartCut(StrStartCutPoint, StrEndCutPoint, TempFilename, DestFileName);
end;

procedure TCutFrm.UpdateProgressBar(progress: Integer);
begin
  Self.rzprgrsbr2.Percent := progress;
  Self.rzprgrsbr2.Refresh;
  if progress = 100 then
  begin
    Self.btnConvert.Enabled := True;
    Self.btnMerger.Enabled := True;
    Self.lblCutTip.Visible := False;
    Self.lblComp.Visible := True;
  end;
end;

procedure TCutFrm.UpdateProgressBar2(progress: Integer);
begin
  Self.rzprgrsbr3.Percent := progress;
  Self.rzprgrsbr3.Refresh;
  if progress = 100 then
  begin
    Self.lblComp.Visible := True;
    Self.btnMerger.Enabled := True;
    Self.btnTransEncoding.Enabled := True;
    Self.lblCutTip1.Visible := False;
  end;
end;

procedure TCutFrm.FormShow(Sender: TObject);
begin
  // 全局变量初始化
  StrStartCutPoint := '';
  StrEndCutPoint := '';
  SourceFileName := '';
  DestFileName := '';
  TempFilename := '';
  MergerStrStartCutPoint1 := '';
  MergerStrEndCutPoint1 := '';
  MergerStrStartCutPoint2 := '';
  MergerStrEndCutPoint2 := '';
  MergerSourceFileName := '';
  MergerDestFileName := '';
  MergerTempFilename := '';
  TempMergeFile1 := '';
  TempMergeFile2 := '';
  TempMergeFileTs1 := '';
  TempMergeFileTs2 := '';
  MergeResultFile := '';
  // 界面初始化
  Self.rzprgrsbr2.Visible := True;
  Self.rzprgrsbr2.Percent := 0;
  Self.rzprgrsbr3.Visible := False;
  Self.rzprgrsbr3.Percent := 0;
  Self.rzprgrsbrMergecut1.Visible := False;
  Self.rzprgrsbrMergecut1.Percent := 0;
  Self.rzprgrsbrMergecut2.Visible := False;
  Self.rzprgrsbrMergecut2.Percent := 0;
  Self.rzprgrsbrMergecut3.Visible := False;
  Self.rzprgrsbrMergecut3.Percent := 0;
  Self.rzprgrsbrMergecut4.Visible := False;
  Self.rzprgrsbrMergecut4.Percent := 0;
  Self.rzprgrsbrMergecut5.Visible := False;
  Self.rzprgrsbrMergecut5.Percent := 0;
  Self.lblCutTip.Visible := False;
  Self.lblCutTip1.Visible := False;
  Self.lblComp.Visible := False;

  Self.btnConvert.Enabled := False;
  Self.btnMerger.Enabled := False;
end;

procedure TCutFrm.btnCancelClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TCutFrm.btnSelSrcClick(Sender: TObject);
var
  FileExt : string;
begin
  with dlgSaveCutDest do
  begin
    Options:=Options-[ofAllowMultiSelect];
    if Execute then
      edtSaveFilePath.Text := dlgSaveCutDest.FileName;
    FileExt := ExtractFileExt(dlgSaveCutDest.FileName);
    if SameText(FileExt, '.mp4') or SameText(FileExt, '.avi') or
    SameText(FileExt, '.flv') or SameText(FileExt, '.mpg') or SameText(FileExt, '.mov') then
      Exit
    else
    begin
      case dlgSaveCutDest.FilterIndex of
        1:edtSaveFilePath.Text := edtSaveFilePath.Text + '.mp4';
        2:edtSaveFilePath.Text := edtSaveFilePath.Text + '.avi';
        3:edtSaveFilePath.Text := edtSaveFilePath.Text + '.flv';
        4:edtSaveFilePath.Text := edtSaveFilePath.Text + '.mpg';
        5:edtSaveFilePath.Text := edtSaveFilePath.Text + '.mov';
      end;
    end;
  end;
end;

procedure TCutFrm.btnTransEncodingClick(Sender: TObject);
var
  StartTime : TTime;
  EndTime   : TTime;
  CmdLine   : string;
  FileExt   : string;   // 获取正在播放文件的后缀，用于裁剪时与保存文件名对比
begin
  SourceFileName := GlobVar.PlayFileName;
  FileExt := ExtractFileExt(SourceFileName);
  DestFileName := Trim(Self.edtSaveFilePath.Text);

  if (DestFileName = '') or (not SameText(FileExt,  ExtractFileExt(DestFileName)))  then
  begin
    MessageBox(Self.handle, '文件保存路径有误或保存格式与原视频不一致！', '提示', MB_ICONINFORMATION + MB_OK);
    Exit;
  end;
  // 界面设置
  Self.lblCutTip.Visible := True;
  Self.lblCutTip1.Visible := False;
  Self.lblComp.Visible := False;
  Self.rzprgrsbr2.Visible := True;
  Self.rzprgrsbr2.Percent := 0;
  Self.rzprgrsbr3.Visible := False;
  Self.rzprgrsbr3.Percent := 0;
  Self.rzprgrsbrMergecut1.Visible := False;
  Self.rzprgrsbrMergecut1.Percent := 0;
  Self.rzprgrsbrMergecut2.Visible := False;
  Self.rzprgrsbrMergecut2.Percent := 0;
  Self.rzprgrsbrMergecut3.Visible := False;
  Self.rzprgrsbrMergecut3.Percent := 0;
  Self.rzprgrsbrMergecut4.Visible := False;
  Self.rzprgrsbrMergecut4.Percent := 0;
  Self.rzprgrsbrMergecut5.Visible := False;
  Self.rzprgrsbrMergecut5.Percent := 0;
  Self.btnConvert.Enabled := False;
  Self.btnMerger.Enabled := False;

  StartTime:= GlobVar.StartCutPonit * GlobVar.VideoLength/SecsPerDay/100;
  EndTime := (GlobVar.EndCutPonit - GlobVar.StartCutPonit) * GlobVar.VideoLength / SecsPerDay/100;
  StrStartCutPoint:= TimeTostr(StartTime);
  StrEndCutPoint := TimeToStr(EndTime);

  TempFilename := 'temp' + FileExt;
  GlobVar.CutTempFilename := TempFilename;

  Log_Info('StrStartCutPoint : %s', [StrStartCutPoint]);
  Log_Info('StrEndCutPoint : %s', [StrEndCutPoint]);
  Core.TransFrameEncoding(SourceFileName, TempFilename);
end;

procedure TCutFrm.btnMergerClick(Sender: TObject);
var
  StartTime1 : TTime;
  EndTime1   : TTime;
  StartTime2 : TTime;
  EndTime2   : TTime;
  CmdLine    : string;
  FileExt    : string;   // 获取正在播放文件的后缀，用于裁剪时与保存文件名对比
begin
  SourceFileName := GlobVar.PlayFileName;
  FileExt := ExtractFileExt(SourceFileName);

  MergeResultFile := Trim(Self.edtSaveFilePath.Text);
  if (MergeResultFile = '') or (not SameText(FileExt,  ExtractFileExt(DestFileName)))  then
  begin
    MessageBox(Self.handle, '文件保存路径有误或保存格式与原视频不一致！', '提示', MB_ICONINFORMATION + MB_OK);
    Exit;
  end;
  // 界面设置
  Self.lblCutTip.Visible := False;
  Self.lblCutTip1.Visible := True;
  Self.lblCutTip1.Caption := '正在裁剪视频1，请稍后...';
  Self.lblComp.Visible := False;
  Self.rzprgrsbr2.Visible := False;
  Self.rzprgrsbr3.Visible := False;
  Self.rzprgrsbrMergecut1.Visible := True;
  Self.rzprgrsbrMergecut1.Percent := 0;
  Self.rzprgrsbrMergecut2.Visible := False;
  Self.rzprgrsbrMergecut3.Visible := False;
  Self.rzprgrsbrMergecut4.Visible := False;
  Self.rzprgrsbrMergecut5.Visible := False;
  Self.btnConvert.Enabled := False;
  Self.btnTransEncoding.Enabled := False;

  GlobVar.tempProgress := 0;

  TempMergeFile1 := 'cut1.mp4';
  globvar.TempMergeFile1 := TempMergeFile1;
  TempMergeFile2 := 'cut2.mp4';
  GlobVar.TempMergeFile2 := TempMergeFile2;
  TempMergeFileTs1 := 'cut1.ts';
  GlobVar.TempMergeFileTs1 := TempMergeFileTs1;
  TempMergeFileTs2 := 'cut2.ts';
  GlobVar.TempMergeFileTs2 := TempMergeFileTs2;

  StartTime1:= 0;
  EndTime1 := (GlobVar.StartCutPonit) * GlobVar.VideoLength / SecsPerDay/100;
  StartTime2:= (GlobVar.EndCutPonit) * GlobVar.VideoLength / SecsPerDay/100;
  EndTime2 := (GlobVar.MergerCutPoint -GlobVar.EndCutPonit) * GlobVar.VideoLength / SecsPerDay/100;

  MergerStrStartCutPoint1:= TimeTostr(StartTime1);
  MergerStrEndCutPoint1 := TimeToStr(EndTime1);
  MergerStrStartCutPoint2:= TimeTostr(StartTime2);
  MergerStrEndCutPoint2 := TimeToStr(EndTime2);
  Log_info('st1,%s,end1,%s,st2,%s,end2,%s',[MergerStrStartCutPoint1,MergerStrEndCutPoint1,MergerStrStartCutPoint2,MergerStrEndCutPoint2]);

  Core.StartMergerCut1(MergerStrStartCutPoint1, MergerStrEndCutPoint1, GlobVar.CutTempFileName, TempMergeFile1);
end;

procedure TCutFrm.UpdateProgressBarMergerCut1(progress: Integer);
begin
  Self.rzprgrsbrMergecut1.Percent := progress;
  Self.rzprgrsbrMergecut1.Refresh;
  if progress = 100 then
  begin
    Self.lblCutTip1.Visible := True;
    Self.lblCutTip1.Caption := '正在裁剪视频2，请稍后...';
    Self.rzprgrsbr2.Visible := False;
    Self.rzprgrsbr3.Visible := False;
    Self.rzprgrsbrMergecut1.Visible := False;
    Self.rzprgrsbrMergecut2.Visible := True;
    Self.rzprgrsbrMergecut3.Visible := False;
    Self.rzprgrsbrMergecut4.Visible := False;
    Self.rzprgrsbrMergecut5.Visible := False;
    GlobVar.tempProgress := 0;

    Core.StartMergerCut2(MergerStrStartCutPoint2, MergerStrEndCutPoint2, GlobVar.CutTempFileName, TempMergeFile2);
  end;
end;

procedure TCutFrm.UpdateProgressBarMergerCut2(progress: Integer);
begin
  Self.rzprgrsbrMergecut2.Percent := progress;
  Self.rzprgrsbrMergecut2.Refresh;
  if progress = 100 then
  begin
    Self.lblCutTip1.Visible := True;
    Self.lblCutTip1.Caption := '正在转码视频1，请稍后...';
    Self.rzprgrsbr2.Visible := False;
    Self.rzprgrsbr3.Visible := False;
    Self.rzprgrsbrMergecut1.Visible := False;
    Self.rzprgrsbrMergecut2.Visible := False;
    Self.rzprgrsbrMergecut3.Visible := True;
    Self.rzprgrsbrMergecut4.Visible := False;
    Self.rzprgrsbrMergecut5.Visible := False;
    GlobVar.tempProgress := 0;

    Core.StartTempToTs1(TempMergeFile1, TempMergeFileTs1);
  end;
end;

procedure TCutFrm.UpdateProgressBarMergerCutTs1(progress: Integer);
begin
  Self.rzprgrsbrMergecut3.Percent := progress;
  Self.rzprgrsbrMergecut3.Refresh;
  if progress = 100 then
  begin
    Self.lblCutTip1.Visible := True;
    Self.lblCutTip1.Caption := '正在转码视频2，请稍后...';
    Self.rzprgrsbr2.Visible := False;
    Self.rzprgrsbr3.Visible := False;
    Self.rzprgrsbrMergecut1.Visible := False;
    Self.rzprgrsbrMergecut2.Visible := False;
    Self.rzprgrsbrMergecut3.Visible := False;
    Self.rzprgrsbrMergecut4.Visible := True;
    Self.rzprgrsbrMergecut5.Visible := False;

    GlobVar.tempProgress := 0;

    Core.StartTempToTs2(TempMergeFile2, TempMergeFileTs2);
  end;
end;


procedure TCutFrm.UpdateProgressBarMergerCutTs2(progress: Integer);
begin
  Self.rzprgrsbrMergecut4.Percent := progress;
  Self.rzprgrsbrMergecut4.Refresh;
  if progress = 100 then
  begin
    Self.lblCutTip1.Visible := True;
    Self.lblCutTip1.Caption := '正在合并视频，请稍后...';
    Self.rzprgrsbr2.Visible := False;
    Self.rzprgrsbr3.Visible := False;
    Self.rzprgrsbrMergecut1.Visible := False;
    Self.rzprgrsbrMergecut2.Visible := False;
    Self.rzprgrsbrMergecut3.Visible := False;
    Self.rzprgrsbrMergecut4.Visible := False;
    Self.rzprgrsbrMergecut5.Visible := True;

    GlobVar.tempProgress := 0;

    Core.StartConcat(TempMergeFileTs1, TempMergeFileTs2, MergeResultFile);
  end;
end;

procedure TCutFrm.UpdateProgressBarMerger(progress: Integer);
begin
  Self.rzprgrsbrMergecut5.Percent := progress;
  Self.rzprgrsbrMergecut5.Refresh;
  if progress = 100 then
  begin
    Self.lblComp.Visible := True;
    Self.lblCutTip1.Visible := False;
    Self.lblCutTip.Visible := False;
    Self.btnConvert.Enabled := True;
    Self.btnTransEncoding.Enabled := True;
    GlobVar.tempProgress := 0;
  end;
end;


end.
