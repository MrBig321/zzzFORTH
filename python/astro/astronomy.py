#python3

import math
from data import *


#
# Jean Meeus: Astronomical Algorithms, 2nd Ed.
#
# Geographic latitude (phi) is positive in the northern hemisphere and 
# negative in the southern one.
# Geographic longitudes are measured positively westwards from the meridian of Greenwich and negatively to the east. (page 93)
#
# BC, zero year, AD : ... -3, -2, -1, 0, +1, +2, +3 ...
#
# Accuracy according to Meeus: 
#  Moon (approximately 10" in long and 4" in lat), 
#  Sun: approximately 1"
#  Mercury - Neptune: a few arcseconds (")
#  Pluto: accurate positions between 1885-2099. On page 264 Meeus says that 
#  the method given there is not valid outside of this period
#
# Meeus' truncated VSOP87 is 38 times faster than the full VSOP87
#

#CONSTANTS
SUN, MOON, MERCURY, VENUS, MARS, JUPITER, SATURN, URANUS, NEPTUNE, PLUTO, NODE, PLNUM = range(12) #i.e. SUN=0, MOON=1, ..., PLUTO=9, NODE=10, PLNUM=11

#CALENDARS
GREGORIAN = 0
JULIAN = 1

#CENTER
HELIO, GEO = range(2) #RECT is missing

#COORDIANTE SYSTEMS
#ECLIPTICAL, EQUATORIAL, HORIZONTAL = range(3) # should be done in test.py by calling ecl2equ and equ2hor

calendar = GREGORIAN
center = GEO
#coordsystem = ECLIPTICAL

#VARIABLES
geolon = 0.0 #positive westwards from Greenwich
geolat = 0.0
altitude = 0 #in meters above sea-level

nutinlon = 0.0
nutinobl = 0.0

obliquity = 0.0

sidtime = 0.0
sidtimeLCL = 0.0

#FLAGS
FL_NUTATION = 1
FL_PARALLAX = 2
FL_ABERRATION = 4
FL_FK5 = 8			#There is very little difference between J2000 and FK5
FL_TRUENODE = 16

#flags = 0 # no nutation, parallax, aberration, FK5 or TrueNode will be used/computed
# flags can be added (nutation, parallax, aberration, FK5 and truenode will all be computed):
#flags = FL_NUTATION | FL_PARALLAX | FL_ABERRATION | FL_FK5 | FL_TRUENODE
# only nutation, aberration and truenode:
flags = FL_NUTATION | FL_ABERRATION | FL_TRUENODE

VERY_SMALL = 1E-10

ASCV, MCV, ARMCV = range(3)
variables = [0.0]*3

#Housesystems
HOUSE_NUM = 12
WHOLESIGNHS, EQUALHS, PORPHYRYHS, ALCHABITIUSHS, REGIOMONTANUSHS, PLACIDUSHS, HSNUM = range(7)


def calcJD(y, m, d, t): #12h will result a zero fraction at the end of JD
	Y = y
	M = m

	if M <= 2:
		Y = y-1
		M = m+12

	D = d+t/24.0

	A = int(Y/100)
	B = 0
	if calendar == GREGORIAN:
		B = 2-A+(int(A/4))

	JD = int(365.25*(Y+4716))+int(30.6001*(M+1))+D+B-1524.5

	return JD

def dateFromJD(JD):
	if JD < 0.0:
		raise Exception('Negative JD')

	JD += 0.5
	Z = int(JD)
	F = JD-Z

	A = Z
	if Z >= 2291161:
		alpha = int((Z-1867216.25)/36524.25)
		A = Z+1+alpha-int(alpha/4)

	B = A+1524
	C = int((B-122.1)/365.25)
	D = int(365.25*C)
	E = int((B-D)/30.6001)

	day = B-D-int(30.6001*E)+F
	month = E-1
	if E == 14 or E == 15: # E>13
		month = E-13

	year = C-4716
	if month == 1 or month == 2: # month<=2 
		year = C-4715

	dd = int(day)
	df = day-dd

	return year, month , dd, df*24.0

def calcNutation(JDE): #JDE differs from JD by deltaT
	global nutinlon, nutinobl

	T = (JDE-2451545)/36525

	D = 297.85036+445267.111480*T-0.0019142*T*T+T*T*T/189474
	M = 357.52772+35999.050340*T-0.0001603*T*T-T*T*T/300000
	Mm = 134.96298+477198.867398*T+0.0086972*T*T+T*T*T/56250
	F = 93.27191+483202.017538*T-0.0036825*T*T+T*T*T/327270
	O = 125.04452-1934.136261*T+0.0020708*T*T+T*T*T/450000

	D = normalize(D)

	rD = math.radians(D)
	rM = math.radians(M)
	rMm = math.radians(Mm)
	rF = math.radians(F)
	rO = math.radians(O)

	#deltaPsi (nutInLon) and deltaEpsilon (nutInObl) from Table 22.A
	#unit is 0.0001"
	deltaPsi = -171996*math.sin(rO)-174.2*T*math.sin(rO) \
		-13187*math.sin(-2*rD+2*rF+2*rO)-1.6*T*math.sin(-2*rD+2*rF+2*rO) \
		-2274*math.sin(2*rF+2*rO)-0.2*T*math.sin(2*rF+2*rO) \
		+2062*math.sin(2*rO)+0.2*T*math.sin(2*rO) \
		+1426*math.sin(rM)-3.4*T*math.sin(rM) \
		+712*math.sin(rMm)+0.1*T*math.sin(rMm) \
		-517*math.sin(-2*rD+rM+2*rF+2*rO)+1.2*T*math.sin(-2*rD+rM+2*rF+2*rO) \
		-386*math.sin(2*rF+rO)-0.4*T*math.sin(2*rF+rO) \
		-301*math.sin(rMm+2*rF+2*rO) \
		+217*math.sin(-2*rD-rM+2*rF+2*rO)-0.5*T*math.sin(-2*rD-rM+2*rF+2*rO) \
		-158*math.sin(-2*rD+rMm) \
		+129*math.sin(-2*rD+2*rF+rO)+0.1*T*math.sin(-2*rD+2*rF+rO) \
		+123*math.sin(-rMm+2*rF+2*rO) \
		+63*math.sin(2*rD) \
		+63*math.sin(rMm+rO)+0.1*T*math.sin(rMm+rO) \
		-59*math.sin(2*rD-rMm+2*rF+2*rO) \
		-58*math.sin(-rMm+rO)-0.1*T*math.sin(-rMm+rO) \
		-51*math.sin(rMm+2*rF+rO) \
		+48*math.sin(-2*rD+2*rMm) \
		+46*math.sin(-2*rMm+2*rF+rO) \
		-38*math.sin(2*rD+2*rF+2*rO) \
		-31*math.sin(2*rMm+2*rF+2*rO) \
		+29*math.sin(2*rMm) \
		+29*math.sin(-2*rD+rMm+2*rF+2*rO) \
		+26*math.sin(2*rF) \
		-22*math.sin(-2*rD+2*rF) \
		+21*math.sin(-rMm+2*rF+rO) \
		+17*math.sin(2*rM)-0.1*T*math.sin(2*rM) \
		+16*math.sin(2*rD-rMm+rO) \
		-16*math.sin(-2*rD+2*rM+2*rF+2*rO)+0.1*T*math.sin(-2*rD+2*rM+2*rF+2*rO) \
		-15*math.sin(rM+rO) \
		-13*math.sin(-2*rD+rMm+rO) \
		-12*math.sin(-rM+rO) \
		+11*math.sin(2*rMm-2*rF) \
		-10*math.sin(2*rD-rMm+2*rF+rO) \
		-8*math.sin(2*rD+rMm+2*rF+2*rO) \
		+7*math.sin(rM+2*rF+2*rO) \
		-7*math.sin(-2*rD+rM+rMm) \
		-7*math.sin(-rM+2*rF+2*rO) \
		-7*math.sin(2*rD+2*rF+rO) \
		+6*math.sin(2*rD+rMm) \
		+6*math.sin(-2*rD+2*rMm+2*rF+2*rO) \
		+6*math.sin(-2*rD+rMm+2*rF+rO) \
		-6*math.sin(2*rD-2*rMm+rO) \
		-6*math.sin(2*rD+rO) \
		+5*math.sin(-rM+rMm) \
		-5*math.sin(-2*rD-rM+2*rF+rO) \
		-5*math.sin(-2*rD+rO) \
		-5*math.sin(2*rMm+2*rF+rO) \
		+4*math.sin(-2*rD+2*rMm+rO) \
		+4*math.sin(-2*rD+rM+2*rF+rO) \
		+4*math.sin(rMm-2*rF) \
		-4*math.sin(-rD+rMm) \
		-4*math.sin(-2*rD+rM) \
		-4*math.sin(rD) \
		+3*math.sin(rMm+2*rF) \
		-3*math.sin(-2*rMm+2*rF+2*rO) \
		-3*math.sin(-rD-rM+rMm) \
		-3*math.sin(rM+rMm) \
		-3*math.sin(-rM+rMm+2*rF+2*rO) \
		-3*math.sin(2*rD-rM-rMm+2*rF+2*rO) \
		-3*math.sin(3*rMm+2*rF+2*rO) \
		-3*math.sin(2*rD-rM+2*rF+2*rO)

	deltaEpsilon = +92025*math.cos(rO)+8.9*T*math.cos(rO) \
		+5736*math.cos(-2*rD+2*rF+2*rO)-3.1*T*math.cos(-2*rD+2*rF+2*rO) \
		+977*math.cos(2*rF+2*rO)-0.5*T*math.cos(2*rF+2*rO) \
		-895*math.cos(2*rO)+0.5*T*math.cos(2*rO) \
		+54*math.cos(rM)-0.1*T*math.cos(rM) \
		-7*math.cos(rMm) *T*math.cos(rMm) \
		+224*math.cos(-2*rD+rM+2*rF+2*rO)-0.6*T*math.cos(-2*rD+rM+2*rF+2*rO) \
		+200*math.cos(2*rF+rO) \
		+129*math.cos(rMm+2*rF+2*rO)-0.1*T*math.cos(rMm+2*rF+2*rO) \
		-95*math.cos(-2*rD-rM+2*rF+2*rO)+0.3*T*math.cos(-2*rD-rM+2*rF+2*rO) \
		-70*math.cos(-2*rD+2*rF+rO) \
		-53*math.cos(-rMm+2*rF+2*rO) \
		-33*math.cos(rMm+rO) \
		+26*math.cos(2*rD-rMm+2*rF+2*rO) \
		+32*math.cos(-rMm+rO) \
		+27*math.cos(rMm+2*rF+rO) \
		-24*math.cos(-2*rMm+2*rF+rO) \
		+16*math.cos(2*rD+2*rF+2*rO) \
		+13*math.cos(2*rMm+2*rF+2*rO) \
		-12*math.cos(-2*rD+rMm+2*rF+2*rO) \
		-10*math.cos(-rMm+2*rF+rO) \
		-8*math.cos(2*rD-rMm+rO) \
		+7*math.cos(-2*rD+2*rM+2*rF+2*rO) \
		+9*math.cos(rM+rO) \
		+7*math.cos(-2*rD+rMm+rO) \
		+6*math.cos(-rM+rO) \
		+5*math.cos(2*rD-rMm+2*rF+rO) \
		+3*math.cos(2*rD+rMm+2*rF+2*rO) \
		-3*math.cos(rM+2*rF+2*rO) \
		+3*math.cos(-rM+2*rF+2*rO) \
		+3*math.cos(2*rD+2*rF+rO) \
		-3*math.cos(-2*rD+2*rMm+2*rF+2*rO) \
		-3*math.cos(-2*rD+rMm+2*rF+rO) \
		+3*math.cos(2*rD-2*rMm+rO) \
		+3*math.cos(2*rD+rO) \
		+3*math.cos(-2*rD-rM+2*rF+rO) \
		+3*math.cos(-2*rD+rO) \
		+3*math.cos(2*rMm+2*rF+rO)

	#deltaPsi (nutInLon) and deltaEpsilon (nutInObl) [unit is 0.0001"]
	deltaPsi /= 10000.0
	deltaEpsilon /= 10000.0

	nutinlon = deltaPsi
	nutinobl = deltaEpsilon

	return deltaPsi, deltaEpsilon  # in "


def calcNutationSimplyfied(JDE): #JDE differs from JD by deltaT
	global nutinlon, nutinobl

	T = (JDE-2451545)/36525
	Omega = 125.04452-1934.136261*T

	L = 280.4665+36000.7698*T
	Lm = 218.3165+481267.8813*T

	Omega = normalize(Omega)
	L = normalize(L)
	Lm = normalize(Lm)

	rOmega = math.radians(Omega)
	rL = math.radians(L)
	rLm = math.radians(Lm)
	
	deltaPsi = -17.20*math.sin(rOmega)--1.32*math.sin(2*rL)-0.23*math.sin(2*rLm)+0.21*math.sin(2*rOmega)
	deltaEpsilon = 9.20*math.cos(rOmega)+0.57*math.cos(2*rL)+0.10*math.cos(2*rLm)-0.09*math.cos(2*rOmega)

	nutinlon = deltaPsi
	nutinobl = deltaEpsilon

	#deltaPsi (nutInLon) and deltaEpsilon (nutInObl)
	return deltaPsi, deltaEpsilon #in " 

def calcOblEcl(JDE):
	global flags, obliquity

	T = (JDE-2451545)/36525

	#Mean obliquity of the ecliptic (no correction for nutation)
	#Not too accurate. Over a period of 2000 yrs (1") and over 4000 (10")
#	epsilon0 = 84381.448-46.8150*T-0.00059*T*T+0.001813*T*T*T

	#more accurate:
	U = T/100
	epsilon0 = 84381.448-4680.93*U-1.55*U*U+1999.25*U*U*U-51.38*U*U*U*U-249.67*U*U*U*U*U-39.05*U*U*U*U*U*U+7.12*U*U*U*U*U*U*U+27.87*U*U*U*U*U*U*U*U+5.79*U*U*U*U*U*U*U*U*U+2.45*U*U*U*U*U*U*U*U*U*U
	
	epsilon = epsilon0
	if flags & FL_NUTATION:
		epsilon = epsilon0+nutinobl

	obliquity = epsilon/3600.0

	return obliquity

#for deltaT computation (from 1600 till 2000 with two-steps)
#in the book it begins with 1620, so the first 10 elements are my interpolations. the last element is for 1998. In seconds
dts = (249.0, 234.0, 219.0, 205.0, 191.0, 178.0, 165.0, 153.0, 142.0, 131.0, 
#first column
121.0, 112.0, 103.0, 95.0, 88.0, 82.0, 77.0, 72.0, 68.0, 63.0, 60.0, 56.0, 53.0, 51.0, 48.0, 46.0, 44.0, 42.0, 40.0, 38.0, 35.0, 33.0, 31.0, 29.0, 26.0, 24.0, 22.0, 20.0, 18.0, 16.0, 14.0, 12.0, 11.0, 10.0, 9.0,8.0, 7.0, 7.0, 7.0, 7.0,    
#second column
7.0, 7.0, 8.0, 8.0, 9.0, 9.0, 9.0, 9.0, 9.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 11.0, 11.0, 11.0, 11.0, 11.0, 12.0, 12.0, 12.0, 12.0, 13.0, 13.0, 13.0, 14.0, 14.0, 14.0, 14.0, 15.0, 15.0, 15.0, 15.0, 15.0, 16.0, 16.0,
#third column
 16.0, 16.0, 16.0, 16.0, 16.0, 16.0, 15.0, 15.0, 14.0, 13.0, 13.1, 12.5, 12.2, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 11.9, 11.6, 11.0, 10.2, 9.2, 8.2, 7.1, 6.2, 5.6, 5.4, 5.3, 5.4, 5.6, 5.9, 6.2, 6.5, 6.8, 7.1, 7.3, 7.5, 7.6,
#fourth column
7.7, 7.3, 6.2, 5.2, 2.7, 1.4, -1.2, -2.8, -3.8, -4.8, -5.5, -5.3, -5.6, -5.7, -5.9, -6.0, -6.3, -6.5, -6.2, -4.7, -2.8, -0.1, 2.6, 5.3, 7.7, 10.4, 13.3, 16.0, 18.2, 20.2, 21.1, 22.4, 23.5, 23.8, 24.3, 24.0, 23.9, 23.9, 23.7, 24.0,    
#last column
24.3, 25.3, 26.2, 27.3, 28.2, 29.1, 30.0, 30.7, 31.4, 32.2, 33.1, 34.0, 35.0, 36.5, 38.3, 40.2, 42.2, 44.5, 46.5, 48.5, 50.5, 52.2, 53.8, 54.9, 55.8, 56.9, 58.3, 60.0, 61.6, 63.0)

def calcDeltaT(y, m, d, cal=GREGORIAN): #deltaT = TD-UT
	day = dayOfTheYear(y, m, d, cal)

	extra = 0
	if isLeap(y, cal):
		extra = 1
	y = float(y+day/(365.0+extra))

	t = (y-2000)/100
	
	if y < 948:
		deltaT = 2177+497*t+44.1*t*t
	elif y < 1600 or y >= 2000:
		corr = 0.0
		if y >= 2000 and y < 2100:
			corr = 0.37*(y-2100)
		deltaT = 102+102*t+25.3*t*t+corr
	else: #1600-2000
		y = int(y)
		idx = int((y-1600)/2)
		even = (y-1600)%2 == 0
		if even:
			deltaT = dts[idx]
		else:
			if idx != len(dts)-1:
				deltaT = (dts[idx]+dts[idx+1])/2
			else:
				deltaT = dts[idx]+(dts[idx]-dts[idx-1])

	return deltaT #in seconds of time

def calcSidTimeMidnight(JD): #JD needs to be computed for midnight (0h), so ends with .5 ###If the next function gives the same result for 0h then we don't need this one
	global flags, sidtime

	T = (JD-2451545.0)/36525
	Th0 = 100.46061837+36000.770053608*T+0.000387933*T*T-T*T*T/38710000

	#To obtain th0 (SidTime at Greenwich for any instant UT of a given date), multiply that instant by 1.00273790935 and add th result to Th0

	corr = 0.0
	if flags & FL_NUTATION:
		#add correction for nutationInLongitude and the true Obliquity of the Ecliptic(epsilon)
		corr = nutinlon*cos(math.radians(obliquity*3600.0))/15.0
		Th0 += corr

	Th0 = normalize(Th0)
	Th0 /= 15.0
	sidtime = Th0

	return Th0 #in degrees

def calcSidTime(JD): #The same as the previous function for 0h
	global flags, sidtime

	T = (JD-2451545.0)/36525
	th0 = 280.46061837+360.98564736629*(JD-2451545.0)+0.000387933*T*T-T*T*T/38710000

	corr = 0.0
	if flags & FL_NUTATION:
		#add correction for nutationInLongitude and the true Obliquity of the Ecliptic(epsilon)
		corr = nutinlon*math.cos(math.radians(obliquity*3600.0))/15.0
		th0 += corr/3600.0 #corr is in seconds of time. th0 is in degrees

	th0 = normalize(th0)
	th0 /= 15.0 # to time (hours.xxxxx)
	sidtime = th0

	return th0 #in degrees

def equ2ecl(ra, decl, obl):
	rra = math.radians(ra)
	rdecl = math.radians(decl)
	robl = math.radians(obl)

	lon = 0.0
	if math.cos(rra) != 0.0:
		lon = math.degrees(math.atan2(math.sin(rra)*math.cos(robl)+math.tan(rdecl)*math.sin(robl), math.cos(rra)))
	lat = math.degrees(math.asin(math.sin(rdecl)*math.cos(robl)-math.cos(rdecl)*math.sin(robl)*math.sin(rra)))

	lon = normalize(lon)

	return lon, lat

def ecl2equ(lon, lat, obl):
	rlon = math.radians(lon)
	rlat = math.radians(lat)
	robl = math.radians(obl)

	ra = 0.0
	if math.cos(rlon) != 0.0:
		ra = math.degrees(math.atan2(math.sin(rlon)*math.cos(robl)-math.tan(rlat)*math.sin(robl), math.cos(rlon)))
	decl = math.degrees(math.asin(math.sin(rlat)*math.cos(robl)+math.cos(rlat)*math.sin(robl)*math.sin(rlon)))

	ra = normalize(ra)

	return ra, decl


def calcH(ra):
#	H = sidtime*15.0-geolon-ra #(H: local hour angle, th: sidtime at Greenwich, geolon is the longitude of place)
	H = normalize(sidtimeLCL*15.0)-ra
	H = normalize(H)
	return H

# Azimuth measured westward from the south.
def equ2hor(H, decl): #add 180 to azi if wish to reckon azi from the North
	rH = math.radians(H)
	rgeo = math.radians(geolat)
	rdecl = math.radians(decl)

	azi = 0.0
	denomin = math.cos(rH)*math.sin(rgeo)-math.tan(rdecl)*math.cos(rgeo)
	if denomin != 0.0:
		azi = math.degrees(math.atan2(math.sin(rH), denomin))
	alt = math.degrees(math.asin(math.sin(rgeo)*math.sin(rdecl)+math.cos(rgeo)*math.cos(rdecl)*math.cos(rH)))

	azi = normalize(azi)

	return azi, alt

def hor2equ(azi, alt, geolat):
	razi = math.radians(azi)
	ralt = math.radians(alt)
	rgeo = math.radians(geolat)

	H = 0.0
	denomin = math.cos(razi)*math.sin(rgeo)+math.tan(alt)*math.cos(rgeo)
	if denomin != 0.0:
		H = math.atan2(math.sin(razi), denomin)
	decl = math.asin(math.sin(rgeo)*math.sin(ralt)-math.cos(rgeo)*math.cos(ralt)*math.cos(razi))

	return H, decl

# Geographic latitude is different from geocentric latitude because the Earth is an ellipsoid and not a sphere.The geographic latitude can be read from maps.
def calcGeocentricLat(geolat, H=0.0): #H: height above sea-level in meters
	a = 6378.14 #in km, semi-major axis
	f = 1/298.257 #Earth's flattening
	b = 6356.755 #in km, a*(1-f), semi-minor axis

	rgeo = math.radians(geolat)

#	if H == 0.0:
#		gclat = math.atan((b*b)/(a*a)*math.tan(rgeo))
#		return gclat

#	else:
	ru = math.atan((b/a)*math.tan(rgeo))
	rosingclat = (b/a)*math.sin(ru)+(H/6378140)*math.sin(rgeo)
	rocosgclat = math.cos(ru)+(H/6378140)*math.cos(rgeo)
	# ro denotes the observer's distance to the center of the Earth

	return rosingclat, rocosgclat

def calcGeoSpecial(geolat):
	a = 6378.14 #in km, semi-major axis
	f = 1/298.257 #Earth's flattening
	b = 6356.755 #in km, a*(1-f), semi-minor axis
	e = 0.08181922 # e=sqrt(2*f-f*f), eccentricity of the Earth's meridian

	rgeo = math.radians(geolat)

	Rp = a*math.cos(rgeo)/math.sqrt(1.0-e*e*math.sin(rgeo)*math.sin(rgeo))
	deg1lon = (math.pi/180.0)*Rp
	omega = 7.292114992*10E-5 #radian/second
	linvel = omega*Rp
	Rm = (a*(1.0-e*e))/math.sqrt(math.pow(1.0-e*e*math.sin(rgeo)*math.sin(rgeo), 3))
	deg1lat = (math.pi/180.0)*Rm

	return Rp, deg1lon, linvel, Rm, deg1lat

def calcGeoDist(lon1, lat1, lon2, lat2):
	a = 6378.14 #in km, semi-major axis
	#rlon1 = math.radians(lon1)
	rlat1 = math.radians(lat1)
	#rlon2 = math.radians(lon2)
	rlat2 = math.radians(lat2)
	rlondiff = math.radians(lon1-lon2)

	#low accuracy #doesn't take into account the Earth's flattening
#	d = math.acos(math.sin(rlat1)*math.sin(rlat2)+math.cos(rlat1)*math.cos(rlat2)*math.cos(rlondiff))
#	d = math.degrees(d)
	#s is linear distance
#	s = 6371*math.pi*d/180.0
#	return s

	#high accuracy
	F = (lat1+lat2)/2
	G = (lat1-lat2)/2
	L = (lon1-lon2)/2

	rF = math.radians(F)
	rG = math.radians(G)
	rL = math.radians(L)

	S = math.sin(rG)*math.sin(rG)*math.cos(rL)*math.cos(rL)+math.cos(rF)*math.cos(rF)*math.sin(rL)*math.sin(rL)
	C = math.cos(rG)*math.cos(rG)*math.cos(rL)*math.cos(rL)+math.sin(rF)*math.sin(rF)*math.sin(rL)*math.sin(rL)

	omega = math.atan(math.sqrt(S/C))
	R = math.sqrt(S*C)/omega  #omega is expressed in radians
	D = 2*omega*a
	H1 = (3*R-1)/(2*C)
	H2 = (3*R+1)/2*S

	f = 1/298.257 #Earth's flattening

	S = D*(1+f*H1*math.sin(rF)*math.sin(rF)*math.cos(rG)*math.cos(rG)-f*H2*math.cos(rF)*math.cos(rF)*math.sin(rG)*math.sin(rG))

	return S


def sumTerms(T, ar):
	val = 0.0
	for i in range(len(ar)):
		subval = 0.0
		for j in range(len(ar[i])):
			A = ar[i][j][0]
			B = ar[i][j][1]
			C = ar[i][j][2]

			subval += A*math.cos(B+C*T) #in radians

		val += subval*math.pow(T, i)

	return val

#Array members: Lon:L, Lat:B, Radius:R
plterms = ((EARTH_L, EARTH_B, EARTH_R), (None, None, None), (MERCURY_L, MERCURY_B, MERCURY_R), (VENUS_L, VENUS_B, VENUS_R), 
			(MARS_L, MARS_B, MARS_R), (JUPITER_L, JUPITER_B, JUPITER_R), (SATURN_L, SATURN_B, SATURN_R), (URANUS_L, URANUS_B, URANUS_R), (NEPTUNE_L, NEPTUNE_B, NEPTUNE_R), (None, None, None))
#returns long, lat and the radius from the center (Earth[Geocentric] or Sun[Heliocentric])
def calcPlanet(pl, JDE):
	global flags, center

	if pl == MOON:
		return calcMoon(JDE)
	elif pl == NODE:
		return calcNode(JDE)
	elif pl == PLUTO:
		return calcPluto(JDE)

	T = (JDE-2451545.0)/365250

	LON = 0
	LAT = 1
	RAD = 2

	#calc L
	L = sumTerms(T, plterms[pl][LON])
	#L and B in radians; HELIOCENTRIC
	L /= math.pow(10, 8) # 100000000
	L = normalize(math.degrees(L))

	#calc B
	B = sumTerms(T, plterms[pl][LAT])
	B /= math.pow(10, 8) # 100000000
	B = math.degrees(B) # don't normalize! It can be negative

	#calc R
	R = sumTerms(T, plterms[pl][RAD])
	R /= math.pow(10, 8) # 100000000

	if center == GEO:
		if pl == SUN:
			#To Geocentric
			L += 180.0
			L = normalize(L)
			B = -B

			#to FK5:
			if (flags & FL_FK5):
				dL = L-1.397*10*T-0.00031*10*T*10*T  #(25.9)
				dB = 0.03916*(math.cos(math.radians(dL)-math.sin(math.radians(dL))))
				#in "

				L += -0.09033/3600.0
				B += dB/3600.0

			#nutation (only the longitude is affected)
			if flags & FL_NUTATION:
				L += nutinlon/3600.0

			#aberration (low accuracy)
			#aberration (high accuracy) [makes sense only with VSOP87] SUN
			if (flags & FL_ABERRATION):
				aber = -20.4898/R
				L += aber/3600.0

			L = normalize(L)

			#parallax
			#correct ra, decl for parallax, chapter 40
			if flags & FL_PARALLAX:
				#equatorial horizontal parallax
				pi = math.degrees(math.asin(math.sin(math.radians(8.794))/R)) # in km, pi will be in degrees but in "
				ra, decl = calcParallax(L, B, pi)
#				L, B = equ2ecl(ra, decl, obliquity)
				L, B = transform(ra, decl, -obliquity)

		else:
			#L0, B0, R0 EARTH's heliocentric coords
			cen = center
			center = HELIO
			L0, B0, R0 = calcPlanet(SUN, JDE) #Slow because gets called for every planet
			center = cen
			
			L, B, R = toGeo(L0, B0, R0, L, B, R)

			#to FK5:
			if (flags & FL_FK5):
				L, B = toFK5(L, B, 10*T)

			if flags & FL_NUTATION:
				L += nutinlon/3600.0
				L = normalize(L)

			#aberration (the Ron-Vondrak would be more accurate but it is much more comlicated)
			if (flags & FL_ABERRATION):
				L, B = calcAberration(10*T, L0, L, B)

			#parallax
			#correct ra, decl for parallax, chapter 40
			if flags & FL_PARALLAX:
				#equatorial horizontal parallax
				pi = math.degrees(math.asin(math.sin(math.radians(8.794))/R)) # in km, pi will be in degrees but in "
				ra, decl = calcParallax(L, B, pi)
#				L, B = equ2ecl(ra, decl, obliquity)
				L, B = transform(ra, decl, -obliquity)
	
	return L, B, R


# returns geocentric long, lat of the center of the Moon referred to the mean equinox of date, and the distance d in kms between the centers of Earth and Moon OR heliocentric L, B, R
def calcMoon(JDE):
	global flags

	T = (JDE-2451545.0)/36525

	#L'
	Lc = 218.3164477+481267.88123421*T-0.0015786*T*T+T*T*T/538841.0-T*T*T*T/65194000.0
	D = 297.8501921+445267.1114034*T-0.0018819*T*T+T*T*T/545868-T*T*T*T/113065000
	M = 357.5291092+35999.0502909*T-0.0001536*T*T+T*T*T/24490000
	#M'
	Mc = 134.9633964+477198.8675055*T+0.0087414*T*T+T*T*T/69699-T*T*T*T/14712000
	F = 93.2720950+483202.0175233*T-0.0036539*T*T-T*T*T/3526000+T*T*T*T/863310000

	Lc = normalize(Lc)
	D = normalize(D)
	M = normalize(M)
	Mc = normalize(Mc)
	F = normalize(F)

	A1 = normalize(119.75+131.849*T)
	A2 = normalize(53.09+479264.290*T)
	A3 = normalize(313.45+481266.484*T)

	E = 1.0-0.002516*T-0.0000074*T*T

	suml = sumr = 0.0
	lrnum = len(MOON_L_R)
	for i in range(lrnum):
		DNum = MOON_L_R[i][0]
		MNum = MOON_L_R[i][1]
		McNum = MOON_L_R[i][2]
		FNum = MOON_L_R[i][3]

		corr = 1
		if MNum == 1 or MNum == -1:
			corr = E
		if MNum == 2 or MNum == -2:
			corr = E*E
 
		suml += MOON_L_R[i][4]*corr*math.sin(math.radians(D*DNum+M*MNum+Mc*McNum+F*FNum))
		sumr += MOON_L_R[i][5]*corr*math.cos(math.radians(D*DNum+M*MNum+Mc*McNum+F*FNum))

	sumb = 0.0
	bnum = len(MOON_B)
	for i in range(bnum):
		DNum = MOON_B[i][0]
		MNum = MOON_B[i][1]
		McNum = MOON_B[i][2]
		FNum = MOON_B[i][3]

		corr = 1
		if MNum == 1 or MNum == -1:
			corr = E
		if MNum == 2 or MNum == -2:
			corr = E*E
 
		sumb += MOON_B[i][4]*corr*math.sin(math.radians(D*DNum+M*MNum+Mc*McNum+F*FNum))

	suml += 3958*math.sin(math.radians(A1))+1962*math.sin(math.radians(Lc-F))+318*math.sin(math.radians(A2))

	sumb += -2235*math.sin(math.radians(Lc))+382*math.sin(math.radians(A3))+175*math.sin(math.radians(A1-F))+175*math.sin(math.radians(A1+F))+127*math.sin(math.radians(Lc-Mc))-115*math.sin(math.radians(Lc+Mc))

	lon = Lc+suml/1000000
	lat = sumb/1000000
	dist = 385000.56+sumr/1000

	if center == HELIO:
		L0, B0, R0 = calcPlanet(SUN, JDE)

		#dist is the distance between the centeroftheEarth and that of the Moon in km
		au1 = 149.60*10e6
		distinAU = dist/au1

		L, B, R = toGeo(L0, B0, -R0, lon, lat, distinAU)

		return L, B, R

	#Apparent longitude (add nutation)
	if flags & FL_NUTATION:
		lon += nutinlon/3600.0

	if flags & FL_PARALLAX:
		#equatorial horizontal parallax
		pi = math.degrees(math.asin(6378.14/dist)) # in km, pi will be in degrees
		pi *= 3600.0 #to "
		ra, decl = calcParallax(lon, lat, pi)
#		lon, lat = equ2ecl(ra, decl, obliquity)
		lon, lat = transform(ra, decl, -obliquity)

	#FK5!?
	#aberration!?

	#it seems that aberration and FK5 shouldn't be computed for the Moon (but Heliocentric!?)
	return lon, lat, dist

def calcNode(JDE):
	global flags

	T = (JDE-2451545.0)/36525

	meannode = 125.0445479-1934.1362891*T+0.0020754*T*T+T*T*T/467441-T*T*T*T/60616000
	meannode = normalize(meannode)

	D = 297.8501921+445267.1114034*T-0.0018819*T*T+T*T*T/545868-T*T*T*T/113065000
	M = 357.5291092+35999.0502909*T-0.0001536*T*T+T*T*T/24490000
	#M'
	Mc = 134.9633964+477198.8675055*T+0.0087414*T*T+T*T*T/69699-T*T*T*T/14712000
	F = 93.2720950+483202.0175233*T-0.0036539*T*T-T*T*T/3526000+T*T*T*T/863310000

	D = normalize(D)
	M = normalize(M)
	Mc = normalize(Mc)
	F = normalize(F)

	node = meannode

	if flags & FL_TRUENODE:
		node = meannode-1.4979*math.sin(math.radians(2*(D-F)))-0.1500*math.sin(math.radians(M))-0.1226*math.sin(math.radians(2*D))+0.1176*math.sin(math.radians(2*F))-0.0801*math.sin(math.radians(2*(Mc-F)))

		node = normalize(node)

	# I guess nutation shouldn't be taken into account here

	return node, 0.0, 0.0


#accurate between 1885 AD - 2099 AD (invalid outside)
#Helio and Geo positions differ little because Pluto's distance is much greater than that of the Sun-Earth.
def calcPluto(JDE):
	global flags, center, obliquity

	T = (JDE-2451545.0)/36525

	J = 34.35+3034.9057*T
	S = 50.08+1222.1138*T
	P = 238.96+144.9600*T

	ARGS = 0
	LONC = 1
	LATC = 2
	RADC = 3

	LON = 0
	LAT = 1
	RAD = 2

	summa = [0.0, 0.0, 0.0]
	num = len(PLUTO_C)
	for i in range(num):
		alpha = PLUTO_C[i][ARGS][0]*J+PLUTO_C[i][ARGS][1]*S+PLUTO_C[i][ARGS][2]*P
		ralpha = math.radians(alpha)
		summa[LON] += PLUTO_C[i][LONC][0]*math.sin(ralpha)+PLUTO_C[i][LONC][1]*math.cos(ralpha)
		summa[LAT] += PLUTO_C[i][LATC][0]*math.sin(ralpha)+PLUTO_C[i][LATC][1]*math.cos(ralpha)
		summa[RAD] += PLUTO_C[i][RADC][0]*math.sin(ralpha)+PLUTO_C[i][RADC][1]*math.cos(ralpha)

	summa[LON] /= 1000000
	summa[LAT] /= 1000000
	summa[RAD] /= 10000000

	#Heliocentric long, lat, radius
	l = 238.958116+144.96*T+summa[LON]
	b = -3.908239+summa[LAT]
	r = 40.7241346+summa[RAD]

	if center == HELIO:
		return l, b, r

	#find geocentric rectangular coords of the Sun
	#should convert to FK5 in calcPlanet!!
	fl = flags
	flags = 0
	cen = center
	center = GEO
	L0, B0, R0 = calcPlanet(SUN, JDE)
	flags = fl
	center = cen

	rL0 = math.radians(L0)
	rB0 = math.radians(B0)
	rR0 = math.radians(R0)

	oblorig = obliquity
	flagsorig = flags
	flags = 0
	meanobl = calcOblEcl(2451545.0) # at 2000J
	obliquity = oblorig
	flags = flagsorig
	rmeanobl = math.radians(meanobl)

	#Sun's geocentric rectangular equatorial coords
	X = R0*math.cos(rB0)*math.cos(rL0)
	Y = R0*(math.cos(rB0)*math.sin(rL0)*math.cos(rmeanobl)-math.sin(rB0)*math.sin(rmeanobl))
	Z = R0*(math.cos(rB0)*math.sin(rL0)*math.sin(rmeanobl)+math.sin(rB0)*math.cos(rmeanobl))

	#Pluto's geocentric rectangular equatorial coords
	rl = math.radians(l)
	rb = math.radians(b)
	rr = math.radians(r)
	x = r*math.cos(rl)*math.cos(rb)
	y = r*(math.sin(rl)*math.cos(rb)*math.cos(rmeanobl)-math.sin(rb)*math.sin(rmeanobl))
	z = r*(math.sin(rl)*math.cos(rb)*math.sin(rmeanobl)+math.sin(rb)*math.cos(rmeanobl))

	#find ra, decl, and pluto's distance d to the Earth
	xi = X+x
	eta = Y+y
	zeta = Z+z
	
	ra = normalize(math.degrees(math.atan2(eta, xi)))
	d = math.sqrt(xi*xi+eta*eta+zeta*zeta)
	decl = math.degrees(math.asin(zeta/d))

	#parallax
	#it makes no sense to calculate parallax in case of Pluto because it is very far away
	
#	lon, lat = equ2ecl(ra, decl, obliquity)
	lon, lat = transform(ra, decl, -obliquity)

	#to FK5
	if (flags & FL_FK5):
		lon, lat = toFK5(lon, lat, T)

	if flags & FL_NUTATION:
		lon += nutinlon/3600.0
		lon = normalize(lon)

	#aberration (the Ron-Vondrak would be more accurate but it is much more complicated)
	if (flags & FL_ABERRATION):
		lon, lat = calcAberration(T, L0, lon, lat)

	return lon, lat, d

def calcParallax(lon, lat, pi): #pi in "
	rosingclat, rocosgclat = calcGeocentricLat(geolat, altitude) #H: height above sea-level in meters

#	ra, decl = ecl2equ(lon, lat, obliquity)
	ra, decl = transform(lon, lat, obliquity)
	rdecl = math.radians(decl)

	H = calcH(ra)
	rH = math.radians(H)
		
	pi /= 3600.0 #to degrees
	rpi = math.radians(pi)
	nominator = -rocosgclat*math.sin(rpi)*math.sin(rH)
	denomin = math.cos(rdecl)-rocosgclat*math.sin(rpi)*math.cos(rH)
	dRA = 0.0
	if denomin != 0.0:
		dRA = math.atan2(nominator, denomin) #dRA in radians

	nominator = (math.sin(rdecl)-rosingclat*math.sin(rpi))*math.cos(dRA)
	denomin = math.cos(rdecl)-rocosgclat*math.sin(rpi)*math.cos(rH)
	decl = 0.0
	if denomin != 0.0:
		decl = math.degrees(math.atan2(nominator, denomin))
	
	ra = normalize(ra+math.degrees(dRA))

	return ra, decl


def calcAberration(T, L0, L, B):
	e = 0.016708634-0.000042037*T-0.0000001267*T*T
	pi = 102.93735+1.71946*T+0.00046*T*T

	K = 20.49552 #(in ")
				
	#Sun's GEO long
	LS = normalize((L0+180.0))
				
	rB = math.radians(B)
	
	dL = 0.0
	if math.cos(rB) != 0.0:
		dL = (-K*math.cos(math.radians(LS-L))+e*K*math.cos(math.radians(pi-L)))/math.cos(rB)
	dB = -K*math.sin(rB)*(math.sin(math.radians(LS-L))-e*math.sin(math.radians(pi-L)))

	L += dL/3600.0
	B += dB/3600.0

	L = normalize(L)

	return L, B


def toFK5(L, B, T):
	LL = L-1.397*T-0.00031*T*T
	rLL = math.radians(LL)
	rB = math.radians(B)
	dL = -0.09033+0.03916*(math.cos(rLL)+math.sin(rLL))*math.tan(rB)
	dB = 0.03916*(math.cos(rLL)-math.sin(rLL))
	#in "

	L += dL/3600.0
	B += dB/3600.0

	L = normalize(L)

	return L, B

def calcLocalSidTime():
	global sidtimeLCL
	#Local sidtime
	loctime = geolon*4.0 #in minutes
	loctime /= 60.0 #to hours

#	sidtimeLCL = sidtime-loctime #Local Sidtime
	sidtimeLCL = normalize(sidtime*15.0-loctime*15.0)/15.0 #Local Sidtime

	return sidtimeLCL


#L0, B0, R0 coords of the Earth (heliocentric), L, B, R coords of the body to transform. If R0 is negative then toHelio
def toGeo(L0, B0, R0, L, B, R):
	rL = math.radians(L)
	rB = math.radians(B)
	rR = math.radians(R)
	rL0 = math.radians(L0)
	rB0 = math.radians(B0)
	rR0 = math.radians(R0)

	x = R*math.cos(rB)*math.cos(rL)-R0*math.cos(rB0)*math.cos(rL0)
	y = R*math.cos(rB)*math.sin(rL)-R0*math.cos(rB0)*math.sin(rL0)
	z = R*math.sin(rB)-R0*math.sin(rB0)

	lon = normalize(math.degrees(math.atan2(y, x)))
	lat = math.degrees(math.atan2(z, math.sqrt(x*x+y*y)))
	rad = math.sqrt(x*x+y*y+z*z)

	return lon, lat, rad


def calcMC(sidtimeLCL):
	global obliquity

	ARMC = normalize(sidtimeLCL*15.0)
	robl = math.radians(obliquity)
	rARMC = math.radians(ARMC)
	rMC = math.atan2(math.tan(rARMC), math.cos(robl))
	if rMC < 0.0:
		rMC += math.pi
	if rARMC > math.pi:
		rMC += math.pi
	MC = math.degrees(rMC)
	MC = normalize(MC)

	return MC, ARMC

def calcAsc(ARMC, obl):
	rARMC = math.radians(ARMC)
	robl = math.radians(obl)

	#According to Astrolog
	rAsc = angle(-math.sin(rARMC)*math.cos(robl)-math.tan(math.radians(geolat))*math.sin(robl), math.cos(rARMC))
#	rAsc = math.atan2(-math.sin(rARMC)*math.cos(robl)-math.tan(math.radians(geolat))*math.sin(robl), math.cos(rARMC))
	Asc = normalize(math.degrees(rAsc)) 

	return Asc

def setPosition(lon, lat, alt):
	global geolon, geolat, altitude

	geolon = lon
	geolat = lat
	altitude = alt

	# north and south poles
	if (math.fabs(math.fabs(geolat)-90) < VERY_SMALL):
		if (geolat < 0):
			geolat = -90+VERY_SMALL
		else:
			geolat = 90-VERY_SMALL


#computes Asc, MC, ARMC
#Inside polar region won't be correct but these are handled during HouseSystem computations
def computeVariables(sidtimeLCL):
	variables[MCV], variables[ARMCV] = calcMC(sidtimeLCL)
	variables[ASCV] = calcAsc(variables[ARMCV], obliquity)

	#within polar circle we swap AC/DC if AC is on wrong side (NOT here!!)
#	if (math.fabs(geolat) >= 90 - obliquity):
#		acmc = difdeg2n(variables[ASCV], variables[MCV])
#		if (acmc < 0):
#			variables[ASCV] = normalize(variables[ASCV]+180)

	return variables

#
# Utilities 
#

def isLeap(y, cal=GREGORIAN):
	if cal == JULIAN:
 		return y % 4 == 0
	elif cal == GREGORIAN:
		return  ((y % 4 == 0) and (y % 100 != 0)) or (y % 400 == 0)
	else:
		raise Exception('There are only two calendars')

def dayOfTheWeek(y, m, d): # t is 0:00UT
	JD = calcJD(y, m, d, 0.0) #works for both calendars

	JD += 1.5
	day = int(JD%7)

	#0: Sunday, 1: Monday, ..., 6: Saturday

	return day

def dayOfTheYear(y, m, d, cal=GREGORIAN): # t is 0:00UT
	k = 2 # common year (not a leap year)
	if isLeap(y, cal):
		k = 1

	return int((275*m)/9)-k*int((m+9)/12)+d-30

def dateFromDayOfTheYear(y, n, cal=GREGORIAN):
	k = 2 # common year (not a leap year)
	if isLeap(y, cal):
		k = 1

	m = int(9*(k+n)/275+1.98) #This was 0.98 in JM's book!!! To test!
	if n < 32:
		m = 1
	d = n-int((275*m)/9)+k*int((m+9)/12)+30

	return y, m, d

def decToDeg(num):
	"""Converts a float number to deg min sec"""
	num2 = math.fabs(num)
	d = int(num2)
	part = (num2-d)*60
	m = int(part)
	s = (part-m)*60
	dd = int(num)
	return (dd, m, s)

def degToDec(h, m, s):
	return h+m/60.0+s/3600.0


#def normalize(deg):
#	"""Adjusts deg between 0-360"""
#	while deg < 0.0:
#		deg += 360.0
#	while deg >= 360.0:
#		deg -= 360.0
#	return deg

def arcsecToDeg(s):
	s = math.fabs(s)
	d = int(s/3600)
	mm = (s-d*3600)/60
	m = int(mm)
	ss = (mm-m)*60

	return d, m, ss

# Given an x and y coordinate, return the angle formed by a line from the 
# origin to this coordinate. This is just converting from rectangular to  
# polar coordinates; however, we don't determine the radius here.         
def angle(x, y):
	if (x != 0.0): 
		if (y != 0.0):
			a = math.atan(y/x)
		else:
			if x < 0.0:
				a = math.pi
			else:
				a = 0.0
	else:
		if y < 0.0:
			a = -math.pi/2
		else:
			a = math.pi/2
	if (a < 0.0):
		a += math.pi
	if (y < 0.0):
		a += math.pi

	return a


def transform(lon, lat, tilt):
	"""(lon,lat,obl) is ecl2equ, (ra,decl,-obl) is equ2ecl, (ra,decl,90-lat) is EquToLocal"""
	rlon = math.radians(lon)
	rlat = math.radians(lat)
	rtilt = math.radians(tilt)

	sinalt = math.sin(rlat)
	cosalt = math.cos(rlat)
	sinazi = math.sin(rlon)
	sintilt = math.sin(rtilt)
	costilt = math.cos(rtilt)

	x = cosalt * sinazi * costilt
	y = sinalt * sintilt
	x -= y
	a1 = cosalt
	y = cosalt * math.cos(rlon)
	l1 = angle(y, x)
	a1 = a1 * sinazi * sintilt + sinalt * costilt
	a1 = math.asin(a1)

	return (math.degrees(l1), math.degrees(a1))


def normalize(x):
	y = math.fmod(x, 360.0)
	if (math.fabs(y) < 1e-13):
		y = 0.0
	if (y < 0.0):
		y += 360.0

	return y


def difdeg2n(p1, p2):
	dif = normalize(p1-p2)
	if (dif >= 180.0):
		return (dif-360.0)

	return dif


#############
#Housesystems

def houseWholeSign():
	hcs = [0.0]

	#within polar circle we swap AC/DC if AC is on wrong side
	acmc = difdeg2n(variables[ASCV], variables[MCV])
	if (acmc < 0):
		variables[ASCV] = normalize(variables[ASCV]+180)

	for i in range(1, HOUSE_NUM+1):
		hcs.append(normalize(int(variables[ASCV]/30)*30+(i-1)*30))

	return hcs


def houseEqual():
	hcs = [0.0]

	#within polar circle we swap AC/DC if AC is on wrong side
	acmc = difdeg2n(variables[ASCV], variables[MCV])
	if (acmc < 0):
		variables[ASCV] = normalize(variables[ASCV]+180)

	for i in range(1, HOUSE_NUM+1):
		hcs.append(normalize(variables[ASCV]+(i-1)*30))

	return hcs

def housePorphyry2(): #from Astrolog
	hcs = [0.0]*(HOUSE_NUM+1)

	asc = variables[ASCV]
	mc = variables[MCV]

	X = asc-mc
	if (X < 0.0):
		X += 360
	Y = X/3.0
	for i in range(1, 3):
		hcs[i+4] = normalize(180+mc+i*Y)
	X = normalize(180+mc)-asc
	if (X < 0.0):
		X += 360
	hcs[1] = asc
	Y = X/3.0
	for i in range(1, 4):
		hcs[i+1] = normalize(asc+i*Y)
	for i in range(1, 7):
		hcs[i+6] = normalize(hcs[i]+180)

	return hcs

def housePorphyry():
	hcs = [0.0]*(HOUSE_NUM+1)

	#within polar circle we swap AC/DC if AC is on wrong side
#	if (math.fabs(geolat) >= 90 - obliquity): 
	acmc = difdeg2n(variables[ASCV], variables[MCV])
	if (acmc < 0):
		variables[ASCV] = normalize(variables[ASCV]+180)

	asc = variables[ASCV]
	mc = variables[MCV]

	acmc = difdeg2n(asc, mc)
	hcs[1] = asc
	hcs[2] = normalize(asc+(180-acmc)/3)
	hcs[3] = normalize(asc+(180-acmc)/3*2)
	hcs[10] = mc
	hcs[11] = normalize(mc+acmc/3)
	hcs[12] = normalize(mc+acmc/3*2)
##
	hcs[4] = normalize(hcs[10]+180)
	hcs[5] = normalize(hcs[11]+180)
	hcs[6] = normalize(hcs[12]+180)
	hcs[7] = normalize(hcs[1]+180)
	hcs[8] = normalize(hcs[2]+180)
	hcs[9] = normalize(hcs[3]+180)

	return hcs

def Asc1(x1, f, sine, cose):
	x1 = normalize(x1)

	n  = (int) ((x1/90)+1)
	if (n == 1):
		ass = (Asc2(x1, f, sine, cose))
	elif (n == 2):
		ass = (180-Asc2(180-x1, -f, sine, cose))
	elif (n == 3):
		ass = (180+Asc2(x1-180, -f, sine, cose))
	else:
		ass = (360-Asc2(360-x1, f, sine, cose))
	ass = normalize(ass)
	if (math.fabs(ass-90) < VERY_SMALL):	# rounding, e.g.: if
		ass = 90				# fi = 0 & st = 0, ac = 89.999... 
	if (math.fabs(ass-180) < VERY_SMALL):
		ass = 180
	if (math.fabs(ass-270) < VERY_SMALL):	# rounding, e.g.: if 
		ass = 270				# fi = 0 & st = 0, ac = 89.999...
	if (math.fabs(ass-360) < VERY_SMALL):
		ass = 0

	return float(ass)

def Asc2(x, f, sine, cose):
	ass = -math.tan(math.radians(f))*sine+cose*math.cos(math.radians(x))
	if (math.fabs(ass) < VERY_SMALL):
		ass = 0
	sinx = math.sin(math.radians(x))
	if (math.fabs(sinx) < VERY_SMALL):
		sinx = 0
	if (sinx == 0):
		if (ass < 0):
			ass = -VERY_SMALL
		else:
			ass = VERY_SMALL
	elif (ass == 0):
		if (sinx < 0):
			ass = -90
		else:
			ass = 90
	else:
		ass = math.degrees(math.atan(sinx/ass))

	if (ass < 0):
		ass = 180+ass

	return float(ass)


def houseAlchabitius():
	hcs = [0.0]*(HOUSE_NUM+1)

	rAsc = math.radians(variables[ASCV])
	armc = variables[ARMCV]
	rObl = math.radians(obliquity)
	rGeolat = math.radians(geolat)

	rDecl = math.asin(math.sin(rObl)*math.sin(rAsc))
	r = -math.tan(rGeolat)*math.tan(rDecl)
	sda = math.degrees(math.acos(r))
	sna = 180-sda
	sinobl = math.sin(rObl)
	cosobl = math.cos(rObl)
	hcs[7] = Asc1(armc-sna, 0, sinobl, cosobl) 
	hcs[8] = Asc1(armc-sna*2.0/3.0, 0, sinobl, cosobl)
	hcs[9] = Asc1(armc-sna/3.0, 0, sinobl, cosobl)
	hcs[10] = variables[MCV]
	hcs[11] = Asc1(armc+sda/3.0, 0, sinobl, cosobl)
	hcs[12] = Asc1(armc+sda*2.0/3.0, 0, sinobl, cosobl)
	for i in range(7, HOUSE_NUM+1):
		hcs[i] = normalize(hcs[i])
	for i in range(1, 7):
		hcs[i] = normalize(hcs[i+6]+180)

	return hcs

def houseRegiomontanus2(): 
	hcs = [0.0]*(HOUSE_NUM+1)

	rARMC = math.radians(variables[ARMCV])
	rObl = math.radians(obliquity)
	rGeolat = math.radians(geolat)

	for i in range(1, HOUSE_NUM+1):
		rD = math.radians(60.0+30.0*i)
		rX = angle(math.cos(rARMC+rD)*math.cos(rObl)-math.sin(rD)*math.tan(rGeolat)*math.sin(rObl), math.sin(rARMC+rD))
		hcs[i] = normalize(math.degrees(rX))

	return hcs

def houseRegiomontanus():
	hcs = [0.0]*(HOUSE_NUM+1)

	asc = variables[ASCV]
	mc = variables[MCV]
	armc = variables[ARMCV]
	rObl = math.radians(obliquity)
	rGeolat = math.radians(geolat)
	sinobl = math.sin(rObl)
	cosobl = math.cos(rObl)

	fh1 = math.degrees(math.atan(math.tan(rGeolat)*0.5))
	fh2 = math.degrees(math.atan(math.tan(rGeolat)*math.cos(math.radians(30))))
	hcs[10] = mc
	hcs[11] = Asc1(30+armc, fh1, sinobl, cosobl) 
	hcs[12] = Asc1(60+armc, fh2, sinobl, cosobl) 
	hcs[1] = asc
	hcs[2] = Asc1(120+armc, fh2, sinobl, cosobl)
	hcs[3] = Asc1(150+armc, fh1, sinobl, cosobl)

	hcs[4] = normalize(hcs[10]+180)
	hcs[5] = normalize(hcs[11]+180)
	hcs[6] = normalize(hcs[12]+180)
	hcs[7] = normalize(hcs[1]+180)
	hcs[8] = normalize(hcs[2]+180)
	hcs[9] = normalize(hcs[3]+180)

	# within polar circle, when mc sinks below horizon and 
	# ascendant changes to western hemisphere, all cusps
	# must be added 180 degrees.
	# houses will be in clockwise direction
	if (math.fabs(geolat) >= 90-obliquity): # within polar circle
		acmc = difdeg2n(asc, mc)
		if (acmc < 0):
			variables[ASCV] = normalize(asc+180)
			variables[MCV] = normalize(mc+180)
		for i in range(1, HOUSE_NUM+1):
			hcs[i] = normalize(hcs[i]+180)

		if (acmc < 0):
			tmp = hcs[2]
			hcs[2] = hcs[12]
			hcs[12] = tmp
			tmp = hcs[3]
			hcs[3] = hcs[11]
			hcs[11] = tmp
			tmp = hcs[4]
			hcs[4] = hcs[10]
			hcs[10] = tmp
			tmp = hcs[5]
			hcs[5] = hcs[9]
			hcs[9] = tmp
			tmp = hcs[6]
			hcs[6] = hcs[8]
			hcs[8] = tmp

	return hcs


def cuspPlacidus(deg, FF, fNeg): 
	geol = geolat
	if geol == 0.0:
		geol = 0.0001

	rDeg = math.radians(deg)
	rARMC = math.radians(variables[ARMCV])
	rGeolat = math.radians(geol)
	rObl = math.radians(obliquity)

	R1 = rARMC+rDeg
	X = 1.0
	if not fNeg:
		X = -1.0

	# Looping 10 times is arbitrary, but it's what other programs do.
	for i in range(1, 11):
		# This formula works except at 0 latitude (AA == 0.0).
		XS = X*math.sin(R1)*math.tan(rObl)*math.tan(rGeolat)
		XS = math.acos(XS)
		if (XS < 0.0):
			XS += math.pi

		val = math.pi-(XS/FF)
		if not fNeg:
			val = XS/FF

		R1 = rARMC + val

	LO = math.atan(math.tan(R1)/math.cos(rObl))
	if (LO < 0.0):
		LO += math.pi
	if (math.sin(R1) < 0.0):
		LO += math.pi

	return math.degrees(LO)


def housePlacidus2(): 
	hcs = [0.0]*(HOUSE_NUM+1)

	asc = variables[ASCV]
	mc = variables[MCV]

	hcs[1] = asc
	hcs[4] = normalize(mc+180)
	hcs[5] = cuspPlacidus(30.0, 3.0, False) + 180
	hcs[6] = cuspPlacidus(60.0, 1.5, False) + 180
	hcs[2] = cuspPlacidus(120.0, 1.5, True)
	hcs[3] = cuspPlacidus(150.0, 3.0, True)
	for i in range(1, HOUSE_NUM+1):
		if (i <= 6):
			hcs[i] = normalize(hcs[i])
		else:
			hcs[i] = normalize(hcs[i-6]+180)

	return hcs

def housePlacidus():
	hcs = [0.0]*(HOUSE_NUM+1)

	armc = variables[ARMCV]
	mc = variables[MCV]
	asc = variables[ASCV]
	rGeolat = math.radians(geolat) #0 lat!?
	rObl = math.radians(obliquity)
	sinobl = math.sin(rObl)
	cosobl = math.cos(rObl)

	hcs[1] = asc
	hcs[10] = mc

	iteration_count = 2 #can be 1 or 2

	a = math.degrees(math.asin(math.tan(rGeolat)*math.tan(rObl)))
	fh1 = math.degrees(math.atan(math.sin(math.radians(a/3))/math.tan(rObl)))
	fh2 = math.degrees(math.atan(math.sin(math.radians(a*2/3))/math.tan(rObl)))

	#/* ************  house 11 ******************** */
	rectasc = normalize(30+armc)
	tant = math.tan(math.asin(sinobl*math.sin(math.radians(Asc1(rectasc, fh1, sinobl, cosobl)))))
	if (math.fabs(tant) < VERY_SMALL):
		hcs[11] = rectasc
	else:
		#/* pole height */
		f = math.degrees(math.atan(math.sin(math.asin(math.tan(rGeolat)*tant)/3)/tant))
		hcs[11] = Asc1(rectasc, f, sinobl, cosobl)
		for i in range(1, iteration_count+1):
			tant = math.tan(math.asin(sinobl*math.sin(math.radians(hcs[11]))))
			if (math.fabs(tant) < VERY_SMALL):
				hcs[11] = rectasc
				break
			#/* pole height */
			f = math.degrees(math.atan(math.sin(math.asin(math.tan(rGeolat)*tant)/3)/tant))
			hcs[11] = Asc1(rectasc, f, sinobl, cosobl)

	#/* ************  house 12 ******************** */
	rectasc = normalize(60+armc)
	tant = math.tan(math.asin(sinobl*math.sin(math.radians(Asc1(rectasc, fh2, sinobl, cosobl)))))
	if (math.fabs(tant) < VERY_SMALL):
		hcs[12] = rectasc
	else:
		f = math.degrees(math.atan(math.sin(math.asin(math.tan(rGeolat)*tant)/1.5)/tant))
		#/*  pole height */
		hcs[12] = Asc1(rectasc, f, sinobl, cosobl)
		for i in range(1, iteration_count+1):
			tant = math.tan(math.asin(sinobl*math.sin(math.radians(hcs[12]))))
			if (math.fabs(tant) < VERY_SMALL):
				hcs[12] = rectasc
				break
			f = math.degrees(math.atan(math.sin(math.asin(math.tan(rGeolat)*tant)/1.5)/tant))
			#/*  pole height */
			hcs[12] = Asc1(rectasc, f, sinobl, cosobl)

	#/* ************  house  2 ******************** */
	rectasc = normalize(120+armc)
	tant = math.tan(math.asin(sinobl*math.sin(math.radians(Asc1(rectasc, fh2, sinobl, cosobl)))))
	if (math.fabs(tant) < VERY_SMALL):
		hcs[2] = rectasc
	else:
		f = math.degrees(math.atan(math.sin(math.asin(math.tan(rGeolat)*tant)/1.5)/tant))
		#/*  pole height */
		hcs[2] = Asc1(rectasc, f, sinobl, cosobl)
		for i in range(1, iteration_count+1):
			tant = math.tan(math.asin(sinobl*math.sin(math.radians(hcs[2]))))
			if (math.fabs(tant) < VERY_SMALL):
				hcs[2] = rectasc
				break
			f = math.degrees(math.atan(math.sin(math.asin(math.tan(rGeolat)*tant)/1.5)/tant))
			#/*  pole height */
			hcs[2] = Asc1(rectasc, f, sinobl, cosobl)

	#/* ************  house  3 ******************** */
	rectasc = normalize(150+armc)
	tant = math.tan(math.asin(sinobl*math.sin(math.radians(Asc1(rectasc, fh1, sinobl, cosobl)))))
	if (math.fabs(tant) < VERY_SMALL):
		hcs[3] = rectasc
	else:
		f = math.degrees(math.atan(math.sin(math.asin(math.tan(rGeolat)*tant)/3)/tant))
		#/*  pole height */
		hcs[3] = Asc1(rectasc, f, sinobl, cosobl)
		for i in range(1, iteration_count+1):
			tant = math.tan(math.asin(sinobl*math.sin(math.radians(hcs[3]))))
			if (math.fabs(tant) < VERY_SMALL):
				hcs[3] = rectasc
				break
			f = math.degrees(math.atan(math.sin(math.asin(math.tan(rGeolat)*tant)/3)/tant))
			#/*  pole height */
			hcs[3] = Asc1(rectasc, f, sinobl, cosobl)

	hcs[4] = normalize(hcs[10]+180)
	hcs[5] = normalize(hcs[11]+180)
	hcs[6] = normalize(hcs[12]+180)
	hcs[7] = normalize(hcs[1]+180)
	hcs[8] = normalize(hcs[2]+180)
	hcs[9] = normalize(hcs[3]+180)

	return hcs

def computeHouses(hs):
	if (hs == WHOLESIGNHS):
		return houseWholeSign()
	elif (hs == EQUALHS):
		return houseEqual()
	elif (hs == PORPHYRYHS):
		return housePorphyry()
	elif (hs == ALCHABITIUSHS):
		if (math.fabs(geolat) >= 90-obliquity):
			return housePorphyry()
		else:
			return houseAlchabitius()
	elif (hs == REGIOMONTANUSHS):
		return houseRegiomontanus()
	else:
		if (math.fabs(geolat) >= 90-obliquity):
			return housePorphyry()
		else:
			return housePlacidus()


#def houseKoch()
#	rARMC = 

#	hcs = [0.0]*(HOUSE_NUM+1)

#	A1 = math.sin(rARMC)*math.tan(rGeolat)*math.tan(rObl)
#	A1 = math.asin(A1)
#	for in in range(1, HOUSE_NUM):
#		D = normalize(60.0+30.0*i)
#		A2 = D/(360/4)-1.0
#		KN = 1.0
#		if (D >= 360/2):
#			KN = -1.0
#			A2 = D/(360/4)-3.0
#		A3 = math.radians(normalize(armc+D+A2*math.degrees(A1)))
#		X = angle(math.cos(A3)*math.cos(rObl)-KN*math.tan(rGeolat)*math.sin(rObl), math.sin(A3))
#		hcs[i] = normalize(math.degrees(X))

#	return hcs

#Topocentric!?


