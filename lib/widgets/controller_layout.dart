/*import 'package:flutter/material.dart';
import '../theme/controller_theme.dart';
import '../services/socket_service.dart';
import 'analog_stick.dart';
import 'face_buttons.dart';
import 'dpad.dart';
import 'triggers.dart';

class ControllerLayout extends StatelessWidget {
  final SocketService socketService;

  const ControllerLayout({
    Key? key,
    required this.socketService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          // Stick sinistro
          Positioned(
            left: size.width * 0.05,
            top: size.height * 0.3,
            child: AnalogStick(
              onInput: (x, y) =>
                  socketService.sendAnalogInput('left-stick', x, y),
            ),
          ),
          // D-pad
          Positioned(
            left: size.width * 0.25,
            top: size.height * 0.3,
            child: Dpad(
              onDirectionPressed: (direction) =>
                  socketService.sendDpadInput(direction),
            ),
          ),
          // Pulsanti faccia (A,B,X,Y)
          Positioned(
            right: size.width * 0.05,
            top: size.height * 0.3,
            child: FaceButtons(
              onButtonPressed: (button) =>
                  socketService.sendButtonInput(button),
            ),
          ),
          // Stick destro
          Positioned(
            right: size.width * 0.25,
            top: size.height * 0.3,
            child: AnalogStick(
              onInput: (x, y) =>
                  socketService.sendAnalogInput('right-stick', x, y),
            ),
          ),
          // Triggers e bumper
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Triggers(
              onTriggerInput: (trigger, value) =>
                  socketService.sendTriggerInput(trigger, value),
            ),
          ),
        ],
      ),
    );
  }
}
*/
