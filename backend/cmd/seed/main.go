// Command seed creates the first administrator from KYQ_SEED_ADMIN_PHONE. Idempotent.
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/google/uuid"

	"github.com/kyq/backend/internal/store"
)

func main() {
	if err := run(context.Background()); err != nil {
		fmt.Fprintln(os.Stderr, "seed:", err)
		os.Exit(1)
	}
}

func run(ctx context.Context) error {
	phone := os.Getenv("KYQ_SEED_ADMIN_PHONE")
	if phone == "" {
		return fmt.Errorf("KYQ_SEED_ADMIN_PHONE is required")
	}
	st, err := store.Open(ctx, os.Getenv("KYQ_DATABASE_URL"))
	if err != nil {
		return err
	}
	defer st.Close()

	existing, err := st.GetUserByPhone(ctx, phone)
	if err == nil {
		if existing.Role != store.UserRoleAdmin {
			return fmt.Errorf("%s ya existe con rol %s", phone, existing.Role)
		}
		fmt.Println("admin ya existe:", existing.ID)
		return grantOperator(ctx, st, existing.ID)
	}
	if !store.IsNotFound(err) {
		return err
	}
	id, err := uuid.NewV7()
	if err != nil {
		return err
	}
	if _, err := st.CreateUser(ctx, store.CreateUserParams{
		ID: id, PhoneE164: phone, Role: store.UserRoleAdmin, DisplayName: "Administrador",
	}); err != nil {
		return err
	}
	fmt.Println("admin creado:", id)
	return grantOperator(ctx, st, id)
}

// grantOperator makes the first administrator an emergency operator on duty (003, FR-011): the
// pilot needs someone to answer the SOS console. Idempotent.
func grantOperator(ctx context.Context, st *store.Store, id uuid.UUID) error {
	return st.GrantEmergencyOperator(ctx, store.GrantEmergencyOperatorParams{UserID: id, OnDuty: true})
}
