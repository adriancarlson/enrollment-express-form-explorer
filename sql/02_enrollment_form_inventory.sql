/*
Enrollment Express configuration inventory - DRAFT for SQL Studio / Oracle.
Source: Data Dictionary 26.4.0.0, pp. 40-43, 45-46, 51-56, 71.

Scope: Enrollment Form checkbox = true; published AND unpublished forms.
Grain: one row per stored element, or one empty-element row for an empty form.
No student records or response tables are read. No database objects are created.

School ownership is NOT interpreted as school visibility. Raw sharing rules
are preserved independently; their combined logic requires live verification.
Workflow values are not split or treated as arbitrary SQL expressions.
Question mapping fields are write targets, not proof of display dependencies.

Ordering: numeric stored POSITION, then ID. Container and collection placement
are returned separately. This is not yet a verified flattened visual order for
nested layouts. IDs break ties only; they do not establish a visual order.

The XMLCAST/XMLAGG summaries return CLOBs without LISTAGG's VARCHAR2 limit.
SQL Studio may limit its displayed/exported CLOB length. Query 03 returns the
individual records without aggregation for checking complete values.
*/
WITH enrollment_forms AS (
    SELECT f.*
    FROM u_fb_form f
    WHERE LOWER(TRIM(f.enrollmentformcheck)) = 'true'
),
sharing_summary AS (
    SELECT
        s.form_id,
        SUM(CASE WHEN LOWER(TRIM(s.share_type)) = 'school'
                 THEN 1 ELSE 0 END) AS school_rule_count,
        COUNT(DISTINCT CASE WHEN LOWER(TRIM(s.share_type)) = 'school'
                            THEN TRIM(s.share_value) END)
            AS distinct_school_value_count,
        SUM(CASE WHEN LOWER(TRIM(s.share_type)) = 'condition'
                 THEN 1 ELSE 0 END) AS condition_rule_count,
        SUM(CASE WHEN LOWER(TRIM(s.share_type)) = 'student'
                 THEN 1 ELSE 0 END) AS student_rule_count,
        XMLCAST(XMLAGG(
            XMLELEMENT("r",
                'Rule ' || TO_CHAR(s.id)
                || ': type=[' || s.share_type
                || ']; field_or_permission=[' || s.share_permission
                || ']; comparator=[' || s.share_comparator
                || ']; value=[' || s.share_value
                || ']; edit_form=[' || s.edit_form || ']' || CHR(10))
            ORDER BY s.share_type, s.id
        ) AS CLOB) AS form_sharing_rules
    FROM u_fb_form_sharing s
    JOIN enrollment_forms f ON f.id = s.form_id
    GROUP BY s.form_id
),
choice_summary AS (
    SELECT
        c.u_fb_form_element_id AS element_id,
        COUNT(*) AS choice_count,
        XMLCAST(XMLAGG(
            XMLELEMENT("c",
                TO_CLOB('Position ') || TO_CHAR(c.position)
                || ': label=[' || c.label || ']; value=[' || c.value
                || ']; mapped_field=[' || c.ps_field || ']' || CHR(10))
            ORDER BY c.position NULLS LAST, c.id
        ) AS CLOB) AS answer_choices
    FROM u_fb_form_element_choice c
    JOIN u_fb_form_element e ON e.id = c.u_fb_form_element_id
    JOIN enrollment_forms f ON f.id = e.u_fb_form_id
    GROUP BY c.u_fb_form_element_id
),
collection_placement AS (
    SELECT
        t.inner_element_id AS element_id,
        COUNT(*) AS placement_count,
        XMLCAST(XMLAGG(
            XMLELEMENT("p",
                TO_CLOB('Collection element ') || TO_CHAR(t.collection_element_id)
                || '; column_position=[' || TO_CHAR(t.position)
                || ']; column_name=[' || t.columnname
                || ']; visible_column_title=[' || t.columntitle || ']' || CHR(10))
            ORDER BY t.collection_element_id, t.position NULLS LAST, t.id
        ) AS CLOB) AS collection_placements
    FROM u_fb_form_element_table t
    GROUP BY t.inner_element_id
)
SELECT
    f.id AS form_id,
    f.form_title,
    f.form_category,
    f.form_type,
    f.enrollmentformcheck,
    f.publish,
    f.publish_open_date,
    f.publish_close_date,
    f.school_id AS form_owning_school_id,
    f.use_by_school_sharing,
    NVL(ss.school_rule_count, 0) AS school_rule_count,
    NVL(ss.distinct_school_value_count, 0) AS distinct_school_value_count,
    CASE
        WHEN LOWER(TRIM(f.use_by_school_sharing)) = 'true'
             AND NVL(ss.school_rule_count, 0) > 0
            THEN 'School sharing enabled; inspect configured rules'
        WHEN LOWER(TRIM(f.use_by_school_sharing)) = 'true'
            THEN 'School sharing enabled; no school rows returned'
        WHEN NVL(ss.school_rule_count, 0) > 0
            THEN 'School rows configured; use-by-school flag is false'
        ELSE 'No school sharing rows; scope not established'
    END AS school_scope_evidence,
    NVL(ss.condition_rule_count, 0) AS condition_rule_count,
    NVL(ss.student_rule_count, 0) AS student_rule_count,
    ss.form_sharing_rules,
    f.sharing_parent,
    f.sharing_student,
    f.sharing_teacher,
    f.sharing_admin,
    f.sharing_global,
    f.single_student_only,
    f.next_form,
    f.custom_css AS form_custom_css,
    e.id AS element_id,
    e.position AS stored_position,
    CASE WHEN REGEXP_LIKE(TRIM(e.position), '^[0-9]{1,9}$')
         THEN TO_NUMBER(TRIM(e.position)) END AS numeric_position,
    CASE
        WHEN e.id IS NULL THEN 'Form has no stored elements'
        WHEN LOWER(TRIM(e.element_type)) IN
             ('textblock', 'sectionbreak', 'sbscontainer')
            THEN 'Layout or information element'
        WHEN LOWER(TRIM(e.element_type)) IN ('hidden', 'pstag')
            THEN 'Hidden or dynamic element; retain for dependencies'
        WHEN LOWER(TRIM(e.element_type)) IN
             ('contacts', 'collection', 'ecollection', 'race',
              'sisdocument', 'event', 'enhancedevent')
            THEN 'Composite element; inspect its internal configuration'
        ELSE 'Question or other element; inspect element_type'
    END AS element_kind,
    e.element_type,
    e.title AS question_title,
    e.description AS question_description,
    e.required,
    e.student_field AS mapped_write_field,
    CASE WHEN LOWER(TRIM(e.element_type)) = 'pinpassword'
         THEN '[omitted for PIN/password element]'
         ELSE e.default_value END AS default_value,
    e.school_id AS element_owning_school_id,
    e.element_permission,
    e.css_class,
    e.containerenabled,
    e.containerid,
    e.containercolumn,
    e.containerposition,
    e.layout,
    e.fixsbselementposition,
    e.collection_dbname,
    e.collection_extension,
    NVL(cp.placement_count, 0) AS collection_placement_count,
    cp.collection_placements,
    e.wf_enabled,
    e.wf_element_id AS controlling_element_id,
    controller.u_fb_form_id AS controller_form_id,
    controller.title AS controlling_question,
    controller.element_type AS controller_element_type,
    controller.student_field AS controller_mapped_field,
    CASE WHEN LOWER(TRIM(controller.element_type)) = 'pinpassword'
         THEN '[omitted for PIN/password element]'
         ELSE controller.default_value END AS controller_default_value,
    e.wf_value AS workflow_trigger_values,
    CASE
        WHEN e.id IS NULL THEN NULL
        WHEN LOWER(TRIM(e.wf_enabled)) = 'true' AND controller.id IS NULL
            THEN 'Enabled workflow; controller not found'
        WHEN LOWER(TRIM(e.wf_enabled)) = 'true'
            THEN 'Direct workflow; inspect controller and trigger values'
        WHEN LOWER(TRIM(e.wf_enabled)) = 'false' OR e.wf_enabled IS NULL
            THEN 'No enabled direct workflow; inherited rules may apply'
        ELSE 'Unrecognized workflow flag; inspect raw value'
    END AS dependency_evidence,
    controller.wf_enabled AS controller_wf_enabled,
    controller.wf_element_id AS next_controller_id,
    controller.wf_value AS next_controller_trigger_values,
    NVL(cs.choice_count, 0) AS answer_choice_count,
    cs.answer_choices,
    e.other_enabled,
    e.autocomplete_type,
    e.autocomplete_special,
    f.modified_on AS form_modified_on
FROM enrollment_forms f
LEFT JOIN u_fb_form_element e ON e.u_fb_form_id = f.id
LEFT JOIN sharing_summary ss ON ss.form_id = f.id
LEFT JOIN u_fb_form_element controller ON controller.id = e.wf_element_id
LEFT JOIN choice_summary cs ON cs.element_id = e.id
LEFT JOIN collection_placement cp ON cp.element_id = e.id
ORDER BY
    f.form_category NULLS LAST,
    f.form_title,
    f.id,
    CASE WHEN REGEXP_LIKE(TRIM(e.position), '^[0-9]{1,9}$')
         THEN TO_NUMBER(TRIM(e.position)) END NULLS LAST,
    e.position NULLS LAST,
    e.id;
