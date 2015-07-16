unit URL;
interface

const PlayableExtensionCount=33;
      PlayableExtensions:array[1..PlayableExtensionCount]of string[7]=(
        'avi','mpg','vob','dat','bin','mpe','pva','mov','qt','mpeg','divx',
        'ogg','ogm','mkv','wmv','asf','mpv','m1v','m2v','dv','m4v','264',
        'wav','mp1','mp2','mp3','mpa','wma','ac3','m4a','26l','jsv','flv'
      );

function MakeURL(Query:string; var DisplayName:string):string;
//function FindPlayableFile(Path:string; MustBeSingleFile:boolean):string;
function GetExtension(FileName:string):integer;

implementation
uses SysUtils, Core, pscpLogger;


function GetExtension(FileName:string):integer;
var i:integer;
begin
  FileName:=Copy(LowerCase(ExtractFileExt(FileName)),2,7);
  Log_Info('URL GetExtension : %s', [Filename]);
  for i:=1 to PlayableExtensionCount do
    if FileName=PlayableExtensions[i] then begin
      Result:=i;
      exit;
    end;
  Result:=0
end;


function FindPlayableFile(Path:string; MustBeSingleFile:boolean):string;
var SR:TSearchRec; Cont:integer;
begin
  Result:='';
  Path:=IncludeTrailingPathDelimiter(Path);
  Cont:=FindFirst(Path+'*.*',$27,SR);
  while Cont=0 do begin
    Cont:=GetExtension(SR.Name);
    if Cont>0 then
      if MustBeSingleFile then begin
        if length(Result)=0
          then Result:=Path+SR.Name
          else begin Result:=''; break; end;
      end else begin
        Result:=Path+SR.Name;
        break;
      end;
    Cont:=FindNext(SR);
  end;
  FindClose(SR);
end;


function MakeURL(Query:string; var DisplayName:string):string;
var s:string; i:integer;
begin
  // by default, pass the URL directly to MPlayer
  Result:=EscapeParam(Query);
  // generate a display name
  i:=Pos('p:',LowerCase(Query));
  if (i>=1) AND (i<6)
    then DisplayName:=Query  // why this? well, the above two lines read like
                             // the regexp /.{1,5}p:/, which matches http:,
                             // ftp:, rtp: and so on ...
    else DisplayName:=ExtractFileName(Query);
  // someone's trying to pass an .IFO file? stupid ...
  if UpperCase(ExtractFileExt(Query))='.IFO' then
    Query:=ExtractFileDir(Query);
  // if is it a regular file, we're set
  if FileExists(Query) then exit;

  // else, it may be a directory
  Query:=ExcludeTrailingPathDelimiter(Query);
  if (length(Query)=2) AND (Query[2]=':') then Query:=Query+'\';
  if DirectoryExists(Query) then begin
    // is there a single playable file?
    s:=FindPlayableFile(Query,true);
    if length(s)>0 then begin
      Result:=EscapeParam(s);
      DisplayName:=ExtractFileName(s);
      exit;
    end;

    // is it a DVD directory?
    if UpperCase(ExtractFileName(Query))='VIDEO_TS' then
      Query:=ExtractFileDir(Query);
    if DirectoryExists(Query+'\VIDEO_TS') then begin
      Result:='-dvd-device '+EscapeParam(Query)+' dvd://';
      DisplayName:='DVD';
      exit;
    end;

    // is it a (S)VCD directory?
    if DirectoryExists(Query+'\MPEGAV') then Query:=Query+'\MPEGAV';
    if DirectoryExists(Query+'\MPEG2') then Query:=Query+'\MPEG2';
    s:=FindPlayableFile(Query,true);
    if length(s)>0 then begin
      Result:=EscapeParam(s);
      if pos('MPEG2',s)>0 then DisplayName:='SVCD' else DisplayName:='VCD';
      exit;
    end;
  end;
end;

end.
