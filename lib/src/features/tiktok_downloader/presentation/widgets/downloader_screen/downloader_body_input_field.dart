import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importa el paquete de servicios

import '../../../../../core/utils/app_strings.dart';

class DownloaderBodyInputField extends StatelessWidget {
  final TextEditingController videoLinkController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSearch;

  const DownloaderBodyInputField({
    super.key,
    required this.videoLinkController,
    required this.formKey,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Form(
            key: formKey,
            child: TextFormField(
              controller: videoLinkController,
              keyboardType: TextInputType.url,
              validator: (String? value) {
                if (value!.isEmpty) return AppStrings.videoLinkRequired;
                return null;
              },
              decoration: const InputDecoration(
                hintText: AppStrings.inputLinkFieldText,
              ),
            ),
          ),
          const SizedBox(height: 16), // Espacio entre el TextFormField y los IconButton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () async {
                    ClipboardData? clipboardData = await Clipboard.getData('text/plain');
                    if (clipboardData != null) {
                      videoLinkController.text = clipboardData.text ?? '';
                    }
                  },
                  icon: const Icon(Icons.paste),
                  tooltip: 'Pegar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
