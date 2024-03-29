import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mspr/error.dart';
import 'package:http/http.dart' as http;
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:mspr/success.dart';
import 'util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
   @override
   Widget build(BuildContext context) {
     return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        canvasColor: CustomColors.GreyBackground,
        fontFamily: 'rubik',
      ),
      home: Home(),
     );
   }
 }

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  HomePage createState() => HomePage();
}
class HomePage extends State<Home> {
  String barcode = "";

  @override
  initState() {
    super.initState();
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Go-Style"),
          backgroundColor: CustomColors.HeaderBlueDark,
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  getHistory();
                },
                child: Icon(
                    Icons.history
                ),
              )
            )
          ],
        ),
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width / 1.2,
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 8,
                  child: Hero(
                    tag: 'Clipboard',
                    child: Image.asset('assets/images/Clipboard.png'),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Go-Style',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: CustomColors.TextHeader),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Scannez un QR Code pour accéder à votre réduction GO Style. Les coupons peuvent aller de -10% à -70% !',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: CustomColors.TextBody,
                            fontFamily: 'opensans'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: RaisedButton(
                    onPressed: () {
                      scan();
                    },
                    textColor: Colors.white,
                    padding: const EdgeInsets.all(0.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Container(
                      //width: MediaQuery.of(context).size.width / 1.4,
                      height: 60,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            CustomColors.BlueLight,
                            CustomColors.BlueDark,
                          ],
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CustomColors.BlueShadow,
                            blurRadius: 10.0,
                            spreadRadius: 1.5,
                            offset: Offset(0.0, 0.0),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Center(
                        child: const Text(
                          'Scan QR Code',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(),
                )
              ],
            ),
          ),
        )
      );
  }

  Future scan() async {
  
    try {
      String barcode;
      await BarcodeScanner.scan().then((onValue) {
        setState(() {
          barcode = onValue.toString();
        });
      checkCoupon(barcode);
      }).catchError((onError) {
        print(onError);
      });
      setState(() => this.barcode = barcode);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        setState(() {
          this.barcode = 'camera permission not granted!';
        });
      } else {
        setState(() => this.barcode = 'Unknown error: $e');
      }
    } on FormatException {
      setState(() => this.barcode = '(User returned)');
    } catch (e) {
      setState(() => this.barcode = 'Unknown error: $e');
    }
  }

  void checkCoupon(code) async {
    var url = "https://gostyle.arthurdufour.com/coupons/" + code;
    var response = await http.get(url);

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> list = prefs.getStringList("coupons");
      list.add(jsonDecode(response.body)['coupon'].toString().toUpperCase() + " - " + jsonDecode(response.body)['discount'].toString() + "%");
      await prefs.setStringList('coupons', list);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Success(data: response.body)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Error(data: response.body)),
      );
    }
  }

  void getHistory() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> list = List<String>();
      String texteCoupons = "";

      if (prefs.getStringList('coupons') != null && prefs.getStringList('coupons').length != 0) {
        list = prefs.getStringList('coupons');
        list.forEach((element) {
          if (list.indexOf(element) == list.length - 1) {
            texteCoupons += "• " + element;
          } else {
            texteCoupons += "• " + element + "\n";
          }
        });
      } else {
        texteCoupons = "Vous n'avez pas encore scanné de coupon";
      }

      // set up the button
      Widget okButton = FlatButton(
        child: Text("OK"),
        onPressed: () { 
          Navigator.pop(context, true);
        },
      );
      // set up the AlertDialog
      AlertDialog alert = AlertDialog(
        title: Text("Historique des scans"),
        content: Text(texteCoupons),
        actions: [
          okButton,
        ],
      );
      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
  }
}

