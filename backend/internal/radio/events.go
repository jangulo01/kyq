package radio

// Realtime events on user:{id} (specs/001-…/contracts/realtime.md, 011).
const (
	// EventMessage: a message is new or ready in a conversation of the user.
	EventMessage = "radio.message"
	// EventPresence: a contact or channel member changed state.
	EventPresence = "radio.presence"
	// EventAlert: a call alert that rings until opened (FR-022).
	EventAlert = "radio.alert"
	// EventEmergency: an emergency from Radio that rings even in Busy (FR-031).
	EventEmergency = "radio.emergency"
	// EventMember: membership changes (joined, request, role, removed, conversation deleted).
	EventMember = "radio.member"
	// EventInvite: a contact was requested or accepted.
	EventInvite = "radio.invite"
	// EventSettings: the panel changed a policy that affects the user.
	EventSettings = "radio.settings"
)
