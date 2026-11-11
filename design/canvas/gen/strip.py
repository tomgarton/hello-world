import sys
ROOT = sys.argv[1]
_m = open(ROOT + '/gen/motion.py').read()
exec(_m[:_m.index('def tile(')])
for name, inner in (('hooray_snap', hooray), ('wave_snap', wave), ('nod', nod)):
    open(f'{ROOT}/gen/strip_{name}.html', 'w').write(f'<body style="margin:0;background:#FBF6E9"><svg id="s" xmlns="http://www.w3.org/2000/svg" width="290" height="354" viewBox="-21 -50 290 354">{inner}</svg></body>')
