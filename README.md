# Enrollment Express Form Explorer

A planned PowerSchool dashboard for exploring Enrollment Express forms,
questions, school availability, and conditional display logic.

The project currently contains read-only Oracle SQL queries for examining form
configuration in PowerSchool SQL Studio. The dashboard page and installable
PowerSchool plugin have not been built yet.

## Planned dashboard

- Browse enrollment forms and the questions on each form.
- Search question text and identify the forms containing matching questions.
- Filter forms and questions by school availability, publication status, and
  other configuration criteria.
- Inspect question details, mapped fields, answer choices, and display conditions.
- Follow relationships between conditional questions and their controlling fields.

The dashboard is intended for use by different districts. Form IDs, school IDs,
and district-specific enrollment rules must come from each installation's
configuration rather than hard-coded values.

## Current SQL tools

| File | Purpose |
| --- | --- |
| [01_form_scope_check.sql](sql/01_form_scope_check.sql) | List form definitions and check which carry the Enrollment Form flag. |
| [02_enrollment_form_inventory.sql](sql/02_enrollment_form_inventory.sql) | Inventory enrollment form elements, sharing rules, workflow links, choices, and stored placement. |
| [03_form_sharing_rules.sql](sql/03_form_sharing_rules.sql) | Return individual form-sharing records without aggregation. |
| [04_element_details.sql](sql/04_element_details.sql) | Inspect answer choices, collection columns, contact configuration, document subquestions, and school preferences. |

Run query 01 first in SQL Studio and check that the enrollment flag identifies
the forms you intend to inventory. Queries 02 through 04 include forms where
`enrollmentformcheck` is `true`, including unpublished forms. Query 01 lists all
form definitions to help verify that scope. In file 04, select and run one
statement at a time.

These queries read configuration, not student records or submitted responses.
They do not create database objects or change forms. The inventory preserves
hidden and layout elements because they can affect question structure and
dependencies. Returned element counts are not counts of visible questions.

## Validation status

The SQL was developed against the Enrollment Express/Ecollect Forms Data
Dictionary 26.4.0.0. Query 01 has been run successfully in one district's SQL
Studio environment. Queries 02 through 04 have passed local parsing and schema
reference checks but have not yet been verified through live execution.

School ownership, sharing configuration, and actual visibility are distinct.
The queries expose the available evidence; they do not yet establish complete
effective visibility or exact visual order for every nested layout. See
[validation and open questions](docs/validation.md) for details.

## Next development step

Review the PowerSchool Grid widget documentation before designing or implementing
the dashboard page. The SQL research will inform the page's data access and
filtering, but the page structure and integration are still to be defined.

## Local reference material

Keep district exports, private notes, vendor documentation, credentials, and
temporary files outside the published source. The ignored `local/` directory
can hold private reference material when needed. Vendor documentation and
district-specific validation results are not included in this repository.

## License

A license has not yet been selected. No license file is included at this stage.
