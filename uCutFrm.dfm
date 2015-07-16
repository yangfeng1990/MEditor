object CutFrm: TCutFrm
  Left = 457
  Top = 246
  Width = 458
  Height = 248
  Caption = #32534#36753
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = #24494#36719#38597#40657
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 16
  object rzprgrsbr2: TRzProgressBar
    Left = 125
    Top = 115
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object rzprgrsbr3: TRzProgressBar
    Left = 125
    Top = 115
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object lblCutTip: TLabel
    Left = 122
    Top = 90
    Width = 204
    Height = 19
    Caption = #27491#22312#36716#25442#32534#30721#65292#33719#21462#31934#30830#35009#21098#26102#38388'...'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl1: TLabel
    Left = 12
    Top = 48
    Width = 65
    Height = 19
    Caption = #36755#20986#25991#20214#65306
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lblCutTip1: TLabel
    Left = 160
    Top = 90
    Width = 139
    Height = 19
    Caption = #27491#22312#35009#21098#35270#39057#65292#35831#31245#21518'...'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lblComp: TLabel
    Left = 360
    Top = 118
    Width = 26
    Height = 19
    Caption = #23436#25104
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object rzprgrsbrMergecut1: TRzProgressBar
    Left = 125
    Top = 115
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object rzprgrsbrMergecut2: TRzProgressBar
    Left = 125
    Top = 115
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object rzprgrsbrMergecut3: TRzProgressBar
    Left = 125
    Top = 115
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object rzprgrsbrMergecut4: TRzProgressBar
    Left = 125
    Top = 115
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object rzprgrsbrMergecut5: TRzProgressBar
    Left = 125
    Top = 115
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object edtSaveFilePath: TEdit
    Left = 86
    Top = 47
    Width = 278
    Height = 24
    TabOrder = 1
  end
  object btnConvert: TRzBmpButton
    Left = 129
    Top = 157
    Bitmaps.TransparentColor = clOlive
    Color = clBtnFace
    Caption = #35009#21098
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = btnCutClick
  end
  object btnCancel: TRzBmpButton
    Left = 353
    Top = 157
    Bitmaps.TransparentColor = clOlive
    Color = clBtnFace
    Caption = #20851#38381
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = btnCancelClick
  end
  object btnSelSrc: TRzBmpButton
    Left = 381
    Top = 43
    Width = 50
    Bitmaps.TransparentColor = clOlive
    Color = clBtnFace
    Caption = #36873#25321
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = btnSelSrcClick
  end
  object btnTransEncoding: TRzBmpButton
    Left = 17
    Top = 157
    Bitmaps.TransparentColor = clOlive
    Color = clBtnFace
    Caption = #36716#30721
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = btnTransEncodingClick
  end
  object btnMerger: TRzBmpButton
    Left = 241
    Top = 157
    Bitmaps.TransparentColor = clOlive
    Color = clBtnFace
    Caption = #21512#24182
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = btnMergerClick
  end
  object dlgSaveCutDest: TSaveDialog
    Filter = 
      '.mp4'#25991#20214'|*.mp4;|.avi'#25991#20214'|*.avi;|.flv'#25991#20214'|*.flv;|.mpg'#25991#20214'|*.mpg;|.mov'#25991#20214'|*' +
      '.mov;'
    Left = 384
    Top = 8
  end
end
