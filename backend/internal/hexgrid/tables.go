// Code generated from H3 v4.4.1 (h3_baseCells.c, h3_faceijk.c; Uber, Apache-2.0). DO NOT EDIT.

package hexgrid

// baseCellData: cara "hogar" y coordenadas ijk+ normalizadas de cada celda base, y si es pentágono.
var baseCellData = [numBaseCells]baseCell{
	{faceIJK{1, coordIJK{1, 0, 0}}, false},  // base cell 0
	{faceIJK{2, coordIJK{1, 1, 0}}, false},  // base cell 1
	{faceIJK{1, coordIJK{0, 0, 0}}, false},  // base cell 2
	{faceIJK{2, coordIJK{1, 0, 0}}, false},  // base cell 3
	{faceIJK{0, coordIJK{2, 0, 0}}, true},   // base cell 4
	{faceIJK{1, coordIJK{1, 1, 0}}, false},  // base cell 5
	{faceIJK{1, coordIJK{0, 0, 1}}, false},  // base cell 6
	{faceIJK{2, coordIJK{0, 0, 0}}, false},  // base cell 7
	{faceIJK{0, coordIJK{1, 0, 0}}, false},  // base cell 8
	{faceIJK{2, coordIJK{0, 1, 0}}, false},  // base cell 9
	{faceIJK{1, coordIJK{0, 1, 0}}, false},  // base cell 10
	{faceIJK{1, coordIJK{0, 1, 1}}, false},  // base cell 11
	{faceIJK{3, coordIJK{1, 0, 0}}, false},  // base cell 12
	{faceIJK{3, coordIJK{1, 1, 0}}, false},  // base cell 13
	{faceIJK{11, coordIJK{2, 0, 0}}, true},  // base cell 14
	{faceIJK{4, coordIJK{1, 0, 0}}, false},  // base cell 15
	{faceIJK{0, coordIJK{0, 0, 0}}, false},  // base cell 16
	{faceIJK{6, coordIJK{0, 1, 0}}, false},  // base cell 17
	{faceIJK{0, coordIJK{0, 0, 1}}, false},  // base cell 18
	{faceIJK{2, coordIJK{0, 1, 1}}, false},  // base cell 19
	{faceIJK{7, coordIJK{0, 0, 1}}, false},  // base cell 20
	{faceIJK{2, coordIJK{0, 0, 1}}, false},  // base cell 21
	{faceIJK{0, coordIJK{1, 1, 0}}, false},  // base cell 22
	{faceIJK{6, coordIJK{0, 0, 1}}, false},  // base cell 23
	{faceIJK{10, coordIJK{2, 0, 0}}, true},  // base cell 24
	{faceIJK{6, coordIJK{0, 0, 0}}, false},  // base cell 25
	{faceIJK{3, coordIJK{0, 0, 0}}, false},  // base cell 26
	{faceIJK{11, coordIJK{1, 0, 0}}, false}, // base cell 27
	{faceIJK{4, coordIJK{1, 1, 0}}, false},  // base cell 28
	{faceIJK{3, coordIJK{0, 1, 0}}, false},  // base cell 29
	{faceIJK{0, coordIJK{0, 1, 1}}, false},  // base cell 30
	{faceIJK{4, coordIJK{0, 0, 0}}, false},  // base cell 31
	{faceIJK{5, coordIJK{0, 1, 0}}, false},  // base cell 32
	{faceIJK{0, coordIJK{0, 1, 0}}, false},  // base cell 33
	{faceIJK{7, coordIJK{0, 1, 0}}, false},  // base cell 34
	{faceIJK{11, coordIJK{1, 1, 0}}, false}, // base cell 35
	{faceIJK{7, coordIJK{0, 0, 0}}, false},  // base cell 36
	{faceIJK{10, coordIJK{1, 0, 0}}, false}, // base cell 37
	{faceIJK{12, coordIJK{2, 0, 0}}, true},  // base cell 38
	{faceIJK{6, coordIJK{1, 0, 1}}, false},  // base cell 39
	{faceIJK{7, coordIJK{1, 0, 1}}, false},  // base cell 40
	{faceIJK{4, coordIJK{0, 0, 1}}, false},  // base cell 41
	{faceIJK{3, coordIJK{0, 0, 1}}, false},  // base cell 42
	{faceIJK{3, coordIJK{0, 1, 1}}, false},  // base cell 43
	{faceIJK{4, coordIJK{0, 1, 0}}, false},  // base cell 44
	{faceIJK{6, coordIJK{1, 0, 0}}, false},  // base cell 45
	{faceIJK{11, coordIJK{0, 0, 0}}, false}, // base cell 46
	{faceIJK{8, coordIJK{0, 0, 1}}, false},  // base cell 47
	{faceIJK{5, coordIJK{0, 0, 1}}, false},  // base cell 48
	{faceIJK{14, coordIJK{2, 0, 0}}, true},  // base cell 49
	{faceIJK{5, coordIJK{0, 0, 0}}, false},  // base cell 50
	{faceIJK{12, coordIJK{1, 0, 0}}, false}, // base cell 51
	{faceIJK{10, coordIJK{1, 1, 0}}, false}, // base cell 52
	{faceIJK{4, coordIJK{0, 1, 1}}, false},  // base cell 53
	{faceIJK{12, coordIJK{1, 1, 0}}, false}, // base cell 54
	{faceIJK{7, coordIJK{1, 0, 0}}, false},  // base cell 55
	{faceIJK{11, coordIJK{0, 1, 0}}, false}, // base cell 56
	{faceIJK{10, coordIJK{0, 0, 0}}, false}, // base cell 57
	{faceIJK{13, coordIJK{2, 0, 0}}, true},  // base cell 58
	{faceIJK{10, coordIJK{0, 0, 1}}, false}, // base cell 59
	{faceIJK{11, coordIJK{0, 0, 1}}, false}, // base cell 60
	{faceIJK{9, coordIJK{0, 1, 0}}, false},  // base cell 61
	{faceIJK{8, coordIJK{0, 1, 0}}, false},  // base cell 62
	{faceIJK{6, coordIJK{2, 0, 0}}, true},   // base cell 63
	{faceIJK{8, coordIJK{0, 0, 0}}, false},  // base cell 64
	{faceIJK{9, coordIJK{0, 0, 1}}, false},  // base cell 65
	{faceIJK{14, coordIJK{1, 0, 0}}, false}, // base cell 66
	{faceIJK{5, coordIJK{1, 0, 1}}, false},  // base cell 67
	{faceIJK{16, coordIJK{0, 1, 1}}, false}, // base cell 68
	{faceIJK{8, coordIJK{1, 0, 1}}, false},  // base cell 69
	{faceIJK{5, coordIJK{1, 0, 0}}, false},  // base cell 70
	{faceIJK{12, coordIJK{0, 0, 0}}, false}, // base cell 71
	{faceIJK{7, coordIJK{2, 0, 0}}, true},   // base cell 72
	{faceIJK{12, coordIJK{0, 1, 0}}, false}, // base cell 73
	{faceIJK{10, coordIJK{0, 1, 0}}, false}, // base cell 74
	{faceIJK{9, coordIJK{0, 0, 0}}, false},  // base cell 75
	{faceIJK{13, coordIJK{1, 0, 0}}, false}, // base cell 76
	{faceIJK{16, coordIJK{0, 0, 1}}, false}, // base cell 77
	{faceIJK{15, coordIJK{0, 1, 1}}, false}, // base cell 78
	{faceIJK{15, coordIJK{0, 1, 0}}, false}, // base cell 79
	{faceIJK{16, coordIJK{0, 1, 0}}, false}, // base cell 80
	{faceIJK{14, coordIJK{1, 1, 0}}, false}, // base cell 81
	{faceIJK{13, coordIJK{1, 1, 0}}, false}, // base cell 82
	{faceIJK{5, coordIJK{2, 0, 0}}, true},   // base cell 83
	{faceIJK{8, coordIJK{1, 0, 0}}, false},  // base cell 84
	{faceIJK{14, coordIJK{0, 0, 0}}, false}, // base cell 85
	{faceIJK{9, coordIJK{1, 0, 1}}, false},  // base cell 86
	{faceIJK{14, coordIJK{0, 0, 1}}, false}, // base cell 87
	{faceIJK{17, coordIJK{0, 0, 1}}, false}, // base cell 88
	{faceIJK{12, coordIJK{0, 0, 1}}, false}, // base cell 89
	{faceIJK{16, coordIJK{0, 0, 0}}, false}, // base cell 90
	{faceIJK{17, coordIJK{0, 1, 1}}, false}, // base cell 91
	{faceIJK{15, coordIJK{0, 0, 1}}, false}, // base cell 92
	{faceIJK{16, coordIJK{1, 0, 1}}, false}, // base cell 93
	{faceIJK{9, coordIJK{1, 0, 0}}, false},  // base cell 94
	{faceIJK{15, coordIJK{0, 0, 0}}, false}, // base cell 95
	{faceIJK{13, coordIJK{0, 0, 0}}, false}, // base cell 96
	{faceIJK{8, coordIJK{2, 0, 0}}, true},   // base cell 97
	{faceIJK{13, coordIJK{0, 1, 0}}, false}, // base cell 98
	{faceIJK{17, coordIJK{1, 0, 1}}, false}, // base cell 99
	{faceIJK{19, coordIJK{0, 1, 0}}, false}, // base cell 100
	{faceIJK{14, coordIJK{0, 1, 0}}, false}, // base cell 101
	{faceIJK{19, coordIJK{0, 1, 1}}, false}, // base cell 102
	{faceIJK{17, coordIJK{0, 1, 0}}, false}, // base cell 103
	{faceIJK{13, coordIJK{0, 0, 1}}, false}, // base cell 104
	{faceIJK{17, coordIJK{0, 0, 0}}, false}, // base cell 105
	{faceIJK{16, coordIJK{1, 0, 0}}, false}, // base cell 106
	{faceIJK{9, coordIJK{2, 0, 0}}, true},   // base cell 107
	{faceIJK{15, coordIJK{1, 0, 1}}, false}, // base cell 108
	{faceIJK{15, coordIJK{1, 0, 0}}, false}, // base cell 109
	{faceIJK{18, coordIJK{0, 1, 1}}, false}, // base cell 110
	{faceIJK{18, coordIJK{0, 0, 1}}, false}, // base cell 111
	{faceIJK{19, coordIJK{0, 0, 1}}, false}, // base cell 112
	{faceIJK{17, coordIJK{1, 0, 0}}, false}, // base cell 113
	{faceIJK{19, coordIJK{0, 0, 0}}, false}, // base cell 114
	{faceIJK{18, coordIJK{0, 1, 0}}, false}, // base cell 115
	{faceIJK{18, coordIJK{1, 0, 1}}, false}, // base cell 116
	{faceIJK{19, coordIJK{2, 0, 0}}, true},  // base cell 117
	{faceIJK{19, coordIJK{1, 0, 0}}, false}, // base cell 118
	{faceIJK{18, coordIJK{0, 0, 0}}, false}, // base cell 119
	{faceIJK{19, coordIJK{1, 0, 1}}, false}, // base cell 120
	{faceIJK{18, coordIJK{1, 0, 0}}, false}, // base cell 121
}

// faceCenterGeo: centro de cada cara del icosaedro en radianes.
var faceCenterGeo = [numIcosaFaces]latLng{
	{0.803582649718989942, 1.248397419617396099},   // face  0
	{1.307747883455638156, 2.536945009877921159},   // face  1
	{1.054751253523952054, -1.347517358900396623},  // face  2
	{0.600191595538186799, -0.450603909469755746},  // face  3
	{0.491715428198773866, 0.401988202911306943},   // face  4
	{0.172745327415618701, 1.678146885280433686},   // face  5
	{0.605929321571350690, 2.953923329812411617},   // face  6
	{0.427370518328979641, -1.888876200336285401},  // face  7
	{-0.079066118549212831, -0.733429513380867741}, // face  8
	{-0.230961644455383637, 0.506495587332349035},  // face  9
	{0.079066118549212831, 2.408163140208925497},   // face 10
	{0.230961644455383637, -2.635097066257444203},  // face 11
	{-0.172745327415618701, -1.463445768309359553}, // face 12
	{-0.605929321571350690, -0.187669323777381622}, // face 13
	{-0.427370518328979641, 1.252716453253507838},  // face 14
	{-0.600191595538186799, 2.690988744120037492},  // face 15
	{-0.491715428198773866, -2.739604450678486295}, // face 16
	{-0.803582649718989942, -1.893195233972397139}, // face 17
	{-1.307747883455638156, -0.604647643711872080}, // face 18
	{-1.054751253523952054, 1.794075294689396615},  // face 19
}

// faceAxesAzRadsCII: acimut de los ejes i, j, k de cada cara (Clase II).
var faceAxesAzRadsCII = [numIcosaFaces][3]float64{
	{5.619958268523939882, 3.525563166130744542, 1.431168063737548730}, // face  0
	{5.760339081714187279, 3.665943979320991689, 1.571548876927796127}, // face  1
	{0.780213654393430055, 4.969003859179821079, 2.874608756786625655}, // face  2
	{0.430469363979999913, 4.619259568766391033, 2.524864466373195467}, // face  3
	{6.130269123335111400, 4.035874020941915804, 1.941478918548720291}, // face  4
	{2.692877706530642877, 0.598482604137447119, 4.787272808923838195}, // face  5
	{2.982963003477243874, 0.888567901084048369, 5.077358105870439581}, // face  6
	{3.532912002790141181, 1.438516900396945656, 5.627307105183336758}, // face  7
	{3.494305004259568154, 1.399909901866372864, 5.588700106652763840}, // face  8
	{3.003214169499538391, 0.908819067106342928, 5.097609271892733906}, // face  9
	{5.930472956509811562, 3.836077854116615875, 1.741682751723420374}, // face 10
	{0.138378484090254847, 4.327168688876645809, 2.232773586483450311}, // face 11
	{0.448714947059150361, 4.637505151845541521, 2.543110049452346120}, // face 12
	{0.158629650112549365, 4.347419854898940135, 2.253024752505744869}, // face 13
	{5.891865957979238535, 3.797470855586042958, 1.703075753192847583}, // face 14
	{2.711123289609793325, 0.616728187216597771, 4.805518392002988683}, // face 15
	{3.294508837434268316, 1.200113735041072948, 5.388903939827463911}, // face 16
	{3.804819692245439833, 1.710424589852244509, 5.899214794638635174}, // face 17
	{3.664438879055192436, 1.570043776661997111, 5.758833981448388027}, // face 18
	{2.361378999196363184, 0.266983896803167583, 4.455774101589558636}, // face 19
}

// faceNeighbors: para cada cara, ella misma y sus vecinas por los cuadrantes ij, ki y jk.
var faceNeighbors = [numIcosaFaces][4]faceOrientIJK{
	{{0, coordIJK{0, 0, 0}, 0}, {4, coordIJK{2, 0, 2}, 1}, {1, coordIJK{2, 2, 0}, 5}, {5, coordIJK{0, 2, 2}, 3}},
	{{1, coordIJK{0, 0, 0}, 0}, {0, coordIJK{2, 0, 2}, 1}, {2, coordIJK{2, 2, 0}, 5}, {6, coordIJK{0, 2, 2}, 3}},
	{{2, coordIJK{0, 0, 0}, 0}, {1, coordIJK{2, 0, 2}, 1}, {3, coordIJK{2, 2, 0}, 5}, {7, coordIJK{0, 2, 2}, 3}},
	{{3, coordIJK{0, 0, 0}, 0}, {2, coordIJK{2, 0, 2}, 1}, {4, coordIJK{2, 2, 0}, 5}, {8, coordIJK{0, 2, 2}, 3}},
	{{4, coordIJK{0, 0, 0}, 0}, {3, coordIJK{2, 0, 2}, 1}, {0, coordIJK{2, 2, 0}, 5}, {9, coordIJK{0, 2, 2}, 3}},
	{{5, coordIJK{0, 0, 0}, 0}, {10, coordIJK{2, 2, 0}, 3}, {14, coordIJK{2, 0, 2}, 3}, {0, coordIJK{0, 2, 2}, 3}},
	{{6, coordIJK{0, 0, 0}, 0}, {11, coordIJK{2, 2, 0}, 3}, {10, coordIJK{2, 0, 2}, 3}, {1, coordIJK{0, 2, 2}, 3}},
	{{7, coordIJK{0, 0, 0}, 0}, {12, coordIJK{2, 2, 0}, 3}, {11, coordIJK{2, 0, 2}, 3}, {2, coordIJK{0, 2, 2}, 3}},
	{{8, coordIJK{0, 0, 0}, 0}, {13, coordIJK{2, 2, 0}, 3}, {12, coordIJK{2, 0, 2}, 3}, {3, coordIJK{0, 2, 2}, 3}},
	{{9, coordIJK{0, 0, 0}, 0}, {14, coordIJK{2, 2, 0}, 3}, {13, coordIJK{2, 0, 2}, 3}, {4, coordIJK{0, 2, 2}, 3}},
	{{10, coordIJK{0, 0, 0}, 0}, {5, coordIJK{2, 2, 0}, 3}, {6, coordIJK{2, 0, 2}, 3}, {15, coordIJK{0, 2, 2}, 3}},
	{{11, coordIJK{0, 0, 0}, 0}, {6, coordIJK{2, 2, 0}, 3}, {7, coordIJK{2, 0, 2}, 3}, {16, coordIJK{0, 2, 2}, 3}},
	{{12, coordIJK{0, 0, 0}, 0}, {7, coordIJK{2, 2, 0}, 3}, {8, coordIJK{2, 0, 2}, 3}, {17, coordIJK{0, 2, 2}, 3}},
	{{13, coordIJK{0, 0, 0}, 0}, {8, coordIJK{2, 2, 0}, 3}, {9, coordIJK{2, 0, 2}, 3}, {18, coordIJK{0, 2, 2}, 3}},
	{{14, coordIJK{0, 0, 0}, 0}, {9, coordIJK{2, 2, 0}, 3}, {5, coordIJK{2, 0, 2}, 3}, {19, coordIJK{0, 2, 2}, 3}},
	{{15, coordIJK{0, 0, 0}, 0}, {16, coordIJK{2, 0, 2}, 1}, {19, coordIJK{2, 2, 0}, 5}, {10, coordIJK{0, 2, 2}, 3}},
	{{16, coordIJK{0, 0, 0}, 0}, {17, coordIJK{2, 0, 2}, 1}, {15, coordIJK{2, 2, 0}, 5}, {11, coordIJK{0, 2, 2}, 3}},
	{{17, coordIJK{0, 0, 0}, 0}, {18, coordIJK{2, 0, 2}, 1}, {16, coordIJK{2, 2, 0}, 5}, {12, coordIJK{0, 2, 2}, 3}},
	{{18, coordIJK{0, 0, 0}, 0}, {19, coordIJK{2, 0, 2}, 1}, {17, coordIJK{2, 2, 0}, 5}, {13, coordIJK{0, 2, 2}, 3}},
	{{19, coordIJK{0, 0, 0}, 0}, {15, coordIJK{2, 0, 2}, 1}, {18, coordIJK{2, 2, 0}, 5}, {14, coordIJK{0, 2, 2}, 3}},
}

// adjacentFaceDir: cuadrante (ij, ki, jk) por el que una cara toca a otra; -1 si no son vecinas.
var adjacentFaceDir = [numIcosaFaces][numIcosaFaces]int{
	{0, ki, -1, -1, ij, jk, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}, // face 0
	{ij, 0, ki, -1, -1, -1, jk, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}, // face 1
	{-1, ij, 0, ki, -1, -1, -1, jk, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}, // face 2
	{-1, -1, ij, 0, ki, -1, -1, -1, jk, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}, // face 3
	{ki, -1, -1, ij, 0, -1, -1, -1, -1, jk, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}, // face 4
	{jk, -1, -1, -1, -1, 0, -1, -1, -1, -1, ij, -1, -1, -1, ki, -1, -1, -1, -1, -1}, // face 5
	{-1, jk, -1, -1, -1, -1, 0, -1, -1, -1, ki, ij, -1, -1, -1, -1, -1, -1, -1, -1}, // face 6
	{-1, -1, jk, -1, -1, -1, -1, 0, -1, -1, -1, ki, ij, -1, -1, -1, -1, -1, -1, -1}, // face 7
	{-1, -1, -1, jk, -1, -1, -1, -1, 0, -1, -1, -1, ki, ij, -1, -1, -1, -1, -1, -1}, // face 8
	{-1, -1, -1, -1, jk, -1, -1, -1, -1, 0, -1, -1, -1, ki, ij, -1, -1, -1, -1, -1}, // face 9
	{-1, -1, -1, -1, -1, ij, ki, -1, -1, -1, 0, -1, -1, -1, -1, jk, -1, -1, -1, -1}, // face 10
	{-1, -1, -1, -1, -1, -1, ij, ki, -1, -1, -1, 0, -1, -1, -1, -1, jk, -1, -1, -1}, // face 11
	{-1, -1, -1, -1, -1, -1, -1, ij, ki, -1, -1, -1, 0, -1, -1, -1, -1, jk, -1, -1}, // face 12
	{-1, -1, -1, -1, -1, -1, -1, -1, ij, ki, -1, -1, -1, 0, -1, -1, -1, -1, jk, -1}, // face 13
	{-1, -1, -1, -1, -1, ki, -1, -1, -1, ij, -1, -1, -1, -1, 0, -1, -1, -1, -1, jk}, // face 14
	{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, jk, -1, -1, -1, -1, 0, ij, -1, -1, ki}, // face 15
	{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, jk, -1, -1, -1, ki, 0, ij, -1, -1}, // face 16
	{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, jk, -1, -1, -1, ki, 0, ij, -1}, // face 17
	{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, jk, -1, -1, -1, ki, 0, ij}, // face 18
	{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, jk, ij, -1, -1, ki, 0}, // face 19
}
