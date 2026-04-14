
DROP TRIGGER IF EXISTS trg_n8n_trigger ON public.events;

CREATE OR REPLACE FUNCTION public.notify_n8n_event()
RETURNS TRIGGER AS $$
DECLARE
  payload jsonb;
BEGIN
  SELECT jsonb_build_object(
    'event_id', NEW.id,
    'data', to_jsonb(NEW),
    'user', jsonb_build_object(
        'name', u.name,
        'phone', u.phone
    ),
    'channel', jsonb_build_object(
        'id', c.id,
        'name', c.name
    )
  ) INTO payload
  FROM public.event_users u
  LEFT JOIN public.channels c ON c.id = NEW.channel_id
  WHERE u.id = NEW.user_id;
  IF payload IS NULL THEN
    payload := to_jsonb(NEW);
  END IF;
  PERFORM pg_notify('n8n_events', payload::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_n8n_trigger
AFTER INSERT ON public.events
FOR EACH ROW
EXECUTE FUNCTION notify_n8n_event();