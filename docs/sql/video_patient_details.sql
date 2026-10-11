-- Applied as the Supabase migration add_video_patient_details.
CREATE SCHEMA IF NOT EXISTS ientier_private;
REVOKE ALL ON SCHEMA ientier_private FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA ientier_private TO authenticated;

-- A scoped read avoids giving professionals general access to patient tables.
CREATE OR REPLACE FUNCTION ientier_private.video_patient_details(p_appointment_id text)
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  appointment ientier.appointments%ROWTYPE;
  result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO appointment FROM ientier.appointments a
  WHERE a.appointment_id = p_appointment_id
    AND a.provider_id = auth.uid()::text
    AND a.mode = 'video' AND a.status = 'confirmed'
    AND NOT a.provider_hidden;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;
  SELECT jsonb_build_object(
    'name', appointment.patient_name_snapshot,
    'service', appointment.service_name_snapshot,
    'scheduled_at', appointment.scheduled_at,
    'patient_note', appointment.patient_note,
    'sex', p.sex, 'birth_date', p.birth_date,
    'weight_kg', p.weight_kg, 'height_cm', p.height_cm,
    'phone', p.phone, 'address', p.address, 'blood_type', p.blood_type,
    'special_needs', p.special_needs, 'pregnancy_status', p.pregnancy_status,
    'primary_doctor', p.primary_doctor, 'insurance', p.insurance,
    'medical_items', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'type', m.item_type, 'label', m.label, 'details', m.details
      ) ORDER BY m.item_type, m.label)
      FROM ientier.patient_medical_items m
      WHERE m.patient_id = p.patient_id AND m.active
    ), '[]'::jsonb)
  ) INTO result FROM ientier.patient_profiles p
  WHERE p.patient_id = appointment.patient_id;
  RETURN result;
END;
$$;
REVOKE ALL ON FUNCTION ientier_private.video_patient_details(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION ientier_private.video_patient_details(text) TO authenticated;

CREATE OR REPLACE FUNCTION ientier.video_patient_details(p_appointment_id text)
RETURNS jsonb
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = ''
AS $$ SELECT ientier_private.video_patient_details(p_appointment_id); $$;
REVOKE ALL ON FUNCTION ientier.video_patient_details(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION ientier.video_patient_details(text) TO authenticated;
