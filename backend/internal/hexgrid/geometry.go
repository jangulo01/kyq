package hexgrid

// Geometría de celdas H3 (centro y contorno) portada de la biblioteca H3 v4.4.1 de Uber
// (Apache-2.0): h3_faceijk.c, h3_coordijk.c, h3_h3Index.c, h3_latLng.c y h3_vec2d.c. Solo lo
// necesario para cellToLatLng y cellToBoundary; ver research.md (R1) de la especificación 007.

import (
	"math"
)

const (
	numBaseCells  = 122
	numIcosaFaces = 20
	numHexVerts   = 6
	numPentVerts  = 5

	epsilon         = 0.0000000000000001
	fltEpsilon      = 1.1920928955078125e-07
	m2Pi            = 6.28318530717958647692528676655900576839433
	mSqrt3_2        = 0.8660254037844386467637231707529361834714
	mOneThird       = 0.333333333333333333333333333333333333333
	mOneSeventh     = 0.14285714285714285714285714285714285
	mAp7RotRads     = 0.333473172251832115336090755351601070065900389
	mRSqrt7         = 0.37796447300922722721451653623418006081576
	res0UGnomonic   = 0.38196601125010500003
	maxH3Res        = 15
	h3PerDigitShift = 3
)

// Cuadrantes de faceNeighbors.
const (
	ij = 1
	ki = 2
	jk = 3
)

type overage int

const (
	noOverage overage = iota
	faceEdge
	newFace
)

type latLng struct{ lat, lng float64 }

type vec2d struct{ x, y float64 }

type coordIJK struct{ i, j, k int }

type faceIJK struct {
	face  int
	coord coordIJK
}

type faceOrientIJK struct {
	face      int
	translate coordIJK
	ccwRot60  int
}

type baseCell struct {
	home       faceIJK
	isPentagon bool
}

var unitVecs = [7]coordIJK{{0, 0, 0}, {0, 0, 1}, {0, 1, 0}, {0, 1, 1}, {1, 0, 0}, {1, 0, 1}, {1, 1, 0}}

var maxDimByCIIres = [17]int{2, -1, 14, -1, 98, -1, 686, -1, 4802, -1, 33614, -1, 235298, -1, 1647086, -1, 11529602}

var unitScaleByCIIres = [17]int{1, -1, 7, -1, 49, -1, 343, -1, 2401, -1, 16807, -1, 117649, -1, 823543, -1, 5764801}

func isClassIII(res int) bool { return res%2 == 1 }

// Índice H3: resolución, celda base y dígitos.

func cellRes(h uint64) int      { return int((h >> 52) & 15) }
func cellBase(h uint64) int     { return int((h >> 45) & 127) }
func digit(h uint64, r int) int { return int((h >> ((maxH3Res - r) * h3PerDigitShift)) & 7) }

func setDigit(h uint64, r, d int) uint64 {
	shift := (maxH3Res - r) * h3PerDigitShift
	return (h &^ (uint64(7) << shift)) | (uint64(d) << shift)
}

func leadingNonZeroDigit(h uint64) int {
	for r := 1; r <= cellRes(h); r++ {
		if d := digit(h, r); d != 0 {
			return d
		}
	}
	return 0
}

func rotateDigit60cw(d int) int {
	switch d {
	case 1:
		return 3
	case 3:
		return 2
	case 2:
		return 6
	case 6:
		return 4
	case 4:
		return 5
	case 5:
		return 1
	}
	return d
}

func rotate60cw(h uint64) uint64 {
	for r := 1; r <= cellRes(h); r++ {
		h = setDigit(h, r, rotateDigit60cw(digit(h, r)))
	}
	return h
}

func isPentagon(h uint64) bool {
	return baseCellData[cellBase(h)].isPentagon && leadingNonZeroDigit(h) == 0
}

// Coordenadas ijk.

func (c *coordIJK) add(o coordIJK) { c.i += o.i; c.j += o.j; c.k += o.k }

func (c *coordIJK) scale(f int) { c.i *= f; c.j *= f; c.k *= f }

func (c *coordIJK) normalize() {
	if c.i < 0 {
		c.j -= c.i
		c.k -= c.i
		c.i = 0
	}
	if c.j < 0 {
		c.i -= c.j
		c.k -= c.j
		c.j = 0
	}
	if c.k < 0 {
		c.i -= c.k
		c.j -= c.k
		c.k = 0
	}
	m := min(c.i, c.j, c.k)
	if m > 0 {
		c.i -= m
		c.j -= m
		c.k -= m
	}
}

// combine sustituye c por c.i·iv + c.j·jv + c.k·kv normalizado (rotaciones y cambios de
// apertura de H3).
func (c *coordIJK) combine(iv, jv, kv coordIJK) {
	iv.scale(c.i)
	jv.scale(c.j)
	kv.scale(c.k)
	iv.add(jv)
	iv.add(kv)
	*c = iv
	c.normalize()
}

func (c *coordIJK) downAp7()       { c.combine(coordIJK{3, 0, 1}, coordIJK{1, 3, 0}, coordIJK{0, 1, 3}) }
func (c *coordIJK) downAp7r()      { c.combine(coordIJK{3, 1, 0}, coordIJK{0, 3, 1}, coordIJK{1, 0, 3}) }
func (c *coordIJK) downAp3()       { c.combine(coordIJK{2, 0, 1}, coordIJK{1, 2, 0}, coordIJK{0, 1, 2}) }
func (c *coordIJK) downAp3r()      { c.combine(coordIJK{2, 1, 0}, coordIJK{0, 2, 1}, coordIJK{1, 0, 2}) }
func (c *coordIJK) rotate60ccw()   { c.combine(coordIJK{1, 1, 0}, coordIJK{0, 1, 1}, coordIJK{1, 0, 1}) }
func (c *coordIJK) neighbor(d int) { c.addUnit(d) }

func (c *coordIJK) addUnit(d int) {
	if d > 0 && d < 7 {
		c.add(unitVecs[d])
		c.normalize()
	}
}

func (c *coordIJK) upAp7r() {
	i := c.i - c.k
	j := c.j - c.k
	c.i = int(math.Round(float64(2*i+j) * mOneSeventh))
	c.j = int(math.Round(float64(3*j-i) * mOneSeventh))
	c.k = 0
	c.normalize()
}

func (c coordIJK) hex2d() vec2d {
	i := c.i - c.k
	j := c.j - c.k
	return vec2d{x: float64(i) - 0.5*float64(j), y: float64(j) * mSqrt3_2}
}

// Proyección gnomónica de cada cara del icosaedro.

func posAngleRads(rads float64) float64 {
	tmp := rads
	if rads < 0 {
		tmp = rads + m2Pi
	}
	if rads >= m2Pi {
		tmp -= m2Pi
	}
	return tmp
}

func constrainLng(lng float64) float64 {
	for lng > math.Pi {
		lng -= 2 * math.Pi
	}
	for lng < -math.Pi {
		lng += 2 * math.Pi
	}
	return lng
}

func geoAzDistanceRads(p1 latLng, az, distance float64) latLng {
	if distance < epsilon {
		return p1
	}
	var p2 latLng
	az = posAngleRads(az)
	if az < epsilon || math.Abs(az-math.Pi) < epsilon {
		if az < epsilon {
			p2.lat = p1.lat + distance
		} else {
			p2.lat = p1.lat - distance
		}
		switch {
		case math.Abs(p2.lat-math.Pi/2) < epsilon:
			p2 = latLng{math.Pi / 2, 0}
		case math.Abs(p2.lat+math.Pi/2) < epsilon:
			p2 = latLng{-math.Pi / 2, 0}
		default:
			p2.lng = constrainLng(p1.lng)
		}
		return p2
	}
	sinlat := math.Sin(p1.lat)*math.Cos(distance) + math.Cos(p1.lat)*math.Sin(distance)*math.Cos(az)
	sinlat = math.Max(-1, math.Min(1, sinlat))
	p2.lat = math.Asin(sinlat)
	switch {
	case math.Abs(p2.lat-math.Pi/2) < epsilon:
		return latLng{math.Pi / 2, 0}
	case math.Abs(p2.lat+math.Pi/2) < epsilon:
		return latLng{-math.Pi / 2, 0}
	}
	inv := 1.0 / math.Cos(p2.lat)
	sinlng := math.Sin(az) * math.Sin(distance) * inv
	coslng := (math.Cos(distance) - math.Sin(p1.lat)*math.Sin(p2.lat)) / math.Cos(p1.lat) * inv
	sinlng = math.Max(-1, math.Min(1, sinlng))
	coslng = math.Max(-1, math.Min(1, coslng))
	p2.lng = constrainLng(p1.lng + math.Atan2(sinlng, coslng))
	return p2
}

func hex2dToGeo(v vec2d, face, res int, substrate bool) latLng {
	r := math.Hypot(v.x, v.y)
	if r < epsilon {
		return faceCenterGeo[face]
	}
	theta := math.Atan2(v.y, v.x)
	for range res {
		r *= mRSqrt7
	}
	if substrate {
		r *= mOneThird
		if isClassIII(res) {
			r *= mRSqrt7
		}
	}
	r *= res0UGnomonic
	r = math.Atan(r)
	if !substrate && isClassIII(res) {
		theta = posAngleRads(theta + mAp7RotRads)
	}
	theta = posAngleRads(faceAxesAzRadsCII[face][0] - theta)
	return geoAzDistanceRads(faceCenterGeo[face], theta, r)
}

func v2dIntersect(p0, p1, p2, p3 vec2d) vec2d {
	s1 := vec2d{p1.x - p0.x, p1.y - p0.y}
	s2 := vec2d{p3.x - p2.x, p3.y - p2.y}
	t := (s2.x*(p0.y-p2.y) - s2.y*(p0.x-p2.x)) / (-s2.x*s1.y + s1.x*s2.y)
	return vec2d{p0.x + t*s1.x, p0.y + t*s1.y}
}

func v2dAlmostEquals(a, b vec2d) bool {
	return math.Abs(a.x-b.x) < fltEpsilon && math.Abs(a.y-b.y) < fltEpsilon
}

// Índice H3 → cara e ijk.

func adjustOverageClassII(f *faceIJK, res int, pentLeading4, substrate bool) overage {
	ov := noOverage
	c := &f.coord
	maxDim := maxDimByCIIres[res]
	if substrate {
		maxDim *= 3
	}
	sum := c.i + c.j + c.k
	if substrate && sum == maxDim {
		return faceEdge
	}
	if sum <= maxDim {
		return ov
	}
	ov = newFace
	var orient faceOrientIJK
	switch {
	case c.k > 0 && c.j > 0:
		orient = faceNeighbors[f.face][jk]
	case c.k > 0:
		orient = faceNeighbors[f.face][ki]
		if pentLeading4 {
			origin := coordIJK{maxDim, 0, 0}
			tmp := coordIJK{c.i - origin.i, c.j - origin.j, c.k - origin.k}
			tmp.combine(coordIJK{1, 0, 1}, coordIJK{1, 1, 0}, coordIJK{0, 1, 1}) // rotación 60° horaria
			tmp.add(origin)
			*c = tmp
		}
	default:
		orient = faceNeighbors[f.face][ij]
	}
	f.face = orient.face
	for range orient.ccwRot60 {
		c.rotate60ccw()
	}
	trans := orient.translate
	unitScale := unitScaleByCIIres[res]
	if substrate {
		unitScale *= 3
	}
	trans.scale(unitScale)
	c.add(trans)
	c.normalize()
	if substrate && c.i+c.j+c.k == maxDim {
		ov = faceEdge
	}
	return ov
}

func toFaceIJK(h uint64) faceIJK {
	bc := cellBase(h)
	if baseCellData[bc].isPentagon && leadingNonZeroDigit(h) == 5 {
		h = rotate60cw(h)
	}
	f := baseCellData[bc].home
	res := cellRes(h)
	possibleOverage := baseCellData[bc].isPentagon || (res != 0 && f.coord != coordIJK{})
	for r := 1; r <= res; r++ {
		if isClassIII(r) {
			f.coord.downAp7()
		} else {
			f.coord.downAp7r()
		}
		f.coord.neighbor(digit(h, r))
	}
	if !possibleOverage {
		return f
	}
	orig := f.coord
	adjRes := res
	if isClassIII(adjRes) {
		f.coord.downAp7r()
		adjRes++
	}
	pentLeading4 := baseCellData[bc].isPentagon && leadingNonZeroDigit(h) == 4
	if adjustOverageClassII(&f, adjRes, pentLeading4, false) != noOverage {
		if baseCellData[bc].isPentagon {
			for adjustOverageClassII(&f, adjRes, false, false) != noOverage {
			}
		}
		if adjRes != res {
			f.coord.upAp7r()
		}
	} else if adjRes != res {
		f.coord = orig
	}
	return f
}

// Vértices.

var (
	vertsCII  = [6]coordIJK{{2, 1, 0}, {1, 2, 0}, {0, 2, 1}, {0, 1, 2}, {1, 0, 2}, {2, 0, 1}}
	vertsCIII = [6]coordIJK{{5, 4, 0}, {1, 5, 0}, {0, 5, 4}, {0, 1, 5}, {4, 0, 5}, {5, 0, 1}}
)

// cellVerts devuelve los vértices de la celda en la cuadrícula sustrato y la resolución ajustada
// (Clase III baja a la Clase II siguiente).
func cellVerts(f faceIJK, res, n int) ([]faceIJK, int) {
	verts := vertsCII
	f.coord.downAp3()
	f.coord.downAp3r()
	if isClassIII(res) {
		verts = vertsCIII
		f.coord.downAp7r()
		res++
	}
	out := make([]faceIJK, n)
	for v := range n {
		c := f.coord
		c.add(verts[v])
		c.normalize()
		out[v] = faceIJK{face: f.face, coord: c}
	}
	return out, res
}

// edgeOf devuelve el lado de la cara (en coordenadas 2D del sustrato) por el que se pasa a la
// cara vecina en el cuadrante dir.
func edgeOf(dir, adjRes int) (vec2d, vec2d) {
	maxDim := float64(maxDimByCIIres[adjRes])
	v0 := vec2d{3.0 * maxDim, 0.0}
	v1 := vec2d{-1.5 * maxDim, 3.0 * mSqrt3_2 * maxDim}
	v2 := vec2d{-1.5 * maxDim, -3.0 * mSqrt3_2 * maxDim}
	switch dir {
	case ij:
		return v0, v1
	case jk:
		return v1, v2
	default:
		return v2, v0
	}
}

func hexBoundary(center faceIJK, res int) []latLng {
	fijkVerts, adjRes := cellVerts(center, res, numHexVerts)
	var out []latLng
	lastFace := -1
	lastOverage := noOverage
	for vert := 0; vert < numHexVerts+1; vert++ {
		v := vert % numHexVerts
		fijk := fijkVerts[v]
		ov := adjustOverageClassII(&fijk, adjRes, false, true)
		// Un lado que cruza una arista del icosaedro necesita un vértice extra en el cruce.
		if isClassIII(res) && vert > 0 && fijk.face != lastFace && lastOverage != faceEdge {
			lastV := (v + 5) % numHexVerts
			orig0 := fijkVerts[lastV].coord.hex2d()
			orig1 := fijkVerts[v].coord.hex2d()
			face2 := lastFace
			if lastFace == center.face {
				face2 = fijk.face
			}
			e0, e1 := edgeOf(adjacentFaceDir[center.face][face2], adjRes)
			inter := v2dIntersect(orig0, orig1, e0, e1)
			if !v2dAlmostEquals(orig0, inter) && !v2dAlmostEquals(orig1, inter) {
				out = append(out, hex2dToGeo(inter, center.face, adjRes, true))
			}
		}
		if vert < numHexVerts {
			out = append(out, hex2dToGeo(fijk.coord.hex2d(), fijk.face, adjRes, true))
		}
		lastFace = fijk.face
		lastOverage = ov
	}
	return out
}

func pentBoundary(center faceIJK, res int) []latLng {
	fijkVerts, adjRes := cellVerts(center, res, numPentVerts)
	var out []latLng
	var last faceIJK
	for vert := 0; vert < numPentVerts+1; vert++ {
		v := vert % numPentVerts
		fijk := fijkVerts[v]
		for adjustOverageClassII(&fijk, adjRes, false, true) == newFace {
		}
		if isClassIII(res) && vert > 0 {
			tmp := fijk
			orig0 := last.coord.hex2d()
			orient := faceNeighbors[tmp.face][adjacentFaceDir[tmp.face][last.face]]
			tmp.face = orient.face
			for range orient.ccwRot60 {
				tmp.coord.rotate60ccw()
			}
			trans := orient.translate
			trans.scale(unitScaleByCIIres[adjRes] * 3)
			tmp.coord.add(trans)
			tmp.coord.normalize()
			orig1 := tmp.coord.hex2d()
			e0, e1 := edgeOf(adjacentFaceDir[tmp.face][fijk.face], adjRes)
			inter := v2dIntersect(orig0, orig1, e0, e1)
			out = append(out, hex2dToGeo(inter, tmp.face, adjRes, true))
		}
		if vert < numPentVerts {
			out = append(out, hex2dToGeo(fijk.coord.hex2d(), fijk.face, adjRes, true))
		}
		last = fijk
	}
	return out
}
