/*
Supplemental detail queries. Select and run ONE statement at a time in SQL Studio.
All scope filters match 02_enrollment_form_inventory.sql.
These are configuration tables, not submitted answers.
*/

/* A. Answer choices in stored order; no aggregation or combined-text limit. */
SELECT
    f.id AS form_id, f.form_title,
    e.id AS element_id, e.title AS question_title,
    c.id AS choice_id, c.position AS choice_position,
    c.label AS choice_label, c.value AS choice_value,
    c.ps_field AS choice_mapped_field, c.default_value
FROM u_fb_form f
JOIN u_fb_form_element e ON e.u_fb_form_id = f.id
JOIN u_fb_form_element_choice c ON c.u_fb_form_element_id = e.id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
ORDER BY f.id, e.id, c.position NULLS LAST, c.id;

/* B. Collection questions, including inner elements whose form ID is different
   or null. Such elements would not be captured by a form-ID-only join. */
SELECT
    f.id AS form_id, f.form_title,
    parent.id AS collection_element_id, parent.title AS collection_title,
    parent.position AS collection_position,
    parent.wf_enabled AS collection_wf_enabled,
    parent.wf_element_id AS collection_controller_id,
    parent.wf_value AS collection_trigger_values,
    t.id AS placement_id, t.position AS column_position,
    t.columnname, t.columntitle,
    t.inner_element_id,
    child.u_fb_form_id AS inner_stored_form_id,
    child.title AS inner_question_title, child.element_type,
    child.required, child.student_field, child.element_permission,
    child.wf_enabled, child.wf_element_id, child.wf_value
FROM u_fb_form f
JOIN u_fb_form_element parent ON parent.u_fb_form_id = f.id
JOIN u_fb_form_element_table t ON t.collection_element_id = parent.id
LEFT JOIN u_fb_form_element child ON child.id = t.inner_element_id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
ORDER BY f.id, parent.id, t.position NULLS LAST, t.id;

/* C. Configured contact fields and their stored sequence.
   Presence/absence here alone does not establish which built-in fields render.
   Verify default-field inheritance against the installed contact element. */
SELECT
    f.id AS form_id, f.form_title,
    e.id AS contact_element_id, e.title AS contact_element_title,
    c.id AS contact_config_id,
    c.contact_structure_details_id,
    c.is_required AS element_required_raw,
    d.sequence_no,
    d.label AS contact_question_label,
    d.contact_structure_type,
    d.input_type,
    d.extension_name, d.table_name, d.column_name,
    d.codesetid,
    d.is_default AS is_default_raw,
    d.is_required_field AS structure_required_raw,
    d.is_contact_match_field,
    d.is_contact_card_display
FROM u_fb_form f
JOIN u_fb_form_element e ON e.u_fb_form_id = f.id
LEFT JOIN u_fb_contacts_detail_custom c ON c.element_id = e.id
LEFT JOIN u_fb_contact_structure_details d
    ON d.id = c.contact_structure_details_id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
  AND LOWER(TRIM(e.element_type)) = 'contacts'
ORDER BY f.id, e.id, d.sequence_no NULLS LAST, d.id, c.id;

/* D. Built-in contact settings. These are configuration flags, not the full
   visible contact-question list. Labels/order require installed UI verification. */
SELECT
    f.id AS form_id, f.form_title,
    e.id AS contact_element_id, e.title AS contact_element_title,
    d.id AS contact_config_id,
    d.r_first_name, d.r_last_name, d.r_gender,
    d.r_relationship, d.r_phone, d.r_address, d.r_email,
    e.reserved6 AS show_contact_type,
    e.reserved7 AS enable_custody,
    e.reserved8 AS enable_school_pickup,
    e.reserved9 AS receives_mail,
    d.calculatecontacttype AS calculate_contact_type,
    d.conditionalupdateofcontact AS conditional_update_non_custodial,
    d.restrict_apply_contacts,
    d.auto_approve_all_responses,
    d.create_new_contacts AS create_new_contacts_for_potential_matches
FROM u_fb_form f
JOIN u_fb_form_element e ON e.u_fb_form_id = f.id
LEFT JOIN u_fb_contacts_detail d ON d.element_id = e.id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
  AND LOWER(TRIM(e.element_type)) = 'contacts'
ORDER BY f.id, e.id, d.id;

/* E. SIS document subquestions. This table has no documented order column.
   Sorting by ID provides stable output, not an asserted question order. */
SELECT
    f.id AS form_id, f.form_title,
    e.id AS element_id, e.title AS attachment_title,
    se.id AS sub_element_id, se.title AS sub_question_title,
    se.description, se.sub_element_type, se.choices
FROM u_fb_form f
JOIN u_fb_form_element e ON e.u_fb_form_id = f.id
JOIN u_fb_form_sub_element se ON se.u_fb_element_id = e.id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
ORDER BY f.id, e.id, se.id;

/* F. Pre-registration school-choice settings for forms in scope.
   CHOOSESCHOOL lists answer options; it is not a form audience list. */
SELECT
    f.id AS form_id, f.form_title,
    e.id AS element_id, e.title AS question_title,
    p.id AS school_preference_id,
    p.chooseschool, p.min_length, p.max_length,
    p.use_default, p.chooseenrolledschool, p.use_enroll_default,
    p.use_pendingschool, p.choosependingschool
FROM u_fb_form f
JOIN u_fb_form_element e ON e.u_fb_form_id = f.id
JOIN u_fb_form_element_prereg p ON p.element_id = e.id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
ORDER BY f.id, e.id, p.id;

/* G. Global contact structure, only when an in-scope contact element exists.
   Needed to compare defaults with per-element custom configuration from C.
   Do not assume every row is visible on every contact element. */
SELECT
    d.id, d.sequence_no, d.label, d.contact_structure_type,
    d.input_type, d.extension_name, d.table_name, d.column_name,
    d.codesetid, d.is_default, d.is_required_field,
    d.is_contact_match_field, d.is_contact_card_display
FROM u_fb_contact_structure_details d
WHERE EXISTS (
    SELECT 1
    FROM u_fb_form f
    JOIN u_fb_form_element e ON e.u_fb_form_id = f.id
    WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
      AND LOWER(TRIM(e.element_type)) = 'contacts'
)
ORDER BY d.sequence_no NULLS LAST, d.id;
