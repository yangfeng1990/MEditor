unit mo_en;
interface
implementation
uses Windows,Locale,Main,Log,Help,About,Options,plist,Info;

procedure Activate;
begin
  with MainForm do begin
    LOCstr_Title:='MPlayer for Windows';
      LOCstr_Status_Opening:='Opening ...';
      LOCstr_Status_Closing:='Closing ...';
      LOCstr_Status_Playing:='Playing';
      LOCstr_Status_Paused:='Paused';
      LOCstr_Status_Stopped:='Stopped';
      LOCstr_Status_Error:='Unable to play media (Click for more info)';
    BPlaylist.Hint:='Show/hide playlist window';
    BStreamInfo.Hint:='Show/hide clip information';
    BFullscreen.Hint:='Toggle fullscreen mode';
    BCompact.Hint:='Toggle compact mode';
    BMute.Hint:='Toggle Mute';
    MPFullscreenControls.Caption:='Show fullscreen controls';
    OSDMenu.Caption:='OSD mode';
      MNoOSD.Caption:='No OSD';
      MDefaultOSD.Caption:='Default OSD';
      MTimeOSD.Caption:='Show time';
      MFullOSD.Caption:='Show total time';
    LEscape.Caption:='Press Escape to exit fullscreen mode.';
    MFile.Caption:='File';
      MOpenFile.Caption:='Play file ...';
      MOpenURL.Caption:='Play URL ...';
        LOCstr_OpenURL_Caption:='Play URL';
        LOCstr_OpenURL_Prompt:='Which URL do you want to play?';
      MOpenDrive.Caption:='Play CD/DVD';
      MClose.Caption:='Close';
      MQuit.Caption:='Quit';
    MView.Caption:='View';
      MSizeAny.Caption:='Custom size';
      MSize50.Caption:='Half size';
      MSize100.Caption:='Original size';
      MSize200.Caption:='Double size';
      MFullscreen.Caption:='Fullscreen';
      MCompact.Caption:='Compact mode';
      MOSD.Caption:='Toggle OSD';
      MOnTop.Caption:='Always on top';
    MSeek.Caption:='Play';
      MPlay.Caption:='Play';
      MPause.Caption:='Pause';
      MPrev.Caption:='Previous title';
      MNext.Caption:='Next title';
      MShowPlaylist.Caption:='Playlist ...';
      MMute.Caption:='Mute';
      MSeekF10.Caption:='Forward 10 seconds'^I'Right';
      MSeekR10.Caption:='Rewind 10 seconds'^I'Left';
      MSeekF60.Caption:='Forward 1 minute'^I'Up';
      MSeekR60.Caption:='Rewind 1 minute'^I'Down';
      MSeekF600.Caption:='Forward 10 minutes'^I'PgUp';
      MSeekR600.Caption:='Rewind 10 minutes'^I'PgDn';
    MExtra.Caption:='Tools';
      MAudio.Caption:='Audio track';
      MSubtitle.Caption:='Subtitle track';
      MAspect.Caption:='Aspect ratio';
        MAutoAspect.Caption:='Autodetect';
        MForce43.Caption:='Force 4:3';
        MForce169.Caption:='Force 16:9';
        MForceCinemascope.Caption:='Force 2.35:1';
      MDeinterlace.Caption:='Deinterlace';
        MNoDeint.Caption:='Off';
        MSimpleDeint.Caption:='Simple';
        MAdaptiveDeint.Caption:='Adaptive';
      MOptions.Caption:='Options ...';
      MLanguage.Caption:='Language';
      MStreamInfo.Caption:='Show clip information ...';
      MShowOutput.Caption:='Show MPlayer output ...';
    MHelp.Caption:='Help';
      MKeyHelp.Caption:='Keyboard help ...';
      MAbout.Caption:='About ...';
  end;
  LogForm.Caption:='MPlayer output';
  LogForm.BClose.Caption:='Close';
  HelpForm.Caption:='Keyboard help';
  HelpForm.HelpText.Text:=
'Navigation keys:'^M^J+
'Space'^I'Play/Pause'^M^J+
'Right'^I'Forward 10 seconds'^M^J+
'Left'^I'Rewind 10 seconds'^M^J+
'Up'^I'Forward 1 minute'^M^J+
'Down'^I'Rewind 1 minute'^M^J+
'PgUp'^I'Forward 10 minutes'^M^J+
'PgDn'^I'Rewind 10 minutes'^M^J+
^M^J+
'Other keys:'^M^J+
'O'^I'Toggle OSD'^M^J+
'F'^I'Toggle fullscreen'^M^J+
'C'^I'Toggle compact mode'^M^J+
'T'^I'Toggle always on top'^M^J+
'Q'^I'Quit immediately'^M^J+
'9/0'^I'Adjust volume'^M^J+
'-/+'^I'Adjust audio/video sync'^M^J+
'1/2'^I'Adjust brightness'^M^J+
'3/4'^I'Adjust contrast'^M^J+
'5/6'^I'Adjust hue'^M^J+
'7/8'^I'Adjust saturation'
  ;
  HelpForm.BClose.Caption:='Close';
  AboutForm.Caption:='About MPUI';
  AboutForm.BClose.Caption:='Close';
  AboutForm.LVersionMPUI.Caption:='MPUI version:';
  AboutForm.LVersionMPlayer.Caption:='MPlayer core version:';
  with OptionsForm do begin
    Caption:='Options';
    BOK.Caption:='OK';
    BApply.Caption:='Apply';
    BSave.Caption:='Save';
    BClose.Caption:='Close';
    LAudioOut.Caption:='Sound output driver';
      CAudioOut.Items[0]:='(don''t decode sound)';
      CAudioOut.Items[1]:='(don''t play sound)';
    LAudioDev.Caption:='DirectSound output device';
    LPostproc.Caption:='Postprocessing';
      CPostproc.Items[0]:='Off';
      CPostproc.Items[1]:='Automatic';
      CPostproc.Items[2]:='Maximum quality';
    LOCstr_AutoLocale:='(Auto-select)';
    CIndex.Caption:='Rebuild file index if necessary';
    CSoftVol.Caption:='Software volume control / Volume boost';
    CPriorityBoost.Caption:='Run with higher priority';
    LParams.Caption:='Additional MPlayer parameters:';
    LHelp.Caption:='Help';
  end;
  with PlaylistForm do begin
    Caption:='Playlist';
    BPlay.Caption:='Play';
    BAdd.Caption:='Add ...';
    BMoveUp.Caption:='Move up';
    BMoveDown.Caption:='Move down';
    BDelete.Caption:='Remove';
    CShuffle.Caption:='Shuffle';
    CLoop.Caption:='Repeat';
    BSave.Caption:='Save ...';
    BClose.Caption:='Close';
  end;
  InfoForm.Caption:='Clip information';
  InfoForm.BClose.Caption:='Close';
  LOCstr_NoInfo:='No clip information is available at the moment.';
  LOCstr_InfoFileFormat:='Format';
  LOCstr_InfoPlaybackTime:='Duration';
  LOCstr_InfoTags:='Clip Metadata';
  LOCstr_InfoVideo:='Video Track';
  LOCstr_InfoAudio:='Audio Track';
  LOCstr_InfoDecoder:='Decoder';
  LOCstr_InfoCodec:='Codec';
  LOCstr_InfoBitrate:='Bitrate';
  LOCstr_InfoVideoSize:='Dimensions';
  LOCstr_InfoVideoFPS:='Frame Rate';
  LOCstr_InfoVideoAspect:='Aspect Ratio';
  LOCstr_InfoAudioRate:='Sample Rate';
  LOCstr_InfoAudioChannels:='Channels';
end;

begin
  RegisterLocale('English',Activate,LANG_ENGLISH,ANSI_CHARSET);
end.
