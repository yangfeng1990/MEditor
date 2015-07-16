object InfoForm: TInfoForm
  Left = 606
  Top = 117
  ActiveControl = BClose
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = 'InfoForm'
  ClientHeight = 296
  ClientWidth = 300
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnCreate = FormCreate
  OnDblClick = FormDblClick
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnShow = FormShow
  DesignSize = (
    300
    296)
  PixelsPerInch = 96
  TextHeight = 13
  object InfoBox: TListBox
    Left = 4
    Top = 4
    Width = 292
    Height = 258
    Style = lbOwnerDrawFixed
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 16
    TabOrder = 0
    OnDrawItem = InfoBoxDrawItem
  end
  object BClose: TButton
    Left = 221
    Top = 267
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    Default = True
    TabOrder = 1
    OnClick = BCloseClick
  end
end
