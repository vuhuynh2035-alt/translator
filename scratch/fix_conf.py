import os

path = 'C:/Translator/lib/ui/conference_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('ContinuousPage', 'ConferencePage')
content = content.replace('ContinuousSession', 'ConferenceSession')
content = content.replace("import '../session/continuous_session.dart';", "import '../session/conference_session.dart';")
content = content.replace("title: const Text('Liên tục'),", "title: const Text('Hội thảo'),")
content = content.replace('Cuộc hội thoại Liên tục', 'Cuộc hội thoại Hội thảo')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
