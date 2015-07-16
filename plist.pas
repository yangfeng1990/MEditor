unit plist;

interface
{$WARN SYMBOL_PLATFORM OFF}

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ShellAPI;

type TPlaybackState=(psNotPlayed,psPlaying,psPlayed,psSkipped);
     TPlaylistEntry=record
                      State:TPlaybackState;
                      Selected:boolean;
                      FullURL:string;
                      DisplayURL:string;
                    end;

type TPlaylist=class
               private
                 Data:array of TPlaylistEntry;
                 function GetCount:integer;
                 function GetItem(Index:integer):TPlaylistEntry;
                 function GetSelected(Index:integer):boolean;
                 procedure SetSelected(Index:integer; Value:boolean);
               public
                 Shuffle,Loop:boolean;
                 procedure Clear;
                 function Add(const Entry:TPlaylistEntry):integer; overload;
                 function Add(const URL:string):integer; overload;
                 function AddM3U(const FileName:string):boolean;
                 procedure AddDirectory(Directory:string);
                 property Count:integer read GetCount;
                 property Items[Index:integer]:TPlaylistEntry read GetItem; default;
                 property Selected[Index:integer]:boolean read GetSelected write SetSelected;
                 function GetNext(ExitState:TPlaybackState; Direction:integer):integer;
                 function GetCurrent:integer;
                 procedure NowPlaying(Index:integer);
                 procedure Changed;
                 procedure MoveSelectedUp;
                 procedure MoveSelectedDown;
                 procedure SaveToFile(const FileName:string);
               end;

type
  TPlaylistForm = class(TForm)
    PlaylistBox: TListBox;
    BPlay: TBitBtn;
    BAdd: TBitBtn;
    BMoveUp: TBitBtn;
    BMoveDown: TBitBtn;
    BDelete: TBitBtn;
    BClose: TBitBtn;
    CShuffle: TCheckBox;
    CLoop: TCheckBox;
    BSave: TBitBtn;
    SavePlaylistDialog: TSaveDialog;
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure PlaylistBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormCreate(Sender: TObject);
    procedure BPlayClick(Sender: TObject);
    procedure BCloseClick(Sender: TObject);
    procedure BDeleteClick(Sender: TObject);
    procedure BAddClick(Sender: TObject);
    procedure BMoveClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure CShuffleClick(Sender: TObject);
    procedure CLoopClick(Sender: TObject);
    procedure BSaveClick(Sender: TObject);
  private
    { Private declarations }
    BMPpsPlaying,BMPpsPlayed,BMPpsSkipped:TBitmap;
    procedure FormDropFiles(var msg:TMessage); message WM_DROPFILES;
    procedure FormMove(var msg:TMessage); message WM_MOVE;
  public
    { Public declarations }
    ControlledMove:boolean;
  end;

var
  PlaylistForm: TPlaylistForm;
  Playlist: TPlaylist;
  Docked:boolean;

implementation

uses Main, Core, URL;

{$R *.dfm}
{$R plist_img.res}

function LoadBitmapResource(const ResName:string; Transparent:boolean):TBitmap;
begin
  Result:=TBitmap.Create;
  Result.LoadFromResourceName(HInstance,ResName);
  if Transparent then begin
    Result.Transparent:=true;
    Result.TransparentMode:=tmAuto;
  end;
end;

procedure TPlaylist.Clear;
begin
  SetLength(Data,0);
end;

function TPlaylist.Add(const Entry:TPlaylistEntry):integer;
begin
  Result:=length(Data);
  SetLength(Data,Result+1);
  Data[Result]:=Entry;
  Changed;
end;

function TPlaylist.Add(const URL:string):integer;
var Entry:TPlaylistEntry;
begin
  // check for directory
  if DirectoryExists(URL) then begin
    AddDirectory(URL);
    Result:=High(Data);
    exit;
  end;
  // check for .m3u playlist file
  if (LowerCase(ExtractFileExt(URL))='.m3u') AND AddM3U(URL) then begin
    Result:=High(Data);
    exit;
  end;
  // no playlist -> enter directly
  with Entry do begin
    State:=psNotPlayed;
    FullURL:=URL;
    MakeURL(URL, DisplayURL);
  end;
  Result:=Add(Entry);
end;

function TPlaylist.GetCount:integer;
begin
  Result:=length(Data);
end;

function TPlaylist.GetItem(Index:integer):TPlaylistEntry;
begin
  if (Index<Low(Data)) OR (Index>High(Data))
    then raise ERangeError.Create('invalid playlist item')
    else Result:=Data[Index];
end;

function TPlaylist.GetSelected(Index:integer):boolean;
begin
  if (Index<Low(Data)) OR (Index>High(Data))
    then raise ERangeError.Create('invalid playlist item')
    else Result:=Data[Index].Selected;
end;

procedure TPlaylist.SetSelected(Index:integer; Value:boolean);
begin
  if (Index<Low(Data)) OR (Index>High(Data))
    then raise ERangeError.Create('invalid playlist item')
    else Data[Index].Selected:=Value;
end;

function TPlaylist.GetCurrent:integer;
var i:integer;
begin
  Result:=-1;
  for i:=Low(Data) to High(Data) do
    if Data[i].State=psPlaying then begin
      Result:=i;
      exit;
    end;
end;

function TPlaylist.GetNext(ExitState:TPlaybackState; Direction:integer):integer;
var i,Count:integer;
begin
  Result:=GetCurrent;
  // mark current track as played
  if Result<0 then Result:=0
              else Data[Result].State:=ExitState;
  if Shuffle then begin
    // ***** SHUFFLE MODE *****
    if Loop then
      Result:=Random(length(Data))
    else begin
      // unplayed tracks left?
      Count:=0;
      for i:=Low(Data) to High(Data) do
        if Data[i].State=psNotPlayed then
          inc(Count);
      // find a track
      if Count=0 then
        Result:=-1
      else repeat
        Result:=Random(length(Data));
      until Data[Result].State=psNotPlayed;
    end;
  end else begin
    // ***** NORMAL MODE *****
    inc(Result,Direction);
    if Result>High(Data) then begin
      if Loop then Result:=Low(Data)
              else Result:=-1;
    end;
    if Result<Low(Data) then begin
      if Loop then Result:=High(Data)
              else Result:=-1;
    end;
  end;
  Changed;
end;

procedure TPlaylist.NowPlaying(Index:integer);
begin
  if (Index<Low(Data)) OR (Index>High(Data)) then exit;
  Data[Index].State:=psPlaying;
  Changed;
  PlaylistForm.PlaylistBox.ItemIndex:=Index;
end;

procedure TPlaylist.Changed;
var PLI:integer;
begin
  if not PlaylistForm.Visible then exit;
  if PlaylistForm.PlaylistBox.Count<>Count then
    PlaylistForm.PlaylistBox.Count:=Count;
  PlaylistForm.PlaylistBox.Invalidate;
  if (Count=0) AND not(Core.Running) then MainForm.BPlay.Enabled:=false;
  PLI:=GetCurrent;
  MainForm.BPrev.Enabled:=(PLI>0);
  MainForm.BNext.Enabled:=(PLI+1<Playlist.Count);
end;

procedure TPlaylist.MoveSelectedUp;
var i:integer; temp:TPlaylistEntry;
begin
  for i:=1 to High(Data) do
    if Data[i].Selected AND not(Data[i-1].Selected) then begin
      temp:=Data[i];
      Data[i]:=Data[i-1];
      Data[i-1]:=temp;
    end;
  Changed;
end;

procedure TPlaylist.MoveSelectedDown;
var i:integer; temp:TPlaylistEntry;
begin
  for i:=(High(Data)-1) downto 0 do
    if Data[i].Selected AND not(Data[i+1].Selected) then begin
      temp:=Data[i];
      Data[i]:=Data[i+1];
      Data[i+1]:=temp;
    end;
  Changed;
end;

procedure TPlaylist.SaveToFile(const FileName:string);
var t:System.Text; i:integer;
begin
  Assign(t,FileName);
  {$I-} Rewrite(t); {$I+}
  if IOresult<>0 then exit;
  for i:=Low(Data) to High(Data) do
    writeln(t,Data[i].FullURL);
  CloseFile(t);
end;



function TryOpen(const FileName:string; var t:System.Text):boolean;
var OFM:byte;
begin
  Result:=False;
  OFM:=FileMode; FileMode:=0;
  {$I-} AssignFile(t,FileName); Reset(t); {$I+}
  if IOResult<>0 then exit;
  FileMode:=OFM;
  Result:=True;
end;

function ExpandName(const BasePath, FileName:string):string;
begin
  Result:=FileName;
  if Pos(':',FileName)>0 then exit;
  if (length(FileName)>1) AND ((FileName[1]='/') OR (FileName[1]='\')) then exit;
  Result:=ExpandUNCFileName(BasePath+FileName);
end;

function TPlaylist.AddM3U(const FileName:string):boolean;
var t:System.Text; BasePath,s:string;
begin
  Result:=TryOpen(FileName, t);
  if not Result then exit;
  BasePath:=IncludeTrailingPathDelimiter(ExtractFilePath(FileName));
  while not EOF(t) do begin
    Readln(t,s);
    if length(s)<1 then continue;
    if s[1]='#' then continue;
    Add(ExpandName(BasePath,s));
  end;
  CloseFile(t);
  Result:=True;
end;

procedure TPlaylist.AddDirectory(Directory:string);
var SR:TSearchRec; Cont:integer;
    Files,Directories:TStringList;
    i:integer;
    Entry:TPlaylistEntry;
begin
  Directory:=ExcludeTrailingPathDelimiter(ExpandUNCFileName(Directory));
  // check for DVD directory
  if (UpperCase(ExtractFileName(Directory))='VIDEO_TS')
  OR (DirectoryExists(Directory+'\VIDEO_TS'))
  then begin
    // if it's a DVD, pass is directly to the URL builder
    with Entry do begin
      State:=psNotPlayed;
      FullURL:=Directory;
      MakeURL(Directory, DisplayURL);
    end;
    Add(Entry);
    exit;
  end;
  // no DVD -> search the directory recursively
  Files:=TStringList.Create;
  Files.CaseSensitive:=True;
  Directories:=TStringList.Create;
  Directories.CaseSensitive:=True;
  // build lists
  Cont:=FindFirst(Directory+'\*.*',faAnyFile,SR);
  while Cont=0 do begin
    // exclude POSIXly or Win32ly hidden files
    if (SR.Name[1]<>'.') AND ((SR.Attr AND faHidden)=0) then begin
      if ((SR.Attr AND faDirectory)<>0) then
        Directories.Add(SR.Name)
      else if GetExtension(SR.Name)>0 then
        Files.Add(SR.Name);
    end;
    Cont:=FindNext(SR);
  end;
  FindClose(SR);
  // add directories
  Directories.Sort;
  for i:=0 to Directories.Count-1 do
    AddDirectory(Directory+'\'+Directories[i]);
  Directories.Free;
  // add files
  Files.Sort;
  for i:=0 to Files.Count-1 do
    Add(Directory+'\'+Files[i]);
  Files.Free;
end;



procedure TPlaylistForm.FormCreate(Sender: TObject);
begin
  BMPpsPlaying:=LoadBitmapResource('PS_PLAYING',true);
  BMPpsPlayed :=LoadBitmapResource('PS_PLAYED' ,true);
  BMPpsSkipped:=LoadBitmapResource('PS_SKIPPED',true);
  ControlledMove:=true;
  Docked:=True;
end;

procedure TPlaylistForm.FormShow(Sender: TObject);
begin
  PlaylistBox.Count:=Playlist.Count;
  DragAcceptFiles(Handle,true);
  MainForm.MShowPlaylist.Checked:=true;
  MainForm.BPlaylist.Down:=true;
end;

procedure TPlaylistForm.FormHide(Sender: TObject);
begin
  DragAcceptFiles(Handle,false);
  MainForm.MShowPlaylist.Checked:=false;
  MainForm.BPlaylist.Down:=false;
end;

procedure TPlaylistForm.PlaylistBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
begin with PlaylistBox.Canvas do begin
  FillRect(Rect);
  if (Index<0) OR (Index>=Playlist.Count) then exit;
  with Playlist[Index] do begin
    case State of
      psPlaying:Draw(Rect.Left+3,Rect.Top+1,BMPpsPlaying);
      psPlayed :Draw(Rect.Left+3,Rect.Top+1,BMPpsPlayed);
      psSkipped:Draw(Rect.Left+3,Rect.Top+1,BMPpsSkipped);
    end;
    TextOut(Rect.Left+16,Rect.Top+1,DisplayURL);
  end;
end; end;

procedure TPlaylistForm.BPlayClick(Sender: TObject);
var Index:integer;
begin
  Index:=PlaylistBox.ItemIndex;
  if (Index<0) OR (Index>=Playlist.Count) then exit;
  Core.ForceStop;
  Playlist.GetNext(psSkipped,0);
  Playlist.NowPlaying(Index);
  MainForm.DoOpen(Playlist[Index].FullURL);
end;

procedure TPlaylistForm.BCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TPlaylistForm.BDeleteClick(Sender: TObject);
var iOld,iNew:integer;
begin
  with Playlist do begin
    iNew:=0;
    for iOld:=0 to High(Data) do
      if not PlaylistBox.Selected[iOld] then begin
        if iNew<iOld then Data[iNew]:=Data[iOld];
        inc(iNew);
      end;
    SetLength(Data,iNew);
    Changed;
  end;
end;

procedure TPlaylistForm.BAddClick(Sender: TObject);
var i:integer;
begin
  with MainForm.OpenDialog do begin
    Options:=Options+[ofAllowMultiSelect];
    if Execute then
      for i:=0 to Files.Count-1 do
        Playlist.Add(Files[i]);
  end;
end;

procedure TPlaylistForm.FormDropFiles(var msg:TMessage);
var hDrop:THandle;
    i,DropCount:integer;
    fnbuf:array[0..1024]of char;
begin
  hDrop:=msg.wParam;
  DropCount:=DragQueryFile(hDrop,cardinal(-1),nil,0);
  for i:=0 to DropCount-1 do begin
    DragQueryFile(hDrop,i,@fnbuf[0],1024);
    Playlist.Add(fnbuf);
    MainForm.BPlay.Enabled:=true;
  end;
  DragFinish(hDrop);
  msg.Result:=0;
end;

procedure TPlaylistForm.BMoveClick(Sender: TObject);
var i:integer;
begin
  for i:=0 to (Playlist.Count-1) do
    Playlist.Selected[i]:=PlaylistBox.Selected[i];
  if (Sender as TComponent).Tag=1
    then Playlist.MoveSelectedUp
    else Playlist.MoveSelectedDown;
  for i:=0 to (Playlist.Count-1) do
    PlaylistBox.Selected[i]:=Playlist.Selected[i];
  PlaylistBox.Invalidate;
end;

procedure TPlaylistForm.FormDestroy(Sender: TObject);
begin
  Docked:=False;
end;

procedure TPlaylistForm.FormMove(var msg:TMessage);
begin
  msg.Result:=0;
  if ControlledMove then ControlledMove:=False else Docked:=False;
end;

procedure TPlaylistForm.FormDblClick(Sender: TObject);
begin
  Docked:=True; MainForm.UpdateDockedWindows;
end;

procedure TPlaylistForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if upcase(Key)='L' then Hide;
end;

procedure TPlaylistForm.CShuffleClick(Sender: TObject);
begin
  Playlist.Shuffle:=CShuffle.Checked;
end;

procedure TPlaylistForm.CLoopClick(Sender: TObject);
begin
  Playlist.Loop:=CLoop.Checked;
end;

procedure TPlaylistForm.BSaveClick(Sender: TObject);
begin
  if SavePlaylistDialog.Execute then
    Playlist.SaveToFile(SavePlaylistDialog.FileName);
end;

initialization
  Playlist:=TPlaylist.Create;
finalization
  Playlist.Free;
end.
