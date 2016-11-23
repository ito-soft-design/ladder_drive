# エスカレーター

## 概要

エスカレーターはPLC(Programmable Logic Controller)向けの抽象的なラダーです。
どのPLCでも同じソース(できればバイナリー)で実行できる形態を目指しています。

まずはニーモニックレベルで実現し、その上に分かりやすい形のプログラミングツールを用意できればと考えています。

## 使い方

使用するにはRubyが実行できる環境が必要です。
Rubyの実行環境の構築はWebサイト等を検索して構築してください。

### インストール

gemでエスカレーターをインストールします。

```
$ gem install escalator
```

### プロジェクト作成

エスカレーターをインストールするとescalatorコマンドが使用できる様になります。
escalatorコマンドでラダーを構成するプロジェクトファイルを作ります。

```
$ escalator create my_project
$ cd my_project
```

ファイルの構成は下の様になっています。
plc以下にエスカレーターを実行するPLCプロジェクトの雛形があります。
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

[![](http://img.youtube.com/vi/aFEtOIgKLvQ/0.jpg)](https://youtu.be/aFEtOIgKLvQ)

### 通信設定

#### PLCの通信設定

plc以下の各種PLCのプロジェクトファイルを開いてIPアドレスなど変更します。
変更後PLCに設定とプログラムを書き込みます。

[![](http://img.youtube.com/vi/fGdyIo9AmuE/0.jpg)](https://youtu.be/fGdyIo9AmuE)

#### エスカレーターの設定

config/plc.ymlファイルで設定します。

現在はiQ-Rのみの対応なので:host: 192.168.0.10の行でPLCに設定したIPアドレスを指定するだけで接続できます。

```plc.yml
plc:
  iq-r:                     # It's a target name
    cpu: iq-r               # It's just a comment.
    protocol: mc_protocol   # It's a protocl to communicate with PLC.
    host: 192.168.0.10      # It's PLC's IP address or dns name.
    port: 5007              # It's PLC's port no.
```

[![](http://img.youtube.com/vi/m0JaOBFIHqw/0.jpg)](https://youtu.be/m0JaOBFIHqw)

### エスカレータープログラム作成

エスカレーターのプログラムはasm以下にあります。
現在はmain.escファイルから生成します。

main.escを編集しプログラムを作成します。
PLC側の実装がまだ進んでいないので実行できるニーモニックはLD、OUT、AND、ORとその反転程度です。

ニーモニックについては[Wiki](https://github.com/ito-soft-design/escalator/wiki/mnemonic)の方を参照してください。

```main.esc
LD  M0
AND M1
OUT M2
END
```

[![](http://img.youtube.com/vi/OjaSqrkWv8Q/0.jpg)](https://youtu.be/OjaSqrkWv8Q)

### プログラムの転送

エスカレータープログラムをplcに転送するには```rake```コマンドを使用します。
デフォルトではエミュレーターが対象になり、エミュレーターが起動します。

```sh
$ rake
```

targetを指定するとplc.ymlのplcセクション内の該当するターゲットが対象になります。

```sh
$ rake target=iq-r
```

plc.ymlファイルのdefaultセクションのtargetでデフォルトのターゲトを設定できます。

```plc.yml
default:
  target: iq-r
```

この場合に```rake```を行うと```rake target=iq-r```をしたのと同じになります。


転送後プログラムが実行されます。

```
$ rake [target=iq-r]
uploading build/main.hex ...
launching emulator ...
done launching
done uploading

  Escalator is an abstract PLC.
  This is a console to communicate with PLC.

>
```

アップロードが完了するとコンソールモードになります。
コンソールモードではコマンドを打つ事でデバイスの読み書きができます。

デバイスの値を読み取るにはrコマンドを使用します。
下の例ではm0から8子分のデバイスを読み出します。

```
> r m0 8
```

デバイスに値を書き込むにはwコマンドを使用します。
下の例ではM0からM7まで書き込んでいます。

```
> w m0 0 0 0 1 1 0 1 1
```



[![](http://img.youtube.com/vi/qGbicGLB7Gs/0.jpg)](https://youtu.be/qGbicGLB7Gs)

## エスカレーターに関する情報

- [一往確認日記 [escalator]](http://diary.itosoft.com/?category=escalator)
- [Wiki](https://github.com/ito-soft-design/escalator/wiki/)

## ライセンス

MIT
