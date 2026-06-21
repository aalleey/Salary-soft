import os
import re

def main():
    directory = 'lib'
    pattern = re.compile(r'\.withOpacity\(([^)]+)\)')
    
    total_subs = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content, num_subs = pattern.subn(r'.withValues(alpha: \1)', content)
                
                if num_subs > 0:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f'Updated {filepath} ({num_subs} replacements)')
                    total_subs += num_subs

    print(f'Total replacements: {total_subs}')

if __name__ == '__main__':
    main()
