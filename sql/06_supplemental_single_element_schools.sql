/*
Schools with exactly one element directly controlled by School Workflow Logic
on the published Enrollment Express Supplemental Information form.

Pipe-delimited workflow values are split so an element configured for
101|107|105 is counted once for each of those schools.

This query counts direct workflow assignments. It does not expand child
elements that inherit visibility from a school-controlled container.
*/

WITH supplemental_elements AS (
    SELECT
        u_fb_form_element.id AS element_id,
        u_fb_form_element.position AS element_position,
        u_fb_form_element.title AS element_title,
        u_fb_form_element.element_type,
        u_fb_form_element.wf_value AS school_number_group
    FROM u_fb_form
    INNER JOIN u_fb_form_element
        ON u_fb_form_element.u_fb_form_id = u_fb_form.id
    INNER JOIN u_fb_form_element controlling_form_element
        ON controlling_form_element.id = u_fb_form_element.wf_element_id
    WHERE TRIM(u_fb_form.form_title) = 'Supplemental Information'
        AND u_fb_form.id > 0
        AND LOWER(TRIM(u_fb_form.enrollmentformcheck)) = 'true'
        AND LOWER(TRIM(u_fb_form.publish)) IN ('true', '1')
        AND LOWER(TRIM(u_fb_form_element.wf_enabled)) IN ('true', '1')
        AND TRIM(controlling_form_element.title) = 'School Workflow Logic'
        AND REGEXP_LIKE(TRIM(u_fb_form_element.wf_value), '^[0-9]+([|][0-9]+)*$')
),
school_element_rows AS (
    SELECT
        supplemental_elements.element_id,
        supplemental_elements.element_position,
        supplemental_elements.element_title,
        supplemental_elements.element_type,
        TO_NUMBER(
            REGEXP_SUBSTR(
                supplemental_elements.school_number_group,
                '[^|]+',
                1,
                LEVEL
            )
        ) AS school_number
    FROM supplemental_elements
    CONNECT BY REGEXP_SUBSTR(
            supplemental_elements.school_number_group,
            '[^|]+',
            1,
            LEVEL
        ) IS NOT NULL
        AND PRIOR supplemental_elements.element_id = supplemental_elements.element_id
        AND PRIOR SYS_GUID() IS NOT NULL
),
school_element_counts AS (
    SELECT
        school_element_rows.school_number,
        COUNT(DISTINCT school_element_rows.element_id) AS element_count
    FROM school_element_rows
    GROUP BY school_element_rows.school_number
    HAVING COUNT(DISTINCT school_element_rows.element_id) = 1
)
SELECT
    school_element_counts.school_number,
    schools.name AS school_name,
    school_element_counts.element_count,
    school_element_rows.element_id,
    school_element_rows.element_position,
    school_element_rows.element_title,
    school_element_rows.element_type
FROM school_element_counts
INNER JOIN school_element_rows
    ON school_element_rows.school_number = school_element_counts.school_number
LEFT JOIN schools
    ON schools.school_number = school_element_counts.school_number
ORDER BY
    school_element_counts.school_number,
    school_element_rows.element_position,
    school_element_rows.element_id;
