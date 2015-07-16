unit pscpLogger;

{$DEFINE DEBUGGING}

interface

uses
  Windows, SysUtils, INIFiles, SyncObjs, Classes, Math;

// 缺省的log文件的最大容量
const
  LOGGER_DEFSIZE    : Integer = 10 * 1000 * 1000;
  // 缺省的log文件在cfg文件中的section名称
const
  LOGGER_SECNAME    : string = 'logger';
  // 缺省的日志文件名称
const
  LOGGER_DEFFILE    : string = 'pscp.log';
  // 缺省的日志文件Title信息
const
  LOGGER_DEFTITLE   : string = 'PSC Platform Running Information';
  // 在日志中使用的Level对应的字符串
const
  LOGGER_LVLSTRS    : array[0..7] of string[4] =
    (
    'UNK',
    'ERR',
    'WAN',
    'INF',
    'VBS',
    'PRF',
    'DBG',
    'wyf'                               // 2^6
    );

type
  TLogLevel = (
    lglNone = 0,                        // 不输出
    lglError = 1,                       // 错误信息
    lglWarning = 2,                     // 警告信息
    lglInfo = 4,                        // 一般信息
    lglVerbose = 8,                     // 不重要的信息
    lglPerf = 16,                       // 性能信息（信息量狂大）
    lglDebug = 32,                      // 调试信息（信息量狂大）
    lglAll = -1                         // 所有信息
    );
  TLogOutput = (
    lgoNone = 0,                        // 不输出
    lgoFile = 1,                        // 文件方式输出
    lgoConsole = 2,                     // 输出到控制台
    lgoDebugger = 4,                    // 输出到调试器
    lgoMsgBox = 8                       // 输出到信息框
    );

  { cfg文件格式如下：
    [logger]
    file			= spi.log
    title			= Speech Programming Interface
    level			= 7
    output		= 3
    flush			=
    maxsize		=
    overwrite	= 0
  }
  TpscpLogCfg = class
  public
    constructor Create;
    function Open(szCfgFile: string; szSection: string = 'logger'): Boolean;
    procedure Reset;
  private
    FFlushAll: Boolean;
    FOverWrite: Boolean;
    FOutput: Integer;
    FMaxSize: Integer;
    FLevel: Integer;
    FLogFile: string;
    FTitle: string;
    FCfgFile: string;
  published
    property LogFile: string read FLogFile write FLogFile;
    property Title: string read FTitle;
    property MaxSize: Integer read FMaxSize;
    property OverWrite: Boolean read FOverWrite;
    property Output: Integer read FOutput;
    property Level: Integer read FLevel;
    property FlushAll: Boolean read FFlushAll;
    property CfgFile: string read FCfgFile;
  end;

  TpscpLogger = class
  private
    // cfg对象
    FCfg: TpscpLogCfg;
    // 所在模块的句柄
    FMod: HMODULE;
    // 写日志的进程锁
    FLockMutex: THandle;
    // FLock: TCriticalSection;
    // 日志文件句柄
    FFileHandle: Integer;

    procedure WriteHead(NewFile: Boolean);
    procedure WriteTail(EndFile: Boolean);
    procedure Back_file;
    function GetFileVersionStr(const AFileName: string): string;
  public
    constructor Create;
    destructor Destroy; override;

    function Open(szFile: string; bCfgOrLog: Boolean = True;
      szSection: string = 'logger'; hMod: HMODULE = 0): Boolean;
    function Open2(szFile: string): Boolean;
    procedure Close;
    procedure Flush;

    // asiafly add - Force Add Log Msg
    procedure LogMsg2(LogLevel: Integer; const Format: string; const Args: array
      of const);
    procedure LogMsg(LogLevel: Integer; const Format: string; const Args: array
      of const);
    procedure LogError(const Format: string; const Args: array of const);
    procedure LogWarning(const Format: string; const Args: array of const);
    procedure LogInfo(const Format: string; const Args: array of const);
    procedure LogVerbose(const Format: string; const Args: array of const);
    procedure LogPerf(const Format: string; const Args: array of const);
    procedure LogDebug(const Format: string; const Args: array of const);
    procedure LogCfg;
  published
    property Cfg: TpscpLogCfg read FCfg;
  end;

function Log_Open(szFile: string; bCfgOrLog: Boolean = True;
  szSection: string = 'logger'; hMod: HMODULE = 0): Boolean;
procedure Log_Close;
procedure Log_Flush;
procedure Log_Msg(LogLevel: Integer; const Format: string; const Args: array of
  const);
procedure Log_Error(const Format: string; const Args: array of const);
procedure Log_Warn(const Format: string; const Args: array of const);
procedure Log_Info(const Format: string; const Args: array of const);
procedure Log_Verb(const Format: string; const Args: array of const);
procedure Log_Perf(const Format: string; const Args: array of const);
procedure Log_Debug(const Format: string; const Args: array of const);
procedure Log_Wyf(const Format: string; const Args: array of const);
procedure Log_Cfg;


function Log2_Open(szFile: string): Boolean;
procedure Log2_Close;
procedure Log2_Msg(const Format: string; const Args: array of const);

implementation

var
  logger_singleton  : TpscpLogger;
  logger2 : TpscpLogger;

  { TpscpLogCfg }

  // 设置类属性的缺省值

constructor TpscpLogCfg.Create;
begin
  Reset;
end;

// 打开cfg文件，并从cfg文件的logger section中读取需要的配置项

function TpscpLogCfg.Open(szCfgFile: string; szSection: string): Boolean;
var
  ini               : TIniFile;
begin
  // 如果文件不存在直接退出函数
  if not FileExists(szCfgFile) then
  begin
    Result := False;
    Exit;
  end;
  if szSection = '' then
    szSection := LOGGER_SECNAME;

  // 打开并解析ini文件
  ini := TIniFile.Create(szCfgFile);
  try
    FFlushAll := ini.ReadBool(szSection, 'flush', false);
    FOverWrite := ini.ReadBool(szSection, 'overwrite', false);
    FMaxSize := ini.ReadInteger(szSection, 'maxsize', LOGGER_DEFSIZE);
    FOutput := ini.ReadInteger(szSection, 'output', 1);
    FLevel := ini.ReadInteger(szSection, 'level', 7);
    FTitle := ini.ReadString(szSection, 'title', LOGGER_DEFTITLE);
    FLogFile := ini.ReadString(szSection, 'file', LOGGER_DEFFILE);

    // 处理Log文件路径
    // FLogFile := ExpandFileName(FLogFile);
  finally
    ini.Free;
  end;
  Result := True;
  FCfgFile := szCfgFile;
end;

procedure TpscpLogCfg.Reset;
begin
  FFlushAll := false;
  FOverWrite := false;
  FMaxSize := LOGGER_DEFSIZE;
  FOutput := 1;
  FLevel := 7;
  FTitle := LOGGER_DEFTITLE;
  FLogFile := LOGGER_DEFFILE;
end;

{ TpscpLogger }

// 构造函数，主要初始化FCfg和FLock对象

constructor TpscpLogger.Create;
begin
  inherited Create;
  FFileHandle := 0;
  FCfg := TpscpLogCfg.Create;
  FMod := 0;
  FLockMutex := 0;
end;

// 析构函数，主要释放FCfg和FLock对象

destructor TpscpLogger.Destroy;
begin
  Close;
  FCfg.Free;
  inherited Destroy;
end;

function TpscpLogger.Open(szFile: string; bCfgOrLog: Boolean;
  szSection: string; hMod: HMODULE): Boolean;
var
  s, cfg_file_path, mod_path, mutex_str: string;
  dwFileSize        : DWORD;
  NewFile           : Boolean;
begin
  // 先关闭,清理对象
  Close;

  // 根据模块名称创建日志的进程锁
  mutex_str := Format('PSCP_Logger_Mutex::%s',
    [ExtractFileName(GetModuleName(hMod))]);
  FLockMutex := CreateMutex(nil, False, PChar(mutex_str));
  if FLockMutex = 0 then
  begin
    Result := False;
    Exit;
  end;

  mod_path := GetModuleName(hMod);
  FMod := hMod;
  if bCfgOrLog then
    // 从配置文件中读取信息，如果失败使用缺省的配置信息
  begin
    if FileExists(szFile) then
      // TIniFile控件需要使用绝对路径来打开cfg文件,否则会失败
      cfg_file_path := ExpandFileName(szFile)
    else
    begin
      // 如果当前路径下cfg文件不存在,使用模块所在路径搜索cfg文件
      cfg_file_path := ExtractFileDir(mod_path) + '\' + ExtractFileName(szFile);
    end;

    Cfg.Open(cfg_file_path, szSection);
  end
  else
    Cfg.LogFile := szFile;

  Result := True;
  if (Cfg.Output and Ord(lgoFile)) <> 0 then
  begin
    // log文件路径如果是相对路径，取Module所在路径的相对路径
    // log文件路径如果是绝对路径，直接读取
    // 如果路径的drive前缀为空，表示相对路径
    if ExtractFileDrive(Cfg.LogFile) = '' then
    begin
      Cfg.LogFile := ExtractFileDir(mod_path) + '\' + Cfg.LogFile;
    end
    else
    begin
      Cfg.LogFile := Cfg.LogFile;
    end;

    // 在打开之前先进行锁定
    WaitForSingleObject(FLockMutex, INFINITE);
    try
      // 打开日志文件
      if FileExists(Cfg.LogFile) then
      begin
        FFileHandle := FileOpen(Cfg.LogFile, fmOpenReadWrite or
          fmShareDenyWrite);
        NewFile := False;
      end
      else
      begin
        FFileHandle := FileCreate(Cfg.LogFile);
        FileClose(FFileHandle);
        FFileHandle := FileOpen(Cfg.LogFile, fmOpenReadWrite or
          fmShareDenyWrite);
        NewFile := True;
      end;

      // 日志文件打开失败,退出
      if FFileHandle = -1 then
      begin
        Result := False;
        FFileHandle := 0;
        Exit;
      end;

      try
        dwFileSize := GetFileSize(FFileHandle, nil);
        FileSeek(FFileHandle, 0, 2);
        // 在日志文件末尾添加回车符号
        if dwFileSize > 0 then
        begin
          s := ''#13#10;
          FileWrite(FFileHandle, (PChar(s))^, Length(s));
        end;

        // 写日志文件头信息
        WriteHead(NewFile);
      except
        Result := False;
        FileClose(FFileHandle);
      end;
    finally
      ReleaseMutex(FLockMutex);
    end;
  end;
end;

function TpscpLogger.Open2(szFile: string): Boolean;
var
  s, mutex_str: string;
  dwFileSize        : DWORD;
  NewFile           : Boolean;
begin
  Result := False;
  // 先关闭,清理对象
  Close;

  // 根据模块名称创建日志的进程锁
  mutex_str := Format('PSCP_Logger2_Mutex::%s',
    [ExtractFileName(szFile)]);
  FLockMutex := CreateMutex(nil, False, PChar(mutex_str));
  if FLockMutex = 0 then
  begin
    Exit;
  end;

  // 在打开之前先进行锁定
  WaitForSingleObject(FLockMutex, INFINITE);
  try
    // 打开日志文件
    if FileExists(szFile) then
    begin
      FFileHandle := FileOpen(szFile, fmOpenReadWrite or
        fmShareDenyWrite);
      NewFile := False;
    end
    else
    begin
      FFileHandle := FileCreate(szFile);
      NewFile := True;
    end;

    // 日志文件打开失败,退出
    if FFileHandle = -1 then
    begin
      Result := False;
      FFileHandle := 0;
      Exit;
    end;

    try
      dwFileSize := GetFileSize(FFileHandle, nil);
      FileSeek(FFileHandle, 0, 2);
      // 在日志文件末尾添加回车符号
      if dwFileSize > 0 then
      begin
        s := ''#13#10;
        FileWrite(FFileHandle, (PChar(s))^, Length(s));
      end;

      // 写日志文件头信息
      WriteHead(NewFile);
    except
      Result := False;
      FileClose(FFileHandle);
    end;
  finally
    ReleaseMutex(FLockMutex);
  end;

  Result := True;
end;

procedure TpscpLogger.Close;
begin
  FMod := 0;
  if FFileHandle <> 0 then
  begin
    // 写日志文件尾信息
    WaitForSingleObject(FLockMutex, INFINITE);
    try
      WriteTail(True);
      FileClose(FFileHandle);
      FFileHandle := 0;
    finally
      ReleaseMutex(FLockMutex);
    end;
  end;
  CloseHandle(FLockMutex);
  FLockMutex := 0;
  Cfg.Reset;
end;

procedure TpscpLogger.Flush;
begin
  if FFileHandle <> 0 then
  begin
    FlushFileBuffers(THandle(FFileHandle));
  end;
end;

procedure TpscpLogger.LogMsg(LogLevel: Integer; const Format: string;
  const Args: array of const);
var
  content, s        : string;
begin
  // 如果配置文件指定不向任何output输出，直接退出
  if Cfg.Output = Ord(lgoNone) then
    Exit;
  // 如果配置文件指定不输出该Level的信息,直接退出
  if (Cfg.Level and Ord(LogLevel)) = 0 then
    Exit;

  // 格式化要输出的字符串
  FmtStr(content, Format, Args);
  Trim(content);
  DateSeparator := '/';
  FmtStr(s, '[%s][%s][Px%4.4x][Tx%4.4x] %s'#13#10, [
    FormatDateTime('yy/mm/dd-hh:nn:ss zzz', Now),
      LOGGER_LVLSTRS[Ceil(log2(LogLevel)) + 1], // Asiafly Notice!
    GetCurrentProcessId, GetCurrentThreadId, content]);

  // 输出到文件
  if ((Cfg.Output and Ord(lgoFile)) <> 0) and (FFileHandle <> 0) then
  begin
    // 在写之前先进行锁定
    WaitForSingleObject(FLockMutex, INFINITE);
    try
      // 如果当前文件大小大于最大容量，先备份再写
      if GetFileSize(FFileHandle, nil) > DWORD(Cfg.MaxSize) then
        Back_file;
      FileWrite(FFileHandle, (PChar(s))^, Length(s));
    finally
      ReleaseMutex(FLockMutex);
    end;
  end;

  // Write console log message
  if ((Cfg.Output and Ord(lgoConsole)) <> 0) and IsConsole then
    WriteLn(s);

  // Write to debugger
  if (Cfg.Output and Ord(lgoDebugger)) <> 0 then
    OutputDebugString(PChar(s));

  // asiafly deletes the messagebox function!
 // Write messagebox message
//  if (Cfg.Output and Ord(lgoMsgBox)) <> 0 then
//    MessageBox(0, PChar(s), PChar(Cfg.Title), MB_OK);
end;

// force Log Msg, without controling by the setting of Config file

procedure TpscpLogger.LogMsg2(LogLevel: Integer; const Format: string;
  const Args: array of const);
var
  content, s        : string;
begin
  // 格式化要输出的字符串
  FmtStr(content, Format, Args);
  Trim(content);
  DateSeparator := '/';
  FmtStr(s, '[%s][%s][Px%4.4x][Tx%4.4x] %s'#13#10, [
    FormatDateTime('yy/mm/dd-hh:nn:ss zzz', Now),
      LOGGER_LVLSTRS[Ceil(log2(LogLevel)) + 1],
      GetCurrentProcessId, GetCurrentThreadId, content]);

  // 输出到文件
  if ((Cfg.Output and Ord(lgoFile)) <> 0) and (FFileHandle <> 0) then
  begin
    // 在写之前先进行锁定
    WaitForSingleObject(FLockMutex, INFINITE);
    try
      // 如果当前文件大小大于最大容量，先备份再写
      if GetFileSize(FFileHandle, nil) > DWORD(Cfg.MaxSize) then
        Back_file;
      FileWrite(FFileHandle, (PChar(s))^, Length(s));
    finally
      ReleaseMutex(FLockMutex);
    end;
  end;
end;

procedure TpscpLogger.LogDebug(const Format: string;
  const Args: array of const);
begin
  LogMsg(Ord(lglDebug), Format, Args);
  if Cfg.FlushAll then
    Flush;
end;

procedure TpscpLogger.LogError(const Format: string;
  const Args: array of const);
begin
  LogMsg(Ord(lglError), Format, Args);
  Flush;
end;

procedure TpscpLogger.LogInfo(const Format: string;
  const Args: array of const);
begin
  LogMsg(Ord(lglInfo), Format, Args);
  if Cfg.FlushAll then
    Flush;
end;

procedure TpscpLogger.LogPerf(const Format: string;
  const Args: array of const);
begin
  LogMsg(Ord(lglPerf), Format, Args);
  if Cfg.FlushAll then
    Flush;
end;

procedure TpscpLogger.LogVerbose(const Format: string;
  const Args: array of const);
begin
  LogMsg(Ord(lglVerbose), Format, Args);
  if Cfg.FlushAll then
    Flush;
end;

procedure TpscpLogger.LogWarning(const Format: string;
  const Args: array of const);
begin
  LogMsg(Ord(lglWarning), Format, Args);
  Flush;
end;

procedure TpscpLogger.LogCfg;
var
  pCfgText          : PBYTE;
  CfgTextSize       : DWORD;
  CfgFileHandle     : Integer;
begin
  if (FFileHandle <> 0) and FileExists(Cfg.CfgFile) then
  begin
    // 打开配置文件
    CfgFileHandle := FileOpen(Cfg.CfgFile, (fmOpenRead or fmShareDenyWrite));
    if CfgFileHandle = -1 then
      Exit;

    pCfgText := nil;
    try
      // 获得配置文件的大小
      CfgTextSize := GetFileSize(THandle(CfgFileHandle), nil);
      if (CfgTextSize <= 0) or (CfgTextSize > DWORD(Cfg.MaxSize)) then
        Exit;

      // 分配内存
      GetMem(pCfgText, CfgTextSize);
      if pCfgText = nil then
        Exit;

      // 读取配置文件的内容
      FileRead(CfgFileHandle, pCfgText^, CfgTextSize);
      // 将配置文件内容写入日志文件
      FileWrite(FFileHandle, pCfgText^, CfgTextSize);
    finally
      FileClose(CfgFileHandle);
      if pCfgText <> nil then
        FreeMem(pCfgText);
    end;
  end;
end;

procedure TpscpLogger.WriteHead(NewFile: Boolean);
var
  s                 : string;
  mod_path, exe_path: string;
begin
  if FFileHandle <> 0 then
  begin
    mod_path := GetModuleName(FMod);
    exe_path := GetModuleName(0);

    DateSeparator := '/';
    s := '============================================================='#13#10;
    s := s + #09'iFLYTEK log file'#13#10;
    s := s + #09'Subject : ' + Cfg.Title + #13#10;
    if NewFile then
      s := s + Format(#09'Created-Time: %s'#13#10,
        [FormatDateTime('yy/mm/dd-hh:nn:ss zzz', Now)])
    else
      s := s + Format(#09'Continued-Time: %s'#13#10,
        [FormatDateTime('yy/mm/dd-hh:nn:ss zzz', Now)]);
    s := s + Format(#09'Application: %s'#13#10, [exe_path]);
    s := s + Format(#09'Module: %s'#13#10, [mod_path]);
    s := s + Format(#09'PID: %d (0x%4.4x) App ver: %s, Module ver: %s'#13#10,
      [GetCurrentProcessId, GetCurrentProcessId,
      GetFileVersionStr(exe_path), GetFileVersionStr(mod_path)]);
    s := s +
      '============================================================='#13#10;

    Flush;
    FileWrite(FFileHandle, (PChar(s))^, Length(s));
  end;
end;

procedure TpscpLogger.WriteTail(EndFile: Boolean);
var
  s                 : string;
begin
  if FFileHandle <> 0 then
  begin
    s := '============================================================='#13#10;
    if EndFile then
      s := s + Format(#09'%s End-Time: %s'#13#10, [Cfg.Title,
        FormatDateTime('yy/mm/dd-hh:nn:ss zzz', Now)])
    else
      s := s + Format(#09'%s Continue-Time: %s'#13#10, [Cfg.Title,
        FormatDateTime('yy/mm/dd-hh:nn:ss zzz', Now)]);
    s := s + Format(#09'PID: %d (0x%4.4x)'#13#10,
      [GetCurrentProcessId, GetCurrentProcessId]);
    s := s +
      '============================================================='#13#10;

    Flush;
    FileWrite(FFileHandle, (PChar(s))^, Length(s));
  end;
end;

procedure TpscpLogger.Back_file;
var
  bak_name, new_name, time_str: string;
begin
  // 先写文件尾，再关闭原日志文件
  WriteTail(False);
  FileClose(FFileHandle);
  FFileHandle := 0;

  if not Cfg.OverWrite then
  begin
    // 在原日志文件末尾加上日期和时间，作为新的日志文件名
    bak_name := ChangeFileExt(Cfg.LogFile, '');
    time_str := FormatDateTime('yymmdd_hhnnsszzz', Now);
    new_name := Format('%s_%s.log', [bak_name, time_str]);

    // 如果重命名日志文件没有成功，删除日志文件
    if not RenameFile(Cfg.LogFile, new_name) then
      DeleteFile(Cfg.LogFile);
  end
  else
  begin
    // 如果配置文件指定覆盖原日志文件，将日志文件删除
    DeleteFile(Cfg.LogFile);
  end;

  // 在备份或删除原日志文件之后，重新打开日志文件
  FFileHandle := FileCreate(Cfg.LogFile);
  if FFileHandle = -1 then
  begin
    FFileHandle := 0;
    Exit;
  end;
  // 写新的日志文件头
  WriteHead(False);
end;

function TpscpLogger.GetFileVersionStr(const AFileName: string): string;
var
  FileName          : string;
  InfoSize, Wnd     : DWORD;
  VerBuf            : Pointer;
  FI                : PVSFixedFileInfo;
  VerSize           : DWORD;
begin
  // GetFileVersionInfo modifies the filename parameter data while parsing.
  // Copy the string const into a local variable to create a writeable copy.
  FileName := AFileName;
  UniqueString(FileName);
  InfoSize := GetFileVersionInfoSize(PChar(FileName), Wnd);
  if InfoSize <> 0 then
  begin
    GetMem(VerBuf, InfoSize);
    try
      if GetFileVersionInfo(PChar(FileName), Wnd, InfoSize, VerBuf) then
        if VerQueryValue(VerBuf, '\', Pointer(FI), VerSize) then
        begin
          Result := Format('%d.%d.%d.%d', [
            HiWord(FI.dwFileVersionMS), LoWord(FI.dwFileVersionMS),
              HiWord(FI.dwFileVersionLS), LoWord(FI.dwFileVersionLS)]);
        end;
    finally
      FreeMem(VerBuf);
    end;
  end;
end;

function Log_Open(szFile: string; bCfgOrLog: Boolean;
  szSection: string; hMod: HMODULE): Boolean;
begin
  Result := logger_singleton.Open(szFile, bCfgOrLog, szSection, hMod);
end;

procedure Log_Close;
begin
  logger_singleton.Close;
end;

procedure Log_Flush;
begin
  logger_singleton.Flush;
end;

procedure Log_Msg(LogLevel: Integer; const Format: string; const Args: array of
  const);
begin
  logger_singleton.LogMsg(LogLevel, Format, Args);
end;

procedure Log_Error(const Format: string; const Args: array of const);
begin
  logger_singleton.LogError(Format, Args);
end;

procedure Log_Warn(const Format: string; const Args: array of const);
begin
  logger_singleton.LogWarning(Format, Args);
end;

procedure Log_Info(const Format: string; const Args: array of const);
begin
  logger_singleton.LogInfo(Format, Args);
end;

procedure Log_Verb(const Format: string; const Args: array of const);
begin
  logger_singleton.LogVerbose(Format, Args);
end;

procedure Log_Perf(const Format: string; const Args: array of const);
begin
  logger_singleton.LogPerf(Format, Args);
end;

procedure Log_Debug(const Format: string; const Args: array of const);
begin
  logger_singleton.LogDebug(Format, Args);
end;

procedure Log_Wyf(const Format: string; const Args: array of const);
begin
{$IFDEF DEBUGGING}
  logger_singleton.LogMsg2(64, Format, Args);
{$ENDIF}
end;

procedure Log_Cfg;
begin
  logger_singleton.LogCfg;
end;

//-------------------------------------------------------------------------//

function Log2_Open(szFile: string): Boolean;
begin
  Result:= logger2.Open2(szFile);
end;

procedure Log2_Close;   
begin
  logger2.Close;
end;

procedure Log2_Msg(const Format: string; const Args: array of const); 
begin
  logger2.LogMsg(4, Format, Args);
end;

//-------------------------------------------------------------------------//

initialization
  logger_singleton := TpscpLogger.Create;
  logger2 := TpscpLogger.Create;

finalization
  if logger_singleton <> nil then
  begin
    logger_singleton.Free;
    logger_singleton := nil;
  end;
  
  if Assigned(logger2) then
  begin
    FreeAndNil(logger2);
  end;

end.

