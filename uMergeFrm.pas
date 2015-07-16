unit uMergeFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RzPrgres, StdCtrls, Core, uGlobVar;
Const
    WM_MINE=WM_USER+100;

type
  TMergeFrm = class(TForm)
    edt1: TEdit;
    edt2: TEdit;
    btnMerge: TButton;
    rzprgrsbrMerge1: TRzProgressBar;
    rzprgrsbrMerge2: TRzProgressBar;
    rzprgrsbrMerge3: TRzProgressBar;
    lbl1: TLabel;
    procedure btnMergeClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure Mine(var msg: TMSG);message WM_MINE;
  public
    procedure UpdateProgressBar1(progress: Integer);
    procedure UpdateProgressBar2(progress: Integer);
    procedure UpdateProgressBar3(progress: Integer);
    function WinExecAndWait32(FileName: string; Visibility: integer): integer;
  end;

var
  MergeFrm: TMergeFrm;
  StrStartCutPoint, StrEndCutPoint : string;
  SourceFileName, DestFileName, TempFilename : string;

implementation

{$R *.dfm}

procedure TMergeFrm.btnMergeClick(Sender: TObject);
 var
  StartTime, EndTime: TTime;
  CmdLine : string;
  FileExt : string;   // 获取正在播放文件的后缀，用于裁剪时与保存文件名对比
  MergerTempFile : string;
begin

  SourceFileName := GlobVar.PlayFileName;
  FileExt := ExtractFileExt(SourceFileName);

  MergerTempFile := '1.mp4';

  StartTime:= 0;
  EndTime := (GlobVar.StartCutPonit) * GlobVar.VideoLength / SecsPerDay/100;
  StrStartCutPoint:= TimeTostr(StartTime);
  StrEndCutPoint := TimeToStr(EndTime);

//  TempFilename := 'temp' + FileExt;
//  GlobVar.CutTempFilename := TempFilename;


   Core.TransFrameEncoding(SourceFileName, MergerTempFile);
end;

procedure TMergeFrm.UpdateProgressBar1(progress: Integer);
var
  srcFile, destFile : string;

begin

  Self.rzprgrsbrMerge1.Percent := progress;
  Self.rzprgrsbrMerge1.Refresh;
  if progress = 100 then
  begin
//    Sendmessage(handle,WM_MINE,0,0);
    srcFile := 'm1.avi';
    destFile := 'm11.mp4';
  //  GlobVar.ConvertID := 2;
    Core.StartConvert(srcFile, destFile);
  end;
end;

procedure TMergeFrm.UpdateProgressBar2(progress: Integer);
var
  srcFile, destFile : string;
  CmdLine : string;
begin
  Self.rzprgrsbrMerge2.Percent := progress;
  Self.rzprgrsbrMerge2.Refresh;
  if progress = 100 then
  begin
    srcFile := 'm1.mpg';
    destFile := 'm2.mpg';


    CmdLine:='copy ' + '/b ' + '/y ' + srcFile + destFile + ' result.mpge';
    WinExecAndWait32(PChar('cmd /c '+ CmdLine),SW_HIDE);
    

    srcFile := 'result.mpge';
    destFile := 'result.mp4';
    GlobVar.ConvertID := 3;
    Core.StartConvert(srcFile, destFile);

    // 合并
  //  Core.StartMerge(srcFile, destFile);
  end;

  // 找出转换的依赖性
end;
procedure TMergeFrm.UpdateProgressBar3(progress: Integer);
var
  srcFile, destFile : string;
begin
  Self.rzprgrsbrMerge3.Percent := progress;
  Self.rzprgrsbrMerge3.Refresh;
  if progress = 100 then
  begin
    Self.lbl1.Visible := TRue ;
  end;

  // 找出转换的依赖性
end;

procedure TMergeFrm.FormShow(Sender: TObject);
begin
  Self.lbl1.Visible := False;
end;

function TMergeFrm.WinExecAndWait32(FileName: string; Visibility: integer): integer;
var
  zAppName          : array[0..25600] of char;
  zCurDir           : array[0..255] of char;
  WorkDir           : string;
  StartupInfo       : TStartupInfo;
  ProcessInfo       : TProcessInformation;
begin
  StrPCopy(zAppName, FileName);
  GetDir(0, WorkDir);
  StrPCopy(zCurDir, WorkDir);
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := Visibility;
  if not CreateProcess(nil,
    zAppName,                           { pointer to command line string }
    nil,                                { pointer to process security attributes }
    nil,                                { pointer to thread security attributes }
    false,                              { handle inheritance flag }
    CREATE_NEW_CONSOLE or               { creation flags }
    NORMAL_PRIORITY_CLASS,
    nil,                                { pointer to new environment block }
    nil,                                { pointer to current directory name }
    StartupInfo,                        { pointer to STARTUPINFO }
    ProcessInfo) then
    Result := -1                        { pointer to PROCESS_INF }
  else
  begin
    WaitforSingleObject(ProcessInfo.hProcess, INFINITE);
    GetExitCodeProcess(ProcessInfo.hProcess, DWORD(Result));
  end;
end;

procedure TMergeFrm.Mine(var msg: TMSG);
var
  srcFile, destFile : string;
begin
    Sleep(2000);
    srcFile := 'm1.avi';
    destFile := 'm12.mp4';
    GlobVar.ConvertID := 2;
    Core.StartConvert(srcFile, destFile);
end;


end.

