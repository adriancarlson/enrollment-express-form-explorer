/* One row per sharing rule. Run separately from the inventory.
   Rules are NOT joined with an assumed AND/OR operator.
   Includes empty forms/rules via LEFT JOIN. No response data is read. */
SELECT
    f.id AS form_id,
    f.form_title,
    f.school_id AS owning_school_id,
    f.use_by_school_sharing,
    f.sharing_parent,
    f.sharing_student,
    f.sharing_teacher,
    f.sharing_admin,
    f.sharing_global,
    s.id AS sharing_rule_id,
    s.share_type,
    s.share_permission AS field_or_permission,
    s.share_comparator,
    s.share_value,
    s.edit_form
FROM u_fb_form f
LEFT JOIN u_fb_form_sharing s ON s.form_id = f.id
WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
ORDER BY f.form_title, f.id, s.share_type, s.id;
