// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:html';
import 'SplitWidget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web.examples.github_dataviz/constants.dart';
import 'package:flutter_web.examples.github_dataviz/data/contribution_data.dart';
import 'package:flutter_web.examples.github_dataviz/data/data_series.dart';
import 'package:flutter_web.examples.github_dataviz/data/stat_for_week.dart';
import 'package:flutter_web.examples.github_dataviz/data/user_contribution.dart';
import 'package:flutter_web.examples.github_dataviz/data/week_label.dart';
import 'package:flutter_web.examples.github_dataviz/layered_chart.dart';
import 'package:flutter_web.examples.github_dataviz/mathutils.dart';
import 'package:flutter_web.examples.github_dataviz/timeline.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => new _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  AnimationController _animation;
  List<UserContribution> contributions;
  List<StatForWeek> starsByWeek;
  List<StatForWeek> forksByWeek;
  List<StatForWeek> pushesByWeek;
  List<StatForWeek> issueCommentsByWeek;
  List<StatForWeek> pullRequestActivityByWeek;
  List<WeekLabel> weekLabels;

  static final double earlyInterpolatorFraction = 0.8;
  static final EarlyInterpolator interpolator =
      new EarlyInterpolator(earlyInterpolatorFraction);
  double animationValue = 1.0;
  double interpolatedAnimationValue = 1.0;
  bool timelineOverride = false;
  String _blogUrl = 'https://parellelmemory.blogspot.com/';
  String _strUrl = 'https://parallelmemory.mystrikingly.com/';

  @override
  void initState() {
    super.initState();

    createAnimation(0);

    weekLabels = [];
    // weekLabels.add(WeekLabel.forDate(new DateTime(2019, 2, 26), "v1.2"));
    // weekLabels.add(WeekLabel.forDate(new DateTime(2018, 12, 4), "v1.0"));
    weekLabels.add(WeekLabel.forDate(new DateTime(2021, 4, 1), "2.0"));
    weekLabels.add(WeekLabel.forDate(new DateTime(2020, 6, 1), "Fit 4 Start"));
    weekLabels.add(WeekLabel.forDate(new DateTime(2019, 8, 1), "1.0"));
    weekLabels
        .add(WeekLabel.forDate(new DateTime(2018, 10, 1), "MassChallenge"));
    // weekLabels.add(WeekLabel.forDate(new DateTime(2018, 1, 1), "0.1"));
    //weekLabels.add(new WeekLabel(48, "Parellel Memory"));

    loadGitHubData();
  }

  void createAnimation(double startValue) {
    _animation?.dispose();
    _animation = new AnimationController(
      value: startValue,
      duration: const Duration(milliseconds: 14400),
      vsync: this,
    )..repeat();
    _animation.addListener(() {
      setState(() {
        if (!timelineOverride) {
          animationValue = _animation.value;
          interpolatedAnimationValue = interpolator.get(animationValue);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Combined contributions data
    List<DataSeries> dataToPlot = [];
    if (contributions != null) {
      List<int> series = [];
      for (UserContribution userContrib in contributions) {
        for (int i = 0; i < userContrib.contributions.length; i++) {
          ContributionData data = userContrib.contributions[i];
          if (series.length > i) {
            series[i] = series[i] + data.add;
          } else {
            series.add(data.add);
          }
        }
      }
      dataToPlot.add(new DataSeries("E.U.", series));
    }

    if (starsByWeek != null) {
      dataToPlot.add(
          new DataSeries("KOSPI", starsByWeek.map((e) => e.stat).toList()));
    }

    if (forksByWeek != null) {
      dataToPlot.add(new DataSeries(
          "Emerging-Asia", forksByWeek.map((e) => e.stat).toList()));
    }

    if (pushesByWeek != null) {
      dataToPlot.add(new DataSeries(
          "Emerging-America", pushesByWeek.map((e) => e.stat).toList()));
    }

    if (issueCommentsByWeek != null) {
      dataToPlot.add(new DataSeries(
          "ASIA TOP 50", issueCommentsByWeek.map((e) => e.stat).toList()));
    }

    if (pullRequestActivityByWeek != null) {
      dataToPlot.add(new DataSeries(
          "U.S.", pullRequestActivityByWeek.map((e) => e.stat).toList()));
    }

    LayeredChart layeredChart =
        new LayeredChart(dataToPlot, weekLabels, interpolatedAnimationValue);

    const double timelinePadding = 60.0;

    var timeline = new Timeline(
      numWeeks: dataToPlot != null && dataToPlot.length > 0
          ? dataToPlot.last.series.length
          : 0,
      animationValue: interpolatedAnimationValue,
      weekLabels: weekLabels,
      mouseDownCallback: (double xFraction) {
        setState(() {
          timelineOverride = true;
          _animation.stop();
          interpolatedAnimationValue = xFraction;
        });
      },
      mouseMoveCallback: (double xFraction) {
        setState(() {
          interpolatedAnimationValue = xFraction;
        });
      },
      mouseUpCallback: () {
        setState(() {
          timelineOverride = false;
          createAnimation(
              interpolatedAnimationValue * earlyInterpolatorFraction);
        });
      },
    );

    Column mainColumn = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Expanded(child: layeredChart),
        // Padding(
        //   padding: const EdgeInsets.only(
        //       left: timelinePadding,
        //       right: timelinePadding,
        //       bottom: timelinePadding),
        //   child: timeline,
        // ),
      ],
    );

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Welcome to Para\'llel Memory',
        home: Scaffold(
          body: Container(
              child: SplitWidget(
                  childFirst: new Container(
                    color: Constants.backgroundColor,
                    child: new Directionality(
                        textDirection: TextDirection.ltr, child: mainColumn),
                  ),
                  childSecond: SplitVerticalWidget(
                    childTop: InkWell(
                      child: Image.asset('images/s1.png', fit: BoxFit.fill),
                      onTap: _goBlog,
                      // width: 640,
                      // height: 320,
                    ),
                    childBottom: InkWell(
                      child: Image.asset('images/s2.png', fit: BoxFit.fill),
                      onTap: _goStrikingly,
                      //width: 640,
                      //height: 320,
                    ),
                  ))),
          bottomNavigationBar: BottomNavigationBar(
            onTap: (int idx) {},
            items: [
              BottomNavigationBarItem(
                  label: 'This webpage could not support mobile now.',
                  icon: Icon(Icons.chat_bubble)),
              BottomNavigationBarItem(
                  label: 'Copyright © ParallelMemory Inc. All rights reserved.',
                  icon: Icon(Icons.emoji_events))
            ],
          ),
        ));
  }

  _goBlog() async =>
      await canLaunch(_blogUrl) ? await launch(_blogUrl) : throw 'err';
  _goStrikingly() async =>
      await canLaunch(_strUrl) ? await launch(_strUrl) : throw 'err';

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Future loadGitHubData() async {
    String contributorsJsonStr =
        await HttpRequest.getString("/github_data/contributors.json");
    List jsonObjs = jsonDecode(contributorsJsonStr) as List;
    List<UserContribution> contributionList =
        jsonObjs.map((e) => UserContribution.fromJson(e)).toList();
    print(
        "Loaded ${contributionList.length} code contributions to /flutter/flutter repo.");

    int numWeeksTotal = contributionList[0].contributions.length;

    String starsByWeekStr =
        await HttpRequest.getString("/github_data/stars.tsv");
    List<StatForWeek> starsByWeekLoaded =
        summarizeWeeksFromTSV(starsByWeekStr, numWeeksTotal);

    String forksByWeekStr =
        await HttpRequest.getString("/github_data/forks.tsv");
    List<StatForWeek> forksByWeekLoaded =
        summarizeWeeksFromTSV(forksByWeekStr, numWeeksTotal);

    String commitsByWeekStr =
        await HttpRequest.getString("/github_data/commits.tsv");
    List<StatForWeek> commitsByWeekLoaded =
        summarizeWeeksFromTSV(commitsByWeekStr, numWeeksTotal);

    String commentsByWeekStr =
        await HttpRequest.getString("/github_data/comments.tsv");
    List<StatForWeek> commentsByWeekLoaded =
        summarizeWeeksFromTSV(commentsByWeekStr, numWeeksTotal);

    String pullRequestActivityByWeekStr =
        await HttpRequest.getString("/github_data/pull_requests.tsv");
    List<StatForWeek> pullRequestActivityByWeekLoaded =
        summarizeWeeksFromTSV(pullRequestActivityByWeekStr, numWeeksTotal);

    setState(() {
      this.contributions = contributionList;
      this.starsByWeek = starsByWeekLoaded;
      this.forksByWeek = forksByWeekLoaded;
      this.pushesByWeek = commitsByWeekLoaded;
      this.issueCommentsByWeek = commentsByWeekLoaded;
      this.pullRequestActivityByWeek = pullRequestActivityByWeekLoaded;
    });
  }

  List<StatForWeek> summarizeWeeksFromTSV(
      String statByWeekStr, int numWeeksTotal) {
    List<StatForWeek> loadedStats = new List();
    HashMap<int, StatForWeek> statMap = new HashMap();
    statByWeekStr.split("\n").forEach((s) {
      List<String> split = s.split("\t");
      if (split.length == 2) {
        int weekNum = int.parse(split[0]);
        statMap[weekNum] = new StatForWeek(weekNum, int.parse(split[1]));
      }
    });
    print("Loaded ${statMap.length} weeks.");
    // Convert into a list by week, but fill in empty weeks with 0
    for (int i = 0; i < numWeeksTotal; i++) {
      StatForWeek starsForWeek = statMap[i];
      if (starsForWeek == null) {
        loadedStats.add(new StatForWeek(i, 0));
      } else {
        loadedStats.add(starsForWeek);
      }
    }
    return loadedStats;
  }
}

void main() {
  runApp(SizedBox(
    child: MainLayout(),
    height: 1200,
    width: 960,
  ));
}
