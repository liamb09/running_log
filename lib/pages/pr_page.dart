import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:running_log/services_and_helpers/User.dart';
import 'package:running_log/services_and_helpers/UserDatabaseHelper.dart';
import 'package:running_log/theme/theme.dart';
import 'package:running_log/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PRPage extends StatefulWidget {
  @override
  State<PRPage> createState() => _PRPageState();
}

class _PRPageState extends State<PRPage> {

  Future<User> getUserFromDB () async {
    var user = await UserDatabase.instance.getUser();
    //UserDatabase.instance.clearDatabase();
    if (user.isEmpty) {
      UserDatabase.instance.addDefaultUser();
      user = await UserDatabase.instance.getUser();
    }
    return user[0];
  }

  String secondsToTime (int s) {
    if (s == 0) return "-:--";
    int hours = s ~/ 3600;
    int minutes = (s - hours * 3600) ~/ 60;
    int seconds = s - (hours * 3600 + minutes * 60);
    String secondsStr = "$seconds";
    if (seconds < 10) {
      secondsStr = "0$seconds";
    }
    if (hours > 0) {
      String minutesStr = "$minutes";
      if (minutes < 10) {
        minutesStr = "0$minutes";
      }
      return "$hours:$minutesStr:$secondsStr";
    } else {
      return "$minutes:$secondsStr";
    }
  }

  Map<String, int> getPRs (String encodedPRs, User user) {
    if (encodedPRs == "") return {};
    Map<String, dynamic> decodedPRs = json.decode(encodedPRs);
    Map<String, int> ret = {};
    for (int i = 0; i < decodedPRs.length; i++) {
      ret.addAll({decodedPRs.keys.elementAt(i): decodedPRs.values.elementAt(i) as int});
    }
    ret = sortPRs(ret, user.distUnit);
    return ret;
  }

  Map<String, int> sortPRs (Map<String, int> prs, String userUnit) {
    return Map.fromEntries(prs.entries.toList()..sort((e1, e2) => toUserUnits(double.parse(e1.key.substring(0, e1.key.length-2)), e1.key.substring(e1.key.length-2), userUnit).compareTo(toUserUnits(double.parse(e2.key.substring(0, e2.key.length-2)), e2.key.substring(e2.key.length-2), userUnit))));
  }

  void savePrs (SharedPreferences sp, Map<String, int> prs) {
    sp.setString("prs", json.encode(prs));
  }

  double toUserUnits (double dist, String distUnit, String userUnit) {
    double newDist = dist;
    if (distUnit != userUnit) {
      if (distUnit == "km") {
        newDist = dist / 1.609;
      } else {
        newDist = dist * 1.609;
      }
    }
    newDist = (newDist*100).round()/100;
    return newDist;
  }

  String? newUnit;
  String inEdit = "";
  List<Widget> zeroTo100 = [];
  List<Widget> zeroTo60 = [];
  int showDetailedIndex = -1;

  @override
  Widget build(BuildContext context) {

    if (zeroTo100.isEmpty) {
      for (int i = 0; i < 100; i++) {
        zeroTo100.add(Center(child: Text("${i < 10 ? "0$i" : i}")));
      }
    }
    if (zeroTo60.isEmpty) {
      for (int i = 0; i < 60; i++) {
        zeroTo60.add(Center(child: Text("${i < 10 ? "0$i" : i}")));
      }
    }

    Future<User> user = getUserFromDB();
    Future<SharedPreferences> sp = SharedPreferences.getInstance();
    return FutureBuilder<SharedPreferences>(
      future: sp,
      builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.data == null) {
          return CircularProgressIndicator();
        }
        SharedPreferences sharedPreferences = snapshot.data!;
        if (sharedPreferences.getString("prs") == null) {
          sharedPreferences.setString("prs", "");
        }
        //
        return FutureBuilder<User>(
          future: user,
          builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
            var userData = snapshot.data;
            if (userData == null) {
              return CircularProgressIndicator();
            }
            Map<String, int> prs = getPRs(sharedPreferences.getString("prs")!, userData);
            return Scaffold(
              appBar: AppBar(
                surfaceTintColor: Theme.of(context).colorScheme.tertiary == Colors.white ? null : Colors.transparent,
                title: Text(
                  "Your PRs",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: Theme.of(context).textTheme.titleLarge!.fontSize,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: ListView.builder(
                    itemCount: prs.length+1,
                    itemBuilder: (context, index) {
                      if (index != prs.length && prs.isNotEmpty) {
                        String thisKey = prs.keys.elementAt(index);
                        return Column(
                          children: [
                            Dismissible(
                              key: Key(thisKey),
                              background: Container(
                                color: Colors.red,
                                child: Row(
                                  children: [
                                    Expanded(child: Container()),
                                    Text("Delete", style: TextStyle(
                                      color: Colors.white, 
                                      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                      fontWeight: FontWeight.w900,
                                    ),),
                                    SizedBox(width: 20,),
                                  ],
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                prs.remove(thisKey);
                                savePrs(sharedPreferences, prs);
                                setState(() {});
                              },
                              child: InkWell(
                                onLongPress: () {
                                  int thisValue = prs.values.elementAt(index);
                                  double dist = double.parse(thisKey.substring(0, thisKey.length-2));
                                  String unit = thisKey.substring(thisKey.length-2);
                                  int hours = (thisValue/3600).floor();
                                  int minutes = ((thisValue-hours*3600)/60).floor();
                                  int seconds = thisValue%60;
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            backgroundColor: Theme.of(context).colorScheme.surface,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            content: SizedBox(
                                              width: double.maxFinite,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text("Add a PR", style: Theme.of(context).textTheme.titleLarge),
                                                    SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                "Distance",
                                                                style: Theme.of(context).textTheme.titleMedium,
                                                              ),
                                                              InkWell(
                                                                highlightColor: Colors.transparent,
                                                                hoverColor: Colors.transparent,
                                                                splashColor: Colors.transparent,
                                                                splashFactory: NoSplash.splashFactory,
                                                                onTap: () {
                                                                  if (unit == "mi") {
                                                                    setState(() {
                                                                      unit = "km";
                                                                    });
                                                                  } else {
                                                                    setState(() {
                                                                      unit = "mi";
                                                                    });
                                                                  }
                                                                },
                                                                child: Text(
                                                                  unit == "mi" ? "Miles" : "Kilometers",
                                                                  textAlign: TextAlign.left,
                                                                  style: TextStyle(
                                                                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                                    color: Theme.of(context).colorScheme.secondary,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        InkWell(
                                                          highlightColor: Colors.transparent,
                                                          hoverColor: Colors.transparent,
                                                          splashColor: Colors.transparent,
                                                          splashFactory: NoSplash.splashFactory,
                                                          onTap: () async {
                                                            showCupertinoModalPopup(
                                                              context: context,
                                                              builder: (context) {
                                                                return Container(
                                                                  color: Provider.of<ThemeProvider>(context, listen: false).themeData == lightMode ? Colors.white : Color(0xff0a0a0a),
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.all(16.0),
                                                                    child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Text("Distance", style: Theme.of(context).textTheme.titleLarge),
                                                                        Row(
                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                          children: [
                                                                            SizedBox(
                                                                              height: 200,
                                                                              width: 100,
                                                                              child: CupertinoPicker(
                                                                                backgroundColor: Provider.of<ThemeProvider>(context, listen: false).themeData == lightMode ? Colors.white : Color(0xff0a0a0a),
                                                                                itemExtent: 40,
                                                                                onSelectedItemChanged: (index) {
                                                                                  setState(() {
                                                                                    dist = index + (dist - dist.floor());
                                                                                  });
                                                                                },
                                                                                scrollController: FixedExtentScrollController(
                                                                                  initialItem: dist.floor(),
                                                                                ),
                                                                                children: zeroTo100,
                                                                              ),
                                                                            ),
                                                                            Text(".", style: Theme.of(context).textTheme.headlineLarge),
                                                                            SizedBox(
                                                                              height: 200,
                                                                              width: 100,
                                                                              child: CupertinoPicker(
                                                                                itemExtent: 40,
                                                                                onSelectedItemChanged: (index) {
                                                                                  setState(() {
                                                                                    dist = dist.floor() + index/100;
                                                                                  });
                                                                                },
                                                                                scrollController: FixedExtentScrollController(
                                                                                  initialItem: (((dist - dist.floor())*100).round()).toInt(),
                                                                                ),
                                                                                children: zeroTo100,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        MaterialButton(
                                                                          color: Theme.of(context).colorScheme.primary,
                                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                          child: Padding(
                                                                            padding: const EdgeInsets.all(6.0),
                                                                            child: Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                SizedBox(
                                                                                  child: Text(
                                                                                    "OK",
                                                                                    style: TextStyle(color: Colors.black),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          onPressed: () {
                                                                            if (dist != 0) {
                                                                              Navigator.pop(context);
                                                                            }
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            );
                                                          },
                                                          child: Text(
                                                            dist == 0 ? "—" : "${(dist*100).round()/100}",
                                                            textAlign: TextAlign.left,
                                                            style: TextStyle(
                                                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                              color: Theme.of(context).colorScheme.secondary,
                                                            ),
                                                          ),
                                                        ),
                                                      ]
                                                    ),
                                                    SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                "Time",
                                                                style: Theme.of(context).textTheme.titleMedium,
                                                              ),
                                                              Text(
                                                                "h:m:s",
                                                                textAlign: TextAlign.left,
                                                                style: TextStyle(
                                                                  fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                                  color: Theme.of(context).colorScheme.secondary,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        InkWell(
                                                          highlightColor: Colors.transparent,
                                                          hoverColor: Colors.transparent,
                                                          splashColor: Colors.transparent,
                                                          splashFactory: NoSplash.splashFactory,
                                                          onTap: () async {
                                                            showCupertinoModalPopup(
                                                              context: context,
                                                              builder: (context) {
                                                                return Container(
                                                                  color: Provider.of<ThemeProvider>(context, listen: false).themeData == lightMode ? Colors.white : Color(0xff0a0a0a),
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.all(16.0),
                                                                    child: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        Text("Time", style: Theme.of(context).textTheme.titleLarge),
                                                                        Row(
                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                          children: [
                                                                            SizedBox(
                                                                              height: 200,
                                                                              width: 100,
                                                                              child: CupertinoPicker(
                                                                                backgroundColor: Provider.of<ThemeProvider>(context, listen: false).themeData == lightMode ? Colors.white : Color(0xff0a0a0a),
                                                                                itemExtent: 40,
                                                                                onSelectedItemChanged: (index) {
                                                                                  setState(() {
                                                                                    hours = index;
                                                                                  });
                                                                                },
                                                                                scrollController: FixedExtentScrollController(
                                                                                  initialItem: hours,
                                                                                ),
                                                                                children: zeroTo60,
                                                                              ),
                                                                            ),
                                                                            Text(":", style: Theme.of(context).textTheme.headlineLarge),
                                                                            SizedBox(
                                                                              height: 200,
                                                                              width: 100,
                                                                              child: CupertinoPicker(
                                                                                itemExtent: 40,
                                                                                onSelectedItemChanged: (index) {
                                                                                  setState(() {
                                                                                    minutes = index;
                                                                                  });
                                                                                },
                                                                                scrollController: FixedExtentScrollController(
                                                                                  initialItem: minutes,
                                                                                ),
                                                                                children: zeroTo60,
                                                                              ),
                                                                            ),
                                                                            Text(":", style: Theme.of(context).textTheme.headlineLarge),
                                                                            SizedBox(
                                                                              height: 200,
                                                                              width: 100,
                                                                              child: CupertinoPicker(
                                                                                itemExtent: 40,
                                                                                onSelectedItemChanged: (index) {
                                                                                  setState(() {
                                                                                    seconds = index;
                                                                                  });
                                                                                },
                                                                                scrollController: FixedExtentScrollController(
                                                                                  initialItem: seconds,
                                                                                ),
                                                                                children: zeroTo60,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        MaterialButton(
                                                                          color: Theme.of(context).colorScheme.primary,
                                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                          child: Padding(
                                                                            padding: const EdgeInsets.all(6.0),
                                                                            child: Row(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                SizedBox(
                                                                                  child: Text(
                                                                                    "OK",
                                                                                    style: TextStyle(color: Colors.black),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          onPressed: () {
                                                                            if (hours + minutes + seconds > 0) {
                                                                              Navigator.pop(context);
                                                                            }
                                                                          },
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            );
                                                          },
                                                          child: Text(
                                                            hours*60*60 + minutes*60 + seconds == 0 ? "—" : secondsToTime(hours*60*60 + minutes*60 + seconds),
                                                            textAlign: TextAlign.left,
                                                            style: TextStyle(
                                                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                              color: Theme.of(context).colorScheme.secondary,
                                                            ),
                                                          ),
                                                        ),
                                                      ]
                                                    ),
                                                    SizedBox(height: 12),
                                                    MaterialButton(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(6.0),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            SizedBox(
                                                              child: Text(
                                                                "Save",
                                                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900,),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        if (dist > 0 && hours + minutes + seconds > 0) {
                                                          prs.remove(thisKey);
                                                          prs.addAll({"$dist$unit": hours*60*60 + minutes*60 + seconds});
                                                          prs = sortPRs(prs, userData.distUnit);
                                                          savePrs(sharedPreferences, prs);
                                                          Navigator.pop(context);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ),
                                          );
                                        }
                                      );
                                    }
                                  ).then((_) => setState(() {}));
                                },
                                onTap: () {
                                  if (showDetailedIndex != index) {
                                    setState(() => showDetailedIndex = index);
                                  } else {
                                    setState(() => showDetailedIndex = -1);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                                  child: Stack(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(
                                            "${thisKey.substring(thisKey.length-4, thisKey.length-2) == ".0" ?
                                              thisKey.substring(0, thisKey.length-4) : thisKey.substring(0, thisKey.length-2)} ${thisKey.substring(thisKey.length-2) == "mi" ? "mile" : "kilometer"}${double.parse(thisKey.substring(0, thisKey.length-4)) == 1 ? "" : "s"}",
                                            style: Theme.of(context).textTheme.titleMedium,
                                          )),
                                          Text(
                                            secondsToTime(prs.values.elementAt(index)),
                                            textAlign: TextAlign.left,
                                            style: TextStyle(
                                              fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              if (showDetailedIndex == index) {
                                                String key = prs.keys.elementAt(index);
                                                int value = prs.values.elementAt(index);
                                                return Text(
                                                  "${secondsToTime((value/toUserUnits(double.parse(key.substring(0, key.length-2)), key.substring(key.length-2), userData.distUnit)).round())}/${userData.distUnit}",
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                    color: Theme.of(context).colorScheme.secondary,
                                                  ),
                                                );
                                              }
                                              return Container();
                                            }
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      if (prs.isEmpty) {
                        return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Your PRs", textAlign: TextAlign.left, style: TextStyle(
                                  fontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
                                  fontWeight: FontWeight.w900,
                                ),),
                              ],
                            ),
                            SizedBox(height: 20),
                            Center(
                              child: Text("You have not added any PRs."),
                            ),
                          ],
                        ),
                      );
                      }
                      return Container();
                    },
                  ),
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: SizedBox(
                width: 150,
                height: 40,
                child: FloatingActionButton.extended(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  icon: Icon(Icons.add, color: Colors.black),
                  label: Text("Add a PR", style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  )),
                  onPressed: () {
                    double dist = 0;
                    String unit = userData.distUnit;
                    int hours = 0;
                    int minutes = 0;
                    int seconds = 0;
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Add a PR", style: Theme.of(context).textTheme.titleLarge),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Distance",
                                                  style: Theme.of(context).textTheme.titleMedium,
                                                ),
                                                InkWell(
                                                  highlightColor: Colors.transparent,
                                                  hoverColor: Colors.transparent,
                                                  splashColor: Colors.transparent,
                                                  splashFactory: NoSplash.splashFactory,
                                                  onTap: () {
                                                    if (unit == "mi") {
                                                      setState(() {
                                                        unit = "km";
                                                      });
                                                    } else {
                                                      setState(() {
                                                        unit = "mi";
                                                      });
                                                    }
                                                  },
                                                  child: Text(
                                                    unit == "mi" ? "Miles" : "Kilometers",
                                                    textAlign: TextAlign.left,
                                                    style: TextStyle(
                                                      fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                      color: Theme.of(context).colorScheme.secondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            highlightColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            splashColor: Colors.transparent,
                                            splashFactory: NoSplash.splashFactory,
                                            onTap: () async {
                                              showCupertinoModalPopup(
                                                context: context,
                                                builder: (context) {
                                                  return Container(
                                                    color: Provider.of<ThemeProvider>(context, listen: false).themeData == lightMode ? Colors.white : Color(0xff0a0a0a),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(16.0),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text("Distance", style: Theme.of(context).textTheme.titleLarge),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              SizedBox(
                                                                height: 200,
                                                                width: 100,
                                                                child: CupertinoPicker(
                                                                  backgroundColor: Provider.of<ThemeProvider>(context, listen: false).themeData == lightMode ? Colors.white : Color(0xff0a0a0a),
                                                                  itemExtent: 40,
                                                                  onSelectedItemChanged: (index) {
                                                                    setState(() {
                                                                      dist = index + (dist - dist.floor());
                                                                    });
                                                                  },
                                                                  scrollController: FixedExtentScrollController(
                                                                    initialItem: dist.floor(),
                                                                  ),
                                                                  children: zeroTo100,
                                                                ),
                                                              ),
                                                              Text(".", style: Theme.of(context).textTheme.headlineLarge),
                                                              SizedBox(
                                                                height: 200,
                                                                width: 100,
                                                                child: CupertinoPicker(
                                                                  itemExtent: 40,
                                                                  onSelectedItemChanged: (index) {
                                                                    setState(() {
                                                                      dist = dist.floor() + index/100;
                                                                    });
                                                                  },
                                                                  scrollController: FixedExtentScrollController(
                                                                    initialItem: (((dist - dist.floor())*100).round()).toInt(),
                                                                  ),
                                                                  children: zeroTo100,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          MaterialButton(
                                                            color: Theme.of(context).colorScheme.primary,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(6.0),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  SizedBox(
                                                                    child: Text(
                                                                      "OK",
                                                                      style: TextStyle(color: Colors.black),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              if (dist != 0) {
                                                                Navigator.pop(context);
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }
                                              );
                                            },
                                            child: Text(
                                              dist == 0 ? "—" : "${(dist*100).round()/100}",
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                        ]
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Time",
                                                  style: Theme.of(context).textTheme.titleMedium,
                                                ),
                                                Text(
                                                  "h:m:s",
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                    fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                    color: Theme.of(context).colorScheme.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            highlightColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            splashColor: Colors.transparent,
                                            splashFactory: NoSplash.splashFactory,
                                            onTap: () async {
                                              showCupertinoModalPopup(
                                                context: context,
                                                builder: (context) {
                                                  return Container(
                                                    color: Provider.of<ThemeProvider>(context, listen: false).themeData == lightMode ? Colors.white : Color(0xff0a0a0a),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(16.0),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text("Time", style: Theme.of(context).textTheme.titleLarge),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              SizedBox(
                                                                height: 200,
                                                                width: 100,
                                                                child: CupertinoPicker(
                                                                  backgroundColor: Provider.of<ThemeProvider>(context, listen: false).themeData == lightMode ? Colors.white : Color(0xff0a0a0a),
                                                                  itemExtent: 40,
                                                                  onSelectedItemChanged: (index) {
                                                                    setState(() {
                                                                      hours = index;
                                                                    });
                                                                  },
                                                                  scrollController: FixedExtentScrollController(
                                                                    initialItem: hours,
                                                                  ),
                                                                  children: zeroTo60,
                                                                ),
                                                              ),
                                                              Text(":", style: Theme.of(context).textTheme.headlineLarge),
                                                              SizedBox(
                                                                height: 200,
                                                                width: 100,
                                                                child: CupertinoPicker(
                                                                  itemExtent: 40,
                                                                  onSelectedItemChanged: (index) {
                                                                    setState(() {
                                                                      minutes = index;
                                                                    });
                                                                  },
                                                                  scrollController: FixedExtentScrollController(
                                                                    initialItem: minutes,
                                                                  ),
                                                                  children: zeroTo60,
                                                                ),
                                                              ),
                                                              Text(":", style: Theme.of(context).textTheme.headlineLarge),
                                                              SizedBox(
                                                                height: 200,
                                                                width: 100,
                                                                child: CupertinoPicker(
                                                                  itemExtent: 40,
                                                                  onSelectedItemChanged: (index) {
                                                                    setState(() {
                                                                      seconds = index;
                                                                    });
                                                                  },
                                                                  scrollController: FixedExtentScrollController(
                                                                    initialItem: seconds,
                                                                  ),
                                                                  children: zeroTo60,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          MaterialButton(
                                                            color: Theme.of(context).colorScheme.primary,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(6.0),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  SizedBox(
                                                                    child: Text(
                                                                      "OK",
                                                                      style: TextStyle(color: Colors.black),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            onPressed: () {
                                                              if (hours + minutes + seconds > 0) {
                                                                Navigator.pop(context);
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }
                                              );
                                            },
                                            child: Text(
                                              hours*60*60 + minutes*60 + seconds == 0 ? "—" : secondsToTime(hours*60*60 + minutes*60 + seconds),
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                fontSize: Theme.of(context).textTheme.titleMedium!.fontSize,
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                        ]
                                      ),
                                      SizedBox(height: 12),
                                      MaterialButton(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                child: Text(
                                                  "Save",
                                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900,),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onPressed: () {
                                          if (dist > 0 && hours + minutes + seconds > 0) {
                                            prs.addAll({"$dist$unit": hours*60*60 + minutes*60 + seconds});
                                            prs = sortPRs(prs, userData.distUnit);
                                            savePrs(sharedPreferences, prs);
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              ),
                            );
                          }
                        );
                      }
                    ).then((_) => setState(() {}));
                  },
                ),
              )
            );
          }
        );
      }
    );
  }
}