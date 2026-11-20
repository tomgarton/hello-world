import sys
ROOT = sys.argv[1]
src = open(ROOT + '/gen/iconsys3.py').read(); src = src[:src.index('ICONS = [')]
x = {'__name__': 'x', 'sys': sys}; exec(src.replace("ROOT = sys.argv[1]", f"ROOT = {ROOT!r}"), x)
ln, fill, both, rr, circ, L, A = x['ln'], x['fill'], x['both'], x['rr'], x['circ'], x['L'], x['A']
BODY = 'M4.800 17.800C4.600 13.500 4.800 9.300 6.100 7C7.200 5.100 9.900 4.800 11.200 6.500C12 7.700 12.500 9.300 14.400 9.500C15.900 9.700 16.700 8.900 17.900 9.400C19.300 10 19.300 12.200 19.200 17.800'
C = {
 'po_f': ln(rr(3.300, 17.800, 17.400, 2.700, 1.350)) + ln(BODY) + ln('M7.300 8.800C7.700 10.900 8.600 12.200 9.700 12.500') +
         '<ellipse cx="13.300" cy="12.400" rx="3.500" ry="1.350" fill="#F4BE2C"></ellipse><ellipse cx="13.300" cy="12.400" rx="3.500" ry="1.350" ' + L + '></ellipse>',
 'po_g': fill(rr(3.300, 17.800, 17.400, 2.700, 1.350)) + ln(rr(3.300, 17.800, 17.400, 2.700, 1.350)) + ln(BODY) + ln('M7.300 8.800C7.700 10.900 8.600 12.200 9.700 12.500') +
         '<ellipse cx="13.300" cy="12.400" rx="3.500" ry="1.350" ' + L + '></ellipse>',
}
def big(k, s):
    return f'<div style="display:flex;flex-direction:column;align-items:center;gap:4px"><svg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 24 24" style="background:#FBF6E9">{s}</svg><div style="display:flex;gap:10px;align-items:center"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">{s}</svg><svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24">{s}</svg></div><div style="font:600 13px sans-serif">{k}</div></div>'
open(ROOT + '/gen/study.html', 'w').write('<body style="margin:0;background:#F2ECDD;display:flex;flex-wrap:wrap;gap:16px;padding:16px">' + ''.join(big(k, s) for k, s in C.items()) + '</body>')
