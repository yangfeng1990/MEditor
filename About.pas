unit About;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ShellAPI;

type
  TAboutForm = class(TForm)
    PLogo: TPanel;
    ILogo: TImage;
    VersionMPUI: TLabel;
    VersionMPlayer: TLabel;
    BClose: TButton;
    MCredits: TMemo;
    LVersionMPlayer: TLabel;
    LVersionMPUI: TLabel;
    MTitle: TMemo;
    LURL: TLabel;
    procedure FormShow(Sender: TObject);
    procedure BCloseClick(Sender: TObject);
    procedure URLClick(Sender: TObject);
    procedure ReadOnlyItemEnter(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutForm: TAboutForm;

implementation
                
uses Main, Core, Locale;

{$R *.dfm}

function GetProductVersion(const FileName:string):string;
const BufSize=1024*1024;
var Buf:array of char;
var VerOut:PChar; VerLen:cardinal;
begin
  Result:='?';
  SetLength(Buf,BufSize);
  if not GetFileVersionInfo(PChar(FileName),0,BufSize,@Buf[0]) then exit;
  if not VerQueryValue(@Buf[0],'\StringFileInfo\000004B0\ProductVersion',Pointer(VerOut),VerLen) then exit;
  Result:=VerOut;
end;

function GetFileVersion(const FileName:string):string;
const BufSize=1024*1024;
var Buf:array of char;
    VerLen:cardinal; Info:^VS_FIXEDFILEINFO;
    Attributes:string;
begin
  Result:='?';
  SetLength(Buf,BufSize);
  if not GetFileVersionInfo(PChar(FileName),0,BufSize,@Buf[0]) then exit;
  if not VerQueryValue(@Buf[0],'\',Pointer(Info),VerLen) then exit;
  Result:=IntToStr(Info.dwFileVersionMS SHR 16)+'.'+
          IntToStr(Info.dwFileVersionMS AND $FFFF)+'.'+
          IntToStr(Info.dwFileVersionLS SHR 16)+' build '+
          IntToStr(Info.dwFileVersionLS AND $FFFF);
  Attributes:='';
  if (Info.dwFileFlags AND VS_FF_PATCHED<>0)      then Attributes:=Attributes+' patched';
  if (Info.dwFileFlags AND VS_FF_DEBUG<>0)        then Attributes:=Attributes+' debug';
  if (Info.dwFileFlags AND VS_FF_PRIVATEBUILD<>0) then Attributes:=Attributes+' private';
  if (Info.dwFileFlags AND VS_FF_SPECIALBUILD<>0) then Attributes:=Attributes+' special';
  if (Info.dwFileFlags AND VS_FF_PRERELEASE<>0)   then Attributes:=Attributes+' pre-release';
  if length(Attributes)>0 then Result:=Result+' ('+Copy(Attributes,2,100)+')';
end;



procedure TAboutForm.FormShow(Sender: TObject);
begin
  ILogo.Picture:=MainForm.Logo.Picture;
  MTitle.Text:=LOCstr_Title;
  VersionMPlayer.Caption:=GetProductVersion(HomeDir+'mplayer.exe');
  VersionMPUI.Caption:=GetFileVersion(HomeDir+ExtractFileName(ParamStr(0)));
  ActiveControl:=BClose;
end;

procedure TAboutForm.BCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TAboutForm.URLClick(Sender: TObject);
begin
  ShellExecute(Handle,'open',PChar((Sender as TLabel).Caption),nil,nil,SW_SHOW);
end;

procedure TAboutForm.ReadOnlyItemEnter(Sender: TObject);
begin
  ActiveControl:=BClose;
end;

procedure TAboutForm.FormCreate(Sender: TObject);
begin
{$IFDEF VER150}
  // some fixes for Delphi>=7 VCLs
  PLogo.ParentBackground:=False;
{$ENDIF}
end;

end.
