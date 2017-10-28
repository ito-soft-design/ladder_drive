# Ladder Drive

Ladder Driveは仮想的なPLCです。
Raspberry Piで動作させるとGPIOをX、Yデバイスとして制御できます。

# Raspberry Pi編

Ladder DriveはRaspberry Pi上で実行させることができます。
ここではその手順を説明します。
詳しいインストールの仕方については、別途Raspberry Piの入門書などをご覧ください。

## Raspberry Piセットアップ

ここでは、Raspberry PiのOSとしてメジャーなRaspbianを使用します。
NOOBSというインストーラでインストールしていきます。

### SDカードの準備

[https://www.raspberrypi.org/downloads/](https://www.raspberrypi.org/downloads/)　にアクセスし、NOOBSをクリックします。

![https://gyazo.com/30be6038352d507d94b8a4e83c3f305e](https://i.gyazo.com/30be6038352d507d94b8a4e83c3f305e.png)

NOOBSのDonwload.zipをクリックしダウンロードします。

![https://gyazo.com/b814dc957234af570526410c2ce676d1](https://i.gyazo.com/b814dc957234af570526410c2ce676d1.png)

ダウンロードが完了したらzipファイルを展開します。
そのファイルを全てフオーマット済み(FAT形式)の micro SD カードにコピーします。

![https://gyazo.com/fb8ed27d51ab48172cbc9a70962cf1dc](https://i.gyazo.com/fb8ed27d51ab48172cbc9a70962cf1dc.png)


### Raspbianのインスール

micro SDカードをRaspberry Piに装着し起動します。
キーボード、マウスをUSBポートに挿入し、HDMIケーブルでモニターかテレビに接続します。
電源を繋いで起動します。

NOBSが起動します。
Raspbianを選択し、画面下の言語選択で日本語を選び、左上のインスールボタンを押します。

![https://gyazo.com/c623af14a4dda765ea4b319f1546496a](https://i.gyazo.com/c623af14a4dda765ea4b319f1546496a.png)


確認ダイアログが表示されるので、はいを押すとインストールが開始されます。

![https://gyazo.com/1d7f34ca92d72dd0466ba9ff935c07bd](https://i.gyazo.com/1d7f34ca92d72dd0466ba9ff935c07bd.png)

インストール中の画面。

![https://gyazo.com/e1dc5ed11f1dfe5c95d81dc96940f290](https://i.gyazo.com/e1dc5ed11f1dfe5c95d81dc96940f290.png)

### 初期設定

インストールが完了するとGUI画面が表示されます。
左上のメニューから設定 > Raspberry Piの設定を選びます。

![https://gyazo.com/f0b366a941ea722fba9fee008ab07f98](https://i.gyazo.com/f0b366a941ea722fba9fee008ab07f98.jpg)

この画面で必要に応じて初期設定を済ませます。
インストール時に日本語を選択しているので、ローカリゼーションはタイムゾーンの設定くらいですみます。

![https://gyazo.com/0b59ea21a4eb97a4b1a340941839ddd0](https://i.gyazo.com/0b59ea21a4eb97a4b1a340941839ddd0.jpg)


## ladder_driveのインストール

Ladder Driveのインストールはターミナルで行なっていきます。
図の様にターミナルを起動します。

![https://gyazo.com/5ab07b8875a820afd6538f7465f7d198](https://i.gyazo.com/5ab07b8875a820afd6538f7465f7d198.jpg)


ターミナルで、以下のコマンドを入力していくとladder_driveがインストールできます。

```
$ sudo apt-get update
$ sudo apt-get install ruby-dev
$ sudo apt-get install libssl-dev
$ sudo gem install ladder_drive --no-ri --no-rdoc
```

## プロジェクト作成

Ladder Driveのプロジェクトを作成します。

```ladder_drive create project``` コマンドでプロジェクトを作成、```cd project``` でプロジェクトディレクトリに移動します。

```
$ ladder_drive create project
$ cd project
```

Ladder Driveでは asm/main.asm ファイルに記述されたラダープログラムを実行します。
asm/main.asmを編集し次の様にします。

```
LD X0
OR M0
OUT Y0
END
```

この例ではX0とM0のORの結果をY0に出力します。

Raspberry PiではX0、Y0はGPIOに割り当てられています。
どのGPIOに割り当てるかは confg/plc.yml ファイルで定義でき、デフォルトではGPIO4がX0、GPIO18がY0に割り当てられています。

```
  raspberrypi:
    cpu: Raspberry Pi
    io: # assign gpio to x and y
      inputs:
        x0:
          pin: 4
          pull: :up
        x1:
          pin: 17
          pull: :up
        x2:
          pin: 27
          pull: :up
      outputs:
        y0:
          pin: 18
        y1:
          pin: 23
        y2:
          pin: 42
```
GPIO4にスイッチを配線し、GPIO18にLEDを配線します。

![https://gyazo.com/ecd45a1a1cbdd71e52d79604bed05ba9](https://i.gyazo.com/ecd45a1a1cbdd71e52d79604bed05ba9.png)


## プロジェクト実行

```sudo rake target=raspberrypi``` を実行するとプロジェクトが起動し、コンソール入力待ちになります。

```
$ sudo rake target=raspberrypi
launching respberrypi plc ... 
done launching
uploading build/main.hex ...
done uploading

  LadderDrive is an abstract PLC.
  This is a console to communicate with PLC.

> 
```

wコマンドにてデバイスの書き込みができます。
```w m0 1``` と入力するとM0がONになります。
main.asmでプログラミングした内容では、M0がONになるとY0もONになり、LEDが点灯します。
```w m0 0``` と入力すると消灯します。

```
> w m0 1
> w m0 0
```

main.asmでプログラミングした内容ではX0がONになってもY0がONになります。
X0はGPIO4のことですから、スイッチを押すとLEDが点灯します。
離すと消灯します。


## サービスとして Ladder Drive を起動

電源投入でLadder Driveが起動する様にサービスとして立ち上げることができます。 Ladder Driveプロジェクのディレクトリで以下のコマンドを実行することでサービスを立ち上げることができます。

```
$ sudo rake service:install
$ sudo rake service:enable
$ sudo rake service:start
```

## デモ

Ladder Driveの動画をYouTubeにアプロードしています。
スイッチを押すとLEDが点灯する様子が見れます。

https://youtu.be/UBhSaRNp_gM
