import os

files_to_fix = [
    ('lib/features/project/cost_estimation_screen.dart', '$${', '\\$${'), 
    ('lib/features/providers/provider_listing_screen.dart', '$5k', '\\$5k'),
    ('lib/features/home/main_layout.dart', '../services/services_screen.dart', '../../services/services_screen.dart'),
    ('lib/core/theme.dart', 'CardTheme(', 'CardThemeData(')
]

for fp, old, new in files_to_fix:
    try:
        with open(fp, 'r', encoding='utf-8') as f: content = f.read()
    except UnicodeDecodeError:
        with open(fp, 'r', encoding='cp1252') as f: content = f.read()
    content = content.replace(old, new)
    with open(fp, 'w', encoding='utf-8') as f:
        f.write(content)
print('Fixes applied.')
