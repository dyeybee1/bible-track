import 'package:flutter/material.dart';

import '../../settings_scope.dart';

class TextSourcesScreen extends StatelessWidget {
  const TextSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.textSources)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              s.webSourceTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(s.webSourceBody),
            const SizedBox(height: 8),
            const SelectableText('https://ebible.org/eng-web-c/'),
            const SizedBox(height: 12),
            Text(s.webTrademarkNote),
            const Divider(height: 36),
            Text(
              'Ang Dating Biblia (1905)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(s.tagalogSourceBody),
            const SizedBox(height: 8),
            const SelectableText(
              'https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=TagAngBiblia',
            ),
            const SizedBox(height: 8),
            const SelectableText('https://api.getbible.net/v2/tagalog.json'),
            const Divider(height: 36),
            Text(s.sourcesEnglishNote),
          ],
        ),
      ),
    );
  }
}
