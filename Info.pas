unit Info;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TInfoForm = class(TForm)
    InfoBox: TListBox;
    BClose: TButton;
    procedure BCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure InfoBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormDestroy(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
  private
    { Private declarations }
    TabOffset:integer;
    procedure FormMove(var msg:TMessage); message WM_MOVE;
  public
    { Public declarations }
    ControlledMove:boolean;
    procedure UpdateInfo;
  end;

var
  InfoForm: TInfoForm;
  Docked:boolean;

implementation
uses Core, Locale, Main;

{$R *.dfm}

function FormatAspectRatio(const Aspect:real):string;
var Numerator,Denominator:integer;
begin
  for Denominator:=1 to 50 do begin
    Numerator:=round(Aspect*Denominator);
    if abs(Numerator/Denominator-Aspect)<0.001 then begin
      Result:=IntToStr(Numerator)+':'+IntToStr(Denominator);
      exit;
    end;
  end;
  str(Aspect:0:3,Result); Result:=Result+':1';
end;


procedure TInfoForm.FormCreate(Sender: TObject);
begin
  UpdateInfo;
  ControlledMove:=True;
  Docked:=true;
end;

procedure TInfoForm.BCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TInfoForm.UpdateInfo;
var HaveTagHeader,HaveVideoHeader,HaveAudioHeader:boolean;
    W,i:integer; s:string;
  procedure AddHeader(var Flag:boolean; const Caption:WideString); begin
    if Flag then exit;
    InfoBox.Items.Add('!'+Caption);
    Flag:=true;
  end;
  procedure AddItem(const Key:WideString; const Value:string); begin
    W:=Canvas.TextWidth(Key);
    if W>TabOffset then TabOffset:=W;
    InfoBox.Items.Add(Key+^I+Value);
  end;
  procedure T(const Key:WideString; const Value:string);
    begin AddHeader(HaveTagHeader,LOCstr_InfoTags); AddItem(Key,Value); end;
  procedure V(const Key:WideString; const Value:string);
    begin AddHeader(HaveVideoHeader,LOCstr_InfoVideo); AddItem(Key,Value); end;
  procedure A(const Key:WideString; const Value:string);
    begin AddHeader(HaveAudioHeader,LOCstr_InfoAudio); AddItem(Key,Value); end;
begin with Core.StreamInfo do begin
  if not Visible then exit;
  InfoBox.Items.Clear;
  TabOffset:=0;
  if length(FileName)=0 then begin
    InfoBox.Items.Add(LOCstr_NoInfo);
    exit;                               
  end;
  HaveTagHeader:=false;
  HaveVideoHeader:=false;
  HaveAudioHeader:=false;
  InfoBox.Items.Add(FileName);
  if length(FileFormat)>0 then
    InfoBox.Items.Add(LOCstr_InfoFileFormat+^I+FileFormat);
  if length(PlaybackTime)>0 then
    InfoBox.Items.Add(LOCstr_InfoPlaybackTime+^I+PlaybackTime);
  for i:=0 to 9 do
    with ClipInfo[i] do
      if (length(Key)>0) AND (length(Value)>0) then
        T(Key, Value);
  if length(Video.Decoder)>0 then
    V(LOCstr_InfoDecoder, Video.Decoder);
  if length(Video.Codec)>0 then
    V(LOCstr_InfoCodec, Video.Codec);
  if Video.Bitrate<>0 then
    V(LOCstr_InfoBitrate, IntToStr(Video.Bitrate DIV 1000)+' kbps');
  if (Video.Width<>0) AND (Video.Height<>0) then
    V(LOCstr_InfoVideoSize, IntToStr(Video.Width)+' x '+IntToStr(Video.Height));
  if (Video.FPS>0.01) then begin
    str(Video.FPS:0:3,s); V(LOCstr_InfoVideoFPS, s+' fps'); end;
  if (Video.Aspect>0.01) then begin
    V(LOCstr_InfoVideoAspect, FormatAspectRatio(Video.Aspect)); end;
  if length(Audio.Decoder)>0 then
    A(LOCstr_InfoDecoder, Audio.Decoder);
  if length(Audio.Codec)>0 then
    A(LOCstr_InfoCodec, Audio.Codec);
  if Audio.Bitrate<>0 then
    A(LOCstr_InfoBitrate, IntToStr(Audio.Bitrate DIV 1000)+' kbps');
  if Audio.Rate<>0 then
    A(LOCstr_InfoAudioRate, IntToStr(Audio.Rate)+' Hz');
  if Audio.Channels<>0 then
    A(LOCstr_InfoAudioChannels, IntToStr(Audio.Channels));
end; end;

procedure TInfoForm.FormShow(Sender: TObject);
begin
  UpdateInfo;
  MainForm.MStreamInfo.Checked:=True;
  MainForm.BStreamInfo.Down:=True;
end;

procedure TInfoForm.FormHide(Sender: TObject);
begin
  MainForm.MStreamInfo.Checked:=False;
  MainForm.BStreamInfo.Down:=False;
end;

procedure TInfoForm.InfoBoxDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
var s:string; p:integer;
begin with InfoBox.Canvas do begin
  s:=InfoBox.Items[Index];
  if s[1]='!' then begin
    Brush.Color:=clBtnFace;
    Font.Color:=clBtnText;
    Font.Style:=Font.Style+[fsBold];
    FillRect(Rect);
    TextOut(Rect.Left+2, Rect.Top+1, Copy(s,2,length(s)));
    exit;
  end;
  p:=Pos(^I,s);
  FillRect(Rect);
  if p>0 then begin
    TextOut(Rect.Left+2, Rect.Top+1, Copy(s,1,p-1));
    TextOut(Rect.Left+TabOffset+10, Rect.Top+1, Copy(s,p+1,length(s)));
  end else
    TextOut(Rect.Left+2, Rect.Top+1, s);
end; end;

procedure TInfoForm.FormDestroy(Sender: TObject);
begin
  Docked:=False;
end;

procedure TInfoForm.FormMove(var msg:TMessage);
begin
  msg.Result:=0;
  if ControlledMove then ControlledMove:=False else Docked:=False;
end;

procedure TInfoForm.FormDblClick(Sender: TObject);
begin
  Docked:=True; MainForm.UpdateDockedWindows;
end;

end.
