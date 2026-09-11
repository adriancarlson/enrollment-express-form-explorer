# Enrollment Express Form Explorer

A PowerSchool dashboard for exploring Enrollment Express forms,
questions, school availability, and conditional display logic.

The project contains read-only Oracle SQL Studio queries and an initial
installable PowerSchool plugin. The first dashboard page browses forms and
stored elements through native PowerSchool Grid widgets. Runtime validation of
the plugin in PowerSchool is still required.

## Dashboard scope

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
| [05_integrity_diagnostics.sql](sql/05_integrity_diagnostics.sql) | Review unresolved workflow controllers, out-of-scope collection parents, and duplicate sharing rules. |

Run query 01 first in SQL Studio and check that the enrollment flag identifies
the forms you intend to inventory. Queries 02 through 04 include forms where
`enrollmentformcheck` is `true`, including unpublished forms. Query 01 lists all
form definitions to help verify that scope. In file 04, select and run one
statement at a time. File 05 contains focused follow-up diagnostics; its results
are review findings rather than automatic error classifications.

These queries read configuration, not student records or submitted responses.
They do not create database objects or change forms. The inventory preserves
hidden and layout elements because they can affect question structure and
dependencies. Returned element counts are not counts of visible questions.

## Validation status

The SQL was developed against the Enrollment Express/Ecollect Forms Data
Dictionary 26.4.0.0. Query 01 has been run successfully in one district's SQL
Studio environment. Query 02's supplied results also reconcile with query 01's
form set and individual element counts. Query 03's individual sharing records
reproduce query 02's sharing summaries, and query 04A reproduces its choice
counts and summaries. Query 04B's returned placements match their inventory
summaries, with one additional query 02 placement requiring a parent-scope
lookup. Query 04C returns the expected contact elements without matched custom
configuration records; query 04D supplies their built-in settings. Query 04E
returned no matching sub-elements, and query 04F returns the expected school
preferences. Query 04G returns a global `default` structure row with no field
details. User-supplied results now cover all 10 SQL statements, including the
empty result for 04E. Query 04D was subsequently extended with five documented
contact settings found during installed-source review and needs to be rerun;
queries 01 and 02 now distinguish condition counts, school-rule counts, and
distinct school values. These revised columns need to be rerun; rendered contact
questions remain unresolved.

School ownership, sharing configuration, and actual visibility are distinct.
The queries expose the available evidence; they do not yet establish complete
effective visibility or exact visual order for every nested layout. See
[validation and open questions](docs/validation.md) for details.

## Dashboard implementation baseline

The dashboard targets **AngularJS 1.4.7** and PowerSchool's native grid
widget, using RequireJS and the existing PowerSchool admin page styles.
The native examples, installed grid source, AngularJS presentation, MBA
reference, and existing project patterns have been reviewed. See the
[AngularJS and grid conventions](docs/angularjs-grid.md) for the implementation
baseline and proposed forms, questions, and detail views.

The initial page and two read-only named-query endpoints are implemented. Next,
install the generated plugin in a test PowerSchool environment and validate the
query responses, grid lifecycle, search, filters, and paging. Continue inspecting
installed form behavior to resolve contact fields, nested placement, and special
workflow references before presenting those interpretations as definitive.

## Local reference material

Keep district exports, private notes, vendor documentation, credentials, and
temporary files outside the published source. The ignored `local/` directory
can hold private reference material when needed. Vendor documentation and
district-specific validation results are not included in this repository.

## License

A license has not yet been selected. No license file is included at this stage.
