import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; //O iOS e o Android possuem caminhos diferentes para aramazenamento de arquivo, este pacote ajuda a obte-los de forma mais simples
import 'dart:convert';
import 'dart:io';
import 'package:flutter/scheduler.dart' show timeDilation;

Void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = _toDoController.text;
      _toDoController.text = "";

      newToDo['ok'] = false;

      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(
      Duration(
        seconds: 1,
      ),
    );

    setState(() {
      _toDoList.sort(
        (a, b) {
          if (a['ok'] && !b['ok'])
            return 1;
          else if (!a['ok'] && b['ok'])
            return -1;
          else
            return 0;
        },
      );
    });
    _saveData();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: 'Nova Tarefa',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.blueAccent),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  child: Text("ADD"),
                  onPressed: _addToDo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList
                    .length, //quantidade de itens que serão renderizados/mostrados na tela
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title'],
            style: _toDoList[index]['ok']
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  )
                : TextStyle(decoration: TextDecoration.none)),
        value: _toDoList[index]['ok'], //check box da tabela
        secondary: avatar(index),
        onChanged: (bool value) {
          setState(() {
            _toDoList[index]['ok'] = value;
            //timeDilation = value ? 10.0 : 1.0;

            //print(value);
            // print(_toDoList[index]);

            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text('Tarefa \"${_lastRemoved['title']}\" removida!'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Widget avatar(index) {
    if (_toDoList[index]['ok'] == true) {
      print("Verdadeiro");
      return CircleAvatar(
        //icone da tarefa
        child: Icon(Icons.check),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      );
    } else if (_toDoList[index]['ok'] == false) {
      return CircleAvatar(
        //icone da tarefa
        child: Icon(Icons.error),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      );
    }
  }

  Future<File> _getFile() async {
    //Asyn, serve para que não trave a aplicação enquanto espera o retorno.
    final directory =
        await getApplicationDocumentsDirectory(); //Essa função pega o caminho/diretorio do sistema no qual irei amarzenar os doc. Utiliza-se o await pois a funçção nao executa instantaneamente e retorna um Future
    // O await serve para aguardar o retorno/resposta de uma chamada/função/método, para que possa executar o resto do método (Não foi explicado na aula, estudei por fora)

    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
