"""Small JSONC editor: retain comments/formatting outside the edited members.

No evaluation, external dependency, or regular-expression comment stripping.
"""
import json


class Document:
    def __init__(self, text):
        self.text, self.i, self.spans, self.members = text, 0, {}, {}
        self.data = self.value(())
        self.space()
        if self.i != len(text): raise ValueError('Trailing JSONC content')

    def space(self):
        while self.i < len(self.text):
            if self.text[self.i].isspace(): self.i += 1
            elif self.text.startswith('//', self.i):
                end = self.text.find('\n', self.i)
                self.i = len(self.text) if end < 0 else end + 1
            elif self.text.startswith('/*', self.i):
                end = self.text.find('*/', self.i + 2)
                if end < 0: raise ValueError('Unterminated JSONC comment')
                self.i = end + 2
            else: break

    def value(self, path):
        self.space(); start = self.i
        if self.i >= len(self.text): raise ValueError('Incomplete JSONC')
        char = self.text[self.i]
        if char in '{[':
            obj = char == '{'; close = '}' if obj else ']'
            result = {} if obj else []; self.i += 1; self.space()
            previous_end = None
            while self.i < len(self.text) and self.text[self.i] != close:
                member_start = self.i
                if obj:
                    key, self.i = json.JSONDecoder().raw_decode(self.text, self.i)
                    if not isinstance(key, str) or key in result: raise ValueError('Invalid/duplicate JSONC key')
                    self.space()
                    if self.text[self.i:self.i+1] != ':': raise ValueError('Expected JSONC colon')
                    self.i += 1
                else: key = len(result)
                value = self.value(path + (key,))
                if obj: result[key] = value
                else: result.append(value)
                end = self.i; self.space()
                comma = self.text[self.i:self.i+1] == ','
                self.members[path + (key,)] = (member_start, self.i + 1 if comma else end, previous_end, comma)
                previous_end = end
                if not comma: break
                self.i += 1; self.space()
            if self.text[self.i:self.i+1] != close: raise ValueError('Expected JSONC closing bracket')
            self.i += 1
        else:
            result, self.i = json.JSONDecoder().raw_decode(self.text, self.i)
        self.spans[path] = (start, self.i)
        return result

    def get(self, path):
        value = self.data
        for key in path: value = value[key]
        return value

    def set(self, path, value, remove=False):
        if path in self.spans:
            start, end = self.spans[path]
            if remove:
                start, end, previous, comma = self.members[path]
                if not comma and previous is not None: start = previous
                replacement = ''
            else: replacement = json.dumps(value, ensure_ascii=False)
        elif remove: return self.text
        else:
            parent = path[:-1]
            if parent not in self.spans:
                return self.set(parent, {path[-1]: value})
            data = self.get(parent)
            if not isinstance(data, dict): raise ValueError('Expected JSONC object')
            _, end = self.spans[parent]; start = end = end - 1
            # Existing trailing commas are legal JSONC. Inspect the last member,
            # not text/comments, to avoid accidentally adding a second comma.
            comma = bool(data) and not self.members[parent + (next(reversed(data)),)][3]
            replacement = (',' if comma else '') + '\n' + json.dumps(path[-1]) + ': ' + json.dumps(value, ensure_ascii=False) + '\n'
        result = self.text[:start] + replacement + self.text[end:]
        Document(result)  # validate before any filesystem write
        return result
