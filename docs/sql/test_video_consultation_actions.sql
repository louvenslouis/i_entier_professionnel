-- No clinical record or notification survives this transaction.
BEGIN;
DO $$
DECLARE
 a record;
 doc jsonb;
 repeated jsonb;
 request uuid := gen_random_uuid();
 body jsonb;
 new_date timestamptz;
 rx text;
 exam_key text;
 count_before bigint;
 denied boolean;
BEGIN
 SELECT ap.* INTO a FROM ientier.appointments ap
 JOIN ientier.provider_profiles p ON p.provider_id=ap.provider_id
 WHERE ap.mode='video' AND ap.status='confirmed' AND NOT ap.provider_hidden
 AND p.verification_status='approved' LIMIT 1;
 IF NOT FOUND THEN RAISE EXCEPTION 'No eligible consultation fixture'; END IF;
 PERFORM set_config('request.jwt.claim.sub',a.provider_id,true);
 body := '{"diagnosis":"TEST rollback diagnostic","symptoms":"TEST","observations":"TEST","plan":"TEST"}'::jsonb;
 SELECT count(*) INTO count_before FROM ientier.notifications;
 doc := ientier.publish_video_consultation(a.appointment_id,request,'diagnosis',body);
 repeated := ientier.publish_video_consultation(a.appointment_id,request,'diagnosis',body);
 IF doc->>'document_id'<>repeated->>'document_id' OR (SELECT count(*) FROM ientier.notifications)<>count_before+1 THEN
   RAISE EXCEPTION 'Idempotency failed';
 END IF;
 denied := false;
 BEGIN PERFORM ientier.publish_video_consultation(a.appointment_id,request,'diagnosis','{"diagnosis":"Different"}'::jsonb);
 EXCEPTION WHEN invalid_parameter_value THEN denied := true; END;
 IF NOT denied THEN RAISE EXCEPTION 'Mismatched retry accepted'; END IF;
 doc := ientier.publish_video_consultation(a.appointment_id,gen_random_uuid(),'prescription',
   '{"items":[{"medication_name":"TEST medication","dosage":"TEST dosage","frequency":"TEST frequency","duration_days":3,"administration_route":"TEST","instructions":"TEST"}],"notes":"TEST rollback"}'::jsonb);
 rx := doc->>'prescription_id';
 IF rx IS NULL OR (SELECT count(*) FROM ientier.prescription_items WHERE prescription_id=rx)<>1
   OR NOT EXISTS(SELECT 1 FROM ientier.prescriptions WHERE prescription_id=rx AND patient_id=a.patient_id AND doctor_id=a.provider_id AND source='doctor' AND length(transcription)>0)
   OR NOT EXISTS(SELECT 1 FROM ientier.notifications WHERE prescription_id=rx AND source='prescription') THEN
   RAISE EXCEPTION 'Prescription connector failed';
 END IF;
 denied := false;
 BEGIN UPDATE ientier.prescription_items SET dosage='changed' WHERE prescription_id=rx;
 EXCEPTION WHEN insufficient_privilege THEN denied := true; END;
 IF NOT denied THEN RAISE EXCEPTION 'Issued prescription was editable'; END IF;
 SELECT exam_id INTO exam_key FROM ientier.laboratory_exam_catalog WHERE active LIMIT 1;
 doc := ientier.publish_video_consultation(a.appointment_id,gen_random_uuid(),'exams',jsonb_build_object(
   'items',jsonb_build_array(jsonb_build_object('exam_id',exam_key,'name','TEST','instructions','TEST rollback')),
   'priority','routine','indication','TEST rollback'));
 IF NOT EXISTS(SELECT 1 FROM ientier.laboratory_exam_requests WHERE document_id=(doc->>'document_id')::uuid AND patient_id=a.patient_id) THEN
   RAISE EXCEPTION 'Laboratory connector failed';
 END IF;
 SELECT slot INTO new_date FROM generate_series(now()+interval '20 days',now()+interval '21 days',interval '1 hour') slot
 WHERE NOT EXISTS(SELECT 1 FROM ientier.appointments booked
   WHERE (booked.provider_id=a.provider_id OR booked.patient_id=a.patient_id) AND booked.status IN ('pending','confirmed')
   AND abs(extract(epoch FROM (booked.scheduled_at-slot)))<1800) LIMIT 1;
 doc := ientier.publish_video_consultation(a.appointment_id,gen_random_uuid(),'followup',jsonb_build_object(
   'scheduled_at',new_date,'mode','video','location','','note','TEST rollback'));
 IF NOT EXISTS(SELECT 1 FROM ientier.appointments WHERE appointment_id=doc->>'followup_appointment_id' AND patient_id=a.patient_id AND status='confirmed')
   OR (SELECT scheduled_at FROM ientier.appointments WHERE appointment_id=a.appointment_id)<>a.scheduled_at THEN
   RAISE EXCEPTION 'Followup connector failed';
 END IF;
 denied := false;
 BEGIN PERFORM ientier.publish_video_consultation(a.appointment_id,gen_random_uuid(),'followup',jsonb_build_object('scheduled_at',new_date,'mode','video'));
 EXCEPTION WHEN unique_violation THEN denied := true; END;
 IF NOT denied THEN RAISE EXCEPTION 'Occupied slot accepted'; END IF;
 -- Exercise the same database role as PostgREST, including private RPC grants.
 EXECUTE 'SET LOCAL ROLE authenticated';
 repeated := ientier.publish_video_consultation(a.appointment_id,request,'diagnosis',body);
 IF repeated->>'document_id'<>request::text THEN RAISE EXCEPTION 'Authenticated RPC failed'; END IF;
 PERFORM set_config('request.jwt.claim.sub',a.patient_id,true);
 IF (SELECT count(*) FROM ientier.consultation_documents WHERE appointment_id=a.appointment_id)<4 THEN
   RAISE EXCEPTION 'Patient cannot read shared documents';
 END IF;
 IF has_table_privilege(current_user,'ientier.consultation_documents','INSERT,UPDATE,DELETE') THEN
   RAISE EXCEPTION 'Documents have direct write grants';
 END IF;
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',a.patient_id,'is_anonymous',true)::text,true);
 IF EXISTS(SELECT 1 FROM ientier.consultation_documents WHERE appointment_id=a.appointment_id) THEN
   RAISE EXCEPTION 'Anonymous session can read documents';
 END IF;
 PERFORM set_config('request.jwt.claims','{}',true);
 PERFORM set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
 IF EXISTS(SELECT 1 FROM ientier.consultation_documents WHERE appointment_id=a.appointment_id)
    OR EXISTS(SELECT 1 FROM ientier.laboratory_exam_requests WHERE patient_id=a.patient_id) THEN
   RAISE EXCEPTION 'Third party can read documents';
 END IF;
 denied := false;
 BEGIN PERFORM ientier.publish_video_consultation(a.appointment_id,gen_random_uuid(),'diagnosis',body);
 EXCEPTION WHEN insufficient_privilege THEN denied := true; END;
 IF NOT denied THEN RAISE EXCEPTION 'Third party can publish'; END IF;
 EXECUTE 'RESET ROLE';
END $$;
ROLLBACK;
