ファイルからImageウィジェットを作成して表示するようにしたら、内容がキャッシュされて画像ファイルを書き換えてもアプリ表示が更新されないようだ。それの検証と、キャッシュを防ぐ方法についての話。

　Flutterで画像ファイルを選択して表示し、ボタンを押すたびにパラメータを変化させながらOpenCVで加工するというアプリを作ってみた。OpenCVで作成されたイメージをFlutterに戻すときにどうやろうかと考えて、結局決まった画像ファイルに書き込んで渡すことにした。OpenCVはC++のライブラリなので、巨大なメモリ空間をFlutterとやり取りするのは少々不安だったからだ。
　すると最初の一回は表示されるが、パラメータを変えていろいろ変更を加えたものは表示されずに一回めの画像のままとなった。
　OpenCVが作成したファイルが残っているので見てみたら、それはちゃんとパラメータにそって更新されていた。setState()の使い方の誤りで画面が更新されてないのか？ 
　検証用のアプリを作ってみることにした。

### 検証用アプリの作成
　Flutterの新規アプリ作成時に自動的にセットされるサンプルソースを元にいろいろ付け加えていく。
　まず画像表示用のImageウィジェットimgを変数に加える。
```dart:イメージウィジェット定義
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late Image img;
```
Widget build()の中の適当なとこにimgを挿入する。
```dart:イメージウィジェット表示箇所
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            img,  // ← テキストの上にイメージを追加
            const Text(
              'You have pushed the button this many times:',
            ),
});
```
_counterの値を画像内に文字列として描画するメソッドを作成する。OpenCVを呼び出すのは大変なので検証にはdart:imageを使うことにした。そのためまずpubspec.yamlにimage: ^3.2.2を追加する。
```yaml:pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  image: ^3.2.2
```
main.dartの先頭でdart:imageをimgLibという名前で呼び出せるように宣言する。Fileも使うのでついでにimport 'dart:io';も追加。
```dart:main.dart
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imgLib;
import 'dart:io';
```
FlutterのImageを作成するメソッドをclass _MyHomePageStateに追加する。まずimgLibで画像を作成しファイルに書き込み、ファイルからFlutterのImageを作成する。
```dart:_counterの値を画像内に文字列として描画するメソッド
  Image make_counter_image(){
    // dart:Image初期化
    imgLib.Image image = imgLib.Image(512, 256);
    // _counterの値を画像に描画
    imgLib.drawString(image, imgLib.arial_48, 100, 100, "_counter=$_counter");
    // 画像のメモリイメージを作成
    List<int> _imageBytes = imgLib.encodeJpg(image);

    // テンポラリファイル名は3つづつローテーションする
    String imgname="img${_counter%3}.jpg";
    // 画像をテンポラリファイルに書き込む
    File _f = File(imgname );
    _f.writeAsBytesSync(_imageBytes);

    // 画像ファイルからイメージを作成
    return Image.file(File(imgname));
  }
});
```
class _MyHomePageStateにinitState()を追加しimg変数の初期化を行う。_incrementCounter() にimgの更新処理を追加する。
```dart:main.dart
  @override
  void initState() {
    super.initState();
    img = make_counter_image();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      img = make_counter_image();
    });
  }
```
### 検証用アプリの結果
これをWindowsで実行すると以下の動画のようになる。ボタンをクリックすると最初の3回は画像が更新されるが、それ以降はカウンタはアップされても画像はくり返し同じものを表示するだけだ。使ったファイルをWindowsで直接見ると内容は確かに更新された画像となっている。ただアプリの表示が変わらない。

https://youtube.com/shorts/zGD3QNzUQXE

これはおそらくFlutterがファイルから読みだした画像をキャッシュしていて、3回ごとに同じファイルをローテーションして使うので、ファイルが更新されても表示は以前のままくり返されるということだろう。つまりプログラム上は毎回ファイルを読むように書かれているが、実際には読まれていない。また、動画を見ると最初はボタンを押すたびに画面がチラつくが、3回目以降はチラつきがなくなることが分かる。これもキャッシュの効果だと思う。

### キャッシュを防ぐには

決まった画像を表示するには役にたつが、更新される内容が参照されないのは困る。キャッシュされない方法はないだろうか。どうやらキャッシュされるのはファイルから読みだしたときだけのようなので、次のようにいったんファイルをメモリに読み込んで、Image.file()ではなくImaage.memory()で作成すれば、キャッシュされないようだ。make_counter_image()の最後を次のように書き換えればいい。
```dart:キャッシュされない方法
    // 画像ファイルからイメージを作成
    //return Image.file(File(imgname)); これを以下のように書き換える
    File fileM = File(imgname);
    final imageForUint8 = fileM.readAsBytesSync();
    return Image.memory(imageForUint8);
  }
});
```
ゲームの背景画像などをAssetに入れるとアプリが大きくなるので、サーバーからダウンロードしたりすることは多いと思う。キャッシュをうまく使えば、複数画像を何度も読みだして表示させても重くならずにすみそうだ。キャッシュされて困るものはいったんメモリに読みだして使えばいいので、状況に応じてImageウィジェットをうまく使うようにしたい。

ソースは以下にあります。

https://github.com/pie-xx/imgfile_cache_sample
