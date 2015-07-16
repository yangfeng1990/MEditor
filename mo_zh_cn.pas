unit mo_zh_cn;

interface
implementation
uses Windows,Locale,Main,Log,Help,About,Options,plist,Info;

procedure Activate;
begin
  with MainForm do begin
    LOCstr_Title:=UTF8Decode('MPlayer for Windows');
      LOCstr_Status_Opening:=UTF8Decode('打开 ...');
      LOCstr_Status_Closing:=UTF8Decode('关闭 ...');
      LOCstr_Status_Playing:=UTF8Decode('播放');
      LOCstr_Status_Paused:=UTF8Decode('暂停');
      LOCstr_Status_Stopped:=UTF8Decode('停止');
      LOCstr_Status_Error:=UTF8Decode('无法播放剪辑（点击查看更多信息）');
    BPlaylist.Hint:=UTF8Decode('显示/隐藏播放列表');
    BStreamInfo.Hint:=UTF8Decode('显示/隐藏剪辑信息');
    BFullscreen.Hint:=UTF8Decode('切换全屏幕模式');
    BCompact.Hint:=UTF8Decode('切换完整模式');
    BMute.Hint:=UTF8Decode('切换静音');
    MPFullscreenControls.Caption:=UTF8Decode('显示全屏幕控制');
    OSDMenu.Caption:=UTF8Decode('OSD 模式');
      MNoOSD.Caption:=UTF8Decode('无 OSD');
      MDefaultOSD.Caption:=UTF8Decode('默认 OSD');
      MTimeOSD.Caption:=UTF8Decode('显示时间');
      MFullOSD.Caption:=UTF8Decode('显示完整时间');
    LEscape.Caption:=UTF8Decode('使用Escape退出全屏幕模式');
    MFile.Caption:=UTF8Decode('文件');
      MOpenFile.Caption:=UTF8Decode('播放文件 ...');
      MOpenURL.Caption:=UTF8Decode('播放 URL ...');
        LOCstr_OpenURL_Caption:=UTF8Decode('播放 URL');
        LOCstr_OpenURL_Prompt:=UTF8Decode('请输入你想播放的URL');
      MOpenDrive.Caption:=UTF8Decode('播放 CD/DVD');
      MClose.Caption:=UTF8Decode('关闭');
      MQuit.Caption:=UTF8Decode('退出');
    MView.Caption:=UTF8Decode('查看');
      MSizeAny.Caption:=UTF8Decode('自定义尺寸');
      MSize50.Caption:=UTF8Decode('半尺寸');
      MSize100.Caption:=UTF8Decode('原始尺寸');
      MSize200.Caption:=UTF8Decode('双倍尺寸');
      MFullscreen.Caption:=UTF8Decode('全屏幕');
      MCompact.Caption:=UTF8Decode('完整模式');
      MOSD.Caption:=UTF8Decode('切换 OSD');
      MOnTop.Caption:=UTF8Decode('保持在窗口最上端');
    MSeek.Caption:=UTF8Decode('播放');
      MPlay.Caption:=UTF8Decode('播放');
      MPause.Caption:=UTF8Decode('暂停');
      MPrev.Caption:=UTF8Decode('上一个标题');
      MNext.Caption:=UTF8Decode('下一个标题');
      MShowPlaylist.Caption:=UTF8Decode('播放列表 ...');
      MMute.Caption:=UTF8Decode('静音');
      MSeekF10.Caption:=UTF8Decode('快进10秒'^I'Right');
      MSeekR10.Caption:=UTF8Decode('后退10秒'^I'Left');
      MSeekF60.Caption:=UTF8Decode('快进1分'^I'Up');
      MSeekR60.Caption:=UTF8Decode('后退1分'^I'Down');
      MSeekF600.Caption:=UTF8Decode('快进10分'^I'PgUp');
      MSeekR600.Caption:=UTF8Decode('后退10分'^I'PgDn');
    MExtra.Caption:=UTF8Decode('工具');
      MAudio.Caption:=UTF8Decode('音轨');
      MSubtitle.Caption:=UTF8Decode('字幕');
      MAspect.Caption:=UTF8Decode('外观比例');
        MAutoAspect.Caption:=UTF8Decode('自动检测');
        MForce43.Caption:=UTF8Decode('强制 4:3');
        MForce169.Caption:=UTF8Decode('强制 16:9');
        MForceCinemascope.Caption:=UTF8Decode('强制 2.35:1');
      MDeinterlace.Caption:=UTF8Decode('去交错');
        MNoDeint.Caption:=UTF8Decode('关闭');
        MSimpleDeint.Caption:=UTF8Decode('简单');
        MAdaptiveDeint.Caption:=UTF8Decode('适应');
      MOptions.Caption:=UTF8Decode('设置 ...');
      MLanguage.Caption:=UTF8Decode('语言');
      MStreamInfo.Caption:=UTF8Decode('显示剪辑信息 ...');
      MShowOutput.Caption:=UTF8Decode('显示 MPlayer 输出 ...');
    MHelp.Caption:=UTF8Decode('帮助');
      MKeyHelp.Caption:=UTF8Decode('热键帮助 ...');
      MAbout.Caption:=UTF8Decode('关于 ...');
  end;
  LogForm.Caption:=UTF8Decode('MPlayer 输出');
  LogForm.BClose.Caption:=UTF8Decode('关闭');
  HelpForm.Caption:=UTF8Decode('热键帮助');
  HelpForm.HelpText.Text:=UTF8Decode(
'浏览热键'^M^J+
'Space'^I'播放/暂停'^M^J+
'Right'^I'快进10秒'^M^J+
'Left'^I'后退10秒'^M^J+
'Up'^I'快进1分'^M^J+
'Down'^I'后退1分'^M^J+
'PgUp'^I'快进10分'^M^J+
'PgDn'^I'后退10分'^M^J+
^M^J+
'其他热键:'^M^J+
'O'^I'切换 OSD'^M^J+
'F'^I'切换全屏幕模式'^M^J+
'C'^I'切换完整模式'^M^J+
'T'^I'切换静音'^M^J+
'Q'^I'立刻退出'^M^J+
'9/0'^I'调整音量'^M^J+
'-/+'^I'调整音频/视频同步'^M^J+
'1/2'^I'调整亮度'^M^J+
'3/4'^I'调整对比度'^M^J+
'5/6'^I'调整色调'^M^J+
'7/8'^I'调整饱和度'
  );
  HelpForm.BClose.Caption:=UTF8Decode('关闭');
  AboutForm.Caption:=UTF8Decode('关于 MPUI');
  AboutForm.BClose.Caption:=UTF8Decode('关闭');
  AboutForm.LVersionMPUI.Caption:=UTF8Decode('MPUI 版本：');
  AboutForm.LVersionMPlayer.Caption:=UTF8Decode('MPlayer 核心版本');
  with OptionsForm do begin
    Caption:=UTF8Decode('设置');
    BOK.Caption:=UTF8Decode('确认');
    BApply.Caption:=UTF8Decode('应用');
    BSave.Caption:=UTF8Decode('保存');
    BClose.Caption:=UTF8Decode('关闭');
    LAudioOut.Caption:=UTF8Decode('音频输出设备');
      CAudioOut.Items[0]:=UTF8Decode('(不解码音频)');
      CAudioOut.Items[1]:=UTF8Decode('(不播放声音)');
    LAudioDev.Caption:=UTF8Decode('DirectSound 输出设备');
    LPostproc.Caption:=UTF8Decode('后处理');
      CPostproc.Items[0]:=UTF8Decode('关闭');
      CPostproc.Items[1]:=UTF8Decode('自动');
      CPostproc.Items[2]:=UTF8Decode('最佳质量');
    LOCstr_AutoLocale:=UTF8Decode('(自动选择)');
    CIndex.Caption:=UTF8Decode('如果必要重建剪辑索引');
    CSoftVol.Caption:=UTF8Decode('软件音量控制/提升');
    CPriorityBoost.Caption:=UTF8Decode('使用更高的运行级别');
    LParams.Caption:=UTF8Decode('额外的MPlayer 参数：');
    LHelp.Caption:=UTF8Decode('帮助');
  end;
  with PlaylistForm do begin
    Caption:=UTF8Decode('播放列表');
    BPlay.Caption:=UTF8Decode('播放');
    BAdd.Caption:=UTF8Decode('添加 ...');
    BMoveUp.Caption:=UTF8Decode('上移');
    BMoveDown.Caption:=UTF8Decode('下移');
    BDelete.Caption:=UTF8Decode('删除');
	CShuffle.Caption:=UTF8Decode('随机');
    CLoop.Caption:=UTF8Decode('重复');
    BSave.Caption:=UTF8Decode('保存 ...');
    BClose.Caption:=UTF8Decode('关闭');
  end;
  InfoForm.Caption:=UTF8Decode('剪辑信息');
  InfoForm.BClose.Caption:=UTF8Decode('关闭');
  LOCstr_NoInfo:=UTF8Decode('当前没有可用的剪辑信息');
  LOCstr_InfoFileFormat:=UTF8Decode('格式');
  LOCstr_InfoPlaybackTime:=UTF8Decode('长度');
  LOCstr_InfoTags:=UTF8Decode('剪辑元数据');
  LOCstr_InfoVideo:=UTF8Decode('视频');
  LOCstr_InfoAudio:=UTF8Decode('音频');
  LOCstr_InfoDecoder:=UTF8Decode('解码器');
  LOCstr_InfoCodec:=UTF8Decode('编码器');
  LOCstr_InfoBitrate:=UTF8Decode('比特率');
  LOCstr_InfoVideoSize:=UTF8Decode('大小');
  LOCstr_InfoVideoFPS:=UTF8Decode('帧率');
  LOCstr_InfoVideoAspect:=UTF8Decode('外观比例');
  LOCstr_InfoAudioRate:=UTF8Decode('采样率');
  LOCstr_InfoAudioChannels:=UTF8Decode('声道数');
end;

begin
  RegisterLocale('Chinese (Simplified)',Activate,LANG_CHINESE,GB2312_CHARSET);
end.
