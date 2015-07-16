object PlaylistForm: TPlaylistForm
  Left = 492
  Top = 112
  AutoScroll = False
  BorderIcons = [biSystemMenu]
  Caption = 'PlaylistForm'
  ClientHeight = 261
  ClientWidth = 370
  Color = clBtnFace
  Constraints.MinHeight = 215
  Constraints.MinWidth = 348
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  Position = poDefaultPosOnly
  OnCreate = FormCreate
  OnDblClick = FormDblClick
  OnDestroy = FormDestroy
  OnHide = FormHide
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  DesignSize = (
    370
    261)
  PixelsPerInch = 96
  TextHeight = 13
  object PlaylistBox: TListBox
    Left = 4
    Top = 4
    Width = 266
    Height = 253
    Style = lbVirtualOwnerDraw
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 16
    MultiSelect = True
    TabOrder = 0
    OnDblClick = BPlayClick
    OnDrawItem = PlaylistBoxDrawItem
  end
  object BPlay: TBitBtn
    Left = 277
    Top = 4
    Width = 89
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Play'
    TabOrder = 1
    OnClick = BPlayClick
  end
  object BAdd: TBitBtn
    Left = 277
    Top = 36
    Width = 89
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Add'
    TabOrder = 2
    OnClick = BAddClick
  end
  object BMoveUp: TBitBtn
    Tag = 1
    Left = 277
    Top = 68
    Width = 89
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Move up'
    TabOrder = 3
    OnClick = BMoveClick
  end
  object BMoveDown: TBitBtn
    Left = 277
    Top = 96
    Width = 89
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Move down'
    TabOrder = 4
    OnClick = BMoveClick
  end
  object BDelete: TBitBtn
    Left = 277
    Top = 128
    Width = 89
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Delete'
    TabOrder = 5
    OnClick = BDeleteClick
  end
  object BClose: TBitBtn
    Left = 277
    Top = 232
    Width = 89
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    TabOrder = 9
    OnClick = BCloseClick
  end
  object CShuffle: TCheckBox
    Left = 277
    Top = 160
    Width = 87
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'Shuffle'
    TabOrder = 6
    OnClick = CShuffleClick
  end
  object CLoop: TCheckBox
    Left = 277
    Top = 180
    Width = 87
    Height = 17
    Anchors = [akTop, akRight]
    Caption = 'Repeat'
    TabOrder = 7
    OnClick = CLoopClick
  end
  object BSave: TBitBtn
    Left = 277
    Top = 201
    Width = 89
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Save'
    TabOrder = 8
    OnClick = BSaveClick
  end
  object SavePlaylistDialog: TSaveDialog
    DefaultExt = 'm3u'
    Filter = 'M3U Playlist (*.m3u)|*.m3u|All Files (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = 'Save Playlist ...'
    Left = 336
    Top = 200
  end
end
