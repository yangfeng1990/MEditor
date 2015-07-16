unit Core;

interface

uses
  Windows, SysUtils, Classes, Forms, Menus, Controls, Dialogs;

const OSDFont='Arial.ttf';

type
  TStatus=(sNone,sOpening,sClosing,sPlaying,sPaused,sStopped,sError);
type
  TWin9xWarnLevel=(wlWarn,wlReject,wlAccept);
var
  Status:TStatus;
  Win9xWarnLevel:TWin9xWarnLevel;
  HomeDir:string;
  MediaURL:string;
  DisplayURL:string;
  FirstOpen:boolean;
  AutoPlay:boolean;
  AudioID:integer;
  SubID:integer;
  AudioOut:integer;
  AudioDev:integer;
  Postproc:integer;
  Deinterlace:integer;
  Aspect:integer;
  ReIndex:boolean;
  SoftVol:boolean;
  PriorityBoost:boolean;
  Params:string;
  Duration:string;
  HaveAudio,HaveVideo:boolean;
  NativeWidth,NativeHeight:integer;
  PercentPos:integer;
  SecondPos:integer;
  OSDLevel:integer;
  Volume:integer;
  Mute:boolean;
  LastVolume:integer;
  
  TotalDuration : Integer;    // 视频总时长  单位 s
  CurTotalDurtion : Integer;  // 当前已转换时长  单位 s
  VideoLength : string;

var StreamInfo:record
      FileName, FileFormat, PlaybackTime: string;
      Video:record
        Decoder, Codec: string;
        Bitrate, Width, Height: integer;
        FPS, Aspect: real;
      end;
      Audio:record
        Decoder, Codec: string;
        Bitrate, Rate, Channels: integer;
      end;
      ClipInfo:array[0..9]of record
        Key, Value: string;
      end;
    end;

function SecondsToTime(Seconds:integer):string;
function EscapeParam(const Param:string):string;
procedure Init;
procedure Start;
procedure Stop;
procedure Restart;
procedure ForceStop;
function Running:boolean;
procedure Terminate;
procedure SendCommand(Command:string);
procedure SendVolumeChangeCommand(Volume:integer);
procedure SetOSDLevel(Level:integer);
procedure ResetStreamInfo;
// 开始转换
procedure StartConvert(const srcFile, destFile: string);
// 改变帧内编码方式，只有这样剪切的时间才准确
procedure TransFrameEncoding(SrcFile, DestFile: string);
// 剪切视频, StrStartCutPoint为起始点时间，StrDuration为持续时间(剪切后视频的长度)
procedure StartCut(StrStartCutPoint, StrDuration, SrcFile, DestFile: string);
// 合并视频
procedure StartMergerCut1(StrStartCutPoint, StrDuration, SrcFile, DestFile: string);
procedure StartMergerCut2(StrStartCutPoint, StrDuration, SrcFile, DestFile: string);
procedure StartTempToTs1(srcFile, destFile:string);
procedure StartTempToTs2(srcFile, destFile:string);
procedure StartConcat(SrcFileTs1, SrcFileTs2, DestFile: string);
// 分割字符串
function SplitString(const source, ch: string): TStringList;

implementation

uses Main,Log,plist,Info, uConvertFrm, uCutFrm, uGlobVar, pscpLogger, uMergeFrm;

type
  TClientWaitThread=class(TThread)
    private procedure ClientDone;virtual;
    protected procedure Execute; override;
    public hProcess:Cardinal;
  end;
// TWaitThreadFFMpeg继承 TClientWaitThread，重写ClientDone方法，为了解决转换线程
// 结束后，kill掉主线程，重写后，转换、合并等线程结束对主线程无影响
type
  TWaitThreadFFMpeg=class(TClientWaitThread)
    public procedure ClientDone;override;
  end;

type
  TWaitThreadTransFrame=class(TClientWaitThread)
    private procedure ClientDone;override;
  end;

type
  TWaitThreadCut=class(TClientWaitThread)
    private procedure ClientDone;override;
  end;

type
  TWaitThreadMergerCut1=class(TClientWaitThread)
    private procedure ClientDone;override;
  end;

type
  TWaitThreadMergerCut2=class(TClientWaitThread)
    private procedure ClientDone;override;
  end;

type
  TWaitThreadMergerCutTs1=class(TClientWaitThread)
    private procedure ClientDone;override;
  end;

type
  TWaitThreadMergerCutTs2=class(TClientWaitThread)
    private procedure ClientDone;override;
  end;

type
  TWaitThreadMerger=class(TClientWaitThread)
    private procedure ClientDone;override;
  end;

type
  TProcessor=class(TThread)
    private Data:string;
    private procedure Process;
    protected procedure Execute; override;
    public hPipe:Cardinal;
    public Master: string; // 判断处理哪一种命令
  end;

var
  ClientWaitThread:TClientWaitThread;
  WaitThreadFFMpeg : TWaitThreadFFMpeg;
  WaitThreadTransFrame : TWaitThreadTransFrame;
  WaitThreadCut : TWaitThreadCut;
  WaitThreadMergerCut1 : TWaitThreadMergerCut1;
  WaitThreadMergerCut2 : TWaitThreadMergerCut2;
  WaitThreadMergerCutTs1 : TWaitThreadMergerCutTs1;
  WaitThreadMergerCutTs2 : TWaitThreadMergerCutTs2;
  WaitThreadMerger : TWaitThreadMerger;

  MPProcor, FMProcor, FEProcor, CutProcor:TProcessor;
  MergerCutProcor1, MergerCutProcor2, MergerCutProcorTs1, MergerCutProcorTs2, MergerCutProcor : TProcessor;
  ClientProcess,ReadPipe,WritePipe,ReadPipeFM,ReadPipiFMFrame, ReadPipeCut:Cardinal;
  ReadPipeMerCut1, ReadPipeMerCut2, ReadPipeMerCutTs1, ReadPipeMerCutTs2, ReadPipeMer : Cardinal;
  FirstChance:boolean;
  ExplicitStop:boolean;
  ExitCode:DWORD;
  FontPath:string;
  LastLine:string;
  LineRepeatCount:integer;
  LastCacheFill:string;

procedure HandleMPInputLine(Line:string); forward;
procedure HandleFMInputLine(Line:string); forward;
procedure HandleFEInputLine(Line:string); forward;
procedure HandleCUTInputLine(Line:string); forward;
procedure HandleMergerCUT1InputLine(Line:string); forward;
procedure HandleMergerCUT2InputLine(Line:string); forward;
procedure HandleMergerCUTTs1InputLine(Line:string); forward;
procedure HandleMergerCUTTs2InputLine(Line:string); forward;
procedure HandleMergeInputLine(Line:string); forward;
procedure HandleIDLine(ID, Content: string); forward;


function SplitLine(var Line:string):string;
var
  i : integer;
begin
  i:=Pos(#32,Line);
  if (length(Line)<72) OR (i<1) then begin
    Result:=Line;
    Line:='';
    exit;
  end;
  if(i>71) then begin
    Result:=Copy(Line,1,i-1);
    Delete(Line,1,i);
    exit;
  end;
  i:=72; while Line[i]<>#32 do dec(i);
  Result:=Copy(Line,1,i-1);
  Delete(Line,1,i);
end;

function EscapeParam(const Param:string):string;
begin
  if Pos(#32,Param)>0 then Result:=#34+Param+#34 else Result:=Param;
end;

function SecondsToTime(Seconds:integer):string;
var
  m, s : integer;
begin
  if Seconds<0 then Seconds:=0;
  m:=(Seconds DIV 60) MOD 60;
  s:= Seconds MOD 60;
  Result:=IntToStr(Seconds DIV 3600)
          +':'+char(48+m DIV 10)+char(48+m MOD 10)
          +':'+char(48+s DIV 10)+char(48+s MOD 10);
end;


procedure Init;
var WinDir:array[0..MAX_PATH]of char;
var OSVersion:_OSVERSIONINFOA;
begin
//  GetWindowsDirectory(@WinDir[0],MAX_PATH);
  GetEnvironmentVariable('windir',@WinDir[0],MAX_PATH);
  FontPath:=IncludeTrailingPathDelimiter(WinDir)+'Fonts\'+OSDFont;
  if FileExists(FontPath) then
    FontPath:=' -font '+EscapeParam(FontPath)
  else
    FontPath:='';
  HomeDir:=IncludeTrailingPathDelimiter(ExtractFileDir(ExpandFileName(ParamStr(0))));

  // check for Win9x
//  FillChar(OSVersion,sizeof(OSVersion),0);
//  OSVersion.dwOSVersionInfoSize:=sizeof(OSVersion);
//  GetVersionEx(OSVersion);
//  if OSVersion.dwPlatformId<VER_PLATFORM_WIN32_NT
//    then Win9xWarnLevel:=wlWarn
//    else Win9xWarnLevel:=wlAccept;
end;

procedure Start;
var
  DummyPipe1   : THandle;
  DummyPipe2   : THandle;
  si           : TStartupInfo;
  pi           : TProcessInformation;
  sec          : TSecurityAttributes;
  CmdLine      : string;
  s            : string;
  Success      : boolean;
  Error        : DWORD;
  ErrorMessage : array[0..1023]of char;
begin
  if ClientProcess<>0 then
    exit;
  if length(MediaURL)=0 then
    exit;

  if FirstOpen then
  begin
    with MainForm do
    begin
      MAudio.Clear;
      MAudio.Enabled:=false;
      MSubtitle.Clear;
      MSubtitle.Enabled:=false;
    end;
    AudioID:=-1; SubID:=-1;
  end;

  Status:=sOpening;
  MainForm.UpdateStatus;

//  if Win9xWarnLevel=wlWarn then begin
//    case MessageDlg(
//           'MPUI will not run properly on Win9x systems. Continue anyway?',
//           mtWarning,[mbYes,mbNo],0)
//    of
//      mrYes:Win9xWarnLevel:=wlAccept;
//      mrNo:Win9xWarnLevel:=wlReject;
//    end;
//  end;
//  if Win9xWarnLevel=wlReject then begin
//    LogForm.TheLog.Text:='not executing MPlayer: invalid Operating System version';
//    Status:=sError;
//    MainForm.UpdateStatus;
//    MainForm.SetupStop(True);
//    exit;
//  end; 

  FirstChance:=true;
  ClientWaitThread:=TClientWaitThread.Create(true);
  MPProcor := TProcessor.Create(true);

  CmdLine:=EscapeParam(HomeDir+'mplayer.exe')+' -slave -identify'
          +' -wid '+IntToStr(MainForm.InnerPanel.Handle)+' -colorkey 0x101010'
          +' -nokeepaspect -framedrop -autosync 100 -vf screenshot'+FontPath;
  if ReIndex then
    CmdLine:=CmdLine+' -idx';
  if SoftVol then
    CmdLine:=CmdLine+' -softvol -softvol-max 1000';
  if PriorityBoost then
    CmdLine:=CmdLine+' -priority abovenormal';
  case AudioOut of
    0:CmdLine:=CmdLine+' -nosound';
    1:CmdLine:=CmdLine+' -ao null';
    2:CmdLine:=CmdLine+' -ao win32';
    3:CmdLine:=CmdLine+' -ao dsound:device='+IntToStr(AudioDev);
  end;
  if (AudioID>=0) AND (AudioOut>0) then
    CmdLine:=CmdLine+' -aid '+IntToStr(AudioID);
  if SubID>=0 then
    CmdLine:=CmdLine+' -sid '+IntToStr(SubID);
  case Aspect of
    1:CmdLine:=CmdLine+' -aspect 4:3';
    2:CmdLine:=CmdLine+' -aspect 16:9';
    3:CmdLine:=CmdLine+' -aspect 2.35';
  end;
  case Postproc of
    1:CmdLine:=CmdLine+' -autoq 10 -vf-add pp';
    2:CmdLine:=CmdLine+' -vf-add pp=hb/vb/dr';
  end;
  case Deinterlace of
    1:CmdLine:=CmdLine+' -vf-add lavcdeint';
    2:CmdLine:=CmdLine+' -vf-add kerndeint';
  end;
  if length(Params)>0 then
    CmdLine:=CmdLine+#32+Params;
  CmdLine:=CmdLine+#32+MediaURL;

  with LogForm do
  begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
  end;

  HaveAudio:=true;
  HaveVideo:=true;
  NativeWidth:=0;
  NativeHeight:=0;
  PercentPos:=0;
  SecondPos:=-1;
  OSDLevel:=1;
  ExplicitStop:=false;
  Duration:='0:00:00';
  ResetStreamInfo;
  StreamInfo.FileName:=MediaURL;
  Log_Info('core Start filename : %s', [StreamInfo.FileName]);
  GlobVar.PlayFileName := StreamInfo.FileName;
  LastLine:=''; LineRepeatCount:=0;
  LastCacheFill:='';

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipe,DummyPipe1,@sec,0);

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(DummyPipe2,WritePipe,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdInput:=DummyPipe2;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;
  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);
  CloseHandle(DummyPipe2);

  if not Success then
  begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting MPlayer:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if MPlayer.exe is installed in the same directory as MPUI.');
    ClientWaitThread.ClientDone;  // this is a synchronized function, so I may                                  // call it here from this thread as well
    exit;
  end;

  ClientProcess:=pi.hProcess;
  ClientWaitThread.hProcess:=ClientProcess;
  MPProcor.hPipe:=ReadPipe;
  MPProcor.Master := 'MPlayer';

  ClientWaitThread.Resume;
  MPProcor.Resume;
  MainForm.SetupStart;

  if AudioOut>1 then
  begin
    // init volume adjustments
    if AudioOut=3 then
      LastVolume:=100;  // DirectSound always starts at 100%
    if SoftVol then
      LastVolume:=-1;  // SoftVol always starts ... somewhere else
    if Volume<>LastVolume then
      SendVolumeChangeCommand(Volume);
    if Mute then
      SendCommand('mute');
  end;
end;

procedure StartConvert(const srcFile, destFile: string);
var
  DummyPipe1   : THandle;
  DummyPipe2   : THandle;
  si           : TStartupInfo;
  pi           : TProcessInformation;
  sec          : TSecurityAttributes;
  CmdLine      : string;
  s            : string;
  Success      : boolean;
  Error        : DWORD;
  ErrorMessage : array[0..1023]of char;
begin
  WaitThreadFFMpeg:=TWaitThreadFFMpeg.Create(true);
  FMProcor:=TProcessor.Create(true);
  CmdLine:=EscapeParam(HomeDir+'ffmpeg.exe') + ' -i '
          + srcFile + ' '
          + destFile + ' -y';

  with LogForm do
  begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
    AddLine('nLength :' + IntToStr(sizeof(sec)));
  end;

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipeFM,DummyPipe1,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;


  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);

  if not Success then
  begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting FFmpeg:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if ffmpeg.exe is installed in the same directory as MEditor.');
    WaitThreadFFMpeg.ClientDone;
    exit;
  end;

  ClientProcess:=pi.hProcess;
  WaitThreadFFMpeg.hProcess:=ClientProcess;
  FMProcor.hPipe:=ReadPipeFM;
  FMProcor.Master := 'FFMpeg';

  WaitThreadFFMpeg.Resume;
  FMProcor.Resume;
end;

procedure TransFrameEncoding(SrcFile, DestFile: string);
var
  DummyPipe1   : THandle;
  DummyPipe2   : THandle;
  si           : TStartupInfo;
  pi           : TProcessInformation;
  sec          : TSecurityAttributes;
  CmdLine      : string;
  s            : string;
  Success      : boolean;
  Error        : DWORD;
  ErrorMessage : array[0..1023]of char;
begin
  WaitThreadTransFrame:=TWaitThreadTransFrame.Create(true);
  FEProcor:=TProcessor.Create(true);
  CmdLine:=EscapeParam(HomeDir+'ffmpeg.exe')+' -i '
          + SrcFile + ' -qscale 0 ' + '-intra ' + '-y '
          + DestFile;

  with LogForm do
  begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
    AddLine('nLength :' + IntToStr(sizeof(sec)));
  end;

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipiFMFrame,DummyPipe1,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;

  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);

  if not Success then
  begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting FFmpeg:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if ffmpeg.exe is installed in the same directory as MEditor.');
    WaitThreadTransFrame.ClientDone;
    exit;
  end;

  ClientProcess:=pi.hProcess;
  WaitThreadTransFrame.hProcess:=ClientProcess;
  FEProcor.hPipe:=ReadPipiFMFrame;
  FEProcor.Master := 'FrameEncoding';

  WaitThreadTransFrame.Resume;
  FEProcor.Resume;

end;

procedure StartCut(StrStartCutPoint, StrDuration, SrcFile, DestFile: string);
var
  DummyPipe1   : THandle;
  DummyPipe2   : THandle;
  si           : TStartupInfo;
  pi           : TProcessInformation;
  sec          : TSecurityAttributes;
  CmdLine      : string;
  s            : string;
  Success      : boolean;
  Error        : DWORD;
  ErrorMessage : array[0..1023]of char;
begin
  WaitThreadCut:=TWaitThreadCut.Create(true);
  CutProcor:=TProcessor.Create(true);
  CmdLine:=EscapeParam(HomeDir+'ffmpeg.exe')+' -ss '
          + StrStartCutPoint + ' -vsync 0 ' + '-t ' + StrDuration
          + ' -i ' + SrcFile + ' -vcodec libx264 ' + '-y '
          + DestFile;

  with LogForm do
  begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
    AddLine('nLength :' + IntToStr(sizeof(sec)));
  end;

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipeCut,DummyPipe1,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;

  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);

  if not Success then
  begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting FFmpeg:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if ffmpeg.exe is installed in the same directory as MEditor.');
    WaitThreadCut.ClientDone;
    exit;
  end;

  ClientProcess:=pi.hProcess;
  WaitThreadCut.hProcess:=ClientProcess;
  CutProcor.hPipe:=ReadPipeCut;
  CutProcor.Master := 'FFMpegCut';

  WaitThreadCut.Resume;
  CutProcor.Resume;
end;

procedure StartMergerCut1(StrStartCutPoint, StrDuration, SrcFile, DestFile: string);
var
  DummyPipe1   : THandle;
  DummyPipe2   : THandle;
  si           : TStartupInfo;
  pi           : TProcessInformation;
  sec          : TSecurityAttributes;
  CmdLine      : string;
  s            : string;
  Success      : boolean;
  Error        : DWORD;
  ErrorMessage : array[0..1023]of char;
begin
  WaitThreadMergerCut1:=TWaitThreadMergerCut1.Create(true);
  MergerCutProcor1:=TProcessor.Create(true);
  CmdLine:=EscapeParam(HomeDir+'ffmpeg.exe')+' -ss '
          + StrStartCutPoint + ' -vsync 0 ' + '-t ' + StrDuration
          + ' -i ' + SrcFile + ' -vcodec libx264 ' + '-y '
          + DestFile;

  with LogForm do
  begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
    AddLine('nLength :' + IntToStr(sizeof(sec)));
  end;

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipeMerCut1,DummyPipe1,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;

  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);

  if not Success then
  begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting FFmpeg:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if ffmpeg.exe is installed in the same directory as MEditor.');
    WaitThreadMergerCut1.ClientDone;
    exit;
  end;

  ClientProcess:=pi.hProcess;
  WaitThreadMergerCut1.hProcess:=ClientProcess;
  MergerCutProcor1.hPipe:=ReadPipeMerCut1;
  MergerCutProcor1.Master := 'FFMpegMergerCut1';

  WaitThreadMergerCut1.Resume;
  MergerCutProcor1.Resume;
end;

procedure StartMergerCut2(StrStartCutPoint, StrDuration, SrcFile, DestFile: string);
var
  DummyPipe1   : THandle;
  DummyPipe2   : THandle;
  si           : TStartupInfo;
  pi           : TProcessInformation;
  sec          : TSecurityAttributes;
  CmdLine      : string;
  s            : string;
  Success      : boolean;
  Error        : DWORD;
  ErrorMessage : array[0..1023]of char;
begin
  WaitThreadMergerCut2:=TWaitThreadMergerCut2.Create(true);
  MergerCutProcor2:=TProcessor.Create(true);
  CmdLine:=EscapeParam(HomeDir+'ffmpeg.exe')+' -ss '
          + StrStartCutPoint + ' -vsync 0 ' + '-t ' + StrDuration
          + ' -i ' + SrcFile + ' -vcodec libx264 ' + '-y '
          + DestFile;
  Log_info('StartMergerCut2, StrStartCutPoint :%s,StrDuration :%s',[StrStartCutPoint,StrDuration]);
  with LogForm do
  begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
    AddLine('nLength :' + IntToStr(sizeof(sec)));
  end;

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipeMerCut2,DummyPipe1,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;

  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);

  if not Success then
  begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting FFmpeg:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if ffmpeg.exe is installed in the same directory as MEditor.');
    WaitThreadMergerCut2.ClientDone;
    exit;
  end;

  ClientProcess:=pi.hProcess;
  WaitThreadMergerCut2.hProcess:=ClientProcess;
  MergerCutProcor2.hPipe:=ReadPipeMerCut2;
  MergerCutProcor2.Master := 'FFMpegMergerCut2';

  WaitThreadMergerCut2.Resume;
  MergerCutProcor2.Resume;
end;

procedure StartTempToTs1(srcFile, destFile:string);
var
  DummyPipe1   : THandle;
  DummyPipe2   : THandle;
  si           : TStartupInfo;
  pi           : TProcessInformation;
  sec          : TSecurityAttributes;
  CmdLine      : string;
  s            : string;
  Success      : boolean;
  Error        : DWORD;
  ErrorMessage : array[0..1023]of char;
begin
  WaitThreadMergerCutTs1:=TWaitThreadMergerCutTs1.Create(true);
  MergerCutProcorTs1:=TProcessor.Create(true);
  CmdLine:=EscapeParam(HomeDir+'ffmpeg.exe')+' -i '
          + srcFile + ' -vcodec copy ' + '-acodec copy ' + '-vbsf ' + 'h264_mp4toannexb '
          + DestFile + ' -y';
 
  with LogForm do
  begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
    AddLine('nLength :' + IntToStr(sizeof(sec)));
  end;

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipeMerCutTs1,DummyPipe1,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;

  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);

  if not Success then
  begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting FFmpeg:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if ffmpeg.exe is installed in the same directory as MEditor.');
    WaitThreadMergerCutTs1.ClientDone;
    exit;
  end;

  ClientProcess:=pi.hProcess;
  WaitThreadMergerCutTs1.hProcess:=ClientProcess;
  MergerCutProcorTs1.hPipe:=ReadPipeMerCutTs1;
  MergerCutProcorTs1.Master := 'FFMpegMergerCutTs1';
  WaitThreadMergerCutTs1.Resume;
  MergerCutProcorTs1.Resume;
end;

procedure StartTempToTs2(srcFile, destFile: string);
var
  DummyPipe1   : THandle;
  DummyPipe2   : THandle;
  si           : TStartupInfo;
  pi           : TProcessInformation;
  sec          : TSecurityAttributes;
  CmdLine      : string;
  s            : string;
  Success      : boolean;
  Error        : DWORD;
  ErrorMessage : array[0..1023]of char;
begin
  WaitThreadMergerCutTs2:=TWaitThreadMergerCutTs2.Create(true);
  MergerCutProcorTs2:=TProcessor.Create(true);
  CmdLine:=EscapeParam(HomeDir+'ffmpeg.exe')+' -i '
          + srcFile + ' -vcodec copy ' + '-acodec copy ' + '-vbsf ' + 'h264_mp4toannexb '
          + DestFile + ' -y';

  with LogForm do begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
    AddLine('nLength :' + IntToStr(sizeof(sec)));
  end;

  with sec do begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipeMerCutTs2,DummyPipe1,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;

  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);

  if not Success then begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting FFmpeg:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if ffmpeg.exe is installed in the same directory as MEditor.');
    WaitThreadMergerCutTs2.ClientDone;
    exit;
  end;

  ClientProcess:=pi.hProcess;
  WaitThreadMergerCutTs2.hProcess:=ClientProcess;
  MergerCutProcorTs2.hPipe:=ReadPipeMerCutTs2;
  MergerCutProcorTs2.Master := 'FFMpegMergerCutTs2';
  WaitThreadMergerCutTs2.Resume;
  MergerCutProcorTs2.Resume;

end;

procedure StartConcat(SrcFileTs1, SrcFileTs2, DestFile: string);
var
  DummyPipe1,DummyPipe2:THandle;
  si:TStartupInfo;
  pi:TProcessInformation;
  sec:TSecurityAttributes;
  CmdLine,s:string;
  Success:boolean; Error:DWORD;
  ErrorMessage:array[0..1023]of char;
begin
  WaitThreadMerger:=TWaitThreadMerger.Create(true);
  MergerCutProcor:=TProcessor.Create(true);
  CmdLine:=EscapeParam(HomeDir+'ffmpeg.exe')+' -i '
          + '"concat:' +  SrcFileTs1 + '|' + SrcFileTs2 + '"' + ' -acodec copy '
          + '-vcodec copy ' + '-absf ' + 'aac_adtstoasc '
          + DestFile + ' -y';

  with LogForm do
  begin
    TheLog.Clear;
    AddLine('command line:');
    s:=CmdLine;
    while length(s)>0 do
      AddLine(SplitLine(s));
    AddLine('');
    AddLine('nLength :' + IntToStr(sizeof(sec)));
  end;

  with sec do
  begin
    nLength:=sizeof(sec);
    lpSecurityDescriptor:=nil;
    bInheritHandle:=true;
  end;
  CreatePipe(ReadPipeMer,DummyPipe1,@sec,0);

  FillChar(si,sizeof(si),0);
  si.cb:=sizeof(si);
  si.dwFlags:=STARTF_USESTDHANDLES;
  si.hStdOutput:=DummyPipe1;
  si.hStdError:=DummyPipe1;

  Success:=CreateProcess(nil,PChar(CmdLine),nil,nil,true,DETACHED_PROCESS,nil,PChar(HomeDir),si,pi);
  Error:=GetLastError();

  CloseHandle(DummyPipe1);

  if not Success then
  begin
    LogForm.AddLine('Error '+IntToStr(Error)+' while starting FFmpeg:');
    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,nil,Error,0,@ErrorMessage[0],1023,nil);
    LogForm.AddLine(ErrorMessage);
    if Error=2 then
      LogForm.AddLine('Please check if ffmpeg.exe is installed in the same directory as MEditor.');
    WaitThreadMerger.ClientDone;
    exit;
  end;

  ClientProcess:=pi.hProcess;
  WaitThreadMerger.hProcess:=ClientProcess;
  MergerCutProcor.hPipe:=ReadPipeMer;
  MergerCutProcor.Master := 'FFMpegMerger';
  WaitThreadMerger.Resume;
  MergerCutProcor.Resume;
end;

procedure TClientWaitThread.ClientDone;
var
  WasExplicit:boolean;
begin
  ClientProcess:=0;
  CloseHandle(ReadPipe);
  ReadPipe:=0;
  ClientWaitThread.Terminate;
  if Assigned(MPProcor) then
    MPProcor.Terminate;
  FirstOpen:=false;
  if (Status=sOpening) OR (ExitCode<>0) then
    Status:=sError
  else
  begin
    Status:=sStopped;
  end;
  DisplayURL:='';
  WasExplicit:=ExplicitStop OR (Status=sError);
  MainForm.UpdateStatus;
  MainForm.SetupStop(WasExplicit);
  MainForm.UpdateCaption;
  ExplicitStop:=false;
  if not WasExplicit then
    MainForm.NextFile(1,psPlayed);
  Log_Info('TClientWaitThread.ClientDone',[]);
end;

procedure TClientWaitThread.Execute;
begin
  WaitForSingleObject(hProcess,INFINITE);
  GetExitCodeProcess(hProcess,ExitCode);
  Synchronize(ClientDone);
end;

procedure TWaitThreadFFMpeg.ClientDone;
begin
  if Assigned(WaitThreadFFMpeg)  then
  begin
    CloseHandle(ReadPipeFM);
    ReadPipeFM:=0;
    WaitThreadFFMpeg.Terminate;
    if Assigned(FMProcor) then
    begin
      FMProcor.Terminate;
    end;
    Log_Info('TWaitThreadFFMpeg : ClientDone',[]);
  end;
end;

procedure TWaitThreadTransFrame.ClientDone;
begin
  if Assigned(WaitThreadTransFrame)  then
  begin
    CloseHandle(ReadPipiFMFrame);
    ReadPipiFMFrame:=0;
    WaitThreadTransFrame.Terminate;
    if Assigned(FEProcor) then
    begin
      FEProcor.Terminate;
    end;
    Log_Info('TWaitThreadTransFrame.ClientDone',[]);
  end;
end;

procedure TWaitThreadCut.ClientDone;
begin
  if Assigned(WaitThreadCut)  then
  begin
    CloseHandle(ReadPipeCut);
    ReadPipeCut:=0;
    WaitThreadCut.Terminate;
    if Assigned(CutProcor) then
    begin
      CutProcor.Terminate;
    end;
    Log_Info('TWaitThreadCut.ClientDone',[]);
  end;
end;

procedure TWaitThreadMergerCut1.ClientDone;
begin
  if Assigned(WaitThreadMergerCut1) then
  begin
    CloseHandle(ReadPipeMerCut1);
    ReadPipeMerCut1:=0;
    WaitThreadMergerCut1.Terminate;
    if Assigned(MergerCutProcor1) then
    begin
      MergerCutProcor1.Terminate;
    end;
    Log_Info('TWaitThreadMergerCut1.ClientDone',[]);
  end;
end;

procedure TWaitThreadMergerCut2.ClientDone;
begin
  if Assigned(WaitThreadMergerCut2) then
  begin
    CloseHandle(ReadPipeMerCut2);
    ReadPipeMerCut2:=0;
    WaitThreadMergerCut2.Terminate;
    if Assigned(MergerCutProcor2) then
    begin
      MergerCutProcor2.Terminate;
    end;
    Log_Info('TWaitThreadMergerCut2.ClientDone',[]);
  end;
end;

procedure TWaitThreadMergerCutTs1.ClientDone;
begin
  if Assigned(WaitThreadMergerCutTs1) then
  begin
    CloseHandle(ReadPipeMerCutTs1);
    ReadPipeMerCutTs1:=0;
    WaitThreadMergerCutTs1.Terminate;
    if Assigned(MergerCutProcorTs1) then
    begin
      MergerCutProcorTs1.Terminate;
    end;
    Log_Info('TWaitThreadMergerCutTs1.ClientDone',[]);
  end;
end;

procedure TWaitThreadMergerCutTs2.ClientDone;
begin
  if Assigned(WaitThreadMergerCutTs2) then
  begin
    CloseHandle(ReadPipeMerCutTs2);
    ReadPipeMerCutTs2:=0;
    WaitThreadMergerCutTs2.Terminate;
    if Assigned(MergerCutProcorTs2) then
    begin
      MergerCutProcorTs2.Terminate;
    end;
    Log_Info('TWaitThreadMergerCutTs2.ClientDone',[]);
  end;
end;

procedure TWaitThreadMerger.ClientDone;
begin
  if Assigned(WaitThreadMerger) then
  begin
    CloseHandle(ReadPipeMer);
    ReadPipeMer:=0;
    WaitThreadMerger.Terminate;
    if Assigned(MergerCutProcor) then
    begin
      MergerCutProcor.Terminate;
    end;
    Log_Info('TWaitThreadMerger.ClientDone',[]);
  end;
end;

procedure TProcessor.Process;
var
  LastEOL, EOL, Len : integer;
begin
  Len:=length(Data);
  LastEOL:=0;
  for EOL:=1 to Len do
    if (EOL>LastEOL) AND ((Data[EOL]=#13) OR (Data[EOL]=#10)) then
    begin
      if Master = 'MPlayer' then
      begin
        HandleMPInputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end
      else if Master = 'FFMpeg' then
      begin
        HandleFMInputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end
      else if Master = 'FrameEncoding' then
      begin
        HandleFEInputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end
      else if Master = 'FFMpegCut' then
      begin
        HandleCUTInputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end
      else if Master = 'FFMpegMergerCut1' then
      begin
        HandleMergerCUT1InputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end
      else if Master = 'FFMpegMergerCut2' then
      begin
        HandleMergerCUT2InputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end
      else if Master = 'FFMpegMergerCutTs1' then
      begin
        HandleMergerCUTTs1InputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end
      else if Master = 'FFMpegMergerCutTs2' then
      begin
        HandleMergerCUTTs2InputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end
      else if Master = 'FFMpegMerger' then
      begin
        HandleMergeInputLine(Copy(Data,LastEOL+1,EOL-LastEOL-1));
        LastEOL:=EOL;
        if (LastEOL<Len) AND (Data[LastEOL+1]=#10) then
          inc(LastEOL);
      end;
    end;
  if LastEOL<>0 then Delete(Data,1,LastEOL);
end;

procedure TProcessor.Execute;
const
  BufSize = 1024;
var
  Buffer    : array[0..BufSize]of char;
  BytesRead : cardinal;
begin
  Data:='';
  repeat
    BytesRead:=0;
    if not ReadFile(hPipe,Buffer[0],BufSize,BytesRead,nil) then break;
    Buffer[BytesRead]:=#0;
    Data:=Data+Buffer;
    Synchronize(Process);
  until BytesRead=0;
end;

function Running:boolean;
begin
  Result:=(ClientProcess<>0);
end;

procedure Stop;
begin
  Status:=sClosing; MainForm.UpdateStatus;
  ExplicitStop:=true;
  if FirstChance then begin
    SendCommand('quit');
    FirstChance:=false;
  end else
    Terminate;
end;

procedure Terminate;
begin
  if ClientProcess=0 then exit;
  TerminateProcess(ClientProcess,cardinal(-1));
end;

procedure ForceStop;
begin
  ExplicitStop:=true;
  if FirstChance then begin
    SendCommand('quit');
    FirstChance:=false;
    if WaitForSingleObject(ClientProcess,1000)<>WAIT_TIMEOUT then exit;
  end;
  Terminate;
end;

procedure SendCommand(Command:string);
var Dummy:cardinal;
begin
  if (ClientProcess=0) OR (WritePipe=0) then exit;
  Command:=Command+#10;
  WriteFile(WritePipe,Command[1],length(Command),Dummy,nil);
end;

procedure SendVolumeChangeCommand(Volume:integer);
begin
  if Mute then exit; 
  LastVolume:=Volume;
  if SoftVol then Volume:=Volume DIV 10;
  SendCommand('volume '+IntToStr(Volume)+' 1');
end;

procedure SetOSDLevel(Level:integer);
begin
  if Level<0 then OSDLevel:=OSDLevel+1
             else OSDLevel:=Level;
  OSDLevel:=OSDLevel AND 3;
  SendCommand('osd '+IntToStr(OSDLevel));
end;

procedure Restart;
var LastPos,LastOSD:integer;
begin
  if not Running then exit;
  LastPos:=PercentPos;
  LastOSD:=OSDLevel;
  ForceStop;
  Sleep(50); // wait for the processing threads to finish
  Application.ProcessMessages;
  Start;
  SendCommand('seek '+IntToStr(LastPos)+' 1');
  SetOSDLevel(LastOSD);
  MainForm.QueryPosition;
end;

////////////////////////////////////////////////////////////////////////////////



procedure HandleMPInputLine(Line:string);
var r,i,j,p:integer; c:char;

  procedure SubMenu_Add(Menu:TMenuItem; ID,SelectedID:integer; Handler:TNotifyEvent);
  var j:integer; Item:TMenuItem;
  begin
    with MainForm.MAudio do
      for j:=0 to Menu.Count-1 do
        if Menu.Items[j].Tag=ID then exit;
    Item:=TMenuItem.Create(Menu);
    with Item do begin
      Caption:=IntToStr(ID);
      Tag:=ID;
      GroupIndex:=$0A;
      RadioItem:=true;
      if ID=SelectedID then Checked:=true else
      if (SelectedID<0) AND (Menu.Count=0) then Checked:=true;
      OnClick:=Handler;
    end;
    Menu.Add(Item);
    Menu.Enabled:=true;
  end;

  procedure SubMenu_SetLang(Menu:TMenuItem; ID:integer; Lang:string);
  var j:integer;
  begin
    with MainForm.MAudio do
      for j:=0 to Menu.Count-1 do
        with Menu.Items[j] do
          if Tag=ID then begin
            Caption:=IntToStr(ID)+' ('+Lang+')';
            exit;
          end;
  end;

  function CheckNativeResolutionLine:boolean;
  begin
    Result:=false;
    if Copy(Line,1,5)<>'VO: [' then exit;
    p:=Pos(' => ',Line); if p=0 then exit; Delete(Line,1,p+3);
    p:=Pos(#32,Line);    if p=0 then exit; SetLength(Line,p-1);
    p:=Pos('x',Line);    if p=0 then exit;
    Val(Copy(Line,1,p-1),i,r); if (r<>0) OR (i<16) OR (i>=4096) then exit;
    Val(Copy(Line,p+1,5),j,r); if (r<>0) OR (j<16) OR (j>=4096) then exit;
    NativeWidth:=i; NativeHeight:=j;
    MainForm.VideoSizeChanged;
    Status:=sPlaying; MainForm.UpdateStatus;
    Result:=true;
  end;

  function CheckNoAudio:boolean;
  begin
    Result:=false;
    if Line<>'Audio: no sound' then exit;
    HaveAudio:=false;
    Result:=true;
  end;

  function CheckNoVideo:boolean;
  begin
    Result:=false;
    if Line<>'Video: no video' then exit;
    HaveVideo:=false;
    Result:=true;
  end;

  function CheckStartPlayback:boolean;
  begin
    Result:=false;
    if Line<>'Starting playback...' then exit;
    MainForm.SetupPlay;
    if not(HaveVideo) then begin
      Status:=sPlaying; MainForm.UpdateStatus;
    end;
    Result:=true;
  end;

  function CheckAudioID:boolean;
  begin
    Result:=false;
    if Copy(Line,1,12)='ID_AUDIO_ID=' then begin
      Val(Copy(Line,13,9),i,r);
      if (r=0) AND (i>=0) AND (i<8191) then begin
        SubMenu_Add(MainForm.MAudio,i,AudioID,MainForm.MAudioClick);
        Result:=true;
      end;
    end;
  end;

  function CheckAudioLang:boolean;
  var s:string; p:integer;
  begin
    Result:=false;
    if Copy(Line,1,7)='ID_AID_' then begin
      s:=Copy(Line,8,20);
      p:=Pos('_LANG=',s);
      if p<=0 then exit;
      Val(Copy(s,1,p-1),i,r);
      if (r=0) AND (i>=0) AND (i<256) then begin
       SubMenu_SetLang(MainForm.MAudio,i,copy(s,p+6,8));
        Result:=true;
      end;
    end;
  end;

  function CheckSubID:boolean;
  begin
    Result:=false;
    if Copy(Line,1,15)='ID_SUBTITLE_ID=' then begin
      Val(Copy(Line,16,9),i,r);
      if (r=0) AND (i>=0) AND (i<256) then begin
        SubMenu_Add(MainForm.MSubtitle,i,SubID,MainForm.MSubtitleClick);
        Result:=true;
      end;
    end;
  end;

  function CheckSubLang:boolean;
  var s:string; p:integer;
  begin
    Result:=false;
    if Copy(Line,1,7)='ID_SID_' then begin
      s:=Copy(Line,8,20);
      p:=Pos('_LANG=',s);
      if p<=0 then exit;
      Val(Copy(s,1,p-1),i,r);
      if (r=0) AND (i>=0) AND (i<256) then begin
        SubMenu_SetLang(MainForm.MSubtitle,i,copy(s,p+6,8));
        Result:=true;
      end;
    end;
  end;

  function CheckLength:boolean;
  var f:real;
  begin
    Result:=(Copy(Line,1,10)='ID_LENGTH=');
    if Result then begin
      Val(Copy(Line,11,10),f,r);
      if r=0 then Duration:=SecondsToTime(round(f));
    end;
  end;

  function CheckFileFormat:boolean;
  begin
    p:=length(Line)-21;
    Result:=(p>0) AND (Copy(Line,p,22)=' file format detected.');
    if Result then
      StreamInfo.FileFormat:=Copy(Line,1,p-1);
  end;

  function CheckDecoder:boolean;
  begin
    Result:=(Copy(Line,1,8)='Opening ') AND (Copy(Line,13,12)='o decoder: [');
    if not Result then exit;
    p:=Pos('] ',Line); Result:=(p>24);
    if not Result then exit;
    if Copy(Line,9,4)='vide' then
      StreamInfo.Video.Decoder:=Copy(Line,p+2,length(Line))
    else if Copy(Line,9,4)='audi' then
      StreamInfo.Audio.Decoder:=Copy(Line,p+2,length(Line))
    else Result:=false;
  end;

  function CheckCodec:boolean;
  begin
    Result:=(Copy(Line,1,9)='Selected ') AND (Copy(Line,14,10)='o codec: [');
    if not Result then exit;
    p:=Pos(' (',Line); Result:=(p>23);
    if not Result then exit;
    if Copy(Line,10,4)='vide' then
      StreamInfo.Video.Codec:=Copy(Line,p+2,length(Line)-p-2)
    else if Copy(Line,10,4)='audi' then
      StreamInfo.Audio.Codec:=Copy(Line,p+2,length(Line)-p-2)
    else Result:=false;
  end;

  function CheckICYInfo:boolean;
  var P:integer;
  begin
    Result:=False;
    if Copy(Line,1,10)<>'ICY Info: ' then exit;
    P:=Pos('StreamTitle=''',Line); if P<10 then exit;
    Delete(Line,1,P+12);
    P:=Pos(''';',Line); if P<1 then exit;
    SetLength(Line,P-1);
    if length(Line)=0 then exit;
    P:=0; while (P<9)
            AND (length(StreamInfo.ClipInfo[P].Key)>0)
            AND (StreamInfo.ClipInfo[P].Key<>'Title')
          do inc(P);
    StreamInfo.ClipInfo[P].Key:='Title';
    if StreamInfo.ClipInfo[P].Value<>Line then begin
      StreamInfo.ClipInfo[P].Value:=Line;
      InfoForm.UpdateInfo;
    end;
  end;

begin
  if (length(Line)>7) then
  begin
    if Line[1]=^J then
      j:=4
    else
      j:=3;
    if ((Line[j-2]='A') OR (Line[j-2]='V')) AND (Line[j-1]=':') then
    begin
      p:=0;
      for i:=0 to 3 do
      begin
        c:=Line[i+j];
        case c of
          '-': begin p:=-1; break; end;
          '0'..'9': p:=p*10+ord(c)-48;
        end;
      end;
      if p<>SecondPos then
      begin
        SecondPos:=p;
        MainForm.UpdateTime;
      end;
      exit;
    end;
  end;

  Line:=Trim(Line);
  // 获取
  if (Copy(Trim(Line), 1, 10) = 'ID_LENGTH=') then
  begin
    VideoLength := Copy(Trim(Line), 11, length(Line));
    GlobVar.VideoLength := Trunc(StrToFloat(VideoLength));
    Log_Info('HandleMPInputLine VideoLength :%s' ,[VideoLength]);
  end;



  if (length(Line)>=18) AND (Line[11]=':') AND (Line[18]='%') AND (Copy(Line,1,10)='Cache fill') then
  begin
    if Copy(Line,12,6)=LastCacheFill then
      exit;
    MainForm.LStatus.Caption:=Line;
    if (Copy(LogForm.TheLog.Lines[LogForm.TheLog.Lines.Count-1],1,11)='Cache fill:') then
      LogForm.TheLog.Lines[LogForm.TheLog.Lines.Count-1]:=Line;
    Sleep(0);  // "yield"
    exit;
  end;
  // check percent_position indicator (hidden from log)
  if Copy(Line,1,21)='ANS_PERCENT_POSITION=' then
  begin
    Val(Copy(Line,22,4),i,r);
    if (r=0) AND (i>=0) AND (i<=100) then
    begin
      PercentPos:=i;
      MainForm.UpdateSeekBar;
    end;
    exit;
  end;
  // suppress repetitive lines
  if (length(Line)>0) AND (Line=LastLine) then
  begin
    inc(LineRepeatCount);
    exit;
  end;
  if LineRepeatCount=1 then
    LogForm.AddLine(Line)
  else if LineRepeatCount>1 then
    LogForm.AddLine('(last message repeated '+IntToStr(LineRepeatCount)+' times)');
  LastLine:=Line;
  LineRepeatCount:=0;
  // add line to log and check for special patterns
  LogForm.AddLine(Line);
  if not CheckNativeResolutionLine then
  if not CheckNoAudio then
  if not CheckNoVideo then
  if not CheckStartPlayback then
  if not CheckAudioID then
  if not CheckAudioLang then
  if not CheckSubID then
  if not CheckSubLang then
  if not CheckLength then
  if not CheckFileFormat then
  if not CheckDecoder then
  if not CheckCodec then
  if not CheckICYInfo then  // modifies Line, should be last
  ;
  // check for generic ID_ pattern
  if Copy(Line,1,3)='ID_' then
  begin
    p:=Pos('=',Line);
    HandleIDLine(Copy(Line,4,p-4), Trim(Copy(Line,p+1,length(Line))));
  end;
end;


procedure HandleFMInputLine(Line:string);
var
  r, i, j, p : integer;
  c : char;
  strList: TStringlist;
  strTemp: string;
  HourSec, MinSec, Sec : Integer;
  progress: Integer;
begin
  LogForm.AddLine(Line);

  if (Copy(Trim(Line), 1, 9) = 'Duration:') then
  begin
    strList := SplitString(Copy(Trim(Line), 11, 11), ':');
    if strList.Count = 3 then
    begin
      // 小时的秒数
      HourSec := strtoint(strList[0]) * 3600;
      // 分钟的秒数
      MinSec := StrToInt(strList[1]) * 60;
      // 秒数
      Sec := Trunc(StrToFloat(strList[2]));
      // 视频总时长，单位为s，精确到个位
      TotalDuration := HourSec + MinSec + Sec ;
      LogForm.AddLine('TotalDuration:' + IntToStr(TotalDuration));
    end;
    strList.Clear;
  end;

  if Copy(Trim(Line), 1 , 6) = 'frame=' then
  begin
    strList := SplitString(Trim(Line), 'time=');
    if strList.Count = 2 then
    begin
      strTemp := strList[1];
      strList.Clear;
      strList := SplitString(Copy(strTemp, 1, 11), ':');
      if strList.Count = 3 then
      begin
        HourSec := strtoint(strList[0]) * 3600;
        MinSec := StrToInt(strList[1]) * 60;
        Sec := Trunc(StrToFloat(strList[2]));
        // 视频总时长，单位为s，精确到个位
        CurTotalDurtion := HourSec + MinSec + Sec ;
        LogForm.AddLine('CurTotalDurtion:' + IntToStr(CurTotalDurtion));

        // update progress bar
        if TotalDuration <> 0 then
        begin
          progress := Round((CurTotalDurtion * 100) div TotalDuration) ;
          if progress >= 100 then
          begin
            TotalDuration := 0;
            progress := 100;
          end;
          ConvertFrm.UpdateProgressBar(progress);
          LogForm.AddLine(IntToStr(progress));
        end;
      end;
    end;
    strList.Clear;
  end;

end;

procedure HandleFEInputLine(Line:string);
var
  r, i, j, p : integer;
  c : char;
  strList: TStringlist;
  strTemp: string;
  HourSec, MinSec, Sec : Integer;
  progress: Integer;
begin
  LogForm.AddLine(Line);
  if (Copy(Trim(Line), 1, 9) = 'Duration:') then
  begin
    strList := SplitString(Copy(Trim(Line), 11, 11), ':');
    if strList.Count = 3 then
    begin
      // 小时的秒数
      HourSec := strtoint(strList[0]) * 3600;
      // 分钟的秒数
      MinSec := StrToInt(strList[1]) * 60;
      // 秒数
      Sec := Trunc(StrToFloat(strList[2]));
      // 视频总时长，单位为s，精确到个位
      TotalDuration := HourSec + MinSec + Sec ;
      LogForm.AddLine('TotalDuration:' + IntToStr(TotalDuration));
    end;
    strList.Clear;
  end;

  if Copy(Trim(Line), 1 , 6) = 'frame=' then
  begin
    strList := SplitString(Trim(Line), 'time=');
    if strList.Count = 2 then
    begin
      strTemp := strList[1];
      strList.Clear;
      strList := SplitString(Copy(strTemp, 1, 11), ':');
      if strList.Count = 3 then
      begin
        HourSec := strtoint(strList[0]) * 3600;
        MinSec := StrToInt(strList[1]) * 60;
        Sec := Trunc(StrToFloat(strList[2]));
        // 视频总时长，单位为s，精确到个位
        CurTotalDurtion := HourSec + MinSec + Sec ;
        LogForm.AddLine('CurTotalDurtion:' + IntToStr(CurTotalDurtion));

        // update progress bar
        if TotalDuration <> 0 then
        begin
          progress := Round((CurTotalDurtion * 100) div TotalDuration) ;
          if progress >= 100 then
          begin
            TotalDuration := 0;
            progress := 100;
          end;
          CutFrm.UpdateProgressBar(progress);
          LogForm.AddLine(IntToStr(progress));
        end;
      end;
    end;
    strList.Clear;
  end;
end;

procedure HandleCUTInputLine(Line:string);
var
  r, i, j, p : integer;
  c : char;
  strList: TStringlist;
  strTemp: string;
  HourSec, MinSec, Sec : Integer;
  progress: Integer;
  Duration : string;
  TempCurTotalDuration : Integer;
begin
  LogForm.AddLine(Line);
  // Duration 为剪切的时间长
  Duration := TimeToStr((GlobVar.EndCutPonit - GlobVar.StartCutPonit) * GlobVar.VideoLength / SecsPerDay/100);
  strList := SplitString(Duration, ':');
  if strList.Count = 3 then
  begin
    // 小时的秒数
    HourSec := strtoint(strList[0]) * 3600;
    // 分钟的秒数
    MinSec := StrToInt(strList[1]) * 60;
    // 秒数
    Sec := Trunc(StrToFloat(strList[2]));
    // 视频总时长，单位为s，精确到个位
    TotalDuration := HourSec + MinSec + Sec ;
    LogForm.AddLine('TotalDuration:' + IntToStr(TotalDuration));
  end;
  strList.Clear;

  // 检测ffmpeg是否已经执行完成
  if Copy(Trim(Line), 1 , 5) = 'video' then
  begin
    TotalDuration := 0;
    progress := 100;
    CutFrm.UpdateProgressBar2(progress);
  end;

  if Copy(Trim(Line), 1 , 6) = 'frame=' then
  begin
    strList := SplitString(Trim(Line), 'time=');
    if strList.Count = 2 then
    begin
      strTemp := strList[1];
      strList.Clear;
      strList := SplitString(Copy(strTemp, 1, 11), ':');
      if strList.Count = 3 then
      begin
        HourSec := strtoint(strList[0]) * 3600;
        MinSec := StrToInt(strList[1]) * 60;
        Sec := Trunc(StrToFloat(strList[2]));
        // 视频总时长，单位为s，精确到个位
        CurTotalDurtion := HourSec + MinSec + Sec ;
        LogForm.AddLine('CurTotalDurtion:' + IntToStr(CurTotalDurtion));

        // update progress bar
//        if TotalDuration <> 0 then
//        begin
//          if TotalDuration <> 1 then
//            progress := Round((CurTotalDurtion * 100) div (TotalDuration -1))  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
//          else
//            progress := 100;
//          if progress >= 100 then
//          begin
//            TotalDuration := 0;
//            progress := 100;
//          end;
//          CutFrm.UpdateProgressBar2(progress);
//          LogForm.AddLine(IntToStr(progress));
//
//
//        end;


        if TotalDuration <> 0 then
        begin
          if TempCurTotalDuration <> CurTotalDurtion then
          begin
            TempCurTotalDuration := CurTotalDurtion;
            progress := Round((CurTotalDurtion * 100) div (TotalDuration));  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
            if progress < GlobVar.tempProgress then
              progress := GlobVar.tempProgress
            else
              GlobVar.tempProgress := progress;
          end
          else
          begin
            progress := 100;
            TotalDuration := 0;

          end;
          if progress >= 100 then
          begin
            TotalDuration := 0;
            progress := 100;
          end;
          CutFrm.UpdateProgressBar2(progress);
          LogForm.AddLine(IntToStr(progress));
        end;
      end;
    end;
    strList.Clear;
  end;
end;

procedure HandleMergerCUT1InputLine(Line:string);
var
  r, i, j, p : integer;
  c : char;
  strList: TStringlist;
  strTemp: string;
  HourSec, MinSec, Sec : Integer;
  progress: Integer;
  Duration : string;
  TempCurTotalDuration : Integer;
begin
  LogForm.AddLine(Line);
  // Duration 为剪切的时间长
  Duration := TimeToStr((GlobVar.StartCutPonit) * GlobVar.VideoLength / SecsPerDay/100);
  strList := SplitString(Duration, ':');
  if strList.Count = 3 then
  begin
    // 小时的秒数
    HourSec := strtoint(strList[0]) * 3600;
    // 分钟的秒数
    MinSec := StrToInt(strList[1]) * 60;
    // 秒数
    Sec := Trunc(StrToFloat(strList[2]));
    // 视频总时长，单位为s，精确到个位
    TotalDuration := HourSec + MinSec + Sec ;
    GlobVar.MergeDurationTs1 := TotalDuration;
    LogForm.AddLine('TotalDuration:' + IntToStr(TotalDuration));
  end;
  strList.Clear;
  // 检测ffmpeg是否已经执行完成
  if Copy(Trim(Line), 1 , 5) = 'video' then
  begin
    TotalDuration := 0;
    progress := 100;
    CutFrm.UpdateProgressBarMergerCut1(progress);
  end;

  if Copy(Trim(Line), 1 , 6) = 'frame=' then
  begin
    strList := SplitString(Trim(Line), 'time=');
    if strList.Count = 2 then
    begin
      strTemp := strList[1];
      strList.Clear;
      strList := SplitString(Copy(strTemp, 1, 11), ':');
      if strList.Count = 3 then
      begin
        HourSec := strtoint(strList[0]) * 3600;
        MinSec := StrToInt(strList[1]) * 60;
        Sec := Trunc(StrToFloat(strList[2]));
        // 视频总时长，单位为s，精确到个位
        CurTotalDurtion := HourSec + MinSec + Sec ;
        LogForm.AddLine('CurTotalDurtion:' + IntToStr(CurTotalDurtion));
        Log_Info('HandleMergerCUT1InputLine : TotalDurtion : %s, CurTotalDurtion : %s', [IntToStr(TotalDuration), IntToStr(CurTotalDurtion)]);
        // update progress bar
//        if TotalDuration <> 0 then
//        begin
//          if TotalDuration <> 1 then
//            progress := Round((CurTotalDurtion * 100) div (TotalDuration - 1))  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
//          else
//            progress := 100;
//          if progress >= 100 then
//          begin
//            TotalDuration := 0;
//            progress := 100;
//          end;
//          CutFrm.UpdateProgressBarMergerCut1(progress);
//          LogForm.AddLine(IntToStr(progress));
//        end;
//
        if TotalDuration <> 0 then
        begin
          if TempCurTotalDuration <> CurTotalDurtion then
          begin
            TempCurTotalDuration := CurTotalDurtion;
            progress := Round((CurTotalDurtion * 100) div (TotalDuration));  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
            if progress < GlobVar.tempProgress then
              progress := GlobVar.tempProgress
            else
              GlobVar.tempProgress := progress;
          end
          else
          begin
            progress := 100;
            TotalDuration := 0;

          end;
          if progress >= 100 then
          begin
            TotalDuration := 0;
            progress := 100;
          end;
          CutFrm.UpdateProgressBarMergerCut1(progress);
          LogForm.AddLine(IntToStr(progress));
        end;
      end;
    end;
    strList.Clear;
  end;
end;

procedure HandleMergerCUT2InputLine(Line:string);
var
  r, i, j, p : integer;
  c : char;
  strList: TStringlist;
  strTemp: string;
  HourSec, MinSec, Sec : Integer;
  progress: Integer;
  Duration : string;
  TempCurTotalDuration : Integer;
begin
  LogForm.AddLine(Line);
  // Duration 为剪切的时间长
  Duration := TimeToStr((GlobVar.MergerCutPoint - GlobVar.EndCutPonit) * GlobVar.VideoLength / SecsPerDay/100);
  strList := SplitString(Duration, ':');
  if strList.Count = 3 then
  begin
    // 小时的秒数
    HourSec := strtoint(strList[0]) * 3600;
    // 分钟的秒数
    MinSec := StrToInt(strList[1]) * 60;
    // 秒数
    Sec := Trunc(StrToFloat(strList[2]));
    // 视频总时长，单位为s，精确到个位
    TotalDuration := HourSec + MinSec + Sec;
    GlobVar.MergeDurationTs2 := TotalDuration;
    LogForm.AddLine('TotalDuration:' + IntToStr(TotalDuration));
  end;
  strList.Clear;
  // 检测ffmpeg是否已经执行完成
  if Copy(Trim(Line), 1 , 5) = 'video' then
  begin
    TotalDuration := 0;
    progress := 100;
    CutFrm.UpdateProgressBarMergerCut2(progress);
  end;

  if Copy(Trim(Line), 1 , 6) = 'frame=' then
  begin
    strList := SplitString(Trim(Line), 'time=');
    if strList.Count = 2 then
    begin
      strTemp := strList[1];
      strList.Clear;
      strList := SplitString(Copy(strTemp, 1, 11), ':');
      if strList.Count = 3 then
      begin
        HourSec := strtoint(strList[0]) * 3600;
        MinSec := StrToInt(strList[1]) * 60;
        Sec := Trunc(StrToFloat(strList[2]));
        // 视频总时长，单位为s，精确到个位
        CurTotalDurtion := HourSec + MinSec + Sec ;
        LogForm.AddLine('CurTotalDurtion:' + IntToStr(CurTotalDurtion));
        Log_Info('HandleMergerCUT2InputLine : TotalDurtion : %s, CurTotalDurtion : %s', [IntToStr(TotalDuration), IntToStr(CurTotalDurtion)]);
        // update progress bar
//        if TotalDuration <> 0 then
//        begin
//          if TotalDuration <> 1 then
//            progress := Round((CurTotalDurtion * 100) div (TotalDuration - 1)) // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
//          else
//            progress := 100;
//          if progress >= 100 then
//          begin
//            TotalDuration := 0;
//            progress := 100;
//          end;
//          CutFrm.UpdateProgressBarMergerCut2(progress);
//          LogForm.AddLine(IntToStr(progress));
//        end;

        if TotalDuration <> 0 then
        begin
          if TempCurTotalDuration <> CurTotalDurtion then
          begin
            TempCurTotalDuration := CurTotalDurtion;
            progress := Round((CurTotalDurtion * 100) div (TotalDuration));  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
            if progress < GlobVar.tempProgress then
              progress := GlobVar.tempProgress
            else
              GlobVar.tempProgress := progress;
          end
          else
          begin
            progress := 100;
            TotalDuration := 0;
          end;
          if progress >= 100 then
          begin
            TotalDuration := 0;
            progress := 100;
          end;
          CutFrm.UpdateProgressBarMergerCut2(progress);
          LogForm.AddLine(IntToStr(progress));
        end;
      end;
    end;
    strList.Clear;
  end;
end;

procedure HandleMergerCUTTs1InputLine(Line:string);
var
  r, i, j, p : integer;
  c : char;
  strList: TStringlist;
  strTemp: string;
  HourSec, MinSec, Sec : Integer;
  progress: Integer;
  TempCurTotalDuration : Integer;
begin
  LogForm.AddLine(Line);
  if (Copy(Trim(Line), 1, 9) = 'Duration:') then
  begin
    strList := SplitString(Copy(Trim(Line), 11, 11), ':');
    if strList.Count = 3 then
    begin
      // 小时的秒数
      HourSec := strtoint(strList[0]) * 3600;
      // 分钟的秒数
      MinSec := StrToInt(strList[1]) * 60;
      // 秒数
      Sec := Trunc(StrToFloat(strList[2]));
      // 视频总时长，单位为s，精确到个位
      TotalDuration := HourSec + MinSec + Sec ;
    //  GlobVar.MergeDurationTs1 := TotalDuration;
      LogForm.AddLine('TotalDuration:' + IntToStr(TotalDuration));
    end;
    strList.Clear;
  end;
  // 检测ffmpeg是否已经执行完成
  if Copy(Trim(Line), 1 , 5) = 'video' then
  begin
    TotalDuration := 0;
    progress := 100;
    CutFrm.UpdateProgressBarMergerCutTs1(progress);
  end;

  if Copy(Trim(Line), 1 , 6) = 'frame=' then
  begin
    strList := SplitString(Trim(Line), 'time=');
    if strList.Count = 2 then
    begin
      strTemp := strList[1];
      strList.Clear;
      strList := SplitString(Copy(strTemp, 1, 11), ':');
      if strList.Count = 3 then
      begin
        HourSec := strtoint(strList[0]) * 3600;
        MinSec := StrToInt(strList[1]) * 60;
        Sec := Trunc(StrToFloat(strList[2]));
        // 视频总时长，单位为s，精确到个位
        CurTotalDurtion := HourSec + MinSec + Sec ;
        LogForm.AddLine('CurTotalDurtion:' + IntToStr(CurTotalDurtion));
        Log_Info('HandleMergerCUTTs1InputLine : TotalDurtion : %s, CurTotalDurtion : %s', [IntToStr(TotalDuration), IntToStr(CurTotalDurtion)]);
        // update progress bar
//        if TotalDuration <> 0 then
//        begin
//          if TotalDuration <> 1 then
//            progress :=Round((CurTotalDurtion * 100) div (TotalDuration - 1)) // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
//          else
//            progress := 100;
//          if progress >= 100 then
//          begin
//            TotalDuration := 0;
//            progress := 100;
//          end;
//          CutFrm.UpdateProgressBarMergerCutTs1(progress);
//          LogForm.AddLine(IntToStr(progress));
//        end;

      if TotalDuration <> 0 then
        begin
          if TempCurTotalDuration <> CurTotalDurtion then
          begin
            TempCurTotalDuration := CurTotalDurtion;
            progress := Round((CurTotalDurtion * 100) div (TotalDuration));  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
            if progress < GlobVar.tempProgress then
              progress := GlobVar.tempProgress
            else
              GlobVar.tempProgress := progress;
          end
          else
          begin
            progress := 100;
            TotalDuration := 0;
          end;
          if progress >= 100 then
          begin
            TotalDuration := 0;
            progress := 100;
          end;
          CutFrm.UpdateProgressBarMergerCutTs1(progress);
          LogForm.AddLine(IntToStr(progress));
        end;
      end;
    end;
    strList.Clear;
  end;
end;

procedure HandleMergerCUTTs2InputLine(Line:string);
var
  r, i, j, p : integer;
  c : char;
  strList: TStringlist;
  strTemp: string;
  HourSec, MinSec, Sec : Integer;
  progress: Integer;
  TempCurTotalDuration : Integer;
begin
  LogForm.AddLine(Line);
  if (Copy(Trim(Line), 1, 9) = 'Duration:') then
  begin
    strList := SplitString(Copy(Trim(Line), 11, 11), ':');
    if strList.Count = 3 then
    begin
      // 小时的秒数
      HourSec := strtoint(strList[0]) * 3600;
      // 分钟的秒数
      MinSec := StrToInt(strList[1]) * 60;
      // 秒数
      Sec := Trunc(StrToFloat(strList[2]));
      // 视频总时长，单位为s，精确到个位
      TotalDuration := HourSec + MinSec + Sec ;
    //  GlobVar.MergeDurationTs2 := TotalDuration;
      LogForm.AddLine('TotalDuration:' + IntToStr(TotalDuration));
    end;
    strList.Clear;
  end;
  // 检测ffmpeg是否已经执行完成
  if Copy(Trim(Line), 1 , 5) = 'video' then
  begin
    TotalDuration := 0;
    progress := 100;
    CutFrm.UpdateProgressBarMergerCutTs2(progress);
  end;

  if Copy(Trim(Line), 1 , 6) = 'frame=' then
  begin
    strList := SplitString(Trim(Line), 'time=');
    if strList.Count = 2 then
    begin
      strTemp := strList[1];
      strList.Clear;
      strList := SplitString(Copy(strTemp, 1, 11), ':');
      if strList.Count = 3 then
      begin
        HourSec := strtoint(strList[0]) * 3600;
        MinSec := StrToInt(strList[1]) * 60;
        Sec := Trunc(StrToFloat(strList[2]));
        // 视频总时长，单位为s，精确到个位
        CurTotalDurtion := HourSec + MinSec + Sec ;
        LogForm.AddLine('CurTotalDurtion:' + IntToStr(CurTotalDurtion));
        Log_Info('HandleMergerCUTTs2InputLine : TotalDurtion : %s, CurTotalDurtion : %s', [IntToStr(TotalDuration), IntToStr(CurTotalDurtion)]);
        // update progress bar
//        if TotalDuration <> 0 then
//        begin
//          if TotalDuration <> 1 then
//            progress := Round((CurTotalDurtion * 100) div (TotalDuration - 1))  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
//          else
//            progress := 100;
//          if progress >= 100 then
//          begin
//            TotalDuration := 0;
//            progress := 100;
//          end;
//          CutFrm.UpdateProgressBarMergerCutTs2(progress);
//          LogForm.AddLine(IntToStr(progress));
//
////          if progress = 100 then
////            TotalDuration := 0;
//        end;

        if TotalDuration <> 0 then
        begin
          if TempCurTotalDuration <> CurTotalDurtion then
          begin
            TempCurTotalDuration := CurTotalDurtion;
            progress := Round((CurTotalDurtion * 100) div (TotalDuration));  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
            if progress < GlobVar.tempProgress then
              progress := GlobVar.tempProgress
            else
              GlobVar.tempProgress := progress;
          end
          else
          begin
            progress := 100;
            TotalDuration := 0;
          end;
          if progress >= 100 then
          begin
            TotalDuration := 0;
            progress := 100;
          end;
          CutFrm.UpdateProgressBarMergerCutTs2(progress);
          LogForm.AddLine(IntToStr(progress));
        end;
      end;
    end;
    strList.Clear;
  end;
end;

procedure HandleMergeInputLine(Line:string);
var
  r, i, j, p : integer;
  c : char;
  strList: TStringlist;
  strTemp: string;
  HourSec, MinSec, Sec : Integer;
  progress: Integer;
  TempCurTotalDuration : Integer;
begin
  LogForm.AddLine(Line);
  TotalDuration := GlobVar.MergeDurationTs1 + GlobVar.MergeDurationTs2;
  LogForm.AddLine('TotalDuration:' + IntToStr(TotalDuration));
  // 检测ffmpeg是否已经执行完成
  if Copy(Trim(Line), 1 , 5) = 'video' then
  begin
    TotalDuration := 0;
    progress := 100;
    CutFrm.UpdateProgressBarMerger(progress);
  end;

  if Copy(Trim(Line), 1 , 6) = 'frame=' then
  begin
    strList := SplitString(Trim(Line), 'time=');
    if strList.Count = 2 then
    begin
      strTemp := strList[1];
      strList.Clear;
      strList := SplitString(Copy(strTemp, 1, 11), ':');
      if strList.Count = 3 then
      begin
        HourSec := strtoint(strList[0]) * 3600;
        MinSec := StrToInt(strList[1]) * 60;
        Sec := Trunc(StrToFloat(strList[2]));
        // 视频总时长，单位为s，精确到个位
        CurTotalDurtion := HourSec + MinSec + Sec ;
        LogForm.AddLine('CurTotalDurtion:' + IntToStr(CurTotalDurtion));

        // update progress bar
//        if TotalDuration <> 0 then
//        begin
//          if TotalDuration <> 1 then
//            progress := Round((CurTotalDurtion * 100) div (TotalDuration - 1))  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
//          else
//            progress := 100;
//          if progress >= 100 then
//          begin
//            TotalDuration := 0;
//            progress := 100;
//          end;
//          CutFrm.UpdateProgressBarMerger(progress);
//          LogForm.AddLine(IntToStr(progress));
//
////          if progress = 100 then
////            TotalDuration := 0;
//        end;

        if TotalDuration <> 0 then
        begin
          if TempCurTotalDuration <> CurTotalDurtion then
          begin
            TempCurTotalDuration := CurTotalDurtion;
            progress := Round((CurTotalDurtion * 100) div (TotalDuration));  // 此处分母减一是为了裁剪时时间的误差，导致进度停在百分之九十几停止
            if progress < GlobVar.tempProgress then
              progress := GlobVar.tempProgress
            else
              GlobVar.tempProgress := progress;
          end
          else
          begin
            progress := 100;
            TotalDuration := 0;
          end;
          if progress >= 100 then
          begin
            TotalDuration := 0;
            progress := 100;
          end;
          CutFrm.UpdateProgressBarMerger(progress);
          LogForm.AddLine(IntToStr(progress));
        end;
      end;
    end;
    strList.Clear;
  end;
end;



////////////////////////////////////////////////////////////////////////////////

procedure HandleIDLine(ID, Content: string);
var AsInt,r:integer; AsFloat:real;
begin with StreamInfo do begin
  // convert to int and float
  val(Content,AsInt,r);
  if r<>0 then begin
    val(Content,AsFloat,r);
    if r<>0 then begin
      AsInt:=0; AsFloat:=0;
    end else AsInt:=trunc(AsFloat);
  end else AsFloat:=AsInt;

  // handle some common ID fields
       if ID='FILENAME'      then FileName:=Content
  else if ID='VIDEO_BITRATE' then Video.Bitrate:=AsInt
  else if ID='VIDEO_WIDTH'   then Video.Width:=AsInt
  else if ID='VIDEO_HEIGHT'  then Video.Height:=AsInt
  else if ID='VIDEO_FPS'     then Video.FPS:=AsFloat
  else if ID='VIDEO_ASPECT'  then Video.Aspect:=AsFloat
  else if ID='AUDIO_BITRATE' then Audio.Bitrate:=AsInt
  else if ID='AUDIO_RATE'    then Audio.Rate:=AsInt
  else if ID='AUDIO_NCH'     then Audio.Channels:=AsInt
  else if (ID='DEMUXER') AND (length(FileFormat)=0) then FileFormat:=Content
  else if (ID='VIDEO_FORMAT') AND (length(Video.Decoder)=0) then Video.Decoder:=Content
  else if (ID='VIDEO_CODEC') AND (length(Video.Codec)=0) then Video.Codec:=Content
  else if (ID='AUDIO_FORMAT') AND (length(Audio.Decoder)=0) then Audio.Decoder:=Content
  else if (ID='AUDIO_CODEC') AND (length(Audio.Codec)=0) then Audio.Codec:=Content
  else if (ID='LENGTH') AND (AsFloat>0.001) then begin
    AsFloat:=Frac(AsFloat);
    if (AsFloat>0.0009) then begin
      str(AsFloat:0:3, PlaybackTime);
      PlaybackTime:=SecondsToTime(AsInt) + Copy(PlaybackTime,2,20);
    end else
      PlaybackTime:=SecondsToTime(AsInt);
  end else if (Copy(ID,1,14)='CLIP_INFO_NAME') AND (length(ID)=15) then begin
    r:=Ord(ID[15])-Ord('0');
    if (r>=0) AND (r<=9) then ClipInfo[r].Key:=Content;
  end else if (Copy(ID,1,15)='CLIP_INFO_VALUE') AND (length(ID)=16) then begin
    r:=Ord(ID[16])-Ord('0');
    if (r>=0) AND (r<=9) then ClipInfo[r].Value:=Content;
  end;
end;
end;


function SplitString(const source, ch: string): TStringList;
var
  temp, t2: string;
  i: integer;
begin
  result := TStringList.Create;
  temp := source;
  i := pos(ch, source);
  while i <> 0 do
  begin
    t2 := copy(temp, 0, i - 1);
    if (t2 <> '') then
      result.Add(t2);
    delete(temp, 1, i - 1 + Length(ch));
    i := pos(ch, temp);
  end;
  result.Add(temp);
end;


procedure ResetStreamInfo;
var
  i:integer;
begin
  with StreamInfo do begin
    FileName:='';
    FileFormat:='';
    PlaybackTime:='';
  with Video do
  begin
    Decoder:=''; Codec:='';
    Bitrate:=0; Width:=0; Height:=0; FPS:=0.0; Aspect:=0.0;
  end;
  with Audio do
  begin
    Decoder:=''; Codec:='';
    Bitrate:=0; Rate:=0; Channels:=0;
  end;
  for i:=0 to 9 do
    with ClipInfo[i] do
    begin
      Key:=''; Value:='';
    end;
end;
end;

begin
  DecimalSeparator:='.';
  NativeWidth:=0; NativeHeight:=0;
  MediaURL:=''; DisplayURL:=''; FirstOpen:=true;
  AudioID:=-1; SubID:=-1; OSDLevel:=1;
  Deinterlace:=0; Aspect:=0; Postproc:=1;
  AudioOut:=3; AudioDev:=0;
  ReIndex:=false; SoftVol:=false; PriorityBoost:=true;
  Params:='';
  Duration:='';
  Status:=sNone;
  Volume:=100; Mute:=False;
  LastVolume:=-1;
  ResetStreamInfo;
end.


