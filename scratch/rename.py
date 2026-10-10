import os

def replace_in_file(path, old, new):
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(old, new)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

replace_in_file('C:/Translator/android/app/src/main/AndroidManifest.xml', 'android:label="Phiên dịch"', 'android:label="phiendich"')
replace_in_file('C:/Translator/ios/Runner/Info.plist', '<string>Phiên dịch</string>', '<string>phiendich</string>')
replace_in_file('C:/Translator/lib/app.dart', "title: 'Phiên dịch'", "title: 'phiendich'")
replace_in_file('C:/Translator/web/index.html', '<title>translator</title>', '<title>phiendich</title>')
replace_in_file('C:/Translator/web/index.html', 'content="translator"', 'content="phiendich"')

print("Done")
