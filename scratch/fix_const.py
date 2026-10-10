import os

files = []
for root, dirs, fs in os.walk('C:/Translator/lib'):
    for f in fs:
        if f.endswith('.dart'):
            files.append(os.path.join(root, f))

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    content = content.replace('const TextStyle(color: context.booth', 'TextStyle(color: context.booth')
    content = content.replace('const BorderSide(color: context.booth', 'BorderSide(color: context.booth')
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
