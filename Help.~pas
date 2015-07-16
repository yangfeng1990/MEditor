unit Help;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  THelpForm = class(TForm)
    HelpText: TMemo;
    BClose: TButton;
    RefLabel: TLabel;
    procedure BCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Format;
  end;

var
  HelpForm: THelpForm;

implementation

{$R *.dfm}

procedure THelpForm.BCloseClick(Sender: TObject);
begin
  Close;
end;

procedure THelpForm.Format;
var NeededHeight:integer;
begin
  NeededHeight:=RefLabel.Height*HelpText.Lines.Count;
  Height:=Height-HelpText.Height+NeededHeight;
end;

end.
