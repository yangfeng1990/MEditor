object LogForm: TLogForm
  Left = 708
  Top = 118
  Width = 550
  Height = 440
  ActiveControl = Command
  Caption = #26085#24535
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object TheLog: TMemo
    Left = 0
    Top = 0
    Width = 542
    Height = 381
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Lucida Console'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    WordWrap = False
  end
  object ControlPanel: TPanel
    Left = 0
    Top = 381
    Width = 542
    Height = 25
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      542
      25)
    object BClose: TButton
      Left = 480
      Top = 4
      Width = 62
      Height = 21
      Anchors = [akTop, akRight]
      Caption = 'Close'
      TabOrder = 1
      OnClick = BCloseClick
    end
    object Command: TEdit
      Left = 0
      Top = 4
      Width = 477
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnKeyDown = CommandKeyDown
      OnKeyPress = CommandKeyPress
    end
  end
end
