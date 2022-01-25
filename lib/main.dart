import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: 'AIzaSyAXPzzaoF8spJyePGAfp7Xn29vvmKaX-u8',
          appId: '1:994671950800:web:959339de9481c1070017d5',
          messagingSenderId: '994671950800',
          projectId: 'fir-demo-e764d'));
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String infoText = '';
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  email = value;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              Container(
                padding: EdgeInsets.all(8),
                child: Text(infoText),
              ),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        final result =
                            await auth.createUserWithEmailAndPassword(
                                email: email, password: password);
                        await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (context) => ChatPage(result.user!)));
                      } catch (e) {
                        setState(() {
                          infoText = '登録に失敗しました：${e.toString()}';
                        });
                      }
                    },
                    child: Text('ユーザー登録')),
              ),
              const SizedBox(
                height: 8,
              ),
              Container(
                width: double.infinity,
                child: OutlinedButton(
                  child: Text('ログイン'),
                  onPressed: () async {
                    try {
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.signInWithEmailAndPassword(
                          email: email, password: password);
                      await Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => ChatPage(result.user!)));
                    } catch (e) {
                      setState(() {
                        infoText = 'ログインに失敗しました：${e.toString()}';
                      });
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  ChatPage(this.user);

  final User user;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット'),
        actions: <Widget>[
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                await Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
              icon: Icon(Icons.close))
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: Text('ログイン情報：${user.email}'),
          ),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final List<DocumentSnapshot> documents = snapshot.data!.docs;
                return ListView(
                  children: documents
                      .map((doc) => Card(
                            child: ListTile(
                                title: Text(doc['text']),
                                subtitle: Text(doc['email']),
                                trailing: doc['email'] == user.email
                                    ? IconButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection('posts')
                                              .doc(doc.id)
                                              .delete();
                                        },
                                        icon: Icon(Icons.delete))
                                    : null),
                          ))
                      .toList(),
                );
              }
              return Center(
                child: Text('読込中…'),
              );
            },
          ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => AddPostPage(user)));
        },
      ),
    );
  }
}

class AddPostPage extends StatefulWidget {
  AddPostPage(this.user);

  final User user;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット投稿'),
      ),
      body: Center(
          child: Container(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
                decoration: InputDecoration(labelText: '投稿メッセージ'),
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                onChanged: (value) => setState(() {
                      messageText = value;
                    })),
            const SizedBox(
              height: 8,
            ),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                child: Text('投稿'),
                onPressed: () async {
                  final date = DateTime.now().toLocal().toIso8601String();
                  final email = widget.user.email;
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc()
                      .set({'text': messageText, 'email': email, 'date': date});
                  Navigator.of(context).pop();
                },
              ),
            )
          ],
        ),
      )),
    );
  }
}
