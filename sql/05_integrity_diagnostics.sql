/*
Enrollment Express configuration integrity diagnostics for SQL Studio / Oracle.
Select and run ONE statement at a time. These statements are read-only and use
the same Enrollment Form scope as the inventory.
*/

/* A. Workflow references that need review: missing controllers, cross-form
   controllers, and controller chains. A returned row is evidence for review,
   not proof that the form is broken; composite elements can use internal data. */
SELECT
    f.id AS form_id,
    f.form_title,
    e.id AS dependent_element_id,
    e.title AS dependent_question,
    e.element_type AS dependent_element_type,
    e.wf_element_id AS controller_element_id,
    e.wf_value AS trigger_values,
    controller.u_fb_form_id AS controller_form_id,
    controller.title AS controller_question,
    controller.element_type AS controller_element_type,
    controller.wf_enabled AS controller_wf_enabled,
    controller.wf_element_id AS next_controller_id,
    CASE
        WHEN controller.id IS NULL THEN 'Controller row not found'
        WHEN controller.u_fb_form_id <> f.id THEN 'Controller belongs to another form'
        WHEN LOWER(TRIM(controller.wf_enabled)) = 'true' THEN 'Controller chain'
        ELSE 'Review'
    END AS diagnostic_status
FROM u_fb_form f
JOIN u_fb_form_element e ON e.u_fb_form_id = f.id
LEFT JOIN u_fb_form_element controller ON controller.id = e.wf_element_id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
  AND LOWER(TRIM(e.wf_enabled)) = 'true'
  AND (
      controller.id IS NULL
      OR controller.u_fb_form_id <> f.id
      OR LOWER(TRIM(controller.wf_enabled)) = 'true'
  )
ORDER BY f.form_title, f.id, e.position, e.id;

/* B. Collection placements referenced by in-scope children whose parent is
   missing or is not on an in-scope enrollment form. This is the inverse scope
   needed to explain placements that appear in query 02 but not query 04B. */
SELECT
    child_form.id AS child_form_id,
    child_form.form_title AS child_form_title,
    child.id AS inner_element_id,
    child.title AS inner_question_title,
    t.id AS placement_id,
    t.collection_element_id,
    t.position AS column_position,
    t.columnname,
    t.columntitle,
    parent.u_fb_form_id AS parent_form_id,
    parent_form.form_title AS parent_form_title,
    parent_form.enrollmentformcheck AS parent_enrollmentformcheck,
    CASE
        WHEN parent.id IS NULL THEN 'Collection parent row not found'
        WHEN parent_form.id IS NULL THEN 'Collection parent form not found'
        ELSE 'Collection parent is outside enrollment scope'
    END AS diagnostic_status
FROM u_fb_form_element_table t
JOIN u_fb_form_element child ON child.id = t.inner_element_id
JOIN u_fb_form child_form ON child_form.id = child.u_fb_form_id
LEFT JOIN u_fb_form_element parent ON parent.id = t.collection_element_id
LEFT JOIN u_fb_form parent_form ON parent_form.id = parent.u_fb_form_id
WHERE LOWER(TRIM(child_form.enrollmentformcheck)) = 'true'
  AND (
      parent.id IS NULL
      OR parent_form.id IS NULL
      OR LOWER(TRIM(parent_form.enrollmentformcheck)) <> 'true'
  )
ORDER BY child_form.form_title, child_form.id, child.id, t.id;

/* C. Duplicate sharing-rule content. Different rule IDs with the same values
   remain separate records; this query does not delete or consolidate them. */
SELECT
    f.id AS form_id,
    f.form_title,
    s.share_type,
    s.share_permission AS field_or_permission,
    s.share_comparator,
    s.share_value,
    s.edit_form,
    COUNT(*) AS matching_rule_count,
    MIN(s.id) AS first_rule_id,
    MAX(s.id) AS last_rule_id
FROM u_fb_form f
JOIN u_fb_form_sharing s ON s.form_id = f.id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
GROUP BY
    f.id, f.form_title, s.share_type, s.share_permission,
    s.share_comparator, s.share_value, s.edit_form
HAVING COUNT(*) > 1
ORDER BY f.form_title, f.id, s.share_type, s.share_value;
