-- name: AddDriverUsage :exec
INSERT INTO driver_usage_daily (driver_id, day, voice_participant_seconds, realtime_events, route_requests)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (driver_id, day) DO UPDATE SET
    voice_participant_seconds = driver_usage_daily.voice_participant_seconds + EXCLUDED.voice_participant_seconds,
    realtime_events = driver_usage_daily.realtime_events + EXCLUDED.realtime_events,
    route_requests = driver_usage_daily.route_requests + EXCLUDED.route_requests;

-- name: ListDriverUsage :many
SELECT u.driver_id, COALESCE(us.display_name, '') AS display_name,
       SUM(u.voice_participant_seconds)::bigint AS voice_participant_seconds,
       SUM(u.realtime_events)::bigint AS realtime_events,
       SUM(u.route_requests)::bigint AS route_requests
FROM driver_usage_daily u
LEFT JOIN users us ON us.id = u.driver_id
WHERE u.day BETWEEN sqlc.arg(from_day) AND sqlc.arg(to_day)
GROUP BY u.driver_id, us.display_name
ORDER BY voice_participant_seconds DESC, realtime_events DESC;
