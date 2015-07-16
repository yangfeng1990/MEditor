object AboutForm: TAboutForm
  Left = 480
  Top = 107
  ActiveControl = BClose
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'AboutForm'
  ClientHeight = 393
  ClientWidth = 350
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    350
    393)
  PixelsPerInch = 96
  TextHeight = 13
  object VersionMPUI: TLabel
    Left = 148
    Top = 74
    Width = 60
    Height = 13
    Caption = 'VersionMPUI'
  end
  object VersionMPlayer: TLabel
    Left = 148
    Top = 104
    Width = 73
    Height = 13
    Caption = 'VersionMPlayer'
  end
  object LVersionMPlayer: TLabel
    Left = 148
    Top = 90
    Width = 91
    Height = 13
    Caption = 'MPlayer version'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LVersionMPUI: TLabel
    Left = 148
    Top = 60
    Width = 75
    Height = 13
    Caption = 'MPUI version'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LURL: TLabel
    Left = 6
    Top = 128
    Width = 136
    Height = 13
    Cursor = crHandPoint
    Caption = 'http://mpui.sourceforge.net'
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsUnderline]
    ParentFont = False
    OnClick = URLClick
  end
  object PLogo: TPanel
    Left = 4
    Top = 4
    Width = 140
    Height = 120
    BevelOuter = bvNone
    BorderStyle = bsSingle
    Color = clBlack
    TabOrder = 0
    object ILogo: TImage
      Left = 9
      Top = 9
      Width = 120
      Height = 100
    end
  end
  object BClose: TButton
    Left = 270
    Top = 363
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Close'
    Default = True
    TabOrder = 3
    OnClick = BCloseClick
  end
  object MCredits: TMemo
    Left = 3
    Top = 144
    Width = 343
    Height = 214
    Cursor = crArrow
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelInner = bvNone
    BevelOuter = bvNone
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Lines.Strings = (
      'This is free software, licensed under the terms of the'
      'GNU General Public License, Version 2.'
      ''
      '(C) 2005 Martin J. Fiedler <martin.fiedler@gmx.net>'
      ''
      'Code contributions and hints:'
      'Joackim Pennerup <joackim@pennerup.net>'
      'Vasily Khoruzhick <fenix-fen@mail.ru>'
      'Maxim Usov <UsovMV@kms.cctpu.edu.ru>'
      'Peter Pinter <pinterpeti@gmail.com>'
      ''
      'Contibuted translations:'
      'Danish by Jens Kikkenborg <flanke@gmail.com>'
      'Dutch by Michal Sindlar <sindlar@gmail.com>'
      'French by Francois Gagne <frenchfrog@gmail.com>'
      'Italian by Andres Zanzani <azanzani@gmail.com>'
      'Spanish by Alex Fu <alexfu@nerdshack.com>'
      'Portuguese by Carlos Silvestre <cags69@portugalmail.pt>'
      'Esperanto by Kristjan Schmidt <Kristjan@yandex.ru>'
      'Romanian by Florin Valcu <florin.valcu@gmail.com>'
      'Hungarian by MrG <mrguba@gmail.com>'
      'Polish by Pawel Wieczorek <platon@radio.ujscie.com>'
      'Czech by Antonin Fujera <fujera@seznam.cz>'
      'Slovak by Peter Habcak <p.habcak@zoznam.sk>'
      'Belarusian and Russian by Vasily Khoruzhick <fenix-fen@mail.ru>'
      'Ukrainian by <vadim-l@foxtrot.kiev.ua>'
      '                     and Andriy Zhouck <juksoft@ukr.net>'
      'Bulgarian by Boyan Boychev <boyan7640@gmail.com>'
      'Simplified Chinese by Tommy He <lovenemesis@163.com>'
      'Traditional Chinese by Kene Lin <kenelin@gmail.com>'
      'Korean by Ken Jun <dalbaragi@gmail.com>'
      'Japanese by Masayuki Mogi <mogmog9@gmail.com>'
      'Arabic by Mohamed Magdy <alnokta@yahoo.com>')
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 2
    WordWrap = False
    OnEnter = ReadOnlyItemEnter
  end
  object MTitle: TMemo
    Left = 146
    Top = 4
    Width = 204
    Height = 49
    Cursor = crArrow
    Anchors = [akLeft, akTop, akRight]
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Verdana'
    Font.Style = [fsBold]
    Lines.Strings = (
      'MTitle')
    ParentColor = True
    ParentFont = False
    ReadOnly = True
    TabOrder = 1
    WantReturns = False
    OnEnter = ReadOnlyItemEnter
  end
end
