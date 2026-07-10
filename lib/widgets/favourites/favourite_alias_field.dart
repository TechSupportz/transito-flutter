import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:transito/models/favourites/favourite.dart';

class FavouriteAliasField extends StatelessWidget {
  const FavouriteAliasField({
    super.key,
    required this.controller,
    required this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      maxLength: Favourite.aliasMaxLength,
      maxLines: 1,
      inputFormatters: [
        LengthLimitingTextInputFormatter(Favourite.aliasMaxLength),
        FilteringTextInputFormatter.deny(RegExp(r'[\n\r\u0000-\u001F\u007F]')),
      ],
      decoration: const InputDecoration(
        labelText: 'Alias (optional)',
        hintText: 'e.g. Home',
        helperText: 'Give a custom name to this bus stop',
      ),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }
}

@Preview(name: 'Favourite alias field', group: 'Favourites', size: Size(390, 180))
Widget favouriteAliasFieldPreview() {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FavouriteAliasField(
          controller: TextEditingController(text: 'Home'),
          validator: (_) => null,
        ),
      ),
    ),
  );
}
