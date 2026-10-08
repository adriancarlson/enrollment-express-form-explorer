/*
Count of elements directly controlled by School Workflow Logic for every
PowerSchool school on the published Enrollment Express Supplemental Information
form.

Pipe-delimited workflow values are split so an element configured for
101|107|105 is counted once for each of those schools.

Schools without a matching element are returned with an element count of zero.
This query counts direct workflow assignments. It does not expand child elements
that inherit visibility from a school-controlled container.
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
)
SELECT
    schools.school_number,
    schools.name AS school_name,
    COUNT(DISTINCT school_element_rows.element_id) AS element_count
FROM schools
LEFT JOIN school_element_rows
    ON school_element_rows.school_number = schools.school_number
WHERE schools.school_number > 0
    AND schools.school_number NOT IN (888888, 79438, 999999, 103, 106)
GROUP BY
    schools.school_number,
    schools.name
HAVING COUNT(DISTINCT school_element_rows.element_id) > 0
ORDER BY
    COUNT(DISTINCT school_element_rows.element_id),
    schools.name,
    schools.school_number;
