import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'add_match_widget.dart' show AddMatchWidget;

class AddMatchModel extends FlutterFlowModel<AddMatchWidget> {
  FocusNode? playerNameFocusNode;
  TextEditingController? playerNameTextController;
  String? Function(BuildContext, String?)? playerNameTextControllerValidator;
  FocusNode? opponentNameFocusNode;
  TextEditingController? opponentNameTextController;
  String? Function(BuildContext, String?)? opponentNameTextControllerValidator;
  FocusNode? partnerNameFocusNode;
  TextEditingController? partnerNameTextController;
  String? Function(BuildContext, String?)? partnerNameTextControllerValidator;
  FocusNode? opponentPartnerNameFocusNode;
  TextEditingController? opponentPartnerNameTextController;
  String? Function(BuildContext, String?)? opponentPartnerNameTextControllerValidator;
  FocusNode? notesTextFieldFocusNode;
  TextEditingController? notesTextFieldTextController;
  String? Function(BuildContext, String?)? notesTextFieldTextControllerValidator;
  String? matchTypeValue;
  FormFieldController<String>? matchTypeValueController;
  String? matchFormatValue;
  FormFieldController<String>? matchFormatValueController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    playerNameFocusNode?.dispose();
    playerNameTextController?.dispose();
    opponentNameFocusNode?.dispose();
    opponentNameTextController?.dispose();
    partnerNameFocusNode?.dispose();
    partnerNameTextController?.dispose();
    opponentPartnerNameFocusNode?.dispose();
    opponentPartnerNameTextController?.dispose();
    notesTextFieldFocusNode?.dispose();
    notesTextFieldTextController?.dispose();
  }
}
