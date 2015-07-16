object MergeFrm: TMergeFrm
  Left = 453
  Top = 228
  Width = 552
  Height = 319
  Caption = 'MergeFrm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object rzprgrsbrMerge1: TRzProgressBar
    Left = 88
    Top = 128
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object rzprgrsbrMerge2: TRzProgressBar
    Left = 96
    Top = 160
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object rzprgrsbrMerge3: TRzProgressBar
    Left = 104
    Top = 200
    BorderWidth = 0
    InteriorOffset = 0
    PartsComplete = 0
    Percent = 0
    TotalParts = 0
  end
  object lbl1: TLabel
    Left = 384
    Top = 120
    Width = 57
    Height = 19
    Caption = #23436#25104
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object edt1: TEdit
    Left = 72
    Top = 40
    Width = 233
    Height = 21
    TabOrder = 0
    Text = 'edt1'
  end
  object edt2: TEdit
    Left = 72
    Top = 88
    Width = 233
    Height = 21
    TabOrder = 1
    Text = 'edt2'
  end
  object btnMerge: TButton
    Left = 96
    Top = 248
    Width = 75
    Height = 25
    Caption = 'btnMerge'
    TabOrder = 2
    OnClick = btnMergeClick
  end
end
