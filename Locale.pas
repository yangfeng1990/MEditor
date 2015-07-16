unit Locale;
interface
uses Graphics, SysUtils;

type proc=procedure;
     TLocale=record
               Name:WideString;
               Func:proc;
               LangID:integer;
               Charset:TFontCharset;
             end;
var Locales:array of TLocale;
    CurrentLocale:integer;

var LOCstr_Title:WideString;
    LOCstr_OpenURL_Caption:WideString;
    LOCstr_OpenURL_Prompt:WideString;
    LOCstr_AutoLocale:WideString;
    LOCstr_Status_Opening:WideString;
    LOCstr_Status_Closing:WideString;
    LOCstr_Status_Playing:WideString;
    LOCstr_Status_Paused:WideString;
    LOCstr_Status_Stopped:WideString;
    LOCstr_Status_Error:WideString;

var LOCstr_NoInfo:WideString;
    LOCstr_InfoFileFormat:WideString;
    LOCstr_InfoPlaybackTime:WideString;
    LOCstr_InfoTags:WideString;
    LOCstr_InfoVideo:WideString;
    LOCstr_InfoAudio:WideString;
    LOCstr_InfoDecoder:WideString;
    LOCstr_InfoCodec:WideString;
    LOCstr_InfoBitrate:WideString;
    LOCstr_InfoVideoSize:WideString;
    LOCstr_InfoVideoFPS:WideString;
    LOCstr_InfoVideoAspect:WideString;
    LOCstr_InfoAudioRate:WideString;
    LOCstr_InfoAudioChannels:WideString;

const NoLocale=-1;
      AutoLocale=-1;

procedure RegisterLocale(const _Name:WideString; const _Func:proc; _LangID:integer; _Charset:TFontCharset);
procedure ActivateLocale(Index:integer);

implementation
uses Windows, Forms, Main, Help, Options, plist, About, Log, Info;

procedure RegisterLocale(const _Name:WideString; const _Func:proc; _LangID:integer; _Charset:TFontCharset);
begin
  SetLength(Locales,length(Locales)+1);
  with Locales[High(Locales)] do begin
    Name:=_Name;
    Func:=_Func;
    LangID:=_LangID;
    Charset:=_Charset;
  end;
end;

procedure ActivateLocale(Index:integer);
var i,WantedLangID:integer;
begin
  if Index=AutoLocale then begin
    WantedLangID:=GetUserDefaultLCID() AND 1023;
    Index:=0;
    for i:=Low(Locales) to High(Locales) do
      if Locales[i].LangID=WantedLangID then begin
        Index:=i;
        break;
      end;
  end;
  if (Index<Low(Locales)) OR (Index>High(Locales)) then exit;

  MainForm.Font.Charset:=Locales[Index].Charset;
  OptionsForm.Font.Charset:=Locales[Index].Charset;
  PlaylistForm.Font.Charset:=Locales[Index].Charset;
  HelpForm.Font.Charset:=Locales[Index].Charset;
  InfoForm.Font.Charset:=Locales[Index].Charset;

  MainForm.LEscape.Font.Charset:=Locales[Index].Charset;
  OptionsForm.LHelp.Font.Charset:=Locales[Index].Charset;
  AboutForm.Font.Charset:=Locales[Index].Charset;
  AboutForm.MTitle.Font.Charset:=Locales[Index].Charset;
  AboutForm.LVersionMPUI.Font.Charset:=Locales[Index].Charset;
  AboutForm.LVersionMPlayer.Font.Charset:=Locales[Index].Charset;

  CurrentLocale:=Index;
  Locales[Index].Func;
  HelpForm.Format;
  OptionsForm.Localize;
  MainForm.Localize;
  MainForm.UpdateStatus;
  Application.Title:=LOCstr_Title;
  MainForm.UpdateCaption;
end;

begin
  SetLength(Locales,0);
  CurrentLocale:=NoLocale;
  LOCstr_Title:='MPlayer for Windows';
  LOCstr_OpenURL_Caption:='URL';
  LOCstr_OpenURL_Prompt:='URL?';
  LOCstr_AutoLocale:='auto';
  LOCstr_Status_Opening:='OPENING';
  LOCstr_Status_Closing:='CLOSING';
  LOCstr_Status_Playing:='PLAYING';
  LOCstr_Status_Paused:='PAUSED';
  LOCstr_Status_Stopped:='STOPPED';
  LOCstr_Status_Error:='ERROR';
  LOCstr_NoInfo:='NO_INFO';
  LOCstr_InfoFileFormat:='FILE_FORMAT';
  LOCstr_InfoPlaybackTime:='LENGTH';
  LOCstr_InfoTags:='TAGS';
  LOCstr_InfoVideo:='VIDEO';
  LOCstr_InfoAudio:='AUDIO';
  LOCstr_InfoDecoder:='DECODER';
  LOCstr_InfoCodec:='CODEC';
  LOCstr_InfoBitrate:='BITRATE';
  LOCstr_InfoVideoSize:='SIZE';
  LOCstr_InfoVideoFPS:='FPS';
  LOCstr_InfoVideoAspect:='ASPECT';
  LOCstr_InfoAudioRate:='RATE';
  LOCstr_InfoAudioChannels:='NCH';
end.
