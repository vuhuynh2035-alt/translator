import os

replacements = {
    'lib/ui/booth_widgets.dart': [
        ('side: $1,', 'side: BorderSide(color: context.booth.line),', 1)
    ],
    'lib/ui/continuous_page.dart': [
        ('style: $1,', 'style: TextStyle(color: context.booth.mute),', 1), # line 106
        ('style: $1,', 'style: TextStyle(color: context.booth.mute, fontSize: 16, height: 1.35),', 1), # line 125
        ('style: $1,', 'style: TextStyle(color: context.booth.mute, height: 1.3),', 1), # line 164
    ],
    'lib/ui/home_page.dart': [
        ('style: $1,', 'style: TextStyle(color: context.booth.mute),', 1), # line 55
        ('style: $1)', 'style: TextStyle(color: context.booth.mute, height: 1.4))', 1), # line 133
    ],
    'lib/ui/settings_page.dart': [
        ('style: $1)', 'style: TextStyle(color: context.booth.mute))', 3), # lines 134, 150, 163
        ('style: $1,', 'style: TextStyle(color: context.booth.mute, height: 1.35),', 1), # line 197
    ],
    'lib/ui/two_way_page.dart': [
        ('style: $1)', 'style: TextStyle(color: context.booth.mute))', 1), # line 52
        ('style: $1,', 'style: TextStyle(color: context.booth.mute, height: 1.35),', 1), # line 70
        ('style: $1,', 'style: TextStyle(color: context.booth.mute, fontSize: 12),', 1), # line 87
        ('style: $1,', 'style: TextStyle(color: context.booth.mute, height: 1.35),', 1), # line 105
    ]
}

for rel_path, reps in replacements.items():
    path = os.path.join('C:/Translator', rel_path)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new, count in reps:
        content = content.replace(old, new, count)
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
