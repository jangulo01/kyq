// Command domainsign prepares the mirror domains of the apps (spec 009, research R7): it creates
// a signing key, prints its public key, or signs the bootstrap list the apps carry for their
// first start.
//
//	go run ./cmd/domainsign -new-key
//	KYQ_DOMAINS_SIGNING_KEY=… go run ./cmd/domainsign -print-public-key
//	KYQ_DOMAINS_SIGNING_KEY=… go run ./cmd/domainsign -api https://api.kyq.co -realtime wss://rt.kyq.co/connection/websocket
package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/kyq/backend/internal/domains"
)

type list []string

func (l *list) String() string     { return strings.Join(*l, ",") }
func (l *list) Set(v string) error { *l = append(*l, v); return nil }

func main() {
	var apis, realtimes list
	newKey := flag.Bool("new-key", false, "imprime una semilla Ed25519 nueva en base64 para KYQ_DOMAINS_SIGNING_KEY")
	printPublic := flag.Bool("print-public-key", false, "imprime la clave pública para KYQ_DOMAINS_PUBLIC_KEY de las apps")
	flag.Var(&apis, "api", "URL de la API (repetible, en orden)")
	flag.Var(&realtimes, "realtime", "URL del tiempo real de cada -api (repetible, en el mismo orden)")
	flag.Parse()

	if *newKey {
		seed := make([]byte, ed25519.SeedSize)
		if _, err := rand.Read(seed); err != nil {
			fail(err)
		}
		fmt.Println(base64.StdEncoding.EncodeToString(seed))
		return
	}
	signer, err := domains.NewSigner(os.Getenv("KYQ_DOMAINS_SIGNING_KEY"))
	if err != nil {
		fail(err)
	}
	if *printPublic {
		fmt.Println(signer.PublicKey())
		return
	}
	if len(apis) == 0 || len(apis) != len(realtimes) {
		fail(fmt.Errorf("indica al menos un -api con su -realtime"))
	}
	// Versión 0: cualquier lista del servidor (versión 1 o mayor) la reemplaza.
	p := domains.Payload{Version: 0, IssuedAt: time.Now().UTC().Truncate(time.Second)}
	for i := range apis {
		p.Domains = append(p.Domains, domains.Entry{APIURL: strings.TrimRight(apis[i], "/"), RealtimeURL: realtimes[i]})
	}
	signed, err := signer.Sign(p)
	if err != nil {
		fail(err)
	}
	out, err := json.Marshal(signed)
	if err != nil {
		fail(err)
	}
	fmt.Println(string(out))
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, "domainsign:", err)
	os.Exit(1)
}
