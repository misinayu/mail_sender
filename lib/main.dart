import 'package:flutter/material.dart';
import 'package:mailto/mailto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        primaryColor: Colors.red,
      ),
      home: MailPackage(),
    );
  }
}

class MailPackage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MailPackage();
}

class _MailPackage extends State<MailPackage> {
  // 設定情報
  var _mail_to = '';
  var _mail_cc = '';
  var _name = '';
  var _header = '';
  var _footer = '';
  TextEditingController emailController = TextEditingController();
  TextEditingController mailToController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController headerController = TextEditingController();
  TextEditingController footerController = TextEditingController();

  // フォーム
  TextEditingController taskController = TextEditingController();
  TextEditingController goodThingsController = TextEditingController();
  TextEditingController improveController = TextEditingController();
  TextEditingController otherController = TextEditingController();
  TimeOfDay _start_time = new TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end_time = new TimeOfDay(hour: 18, minute: 0);
  var _now = DateTime.now();
  List<String> _items = ["60", "75", "90"];
  String _selectedItem = "60";

  _saveMailTo(String key, String value) async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  _restoreValues() async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      _mail_to = prefs.getString('mail_to') ?? '';
      _mail_cc = prefs.getString('mail_cc') ?? '';
      _name = prefs.getString('name') ?? '';
      _header = prefs.getString('header') ?? '';
      _footer = prefs.getString('footer') ?? '';
      emailController.text = _mail_to;
      mailToController.text = _mail_cc;
      nameController.text = _name;
      headerController.text = _header;
      footerController.text = _footer;
    });
  }

  @override
  void initState() {
    _restoreValues();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('日報報告'),
        actions: [
          IconButton(icon: Icon(Icons.list), onPressed: _pushSaved),
        ],
      ),
      resizeToAvoidBottomPadding: false,
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('稼働時間：'),
                  new RaisedButton(
                    onPressed: () => _selectStartTime(context),
                    child: new Text(
                        '${_start_time.hour}:${_start_time.minute.toString().padLeft(2, '0')}'),
                  ),
                  Text(' ～ '),
                  new RaisedButton(
                    onPressed: () => _selectEndTime(context),
                    child: new Text(
                        '${_end_time.hour}:${_end_time.minute.toString().padLeft(2, '0')}'),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('休憩時間：'),
                  DropdownButton<String>(
                    value: _selectedItem,
                    onChanged: (String newValue) {
                      setState(() {
                        _selectedItem = newValue;
                      });
                    },
                    selectedItemBuilder: (context) {
                      return _items.map((String item) {
                        return Text(
                          item,
                          style: TextStyle(color: Colors.pink),
                        );
                      }).toList();
                    },
                    items: _items.map((String item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: item == _selectedItem
                              ? TextStyle(fontWeight: FontWeight.bold)
                              : TextStyle(fontWeight: FontWeight.normal),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              new TextFormField(
                enabled: true,
                maxLengthEnforced: false,
                obscureText: false,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: taskController,
                decoration: const InputDecoration(
                  hintText: '目標に対する今日一日の取り組みを記載',
                  labelText: '実務記録',
                ),
                validator: (String value) {
                  return value.isEmpty ? '必須入力です' : null;
                },
              ),
              new TextFormField(
                enabled: true,
                maxLengthEnforced: false,
                obscureText: false,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: goodThingsController,
                decoration: const InputDecoration(
                  hintText: '目標達成のための取り組み、うまくいったこと',
                  labelText: 'うまくいったこと',
                ),
                validator: (String value) {
                  return value.isEmpty ? '必須入力です' : null;
                },
              ),
              new TextFormField(
                enabled: true,
                maxLengthEnforced: false,
                obscureText: false,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: improveController,
                decoration: const InputDecoration(
                  hintText: 'さらに良くするために、取り組みたいこと',
                  labelText: '改善したいこと',
                ),
                validator: (String value) {
                  return value.isEmpty ? '必須入力です' : null;
                },
              ),
              new TextFormField(
                enabled: true,
                maxLengthEnforced: false,
                obscureText: false,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: otherController,
                decoration: const InputDecoration(
                  hintText: '工夫、アイディア、やるべきと思ったこと、教訓',
                  labelText: 'その他',
                ),
                validator: (String value) {
                  return value.isEmpty ? '必須入力です' : null;
                },
              ),
              RaisedButton(
                child: Text('日報送信'),
                onPressed: () {
                  urlLauncherMail();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

//url_launcherを使ってメールを送信
  urlLauncherMail() async {
    final mailtoLink = Mailto(
        to: ['${emailController.text}'],
        cc: ['${mailToController.text}'],
        subject:
            '日報_${_name}_${_now.year}-${_now.month.toString().padLeft(2, '0')}-${_now.day.toString().padLeft(2, '0')}',
        body: '${_createMailBody()}');

    return launch('$mailtoLink');
  }

  void _pushSaved() {
    _saveMailTo('mail_to', emailController.text);
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
          appBar: AppBar(
            title: Text('設定'),
          ),
          resizeToAvoidBottomPadding: false,
          body: SingleChildScrollView(
              reverse: true,
              child: Container(
                padding: const EdgeInsets.all(50.0),
                child: Column(
                  children: <Widget>[
                    new TextField(
                      enabled: true,
                      maxLength: 30,
                      maxLengthEnforced: false,
                      style: TextStyle(color: Colors.red),
                      obscureText: false,
                      maxLines: 1,
                      controller: emailController,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.face),
                          labelText: 'To',
                          hintText: 'メールアドレスを入力してください'),
                    ),
                    new TextField(
                      enabled: true,
                      maxLength: 30,
                      maxLengthEnforced: false,
                      style: TextStyle(color: Colors.red),
                      obscureText: false,
                      maxLines: 1,
                      controller: mailToController,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.face),
                          labelText: 'Cc',
                          hintText: 'メールアドレスを入力してください'),
                    ),
                    new TextField(
                      enabled: true,
                      maxLength: 30,
                      maxLengthEnforced: false,
                      style: TextStyle(color: Colors.red),
                      obscureText: false,
                      maxLines: 1,
                      controller: nameController,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.face),
                          labelText: '送信者名',
                          hintText: '自身の名前を入力してください'),
                    ),
                    new TextField(
                      enabled: true,
                      maxLengthEnforced: false,
                      style: TextStyle(color: Colors.red),
                      keyboardType: TextInputType.multiline,
                      obscureText: false,
                      maxLines: null,
                      controller: headerController,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.face),
                          labelText: 'Header',
                          hintText: 'メールのヘッダーを入力してください'),
                    ),
                    new TextField(
                      enabled: true,
                      maxLengthEnforced: false,
                      style: TextStyle(color: Colors.red),
                      obscureText: false,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      controller: footerController,
                      decoration: const InputDecoration(
                          icon: Icon(Icons.face),
                          labelText: 'Footer',
                          hintText: 'メールのフッダーを入力してください'),
                    ),
                    RaisedButton(
                      child: Text('保存'),
                      onPressed: () {
                        setState(() {
                          _mail_to = emailController.text;
                          _mail_cc = mailToController.text;
                          _name = nameController.text;
                          _header = headerController.text;
                          _footer = footerController.text;
                          _saveMailTo('mail_to', _mail_to);
                          _saveMailTo('mail_cc', _mail_cc);
                          _saveMailTo('name', _name);
                          _saveMailTo('header', _header);
                          _saveMailTo('footer', _footer);
                        });
                      },
                    )
                  ],
                ),
              )));
    }));
  }

  // 時間選択
  Future<Null> _selectStartTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: _start_time,
    );
    if (picked != null)
      setState(() {
        _start_time = picked;
      });
  }

  Future<Null> _selectEndTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: _end_time,
    );
    if (picked != null)
      setState(() {
        _end_time = picked;
      });
  }

  // メール本文作成
  String _createMailBody() {
    var task = taskController.text;
    if (task == '') {
      task = '特になし';
    }
    var good = goodThingsController.text;
    if (good == '') {
      good = '特になし';
    }
    var improve = improveController.text;
    if (improve == '') {
      improve = '特になし';
    }
    var other = otherController.text;
    if (other == '') {
      other = '特になし';
    }

    return '${headerController.text}\n\n'
        '<稼働時間>'
        '${_start_time.hour}:${_start_time.minute.toString().padLeft(2, '0')}'
        ' ~ ${_end_time.hour}:${_end_time.minute.toString().padLeft(2, '0')}\n\n'
        '<休憩時間>\n'
        '${_selectedItem}'
        '<実務記録>\n'
        '$task\n\n'
        '<うまくいったこと>\n'
        '$good\n\n'
        '<改善したいこと>\n'
        '$improve\n\n'
        '<その他>\n'
        '$other\n\n\n'
        '${footerController.text}';
  }
}
