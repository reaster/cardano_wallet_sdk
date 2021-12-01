// Copyright 2021 Richard Easterling
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';

//
// used https://fluttershapemaker.com to convert svg to CustomPainter.
//
// Add this CustomPaint widget to the Widget Tree
// CustomPaint(
//     size: Size(WIDTH, (WIDTH*1).toDouble()), //You can Replace [WIDTH] with your desired width for Custom Paint and height will be calculated automatically
//     painter: RPSCustomPainter(),
// )

//Copy this CustomPainter code to the Bottom of the File
class AdaCustomPainter extends CustomPainter {
  // ignore: non_constant_identifier_names
  final double NaN = 0.5; //hack to fix generated NaN instances
  final Color? color;
  final PaintingStyle style;

  AdaCustomPainter(
      {this.color = const Color(0xff000000), this.style = PaintingStyle.fill});

  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.5000000, size.height);
    path_0.cubicTo(size.width * 0.2238438, size.height, 0,
        size.height * 0.7761562, 0, size.height * 0.5000000);
    path_0.cubicTo(0, size.height * 0.2238438, size.width * 0.2238438, 0,
        size.width * 0.5000000, 0);
    path_0.cubicTo(size.width * 0.7761562, 0, size.width,
        size.height * 0.2238438, size.width, size.height * 0.5000000);
    path_0.cubicTo(size.width, size.height * 0.7761562, size.width * 0.7761562,
        size.height, size.width * 0.5000000, size.height);
    path_0.close();
    path_0.moveTo(size.width * 0.4914062, size.height * 0.1893750);
    path_0.cubicTo(
        size.width * 0.4792187,
        size.height * 0.1941250,
        size.width * 0.4760937,
        size.height * 0.2114687,
        size.width * 0.4855937,
        size.height * 0.2202500);
    path_0.cubicTo(
        size.width * 0.4945625,
        size.height * 0.2294062,
        size.width * 0.5120625,
        size.height * 0.2261875,
        size.width * 0.5166875,
        size.height * 0.2142187);
    path_0.cubicTo(
        size.width * 0.5246562,
        size.height * 0.1995000,
        size.width * 0.5063750,
        size.height * 0.1816562,
        size.width * 0.4913750,
        size.height * 0.1893437);
    path_0.close();
    path_0.moveTo(size.width * 0.3303125, size.height * 0.2064375);
    path_0.cubicTo(
        size.width * 0.3176563,
        size.height * 0.2097500,
        size.width * 0.3162500,
        size.height * 0.2293750,
        size.width * 0.3285312,
        size.height * 0.2340625);
    path_0.cubicTo(
        size.width * 0.3378125,
        size.height * 0.2390625,
        size.width * 0.3509687,
        size.height * 0.2312812,
        size.width * 0.3500000,
        size.height * 0.2207187);
    path_0.cubicTo(
        size.width * 0.3509375,
        size.height * 0.2109375,
        size.width * 0.3394062,
        size.height * 0.2027500,
        size.width * 0.3303125,
        size.height * 0.2064375);
    path_0.close();
    path_0.moveTo(size.width * 0.6602500, size.height * 0.2343437);
    path_0.cubicTo(
        size.width * 0.6699375,
        size.height * 0.2367812,
        size.width * 0.6771250,
        size.height * 0.2290312,
        size.width * 0.6793750,
        size.height * 0.2205937);
    path_0.cubicTo(
        size.width * 0.6778125,
        size.height * 0.2106875,
        size.width * 0.6680625,
        size.height * 0.2011562,
        size.width * 0.6574687,
        size.height * 0.2062187);
    path_0.cubicTo(
        size.width * 0.6437812,
        size.height * 0.2106562,
        size.width * 0.6460312,
        size.height * 0.2326562,
        size.width * 0.6602500,
        size.height * 0.2343437);
    path_0.close();
    path_0.moveTo(size.width * 0.3669688, size.height * 0.2738750);
    path_0.cubicTo(
        size.width * 0.3527188,
        size.height * 0.2810625,
        size.width * 0.3507500,
        size.height * 0.3024375,
        size.width * 0.3636875,
        size.height * 0.3117500);
    path_0.cubicTo(
        size.width * 0.3770625,
        size.height * 0.3236250,
        size.width * 0.4007500,
        size.height * 0.3134375,
        size.width * 0.4015313,
        size.height * 0.2959062);
    path_0.cubicTo(
        size.width * 0.4038750,
        size.height * 0.2785000,
        size.width * 0.3821563,
        size.height * 0.2644062,
        size.width * 0.3669688,
        size.height * 0.2738750);
    path_0.close();
    path_0.moveTo(size.width * 0.5991563, size.height * 0.2839375);
    path_0.cubicTo(
        size.width * 0.5906875,
        size.height * 0.3006875,
        size.width * 0.6077813,
        size.height * 0.3198750,
        size.width * 0.6258125,
        size.height * 0.3165625);
    path_0.cubicTo(
        size.width * 0.6394063,
        size.height * 0.3121250,
        size.width * 0.6488125,
        size.height * 0.2959687,
        size.width * 0.6411563,
        size.height * 0.2829375);
    path_0.cubicTo(
        size.width * 0.6334375,
        size.height * 0.2661875,
        size.width * 0.6059375,
        size.height * 0.2667187,
        size.width * 0.5991563,
        size.height * 0.2839375);
    path_0.close();
    path_0.moveTo(size.width * 0.4720000, size.height * 0.3155937);
    path_0.cubicTo(
        size.width * 0.4711875,
        size.height * 0.3276562,
        size.width * 0.4799688,
        size.height * 0.3375312,
        size.width * 0.4903750,
        size.height * 0.3425625);
    path_0.cubicTo(
        size.width * 0.4971875,
        size.height * 0.3429687,
        size.width * 0.5045938,
        size.height * 0.3442500,
        size.width * 0.5108438,
        size.height * 0.3408125);
    path_0.cubicTo(
        size.width * 0.5245313,
        size.height * 0.3348750,
        size.width * 0.5312813,
        size.height * 0.3170000,
        size.width * 0.5236875,
        size.height * 0.3040000);
    path_0.cubicTo(
        size.width * 0.5196250,
        size.height * 0.2946250,
        size.width * 0.5093125,
        size.height * 0.2906250,
        size.width * 0.4998438,
        size.height * 0.2887500);
    path_0.cubicTo(
        size.width * 0.4855313,
        size.height * 0.2897812,
        size.width * 0.4718438,
        size.height * 0.3007812,
        size.width * 0.4720000,
        size.height * 0.3155937);
    path_0.close();
    path_0.moveTo(size.width * 0.2324375, size.height * 0.3371562);
    path_0.cubicTo(
        size.width * 0.2203125,
        size.height * 0.3426250,
        size.width * 0.2186250,
        size.height * 0.3610937,
        size.width * 0.2293125,
        size.height * 0.3687812);
    path_0.cubicTo(
        size.width * 0.2393750,
        size.height * 0.3769687,
        size.width * 0.2569375,
        size.height * 0.3717500,
        size.width * 0.2598125,
        size.height * 0.3589062);
    path_0.cubicTo(
        size.width * 0.2650938,
        size.height * 0.3440625,
        size.width * 0.2463438,
        size.height * 0.3287187,
        size.width * 0.2324375,
        size.height * 0.3371250);
    path_0.close();
    path_0.moveTo(size.width * 0.7468750, size.height * 0.3370937);
    path_0.cubicTo(
        size.width * 0.7347500,
        size.height * 0.3444062,
        size.width * 0.7360938,
        size.height * 0.3639062,
        size.width * 0.7489688,
        size.height * 0.3695937);
    path_0.cubicTo(
        size.width * 0.7606563,
        size.height * 0.3764687,
        size.width * 0.7775000,
        size.height * 0.3664062,
        size.width * 0.7766875,
        size.height * 0.3530625);
    path_0.cubicTo(
        size.width * 0.7780938,
        size.height * 0.3384375,
        size.width * 0.7586563,
        size.height * 0.3280937,
        size.width * 0.7468750,
        size.height * 0.3371250);
    path_0.close();
    path_0.moveTo(size.width * 0.5393750, size.height * 0.3636875);
    path_0.cubicTo(
        size.width * 0.5151250,
        size.height * 0.3709375,
        size.width * 0.5007500,
        size.height * 0.3998750,
        size.width * 0.5106250,
        size.height * 0.4230000);
    path_0.cubicTo(
        size.width * 0.5193125,
        size.height * 0.4488437,
        size.width * 0.5536562,
        size.height * 0.4608437,
        size.width * 0.5771875,
        size.height * 0.4466875);
    path_0.cubicTo(
        size.width * 0.5998438,
        size.height * 0.4347187,
        size.width * 0.6076250,
        size.height * 0.4029375,
        size.width * 0.5930000,
        size.height * 0.3820937);
    path_0.cubicTo(
        size.width * 0.5819375,
        size.height * 0.3650312,
        size.width * 0.5588125,
        size.height * 0.3567812,
        size.width * 0.5393750,
        size.height * 0.3636875);
    path_0.close();
    path_0.moveTo(size.width * 0.4252188, size.height * 0.3659687);
    path_0.cubicTo(
        size.width * 0.4022500,
        size.height * 0.3760625,
        size.width * 0.3916875,
        size.height * 0.4058437,
        size.width * 0.4035938,
        size.height * 0.4277812);
    path_0.cubicTo(
        size.width * 0.4142188,
        size.height * 0.4504375,
        size.width * 0.4451563,
        size.height * 0.4597500,
        size.width * 0.4670938,
        size.height * 0.4474687);
    path_0.cubicTo(
        size.width * 0.4890000,
        size.height * 0.4365625,
        size.width * 0.4984688,
        size.height * 0.4071562,
        size.width * 0.4862188,
        size.height * 0.3860312);
    path_0.cubicTo(
        size.width * 0.4758125,
        size.height * 0.3643437,
        size.width * 0.4467813,
        size.height * 0.3559375,
        size.width * 0.4252188,
        size.height * 0.3659688);
    path_0.close();
    path_0.moveTo(size.width * 0.3109375, size.height * 0.4043750);
    path_0.cubicTo(
        size.width * 0.3077812,
        size.height * 0.4204375,
        size.width * 0.3223437,
        size.height * 0.4367500,
        size.width * 0.3390000,
        size.height * 0.4353125);
    path_0.cubicTo(
        size.width * 0.3541250,
        size.height * 0.4354062,
        size.width * 0.3651562,
        size.height * 0.4216875,
        size.width * 0.3660937,
        size.height * 0.4076562);
    path_0.arcToPoint(Offset(size.width * 0.3393125, size.height * NaN),
        radius: Radius.elliptical(
            size.width * 0.03056250, size.height * 0.03056250),
        rotation: 0,
        largeArc: false,
        clockwise: false);
    path_0.cubicTo(
        size.width * 0.3260938,
        size.height * NaN,
        size.width * 0.3130000,
        size.height * NaN,
        size.width * 0.3113438,
        size.height * NaN);
    path_0.close();
    path_0.moveTo(size.width * 0.6485000, size.height * 0.3838750);
    path_0.cubicTo(
        size.width * 0.6301562,
        size.height * 0.3923750,
        size.width * 0.6288125,
        size.height * 0.4205000,
        size.width * 0.6464687,
        size.height * 0.4305000);
    path_0.cubicTo(
        size.width * 0.6634687,
        size.height * 0.4425000,
        size.width * 0.6897187,
        size.height * 0.4280937,
        size.width * 0.6885625,
        size.height * 0.4076250);
    path_0.cubicTo(
        size.width * 0.6893125,
        size.height * 0.3883125,
        size.width * 0.6655937,
        size.height * 0.3740938,
        size.width * 0.6485000,
        size.height * 0.3838750);
    path_0.close();
    path_0.moveTo(size.width * 0.3788125, size.height * 0.4559687);
    path_0.cubicTo(
        size.width * 0.3516875,
        size.height * 0.4624062,
        size.width * 0.3358125,
        size.height * 0.4952187,
        size.width * 0.3488750,
        size.height * 0.5196875);
    path_0.cubicTo(
        size.width * 0.3602812,
        size.height * 0.5463750,
        size.width * 0.3996875,
        size.height * 0.5542500,
        size.width * 0.4210625,
        size.height * 0.5346875);
    path_0.cubicTo(
        size.width * 0.4377500,
        size.height * 0.5213437,
        size.width * 0.4421250,
        size.height * 0.4960625,
        size.width * 0.4314062,
        size.height * 0.4778750);
    path_0.cubicTo(
        size.width * 0.4215937,
        size.height * 0.4598125,
        size.width * 0.3987500,
        size.height * 0.4505625,
        size.width * 0.3787812,
        size.height * 0.4559687);
    path_0.close();
    path_0.moveTo(size.width * 0.5952812, size.height * 0.4558750);
    path_0.cubicTo(
        size.width * 0.5679688,
        size.height * 0.4632187,
        size.width * 0.5535313,
        size.height * 0.4972812,
        size.width * 0.5678750,
        size.height * 0.5213750);
    path_0.cubicTo(
        size.width * 0.5797500,
        size.height * 0.5446875,
        size.width * 0.6130937,
        size.height * 0.5525000,
        size.width * 0.6346250,
        size.height * 0.5376250);
    path_0.cubicTo(
        size.width * 0.6551562,
        size.height * 0.5247812,
        size.width * 0.6617500,
        size.height * 0.4950625,
        size.width * 0.6479375,
        size.height * 0.4751562);
    path_0.cubicTo(
        size.width * 0.6375000,
        size.height * 0.4577500,
        size.width * 0.6146875,
        size.height * 0.4504062,
        size.width * 0.5952812,
        size.height * 0.4558750);
    path_0.close();
    path_0.moveTo(size.width * 0.2502813, size.height * 0.4785625);
    path_0.cubicTo(
        size.width * 0.2337188,
        size.height * 0.4831875,
        size.width * 0.2288125,
        size.height * 0.5068125,
        size.width * 0.2420937,
        size.height * 0.5174062);
    path_0.cubicTo(
        size.width * 0.2534375,
        size.height * 0.5287187,
        size.width * 0.2754063,
        size.height * 0.5230312,
        size.width * 0.2796875,
        size.height * 0.5077187);
    path_0.cubicTo(
        size.width * 0.2866563,
        size.height * 0.4908750,
        size.width * 0.2675312,
        size.height * 0.4721562,
        size.width * 0.2502812,
        size.height * 0.4785625);
    path_0.close();
    path_0.moveTo(size.width * 0.7180625, size.height * 0.5030000);
    path_0.cubicTo(
        size.width * 0.7209375,
        size.height * 0.5095625,
        size.width * 0.7244063,
        size.height * 0.5164375,
        size.width * 0.7311875,
        size.height * 0.5198125);
    path_0.cubicTo(
        size.width * 0.7456875,
        size.height * 0.5276563,
        size.width * 0.7661563,
        size.height * 0.5163125,
        size.width * 0.7650625,
        size.height * 0.4995938);
    path_0.cubicTo(
        size.width * 0.7660000,
        size.height * 0.4869062,
        size.width * 0.7545000,
        size.height * 0.4775313,
        size.width * 0.7426875,
        size.height * 0.4756875);
    path_0.arcToPoint(Offset(size.width * 0.7700000, size.height * NaN),
        radius: Radius.elliptical(
            size.width * 0.02612500, size.height * 0.02612500),
        rotation: 0,
        largeArc: false,
        clockwise: false);
    path_0.close();
    path_0.moveTo(size.width * 0.1654375, size.height * 0.4868750);
    path_0.cubicTo(
        size.width * 0.1568437,
        size.height * 0.4907187,
        size.width * 0.1531250,
        size.height * 0.5021875,
        size.width * 0.1593750,
        size.height * 0.5096563);
    path_0.cubicTo(
        size.width * 0.1664375,
        size.height * 0.5203750,
        size.width * 0.1857187,
        size.height * 0.5154375,
        size.width * 0.1862500,
        size.height * 0.5025938);
    path_0.cubicTo(
        size.width * 0.1886562,
        size.height * 0.4912500,
        size.width * 0.1758125,
        size.height * 0.4824063,
        size.width * 0.1654375,
        size.height * 0.4868750);
    path_0.close();
    path_0.moveTo(size.width * 0.8200938, size.height * 0.4865937);
    path_0.cubicTo(
        size.width * 0.8079063,
        size.height * 0.4930000,
        size.width * 0.8126875,
        size.height * 0.5150938,
        size.width * 0.8274375,
        size.height * 0.5137812);
    path_0.cubicTo(
        size.width * 0.8379375,
        size.height * 0.5153437,
        size.width * 0.8469375,
        size.height * 0.5027500,
        size.width * 0.8420313,
        size.height * 0.4935625);
    path_0.cubicTo(
        size.width * 0.8391250,
        size.height * 0.4851562,
        size.width * 0.8274063,
        size.height * 0.4815000,
        size.width * 0.8200938,
        size.height * 0.4865937);
    path_0.close();
    path_0.moveTo(size.width * 0.4351875, size.height * 0.5482500);
    path_0.cubicTo(
        size.width * 0.4147500,
        size.height * 0.5526250,
        size.width * 0.3990000,
        size.height * 0.5717188,
        size.width * 0.3990625,
        size.height * 0.5922812);
    path_0.cubicTo(
        size.width * 0.3983438,
        size.height * 0.6137500,
        size.width * 0.4153125,
        size.height * 0.6342500,
        size.width * 0.4369375,
        size.height * 0.6376875);
    path_0.cubicTo(
        size.width * 0.4649063,
        size.height * 0.6441250,
        size.width * 0.4938125,
        size.height * 0.6193437,
        size.width * 0.4920313,
        size.height * 0.5913750);
    path_0.cubicTo(
        size.width * 0.4918750,
        size.height * 0.5636875,
        size.width * 0.4625000,
        size.height * 0.5412812,
        size.width * 0.4351563,
        size.height * 0.5482500);
    path_0.close();
    path_0.moveTo(size.width * 0.5433750, size.height * 0.5482187);
    path_0.cubicTo(
        size.width * 0.5269375,
        size.height * 0.5522187,
        size.width * 0.5130000,
        size.height * 0.5655625,
        size.width * 0.5093750,
        size.height * 0.5819687);
    path_0.cubicTo(
        size.width * 0.5021875,
        size.height * 0.6065625,
        size.width * 0.5211875,
        size.height * 0.6344062,
        size.width * 0.5469688,
        size.height * 0.6376875);
    path_0.cubicTo(
        size.width * 0.5743438,
        size.height * 0.6431250,
        size.width * 0.6023750,
        size.height * 0.6191562,
        size.width * 0.6009062,
        size.height * 0.5917187);
    path_0.cubicTo(
        size.width * 0.6013437,
        size.height * 0.5634062,
        size.width * 0.5710937,
        size.height * 0.5405937,
        size.width * 0.5434062,
        size.height * 0.5482187);
    path_0.close();
    path_0.moveTo(size.width * 0.3347500, size.height * 0.5652500);
    path_0.cubicTo(
        size.width * 0.3140313,
        size.height * 0.5673125,
        size.width * 0.3030938,
        size.height * 0.5947188,
        size.width * 0.3177188,
        size.height * 0.6096875);
    path_0.cubicTo(
        size.width * 0.3302188,
        size.height * 0.6253125,
        size.width * 0.3584688,
        size.height * 0.6201250,
        size.width * 0.3641563,
        size.height * 0.6010000);
    path_0.cubicTo(
        size.width * 0.3719375,
        size.height * 0.5830938,
        size.width * 0.3539375,
        size.height * 0.5620313,
        size.width * 0.3347813,
        size.height * 0.5652500);
    path_0.close();
    path_0.moveTo(size.width * 0.6520625, size.height * 0.5660938);
    path_0.cubicTo(
        size.width * 0.6314062,
        size.height * 0.5725625,
        size.width * 0.6279375,
        size.height * 0.6035938,
        size.width * 0.6469063,
        size.height * 0.6140938);
    path_0.cubicTo(
        size.width * 0.6636250,
        size.height * 0.6258438,
        size.width * 0.6895625,
        size.height * 0.6119688,
        size.width * 0.6888750,
        size.height * 0.5918750);
    path_0.cubicTo(
        size.width * 0.6901875,
        size.height * 0.5735938,
        size.width * 0.6691875,
        size.height * 0.5590625,
        size.width * 0.6520625,
        size.height * 0.5660938);
    path_0.close();
    path_0.moveTo(size.width * 0.7407500, size.height * 0.6535938);
    path_0.cubicTo(
        size.width * 0.7452813,
        size.height * 0.6660313,
        size.width * 0.7641875,
        size.height * 0.6690000,
        size.width * 0.7725313,
        size.height * 0.6585938);
    path_0.cubicTo(
        size.width * 0.7786875,
        size.height * 0.6530000,
        size.width * 0.7771562,
        size.height * 0.6443125,
        size.width * 0.7762500,
        size.height * 0.6370313);
    path_0.cubicTo(
        size.width * 0.7718438,
        size.height * 0.6325313,
        size.width * 0.7670000,
        size.height * 0.6271875,
        size.width * 0.7600938,
        size.height * 0.6273125);
    path_0.cubicTo(
        size.width * 0.7462188,
        size.height * 0.6250313,
        size.width * 0.7340625,
        size.height * 0.6413125,
        size.width * 0.7407500,
        size.height * 0.6535938);
    path_0.close();
    path_0.moveTo(size.width * 0.2323750, size.height * 0.6307188);
    path_0.cubicTo(
        size.width * 0.2200313,
        size.height * 0.6369063,
        size.width * 0.2195938,
        size.height * 0.6562500,
        size.width * 0.2315312,
        size.height * 0.6630313);
    path_0.cubicTo(
        size.width * 0.2426562,
        size.height * 0.6705313,
        size.width * 0.2595312,
        size.height * 0.6630000,
        size.width * 0.2610625,
        size.height * 0.6498125);
    path_0.cubicTo(
        size.width * 0.2640000,
        size.height * 0.6349063,
        size.width * 0.2453437,
        size.height * 0.6222500,
        size.width * 0.2323750,
        size.height * 0.6307500);
    path_0.close();
    path_0.moveTo(size.width * 0.4884062, size.height * 0.6583125);
    path_0.cubicTo(
        size.width * 0.4679687,
        size.height * 0.6647813,
        size.width * 0.4649062,
        size.height * 0.6955938,
        size.width * 0.4833125,
        size.height * 0.7060625);
    path_0.cubicTo(
        size.width * 0.4999062,
        size.height * 0.7182500,
        size.width * 0.5266562,
        size.height * 0.7041875,
        size.width * 0.5253750,
        size.height * 0.6838750);
    path_0.cubicTo(
        size.width * 0.5270000,
        size.height * 0.6655000,
        size.width * 0.5053750,
        size.height * 0.6509687,
        size.width * 0.4884062,
        size.height * 0.6583125);
    path_0.close();
    path_0.moveTo(size.width * 0.3698437, size.height * 0.6855313);
    path_0.cubicTo(
        size.width * 0.3596562,
        size.height * 0.6892813,
        size.width * 0.3555000,
        size.height * 0.7003438,
        size.width * 0.3553125,
        size.height * 0.7102500);
    path_0.cubicTo(
        size.width * 0.3588125,
        size.height * 0.7193438,
        size.width * 0.3658750,
        size.height * 0.7289375,
        size.width * 0.3767187,
        size.height * 0.7291563);
    path_0.cubicTo(
        size.width * 0.3898437,
        size.height * 0.7310938,
        size.width * 0.4027812,
        size.height * 0.7199688,
        size.width * 0.4023438,
        size.height * 0.7069063);
    path_0.cubicTo(
        size.width * 0.4036562,
        size.height * 0.6909688,
        size.width * 0.3842813,
        size.height * 0.6780625,
        size.width * 0.3698438,
        size.height * 0.6855313);
    path_0.close();
    path_0.moveTo(size.width * 0.6100313, size.height * 0.6857813);
    path_0.cubicTo(
        size.width * 0.5955313,
        size.height * 0.6930625,
        size.width * 0.5939063,
        size.height * 0.7150625,
        size.width * 0.6072812,
        size.height * 0.7242188);
    path_0.cubicTo(
        size.width * 0.6211250,
        size.height * 0.7359062,
        size.width * 0.6450000,
        size.height * 0.7245313,
        size.width * 0.6446250,
        size.height * 0.7067188);
    path_0.cubicTo(
        size.width * 0.6460313,
        size.height * 0.6897188,
        size.width * 0.6249062,
        size.height * 0.6767188,
        size.width * 0.6100313,
        size.height * 0.6857813);
    path_0.close();
    path_0.moveTo(size.width * 0.6518125, size.height * 0.7873438);
    path_0.cubicTo(
        size.width * 0.6585937,
        size.height * 0.7987812,
        size.width * 0.6783750,
        size.height * 0.7947188,
        size.width * 0.6796563,
        size.height * 0.7814062);
    path_0.cubicTo(
        size.width * 0.6814688,
        size.height * 0.7715313,
        size.width * 0.6723438,
        size.height * 0.7651562,
        size.width * 0.6637188,
        size.height * 0.7634375);
    path_0.cubicTo(
        size.width * 0.6529687,
        size.height * 0.7656875,
        size.width * 0.6451875,
        size.height * 0.7775313,
        size.width * 0.6518125,
        size.height * 0.7873750);
    path_0.close();
    path_0.moveTo(size.width * 0.3202187, size.height * 0.7788125);
    path_0.cubicTo(
        size.width * 0.3211562,
        size.height * 0.7900312,
        size.width * 0.3335938,
        size.height * 0.7997500,
        size.width * 0.3442812,
        size.height * 0.7926563);
    path_0.cubicTo(
        size.width * 0.3561875,
        size.height * 0.7864063,
        size.width * 0.3521563,
        size.height * 0.7662500,
        size.width * 0.3385625,
        size.height * 0.7653125);
    path_0.cubicTo(
        size.width * 0.3292188,
        size.height * 0.7632813,
        size.width * 0.3228437,
        size.height * 0.7710313,
        size.width * 0.3202187,
        size.height * 0.7788125);
    path_0.close();
    path_0.moveTo(size.width * 0.4802188, size.height * 0.7877812);
    path_0.cubicTo(
        size.width * 0.4754375,
        size.height * 0.7994375,
        size.width * 0.4868750,
        size.height * 0.8135313,
        size.width * 0.4995313,
        size.height * 0.8120625);
    path_0.cubicTo(
        size.width * 0.5063438,
        size.height * 0.8122187,
        size.width * 0.5116250,
        size.height * 0.8074375,
        size.width * 0.5157188,
        size.height * 0.8026875);
    path_0.cubicTo(
        size.width * 0.5165000,
        size.height * 0.7994687,
        size.width * 0.5173125,
        size.height * 0.7962187,
        size.width * 0.5182187,
        size.height * 0.7930000);
    path_0.cubicTo(
        size.width * 0.5165312,
        size.height * 0.7868125,
        size.width * 0.5145937,
        size.height * 0.7795625,
        size.width * 0.5079687,
        size.height * 0.7767500);
    path_0.cubicTo(
        size.width * 0.4979687,
        size.height * 0.7706250,
        size.width * 0.4828125,
        size.height * 0.7762500,
        size.width * 0.4801875,
        size.height * 0.7877813);
    path_0.close();

    var paint0Fill = Paint()..style = style; //PaintingStyle.fill;
    paint0Fill.color = color!; // Color(0xff000000).withOpacity(1.0);
    canvas.drawPath(path_0, paint0Fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
