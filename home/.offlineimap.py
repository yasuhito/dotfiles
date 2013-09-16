from offlineimap import imaputil
import re

high = ['^important$', '^work$']
low = ['^archives', '^spam$']

def mycmp(x, y):
    for r in high:
        xm = re.search (r, x)
        ym = re.search (r, y)
        if xm and ym:
            return cmp(x, y)
        elif xm:
            return -1
        elif ym:
            return +1
    for r in low:
        xm = re.search (r, x)
        ym = re.search (r, y)
        if xm and ym:
            return cmp(x, y)
        elif xm:
            return +1
        elif ym:
            return -1
    return cmp(x, y)
