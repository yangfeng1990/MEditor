{   MPUI, an MPlayer frontend for Windows
    Copyright (C) 2005 Martin J. Fiedler <martin.fiedler@gmx.net>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}
unit Config;
interface
uses Core, Main, Locale;

const DefaultFileName='MPUI.ini';
      SectionName='MPUI';

var DefaultLocale:integer=AutoLocale;

const AudioOutMap:array[0..3]of string=('nosound','null','win32','dsound');
const PostprocMap:array[0..2]of string=('off','auto','max');
const DeinterlaceMap:array[0..2]of string=('off','simple','adaptive');
const AspectMap:array[0..3]of string=('auto','4:3','16:9','2.35:1');

procedure Load(const FileName:string);
procedure Save(const FileName:string);

implementation
uses SysUtils, INIFiles;

procedure Unmap(const Map:array of string; var Dest:integer; Value:string);
var i:integer;
begin
  Value:=LowerCase(Value);
  for i:=Low(Map) to High(Map) do
    if Map[i]=Value then begin
      Dest:=i;
      exit;
    end;
end;

procedure Load(const FileName:string);
var INI:TINIFile;
begin
  if not FileExists(FileName) then exit;
  INI:=TINIFile.Create(FileName);
  with INI do begin
    DefaultLocale:=ReadInteger(SectionName,'Locale',DefaultLocale);
    Unmap(AudioOutMap,Core.AudioOut,ReadString(SectionName,'AudioOut',''));
    Core.AudioDev:=ReadInteger(SectionName,'AudioDev',Core.AudioDev);
    Unmap(PostprocMap,Core.Postproc,ReadString(SectionName,'Postproc',''));
    Unmap(DeinterlaceMap,Core.Deinterlace,ReadString(SectionName,'Deinterlace',''));
    Unmap(AspectMap,Core.Aspect,ReadString(SectionName,'Aspect',''));
    Core.ReIndex:=ReadBool(SectionName,'ReIndex',Core.ReIndex);
    Core.SoftVol:=ReadBool(SectionName,'SoftVol',Core.SoftVol);
    Core.PriorityBoost:=ReadBool(SectionName,'PriorityBoost',Core.PriorityBoost);
    Core.Params:=ReadString(SectionName,'Params',Core.Params);
    Core.AutoPlay:=ReadBool(SectionName,'AutoPlay',Core.AutoPlay);
    MainForm.WantFullscreen:=ReadBool(SectionName,'Fullscreen',MainForm.WantFullscreen);
    MainForm.AutoQuit:=ReadBool(SectionName,'AutoQuit',MainForm.AutoQuit);
    Free;
  end;
end;

procedure Save(const FileName:string);
var INI:TINIFile;
begin
  try INI:=TINIFile.Create(FileName); except exit; end;
  with INI do try
  finally
    WriteInteger(SectionName,'Locale',DefaultLocale);
    WriteString(SectionName,'AudioOut',AudioOutMap[Core.AudioOut]);
    WriteInteger(SectionName,'AudioDev',Core.AudioDev);
    WriteString(SectionName,'Postproc',PostprocMap[Core.Postproc]);
    WriteString(SectionName,'Deinterlace',DeinterlaceMap[Core.Deinterlace]);
    WriteString(SectionName,'Aspect',AspectMap[Core.Aspect]);
    WriteBool  (SectionName,'ReIndex',Core.ReIndex);
    WriteBool  (SectionName,'SoftVol',Core.SoftVol);
    WriteBool  (SectionName,'PriorityBoost',Core.PriorityBoost);
    WriteString(SectionName,'Params',Core.Params);
    Free;
  end;
end;

end.
