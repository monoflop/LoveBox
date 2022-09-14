import 'package:flutter/material.dart';

class PasswordTextFormField extends StatefulWidget {
  final Function(String? value) onSaved;

  const PasswordTextFormField({required this.onSaved, Key? key})
      : super(key: key);

  @override
  PasswordTextFormFieldState createState() => PasswordTextFormFieldState();
}

class PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textInputAction: TextInputAction.done,
      obscureText: _obscureText,
      enableSuggestions: false,
      autocorrect: false,
      maxLines: 1,
      decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: "Password",
          suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              })),
      // The validator receives the text that the user has entered.
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter password";
        }
        return null;
      },
      onSaved: widget.onSaved,
    );
  }
}
