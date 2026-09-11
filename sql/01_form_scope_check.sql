/*
Run this SELECT first in SQL Studio and export the result.
Purpose: confirm which real forms carry the Enrollment Form checkbox.
This deliberately lists ALL form definitions so missing enrollment flags and
pre-registration forms can be identified before narrowing the inventory.
No student records or submitted responses are read.
*/
SELECT
    f.id AS form_id,
    f.form_title,
    f.form_category,
    f.form_type,
    f.enrollmentformcheck,
    CASE
        WHEN LOWER(TRIM(f.enrollmentformcheck)) = 'true'
            THEN 'Included in draft inventory'
        ELSE 'Excluded; check if this is an enrollment form'
    END AS draft_scope,
    f.publish,
    f.school_id AS owning_school_id,
    f.use_by_school_sharing,
    f.sharing_parent,
    f.publish_open_date,
    f.publish_close_date,
    (SELECT COUNT(*) FROM u_fb_form_element e
      WHERE e.u_fb_form_id = f.id) AS element_count,
    (SELECT COUNT(*) FROM u_fb_form_sharing s
      WHERE s.form_id = f.id AND LOWER(TRIM(s.share_type)) = 'school')
        AS school_rule_count,
    (SELECT COUNT(DISTINCT TRIM(s.share_value)) FROM u_fb_form_sharing s
      WHERE s.form_id = f.id AND LOWER(TRIM(s.share_type)) = 'school')
        AS distinct_school_value_count,
    (SELECT COUNT(*) FROM u_fb_form_sharing s
      WHERE s.form_id = f.id AND LOWER(TRIM(s.share_type)) = 'condition')
        AS condition_rule_count,
    (SELECT COUNT(*) FROM u_fb_form_sharing s
      WHERE s.form_id = f.id AND LOWER(TRIM(s.share_type)) = 'student')
        AS student_rule_count
FROM u_fb_form f
ORDER BY f.form_category NULLS LAST, f.form_title, f.id;
