import 'dart:io';
import 'dart:math';

import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Data {
  String peer = "Tap to add";
  String myId = "";
  List<String> peerInfo = [];
  late Future<Socket> socket;
  KeyPair appKeyPair = KeyPair(
"""

""",
"""

"""     
);

  Future<KeyPair> keyPair = RSA.generate(512);

  Future<InternetAddress> address =
      NetworkInterface.list(type: InternetAddressType.IPv6).then((list) {
    for (var networkInterface in list) {
      for (var address in networkInterface.addresses) {
        if (address.address.substring(0, 1) == "2" ||
            address.address.substring(0, 1) == "3") {
          return address;
        }
      }
    }
    return Future.error("No globally routable ipv6 found");
  });
}

Future<ServerSocket> init(Data data) async {
  ServerSocket ret;
  return await data.address.then((value) async {
    KeyPair keyPair = await data.keyPair;
    while (true) {
      try {
        ret = await ServerSocket.bind(value, Random().nextInt(40000) + 20000);
        print(ret.port);
        List<String> message = [keyPair.publicKey,ret.address.address,ret.port.toString()];
        data.myId = await RSA.encryptOAEP(message.toString(), "Id", Hash.MD5, data.appKeyPair.publicKey);
        return Future.value(ret);
      } catch (e) {
        e;
      }
    }
  }).onError((error, stackTrace) {
    return Future.error(error!);
  });
}

void main(List<String> args) {
  Data data = Data();
  Future<ServerSocket> serverSocket = init(data);
  TextEditingController controller = TextEditingController();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {
          serverSocket.then((value) {
            Clipboard.setData(ClipboardData(text: data.myId));
          });
        }, icon: const Icon(Icons.copy)),
        title: Paste(data),
        actions: [
          IconButton(
              onPressed: () {

              }, icon: const Icon(Icons.dark_mode_outlined))
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return Column(
          children: [
            Container(
              height: constraints.maxHeight - 50,
              width: constraints.maxWidth,
              color: Colors.amber,
              child: Messages(data, serverSocket),
            ),
            Container(
              height: 50,
              width: constraints.maxWidth,
              color: Colors.black87,
              child: Row(
                children: [
                  Container(
                    height: 50,
                    width: constraints.maxWidth - 50,
                    color: Colors.lightGreenAccent,
                    child: TextField(controller: controller,),
                  ),
                  Container(
                    height: 50,
                    width: 50,
                    color: Colors.indigo,
                    child: IconButton(
                        onPressed: () {
                          data.socket.then((value) {
                            value.write(controller.text);
                            controller.clear();
                          });
                        },
                        icon: const Icon(Icons.arrow_circle_right_outlined)),
                  )
                ],
              ),
            )
          ],
        );
      }),
    ),
  ));
}

class Messages extends StatefulWidget {
  const Messages(this.data, this.serverSocket, {super.key});
  final Future<ServerSocket> serverSocket;
  final Data data;

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  @override
  void initState() {
    super.initState();
    widget.serverSocket.then((value) {
      value.listen((socket) {
        socket.listen((event) {
           info = String.fromCharCodes(event);
           setState(() {

           });
        });
      });
    });
  }

  String info = "string";

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.brown,
        child: Center(child: Text(info)),
  );
  }
}

class Paste extends StatefulWidget {
  const Paste(this.data, {super.key});
  final Data data;
  @override
  State<Paste> createState() => _PasteState();
}

class _PasteState extends State<Paste> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: () {
                Clipboard.getData("text/plain").then((value){
                  if(value != null && value.text != null){
                    RSA.decryptOAEP(value.text!, "Id", Hash.MD5, widget.data.appKeyPair.privateKey).then((value) {
                      widget.data.peerInfo = value.substring(1,value.length-1).split(", ");
                      print(widget.data.peerInfo);
                      widget.data.socket = Socket.connect(widget.data.peerInfo[1],int.parse(widget.data.peerInfo[2]));

                    });
                  }
                });
        },
        child: Text(
          widget.data.peer,
          style: const TextStyle(fontSize: 40, color: Colors.white),
        ));
  }
}
