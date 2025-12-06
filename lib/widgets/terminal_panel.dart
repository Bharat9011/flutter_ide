import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laravelide/GetProvider/new_project_getx_provider.dart';
import 'package:laravelide/widgets/terminal/terminal_cmd_debug.dart';
import 'package:laravelide/widgets/terminal/terminal_cmd_output.dart';
import 'package:laravelide/widgets/terminal/terminal_cmd_problem.dart';
import 'package:laravelide/widgets/terminal/terminal_cmd_terminal.dart';

class TerminalPanel extends StatefulWidget {
  TerminalPanel({super.key, required this.projectPath});

  String projectPath;

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  int terminalIndex = 0;

  bool isHoverProblem = false,
      isHoverDebug = false,
      isHoverTerminal = false,
      isHoverOutput = false;
  bool isSelectProblem = true,
      isSelectDebug = false,
      isSelectTerminal = false,
      isSelectOutput = false;

  void checkNewProjectCreatedOrNot() {
    var newProjectController = Get.put(NewProjectGetxProvider());

    if (newProjectController.isCreated.value) {
      terminalIndex = 2;
      isSelectOutput = true;
      isSelectDebug = false;
      isSelectProblem = false;
      isSelectTerminal = false;
    }
  }

  @override
  void initState() {
    super.initState();
    checkNewProjectCreatedOrNot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: EdgeInsets.all(5),
            child: Row(
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() {
                    isHoverProblem = true;
                  }),
                  onExit: (_) => setState(() {
                    isHoverProblem = false;
                  }),
                  child: InkWell(
                    onTap: () => setState(() {
                      terminalIndex = 0;
                      isSelectOutput = false;
                      isSelectProblem = true;
                      isSelectDebug = false;
                      isSelectTerminal = false;
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelectProblem
                            ? Colors.lightBlue
                            : isHoverProblem
                            ? Colors.lightBlue
                            : Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "Problem",
                        style: isSelectProblem
                            ? textStyleBlack()
                            : isHoverProblem
                            ? textStyleBlack()
                            : textStylewhite(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                MouseRegion(
                  onEnter: (_) => setState(() {
                    isHoverDebug = true;
                  }),
                  onExit: (_) => setState(() {
                    isHoverDebug = false;
                  }),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        terminalIndex = 1;
                        isSelectDebug = true;
                        isSelectOutput = false;
                        isSelectProblem = false;
                        isSelectTerminal = false;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelectDebug
                            ? Colors.lightBlue
                            : isHoverDebug
                            ? Colors.lightBlue
                            : Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "Debug",
                        style: isSelectDebug
                            ? textStyleBlack()
                            : isHoverDebug
                            ? textStyleBlack()
                            : textStylewhite(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                MouseRegion(
                  onEnter: (_) => setState(() {
                    isHoverOutput = true;
                  }),
                  onExit: (_) => setState(() {
                    isHoverOutput = false;
                  }),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        terminalIndex = 2;
                        isSelectOutput = true;
                        isSelectDebug = false;
                        isSelectProblem = false;
                        isSelectTerminal = false;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelectOutput
                            ? Colors.lightBlue
                            : isHoverOutput
                            ? Colors.lightBlue
                            : Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "Output",
                        style: isSelectOutput
                            ? textStyleBlack()
                            : isHoverOutput
                            ? textStyleBlack()
                            : textStylewhite(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                MouseRegion(
                  onEnter: (_) => setState(() {
                    isHoverTerminal = true;
                  }),
                  onExit: (_) => setState(() {
                    isHoverTerminal = false;
                  }),
                  child: InkWell(
                    onTap: () => setState(() {
                      terminalIndex = 3;
                      isSelectTerminal = true;
                      isSelectDebug = false;
                      isSelectOutput = false;
                      isSelectProblem = false;
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelectTerminal
                            ? Colors.lightBlue
                            : isHoverTerminal
                            ? Colors.lightBlue
                            : Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "Terminal",
                        style: isSelectTerminal
                            ? textStyleBlack()
                            : isHoverTerminal
                            ? textStyleBlack()
                            : textStylewhite(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _showSelectedTerminal()),
        ],
      ),
    );
  }

  Widget _showSelectedTerminal() {
    switch (terminalIndex) {
      case 0:
        return TerminalCmdProblem(projectPath: widget.projectPath);
      case 1:
        return TerminalCmdDebug(projectPath: widget.projectPath);
      case 2:
        return TerminalCmdOutput(projectPath: widget.projectPath);
      case 3:
        return TerminalCmdTerminal(projectPath: widget.projectPath);
      default:
        return TerminalCmdProblem(projectPath: widget.projectPath);
    }
  }

  TextStyle textStyleBlack() {
    return TextStyle(
      color: Colors.black,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
  }

  TextStyle textStylewhite() {
    return TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
  }
}
