import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imgLib;
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late Image img;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            img,
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
