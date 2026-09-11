import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Privacy')), body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: Column(children: [
        SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Show online status'), subtitle: const Text('Let contacts see when you are online.')),
        const Divider(height: 1),
        SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Allow call notifications'), subtitle: const Text('Receive incoming-call alerts.')),
        const Divider(height: 1),
        const ListTile(leading: Icon(Icons.lock_outline), title: Text('Call media'), subtitle: Text('Audio and video are delivered by ZEGOCLOUD realtime services.')),
      ])),
      const SizedBox(height: 16),
      const Text('For a production deployment, add a full privacy policy, consent wording, retention rules and legal disclosure before enabling recording or other advanced features.'),
    ]));
  }
}
