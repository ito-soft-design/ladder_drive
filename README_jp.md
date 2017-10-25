# LadderDrive

## 概要

LadderDriveはPLC(Programmable Logic Controller)向けの抽象的なラダーです。
どのPLCでも同じソース(できればバイナリー)で実行できる形態を目指しています。

まずはニーモニックレベルで実現し、その上に分かりやすい形のプログラミングツールを用意できればと考えています。

## 使い方

使用するにはRubyが実行できる環境が必要です。
Rubyの実行環境の構築はWebサイト等を検索して構築してください。

### インストール

gemでLadderDriveをインストールします。

```sh
$ gem install ladder_drive
```

[![https://gyazo.com/6f00d74612def41fb33d836275b74c24](https://i.gyazo.com/6f00d74612def41fb33d836275b74c24.gif)](https://gyazo.com/6f00d74612def41fb33d836275b74c24)

### プロジェクト作成

LadderDriveをインストールするとladder_driveコマンドが使用できる様になります。
ladder_driveコマンドでラダーを構成するプロジェクトファイルを作ります。

```sh
$ ladder_drive create my_project
$ cd my_project
```

[![https://gyazo.com/c538f66129aa425e2b1da4f478a10f52](https://i.gyazo.com/c538f66129aa425e2b1da4f478a10f52.gif)](https://gyazo.com/c538f66129aa425e2b1da4f478a10f52)

ファイルの構成は下の様になっています。
plc以下にLadderDriveを実行するPLCプロジェクトの雛形があります。
現在はエミュレーターと三菱電機のiQ-RシリーズR08CPUのみの対応となっています。
他メーカーや他の機種は今後追加する予定です。


```
.
├── Rakefile
├── asm
│   └── main.esc
├── config
│   └── plc.yml
└── plc
    └── mitsubishi
        └── iq-r
            └── r08
                ├── LICENSE
                └── r08.gx3
```

### 通信設定

#### PLCの通信設定

plcディレクトリ以下の使用したいPLCのプロジェクトファイルを開きます。
IPアドレスなど必要な箇所を変更し、PLCに転送します。

[![](http://img.youtube.com/vi/fGdyIo9AmuE/0.jpg)](https://youtu.be/fGdyIo9AmuE)

#### LadderDriveの設定

config/plc.ymlファイルで設定します。

現在はiQ-Rのみの対応なので:host: 192.168.0.10の行でPLCに設定したIPアドレスを指定するだけで接続できます。

```
# plc.yml
plc:                        # Beginning of PLC section.
  iq-r:                     # It's a target name
    cpu: iq-r               # It's just a comment.
    protocol: mc_protocol   # It's a protocol to communicate with PLC.
    host: 192.168.0.10      # It's PLC's IP address or dns name.
    port: 5007              # It's PLC's port no.
```

[![](http://img.youtube.com/vi/m0JaOBFIHqw/0.jpg)](https://youtu.be/m0JaOBFIHqw)

### LadderDriveプログラム作成

LadderDriveのプログラムはasm以下にあります。
現在はmain.escファイルから生成します。

main.escを編集しプログラムを作成します。
PLC側の実装がまだ進んでいないので実行できるニーモニックはLD、OUT、AND、ORとその反転程度です。

ニーモニックについては[Wiki](https://github.com/ito-soft-design/ladder_drive/wiki/mnemonic)の方を参照してください。

```
# main.esc
# |M0|-|M1|----(M2)
LD  M0
AND M1
OUT M2
END
```

[![](http://img.youtube.com/vi/OjaSqrkWv8Q/0.jpg)](https://youtu.be/OjaSqrkWv8Q)

### プログラムの転送

LadderDriveプログラムをplcに転送するには```rake```コマンドを使用します。
デフォルトではエミュレーターが対象になり、エミュレーターが起動します。

```sh
$ rake
```

targetを指定するとplc.ymlのplcセクション内の該当するターゲットが対象になります。

```sh
$ rake target=iq-r
```

plc.ymlファイルのdefaultセクションのtargetでデフォルトのターゲットを設定できます。

```
# plc.yml
default:
  target: iq-r
```

この場合に```rake```を行うと```rake target=iq-r```をしたのと同じになります。


転送後プログラムが実行されます。

```sh
$ rake [target=iq-r]
uploading build/main.hex ...
launching emulator ...
done launching
done uploading

  LadderDrive is an abstract PLC.
  This is a console to communicate with PLC.

>
```

アップロードが完了するとコンソールモードになります。
コンソールモードではコマンドを打つ事でデバイスの読み書きができます。

デバイスの値を読み取るにはrコマンドを使用します。
下の例ではm0から8個分のデバイスを読み出します。

```sh
> r m0 8
```

デバイスに値を書き込むにはwコマンドを使用します。
下の例ではM0からM7まで書き込んでいます。

```sh
> w m0 0 0 0 1 1 0 1 1
```

ボタンを押した様にパルス状にデバイスをオンにするにはpコマンドを使用します。

```sh
> p m0
```

オンになる時間をデバイスのあとに指定することもできます。単位は秒です。

```sh
> p m0 1.5
```

```
# |M0|---(M1)
LD  M0
OUT M1
```

[![https://gyazo.com/565d24a35887503281a46775f6ccd747](https://i.gyazo.com/565d24a35887503281a46775f6ccd747.gif)](https://gyazo.com/565d24a35887503281a46775f6ccd747)

<!-- [![](http://img.youtube.com/vi/qGbicGLB7Gs/0.jpg)](https://youtu.be/qGbicGLB7Gs) -->

## Raspberry Pi

Raspberry Pi上で動作させることもできます。
XとYデバイスはGPIOに割り付けます。

### インストール

OSとしてRaspbianを使用した場合は次の手順でインストールできます。

```sh
$ sudo apt-get update
$ sudo apt-get install ruby-dev
$ sudo apt-get install libssl-dev
$ sudo gem install ladder_drive --no-ri --no-rdoc
```

この時の環境は下の通りです。

```
$ uname -a
Linux raspberrypi 4.9.41+ #1023 Tue Aug 8 15:47:12 BST 2017 armv6l GNU/Linux
```


### 実行

```sh
$ ladder_drive create project
$ cd project
$ sudo rake target=raspberrypi
```

### I/O設定

Project下のconfig/plc.ymlファイルで変更できます。
inputsで入力ピンを定義します。outputsで出力ピンを定義します。
pinにGPIO番号を指定します。
入力の場合は pull up, pull downの指定や invertで反転させることができます。

```
  # Raspberry Pi
  raspberrypi:
    cpu: Raspberry Pi
    io: # assign gpio to x and y
      inputs:
        x0:
          pin: 4        # gpio no
          pull: up      # up | down | off　で指定します。
          invert: true
        x1:
          pin: 17
          pull: up
          invert: true
        x2:
          pin: 27
          pull: up
          invert: true
      outputs:
        y0:
          pin: 18
        y1:
          pin: 23
        y2:
          pin: 42
```

### サービスとして Ladder Drive を起動

電源投入でLadder Driveが起動する様にサービスとして立ち上げることができます。
Ladder Driveプロジェクのディレクトリで以下のコマンドを実行することでサービスを立ち上げることができます。

```
$ sudo rake service:install
$ sudo rake service:enable
$ sudo rake service:start
```

[![LadderDrive on Raspberry Pi](http://img.youtube.com/vi/UBhSaRNp_gM/0.jpg)](http://www.youtube.com/watch?v=UBhSaRNp_gM)

## PLCデバイスへのアクセスツールとしての利用

LadderDriveはPLCデバイスの読み書きツールとしての利用もできます。
下の様にとても簡単に読み書きできます。

```
require 'ladder_drive'

plc = LadderDrive::Protocol::Mitsubishi::McProtocol.new host:"192.168.0.10"

plc["M0"] = true
plc["M0"]         # => true
plc["M0", 10]     # => [true, false, ..., false]

plc["D0"] = 123
plc["D0"]       # => 123
plc["D0", 10] = [0, 1, 2, ..., 9]
plc["D0".."D9"]   => [0, 1, 2, ..., 9]
```

## LadderDriveに関する情報

- [一往確認日記 [ladder_drive]](http://diary.itosoft.com/?category=ladder_drive)
- [Wiki](https://github.com/ito-soft-design/ladder_drive/wiki/)

## ライセンス

MIT
