Future<void> _publishUpdate() async {
    final urlCtrl = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Publier une nouvelle version'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
              labelText: 'Lien de téléchargement du nouvel APK'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, urlCtrl.text.trim()),
              child: const Text('Publier')),
        ],
      ),
    );
    if (link == null || link.isEmpty) return;
    final v = await _fs.getJSON('appVersion', {'v': 1, 'url': ''});
    await _fs.setJSON(
        'appVersion', {'v': (v['v'] ?? 1) + 1, 'url': link});
    SoundService.instance.playSuccess();
}
