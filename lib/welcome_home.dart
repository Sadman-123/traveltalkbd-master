import 'package:flutter/material.dart';
import 'package:traveltalkbd/admin_panel.dart';
import 'package:traveltalkbd/diy_components/adaptive_helper.dart';
import 'package:traveltalkbd/mobile_related/mobile_home.dart';
import 'package:traveltalkbd/web_related/web_home.dart';
class WelcomeHome extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
   return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/trv.png',height: 250,width: 240,),

         ElevatedButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>AdaptiveHelper(mobile: MobileHome(), web: WebHome())));
         }, child: Text("Website")),
         SizedBox(height: 15,),
         ElevatedButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>AdminPanel()));
         }, child: Text("Admin Panel")),

        ],
      )
    ),
   );
  }
}