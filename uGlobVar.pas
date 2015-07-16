unit uGlobVar;

interface

uses
  SysUtils,
  Windows,
  Classes,
  StdCtrls, Controls, Graphics, Forms, Dialogs;


type
  TGlobVar = class
  private
    FStartCutPonit : integer;       // 编辑时设置为起点的时间点百分比
    FEndCutPonit : integer;         // 编辑时设置为终点的时间点百分比
    FMergerCutPoint : Integer;      // 合并时第二个视频的终点，即百分百
    FPlayFileName : string;         // 正在播放的视频文件名称
    FVideoLength : Integer;         // 视频总时长
    FCutTempFileName : string;      // 裁剪转码生成的临时文件，在程序退出时进行清理
    FConvertID : Integer;           // 转换的ID，ID=0为ConvertFrm的转换，ID=1为MergerFrm的视频1转换，
                                    // ID=2为MergerFrm的视频2转换，ID=3为MergerFrm的合并结果转换
    FMergeDurationTs1 : Integer;
    FMergeDurationTs2 : Integer;

    FTempMergeFile1 : string;       // 合并时Ts文件名
    FTempMergeFile2 : string;
    FTempMergeFileTs1 : string;
    FTempMergeFileTs2 : string;

    FtempProgress : Integer;        // 当前进度条的值，用于优化进度条前后反复的问题

  public
    constructor Create(runPath: string);
    destructor Destroy; override;

    property StartCutPonit: Integer read FStartCutPonit write FStartCutPonit;
    property EndCutPonit: Integer read FEndCutPonit write FEndCutPonit;
    property MergerCutPoint : Integer read FMergerCutPoint write FMergerCutPoint;
    property PlayFileName : string read FPlayFileName write FPlayFileName;
    property VideoLength : Integer read FVideoLength write FVideoLength;
    property CutTempFileName : string read FCutTempFileName write FCutTempFileName;
    property ConvertID : Integer read FConvertID write FConvertID;
    property MergeDurationTs1 : Integer read FMergeDurationTs1 write FMergeDurationTs1;
    property MergeDurationTs2 : Integer read FMergeDurationTs2 write FMergeDurationTs2;
    property TempMergeFile1 : string  read FTempMergeFile1 write FTempMergeFile1;
    property TempMergeFile2 : string read FTempMergeFile2 write FTempMergeFile2;
    property TempMergeFileTs1 : string read FTempMergeFileTs1 write FTempMergeFileTs1;
    property TempMergeFileTs2 : string read FTempMergeFileTs2 write FTempMergeFileTs2;
    property tempProgress : Integer read FtempProgress write FtempProgress;
  published
  end;

var
  GlobVar: TGlobVar;

implementation

constructor TGlobVar.Create(runPath: string);

begin
  FStartCutPonit := 0;
  FEndCutPonit := 0;
  FMergerCutPoint := 0;
  FPlayFileName := '';
  FVideoLength := 0;
  FCutTempFileName := '';
  FConvertID := 0;
  FMergeDurationTs1 := 0;
  FMergeDurationTs2 := 0;
  FTempMergeFile1 := '';
  FTempMergeFile2 := '';
  FTempMergeFileTs1 := '';
  FTempMergeFileTs2 := '';
  FtempProgress := 0;
end;

destructor TGlobVar.Destroy;
begin
  inherited;
end;

end.

