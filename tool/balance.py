import sys

path = sys.argv[1]
src = open(path, encoding='utf-8').read().split('\n')
stack = []


def strip(line):
    out = []
    j = 0
    n = len(line)
    while j < n:
        c = line[j]
        if c == '/' and j + 1 < n and line[j + 1] == '/':
            break
        if c == "'" or c == '"':
            q = c
            k = j + 1
            while k < n and line[k] != q:
                if line[k] == chr(92):
                    k += 1
                k += 1
            j = k + 1
            continue
        out.append(c)
        j += 1
    return ''.join(out)


for idx, line in enumerate(src, start=1):
    s = strip(line)
    for ch in s:
        if ch in '([{':
            stack.append((ch, idx))
        elif ch in ')]}':
            if not stack:
                print('UNDERFLOW at line', idx, repr(line))
                stack = []
            else:
                stack.pop()
    if idx in (1529, 1530, 1645, 1646, 1647, 1650, 1660, 1680, 1700, 1750, 1800):
        print('after line', idx, 'depth', len(stack), 'top', stack[-1] if stack else None)
print('final depth', len(stack))
print('remaining (last 8):', stack[-8:])
