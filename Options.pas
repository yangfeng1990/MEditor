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
unit Options;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI;

type PDSEnumCallback=function(lpGuid:PGUID; lpcstrDescription,lpcstrModule:PChar; lpContext:pointer):LongBool; stdcall;
function DirectSoundEnumerate(lpDSEnumCallback:PDSEnumCallback; lpContext:pointer):HRESULT;
         stdcall; external 'dsound.dll' name 'DirectSoundEnumerateA';

type
  TOptionsForm = class(TForm)
    LAudioOut: TLabel;
    BOK: TButton;
    BApply: TButton;
    BSave: TButton;
    BClose: TButton;
    CAudioOut: TComboBox;
    LPostproc: TLabel;
    CPostproc: TComboBox;
    LAspect: TLabel;
    CAspect: TComboBox;
    LDeinterlace: TLabel;
    CDeinterlace: TComboBox;
    CIndex: TCheckBox;
    EParams: TEdit;
    LParams: TLabel;
    LHelp: TLabel;
    LLanguage: TLabel;
    CLanguage: TComboBox;
    LAudioDev: TLabel;
    CAudioDev: TComboBox;
    CSoftVol: TCheckBox;
    CPriorityBoost: TCheckBox;
    procedure BCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LHelpClick(Sender: TObject);
    procedure BApplyClick(Sender: TObject);
    procedure BOKClick(Sender: TObject);
    procedure SomethingChanged(Sender: TObject);
    procedure BSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CAudioOutChange(Sender: TObject);
  private
    { Private declarations }
    HelpFile:string;
  public
    { Public declarations }
    Changed:boolean;
    procedure Localize;
    procedure ApplyValues;
    procedure LoadValues;
  end;

var
  OptionsForm: TOptionsForm;

implementation
uses Core, Config, Main, Locale;

{$R *.dfm}

procedure TOptionsForm.BCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TOptionsForm.Localize;
var i:integer;
begin with MainForm do begin
  LAspect.Caption:=MAspect.Caption;
  CAspect.Items[0]:=MAutoAspect.Caption;
  LDeinterlace.Caption:=MDeinterlace.Caption;
  CDeinterlace.Items[0]:=MNoDeint.Caption;
  CDeinterlace.Items[1]:=MSimpleDeint.Caption;
  CDeinterlace.Items[2]:=MAdaptiveDeint.Caption;
  LLanguage.Caption:=MLanguage.Caption;
  CLanguage.Clear;
  CLanguage.Items.Add(LOCstr_AutoLocale);
  for i:=0 to High(Locales) do
    CLanguage.Items.Add(Locales[i].Name);
end; end;

procedure TOptionsForm.FormShow(Sender: TObject);
begin
  LoadValues;
  Changed:=false;

  HelpFile:=HomeDir+'man_page.html';
  if not FileExists(HelpFile) then begin
    HelpFile:=HomeDir+'MPlayer.html';
    if not FileExists(HelpFile) then
      HelpFile:='';
  end;
  if length(HelpFile)>0 then begin
    LHelp.Visible:=true;
    HelpFile:=#34+HelpFile+#34;
  end else
    LHelp.Visible:=false;
end;

procedure TOptionsForm.LHelpClick(Sender: TObject);
begin
  if length(HelpFile)>0 then
    ShellExecute(Handle,'open',PChar(HelpFile),nil,nil,SW_SHOW);
end;

procedure TOptionsForm.LoadValues;
begin
  CAudioOut.ItemIndex:=Core.AudioOut;
  CAudioDev.ItemIndex:=Core.AudioDev;
  CPostproc.ItemIndex:=Core.Postproc;
  CAspect.ItemIndex:=Core.Aspect;
  CDeinterlace.ItemIndex:=Core.Deinterlace;
  CLanguage.ItemIndex:=DefaultLocale+1;
  CIndex.Checked:=Core.ReIndex;
  CSoftVol.Checked:=Core.SoftVol;
  CPriorityBoost.Checked:=Core.PriorityBoost;
  EParams.Text:=Core.Params;
  CAudioOutChange(nil);
end;

procedure TOptionsForm.ApplyValues;
begin
  Core.AudioOut:=CAudioOut.ItemIndex;
  Core.AudioDev:=CAudioDev.ItemIndex;
  Core.Postproc:=CPostproc.ItemIndex;
  Core.Aspect:=CAspect.ItemIndex;
  Core.Deinterlace:=CDeinterlace.ItemIndex;
  Core.ReIndex:=CIndex.Checked;
  Core.SoftVol:=CSoftVol.Checked;
  Core.PriorityBoost:=CPriorityBoost.Checked;
  Core.Params:=Trim(EParams.Text);
  DefaultLocale:=CLanguage.ItemIndex-1;
  ActivateLocale(DefaultLocale);
end;

procedure TOptionsForm.BApplyClick(Sender: TObject);
begin
  ApplyValues;
  Core.Restart;
  LoadValues;
end;

procedure TOptionsForm.BOKClick(Sender: TObject);
begin
  if Changed then begin
    ApplyValues;
    Core.Restart;
  end;
  Close;
end;

procedure TOptionsForm.SomethingChanged(Sender: TObject);
begin
  Changed:=true;
end;

procedure TOptionsForm.BSaveClick(Sender: TObject);
begin
  ApplyValues;
  Config.Save(HomeDir+Config.DefaultFileName);
  LoadValues;
end;

function EnumFunc(lpGuid:PGUID; lpcstrDescription,lpcstrModule:PChar; lpContext:pointer):LongBool; stdcall;
begin
  TComboBox(lpContext^).Items.Add(lpcstrDescription);
  Result:=True;
end;

procedure TOptionsForm.FormCreate(Sender: TObject);
begin
  DirectSoundEnumerate(EnumFunc,@CAudioDev);
end;

procedure TOptionsForm.CAudioOutChange(Sender: TObject);
var e:boolean;
begin
  e:=(CAudioOut.ItemIndex=3);
  LAudioDev.Enabled:=e;
  CAudioDev.Enabled:=e;
  if Assigned(Sender) then SomethingChanged(Sender);
end;

end.
