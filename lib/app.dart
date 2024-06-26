import 'dart:async';
import 'dart:io';

import 'package:charset_converter/charset_converter.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/post_code.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _info = "";
  String _msj = '';
  bool connected = false;
  List<BluetoothInfo> items = [];
  List<String> _options = [
    "permission bluetooth granted",
    "bluetooth enabled",
    "connection status",
    "update info"
  ];

  String _selectSize = "2";
  final _txtText = TextEditingController(text: "Hello developer");
  bool _progress = false;
  String _msjprogress = "";

  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            PopupMenuButton(
              elevation: 3.2,
              //initialValue: _options[1],
              onCanceled: () {
                print('You have not chossed anything');
              },
              tooltip: 'Menu',
              onSelected: (Object select) async {
                String sel = select as String;
                if (sel == "permission bluetooth granted") {
                  bool status =
                      await PrintBluetoothThermal.isPermissionBluetoothGranted;
                  setState(() {
                    _info = "permission bluetooth granted: $status";
                  });
                  //open setting permision if not granted permision
                } else if (sel == "bluetooth enabled") {
                  bool state = await PrintBluetoothThermal.bluetoothEnabled;
                  setState(() {
                    _info = "Bluetooth enabled: $state";
                  });
                } else if (sel == "update info") {
                  initPlatformState();
                } else if (sel == "connection status") {
                  final bool result =
                      await PrintBluetoothThermal.connectionStatus;
                  connected = result;
                  setState(() {
                    _info = "connection status: $result";
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                return _options.map((String option) {
                  return PopupMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList();
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('info: $_info\n '),
                Text(_msj),
                Row(
                  children: [
                    Text("Type print"),
                    SizedBox(width: 10),
                    DropdownButton<String>(
                      value: optionprinttype,
                      items: options.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          optionprinttype = newValue!;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        this.getBluetoots();
                      },
                      child: Row(
                        children: [
                          Visibility(
                            visible: _progress,
                            child: SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 1,
                                  backgroundColor: Colors.white),
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(_progress ? _msjprogress : "Search"),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.disconnect : null,
                      child: Text("Disconnect"),
                    ),
                    ElevatedButton(
                      onPressed: connected ? printTest : null,
                      child: Text("Test"),
                    ),
                  ],
                ),
                Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    child: ListView.builder(
                      itemCount: items.length > 0 ? items.length : 0,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            String mac = items[index].macAdress;
                            this.connect(mac);
                          },
                          title: Text('Name: ${items[index].name}'),
                          subtitle:
                              Text("macAddress: ${items[index].macAdress}"),
                        );
                      },
                    )),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: Column(children: [
                    Text(
                        "Text size without the library without external packets, print images still it should not use a library"),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _txtText,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Text",
                            ),
                          ),
                        ),
                        SizedBox(width: 5),
                        DropdownButton<String>(
                          hint: Text('Size'),
                          value: _selectSize,
                          items: <String>['1', '2', '3', '4', '5']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: new Text(value),
                            );
                          }).toList(),
                          onChanged: (String? select) {
                            setState(() {
                              _selectSize = select.toString();
                            });
                          },
                        )
                      ],
                    ),
                    ElevatedButton(
                      onPressed: connected ? this.printWithoutPackage : null,
                      child: Text("Print"),
                    ),
                  ]),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    int porcentbatery = 0;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
      //print("patformversion: $platformVersion");
      porcentbatery = await PrintBluetoothThermal.batteryLevel;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    print("bluetooth enabled: $result");
    if (result) {
      _msj = "Bluetooth enabled, please search and connect";
    } else {
      _msj = "Bluetooth not enabled";
    }

    setState(() {
      _info = platformVersion + " ($porcentbatery% battery)";
    });
  }

  Future<void> getBluetoots() async {
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    /*await Future.forEach(listResult, (BluetoothInfo bluetooth) {
      String name = bluetooth.name;
      String mac = bluetooth.macAdress;
    });*/

    setState(() {
      _progress = false;
    });

    if (listResult.length == 0) {
      _msj =
          "There are no bluetoohs linked, go to settings and link the printer";
    } else {
      _msj = "Touch an item in the list to connect";
    }

    setState(() {
      items = listResult;
    });
  }

  Future<void> connect(String mac) async {
    setState(() {
      _progress = true;
      _msjprogress = "Connecting...";
      connected = false;
    });
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    print("state conected $result");
    if (result) connected = true;
    setState(() {
      _progress = false;
    });
  }

  Future<void> disconnect() async {
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
    print("status disconnect $status");
  }

  Future<void> printTest() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    //print("connection status: $conexionStatus");
    if (conexionStatus) {
      bool result = false;
      List<int> ticket = await testTicket();
      result = await PrintBluetoothThermal.writeBytes(ticket);
      print("print test result:  $result");
    } else {
      print("print test conexionStatus: $conexionStatus");
      setState(() {
        disconnect();
      });
    }
  }

  Future<void> printString() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    if (conexionStatus) {
      String enter = '\n';
      await PrintBluetoothThermal.writeBytes(enter.codeUnits);
      //size of 1-5
      String text = "Hello";
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 1, text: text));
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 2, text: text + " size 2"));
      await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: 3, text: text + " size 3"));
    } else {
      //desconectado
      print("desconectado bluetooth $conexionStatus");
    }
  }

  Future<Uint8List> getEncoded(String text) async {
    final encoded = await CharsetConverter.encode("UTF-8", text);
    return encoded;
  }

  Future<List<int>> testTicket() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    //bytes += generator.setGlobalFont(PosFontType.fontA);
    bytes += generator.reset();

    /// Title

    bytes += generator.textEncoded(await getEncoded('فاتورة'),
        styles: PosStyles(align: PosAlign.center, bold: true), linesAfter: 1);

    /// Image of logo
    bytes = await _logo(bytes, generator);
    bytes += generator.textEncoded(await getEncoded('شركة آيزام للتكنولوجيا'),
        styles: PosStyles(align: PosAlign.center, bold: true), linesAfter: 1);

    bytes += generator.textEncoded(
        await getEncoded(
            'Elmasged ElAqsa Mosque street 7 \n smart Village /n Giza'),
        styles: PosStyles(align: PosAlign.center),
        linesAfter: 1);

    bytes += generator.textEncoded(
        await getEncoded('فاتورة إلى: \n  POS Client'),
        styles: PosStyles(align: PosAlign.right),
        linesAfter: 1);

    bytes += generator.textEncoded(
      await getEncoded('رقم الفاتورة:POS10123499949949'),
      styles: PosStyles(align: PosAlign.right),
    );
    bytes += generator.textEncoded(
      await getEncoded('تاريخ الفاتورة:02/04/2024'),
      styles: PosStyles(align: PosAlign.right),
    );
    bytes += generator.textEncoded(
      await getEncoded('--------------------------------'),
      styles: PosStyles(align: PosAlign.right),
    );

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        textEncoded: await getEncoded('العدد'),
        width: 3,
        styles: PosStyles(
          align: PosAlign.center,
          reverse: true,
        ),
      ),
      PosColumn(
        textEncoded: await getEncoded('العنصر'),
        width: 6,
        styles: PosStyles(
          align: PosAlign.center,
          reverse: true,
        ),
      ),
      PosColumn(
        textEncoded: await getEncoded('السعر'),
        width: 3,
        styles: PosStyles(
          align: PosAlign.center,
          reverse: true,
        ),
      ),
    ]);

    bytes += generator.row([
      PosColumn(
          text: "count",
          width: 4,
          styles: PosStyles(bold: true, underline: false)),
      PosColumn(
          text: "Name",
          width: 4,
          styles: PosStyles(bold: true, underline: false)),
      PosColumn(
          text: "Price",
          width: 4,
          styles: PosStyles(bold: true, underline: false)),
    ]);

    bytes += generator.row([
      PosColumn(text: "1", width: 4),
      PosColumn(text: "2", width: 4),
      PosColumn(text: "3", width: 4),
    ]);

    bytes += generator.row([
      PosColumn(text: "Product1", width: 4),
      PosColumn(text: "Product2", width: 4),
      PosColumn(text: "Product3", width: 4),
    ]);

    // bytes += generator.row([
    //   PosColumn(
    //     textEncoded: await getEncoded('1'),
    //     width: 3,
    //     styles: PosStyles(
    //       align: PosAlign.center,
    //     ),
    //   ),
    //   PosColumn(
    //     textEncoded: await getEncoded('شيبسي'),
    //     width: 6,
    //     styles: PosStyles(
    //       align: PosAlign.center,
    //     ),
    //   ),
    //   PosColumn(
    //     textEncoded: await getEncoded('١٥ جنيه'),
    //     width: 3,
    //     styles: PosStyles(
    //       align: PosAlign.center,
    //     ),
    //   ),
    // ]);

    //QR code
    // bytes += generator.feed(2);
    // bytes += generator.qrcode('example.com');
    //
    // bytes += generator.feed(2);

    //bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> _logo(List<int> bytes, Generator generator) async {
    final ByteData data = await rootBundle.load('assets/images/mylogo.jpg');
    final Uint8List imgBytes = data.buffer.asUint8List();
    img.Image? image = img.decodeImage(imgBytes)!;
    if (Platform.isIOS) {
      final resizedImage = img.copyResize(image!,
          width: image.width ~/ 1.3,
          height: image.height ~/ 1.3,
          interpolation: img.Interpolation.nearest);
      final bytesimg = Uint8List.fromList(img.encodeJpg(resizedImage));
      image = img.decodeImage(bytesimg);
    }
    bytes += generator.imageRaster(
      image!,
    );
    return bytes;
  }

  Future<List<int>> testWindows() async {
    List<int> bytes = [];

    bytes +=
        PostCode.text(text: "Size compressed", fontSize: FontSize.compressed);
    bytes += PostCode.text(text: "Size normal", fontSize: FontSize.normal);
    bytes += PostCode.text(text: "Bold", bold: true);
    bytes += PostCode.text(text: "Inverse", inverse: true);
    bytes += PostCode.text(text: "AlignPos right", align: AlignPos.right);
    bytes += PostCode.text(text: "Size big", fontSize: FontSize.big);
    bytes += PostCode.enter();

    //List of rows
    bytes += PostCode.row(
        texts: ["PRODUCT", "VALUE"],
        proportions: [60, 40],
        fontSize: FontSize.compressed);
    for (int i = 0; i < 3; i++) {
      bytes += PostCode.row(
          texts: ["Item $i", "$i,00"],
          proportions: [60, 40],
          fontSize: FontSize.compressed);
    }

    bytes += PostCode.line();

    bytes += PostCode.barcode(barcodeData: "123456789");
    bytes += PostCode.qr("123456789");

    bytes += PostCode.enter(nEnter: 5);

    return bytes;
  }

  Future<void> printWithoutPackage() async {
    //impresion sin paquete solo de PrintBluetoothTermal
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      String text = _txtText.text.toString() + "\n";
      bool result = await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: int.parse(_selectSize), text: text));
      print("status print result: $result");
      setState(() {
        _msj = "printed status: $result";
      });
    } else {
      //no conectado, reconecte
      setState(() {
        _msj = "no connected device";
      });
      print("no conectado");
    }
  }
}
