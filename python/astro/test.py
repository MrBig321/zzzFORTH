#python3

import math
import astronomy as astr

def diff8360(a, b):
	d = a-b
	if (d >= 180.0):
		return d - 360.0
	if (d < -180.0):
		return d + 360.0

	return d


interval = (0.0, 0.0, 0.0002, 0.0002, 0.0004, 0.0025, 0.005, 0.0, 0.0, 0.0, 0.005)

y = 2000
m = 6
d = 11

#time in UT (GMT)
hour = 11
minute = 15
second = 0

t = hour+minute/60.0+second/3600.0

#lon: positive westwards from Greenwich # e.g. Palomar Observatory: 116.8638
#lat: positive on northern hemisphere #e.g. Palomar Observatory: 33.356111	
#altitude above sea-level in meters
astr.setPosition(-21.091, 46.679, 100)

#according to Meeus deltaT (is in sec of time) should be added to the t.
# JDE should be calculated from that by calling calcJD
# but this should be the same, since 84400 is the number of seconds in a day
# 24*60*60

JD = astr.calcJD(y, m, d, t)
print ('JD=%f' % JD)

deltaT = astr.calcDeltaT(y, m, d) #deltaT = TD-UT
JDE = JD+deltaT/86400.0
print ('deltaT=%f' % deltaT)
#print ('deltaT=%f (in days)' % deltaT/86400.0)
print ('JDE=%f' % JDE)

#variables that affect the computation (these are the defaults. See the top of astronomy.py for details)
#astr.center = astr.GEO
#astr.coordsystem = astr.ECLIPTICAL
#flags = 0 #nothing
#astr.center = astr.HELIO
astr.flags = astr.FL_NUTATION | astr.FL_ABERRATION# | astr.FL_FK5 | astr.FL_PARALLAX

# The funtions below store the result in the corresponding variables that will be used later in astronomy.py (e.g. calcNutation fills astr.nutinlon and astr.nutinobl)

nutInLon, nutInObl = astr.calcNutation(JDE) #JDE differs from JD by deltaT
print ('nutInLon=%f nuInObl=%f (in ")' % (nutInLon, nutInObl))

#needs nutInObl in ", so it's ok
obl = astr.calcOblEcl(JDE)
#print ('obl=%f (in ")' % obl)
dd, mm, ss = astr.decToDeg(obl)
print ('obl=%dd %02dm %fs' % (dd, mm, ss))

sidtimeGRW = astr.calcSidTime(JD)
dd, mm, ss = astr.decToDeg(sidtimeGRW) 
print ('siderealtime=%d:%02d:%f (in Greenwich)' % (dd, mm, ss))
#Local sidtime
sidtimeLCL = astr.calcLocalSidTime() #uses astr.sidtime
dd, mm, ss = astr.decToDeg(sidtimeLCL)
print ('siderealtime=%d:%02d:%f (LOCAL)' % (dd, mm, ss))

#MC
ascmc = astr.computeVariables(sidtimeLCL) 
#MC, ARMC = astr.calcMC(sidtimeLCL)
dd, mm, ss = astr.decToDeg(ascmc[astr.MCV])
print ('MC=%dd %02dm %fs' % (dd, mm, ss))
dd, mm, ss = astr.decToDeg(ascmc[astr.ARMCV])
print ('ARMC=%dd %02dm %fs' % (dd, mm, ss))

#Asc
#Asc = astr.calcAsc(ARMC, obl)
dd, mm, ss = astr.decToDeg(ascmc[astr.ASCV])
print ('Asc=%dd %02dm %fs' % (dd, mm, ss))

signs = ('Ari', 'Tau', 'Gem', 'Can', 'Leo', 'Vir', 'Lib', 'Sco', 'Sag', 'Cap', 'Aqu', 'Pis')

#Planets
names = ('Sun', 'Moon', 'Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto', 'AscNode')
for i in range(astr.PLNUM):
	print ('*** %s ***' % names[i])
	lon, lat, rad = astr.calcPlanet(i, JDE)
	retr = ""
	if (i != astr.SUN and i != astr.MOON and i != astr.URANUS and i != astr.NEPTUNE and i != astr.PLUTO):
		lon2, lat2, rad2 = astr.calcPlanet(i, JDE+interval[i])
		dist = diff8360(lon2, lon)
		print ('lon=%f' % lon)
		print ('lon2=%f dist=%f' % (lon2, dist))
		if (dist < 0.0):
			retr = "R"

	sign = int(lon/30)
	pos = lon%30
	dd, mm, ss = astr.decToDeg(pos)
	print ('lon=%d%s %02dm %fs %s' % (dd, signs[sign], mm, ss, retr))
	dd, mm, ss = astr.decToDeg(lat)
	print ('lat=%dd %02dm %fs' % (dd, mm, ss))
	print ('rad=%f' % rad)
	ra, decl = astr.transform(lon, lat, obl)
	dd, mm, ss = astr.decToDeg(ra)
	print ('ra=%dd %02dm %fs' % (dd, mm, ss))
	dd, mm, ss = astr.decToDeg(decl)
	print ('decl=%dd %02dm %fs' % (dd, mm, ss))

	# Horizontal coords (azimuth, altitude)
	H = astr.calcH(ra)
	azi, alt = astr.equ2hor(H, decl)
	dd, mm, ss = astr.decToDeg(azi)
	print ('azi=%dd %02dm %fs' % (dd, mm, ss))
	dd, mm, ss = astr.decToDeg(alt)
	print ('alt=%dd %02dm %fs' % (dd, mm, ss))
	print()


#Houses
hsnames = ('WholeSign', 'Equal', 'Porhyry', 'Alchabitius', 'Regiomontanus', 'Placidus')
#hval = astr.WHOLESIGNHS
#hval = astr.EQUALHS
#hval = astr.PORPHYRYHS
#hval = astr.ALCHABITIUSHS
#hval = astr.REGIOMONTANUSHS
hval = astr.PLACIDUSHS
hcs = astr.computeHouses(hval)
print ('*** %s ***' % hsnames[hval])
for i in range(1, astr.HOUSE_NUM+1):
	sign = int(hcs[i]/30)
	pos = hcs[i]%30
	dd, mm, ss = astr.decToDeg(pos)
	print ('%d. %d%s %02dm %fs' % (i, dd, signs[sign], mm, ss))











