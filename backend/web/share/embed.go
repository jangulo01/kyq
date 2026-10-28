// Package share embeds the public page of a shared live trip (003, research R5): one HTML file
// with MapLibre GL JS that polls GET /v1/share/{token} every 3 s. It loads in any browser
// without an account or the Flutter runtime.
package share

import _ "embed"

// Page is the html/template of GET /s/{token}; it receives StyleURL.
//
//go:embed index.html
var Page string
