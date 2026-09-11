# SQL validation and open questions

## Completed checks

The initial SQL files were checked on September 10, 2026:

- All 10 statements parsed using SQLGlot's Oracle dialect and were SELECT
  statements.
- An independent extraction of column definitions from Data Dictionary 26.4.0.0
  matched all 330 checked physical-column references.
- Query 01 subsequently ran in one district's PowerSchool SQL Studio environment.
  Its results support using the enrollment checkbox as that installation's
  initial scope filter, including pre-registration forms that carry the flag.

- Query 02 results supplied on September 11, 2026 were successfully parsed and
  reconciled against query 01: the form set and each form's element count match,
  including the retained empty-form row. No duplicate form-element keys were found.
  School-rule, choice, and collection-summary entry counts match their count
  columns. Individual text values still require fidelity checks where relevant.
- The output confirms that sharing type `condition` carries field restrictions.
  `student_rule_count` counts only type `student`; it is not a count of all
  student-value conditions. A dashboard should expose a separate condition count.
- Enabled workflows with unresolved controller joins and controllers with their
  own enabled workflows require further inspection. Composite-element internals
  must be checked before classifying an unresolved controller as broken.

- Query 03 results supplied on September 11, 2026 match query 02's form set.
  Reconstructing every form's sharing summary from the individual records
  reproduces query 02's summary text, excluding terminal newline differences.
  No sharing-rule IDs repeat. Distinct records can nevertheless contain the
  same school rule, so record counts must remain separate from distinct values.
- Admin-role records include both populated role permissions and blank values.
  Blank values are retained as unknown configuration, not interpreted as access
  for all administrators. Role IDs need installation-specific name resolution.

- Query 04A results reproduce query 02's choice counts and summary text for
  every element with choices, excluding terminal newline differences. Choice IDs
  are unique. Stored choice positions can tie; an ID tie-breaker is deterministic
  but does not prove rendered order. Blank choices and labels containing pipe
  characters must be preserved until their rendering semantics are verified.

- Query 04B's returned placements match their corresponding query 02 summaries,
  and all returned inner elements resolve to the same form as their collection.
  One additional placement in query 02 is absent from 04B: query 02 aggregates
  placements without restricting the parent, whereas 04B requires a parent on
  an in-scope form. A parent lookup is needed to distinguish a missing parent
  from one outside that scope; a negative ID alone does not resolve this.
- Returned collection column positions all tie. They do not establish visual
  column order. Some collection parents have enabled workflows while their
  children do not; retain parent-condition evidence in question details.

- Query 04C returns the contact elements identified in query 02, with blank
  per-element custom configuration IDs and joined structure fields. These are
  retained LEFT JOIN rows, not a list of rendered contact questions. Compare
  built-in settings (04D), global structure (04G), and the installed UI before
  determining defaults, required fields, or question order.

- Query 04D returns a built-in settings record for each contact element seen in
  04C. The records have different requirement and option flags despite having
  the same element title. Preserve settings per element; false requirement
  flags do not establish that the corresponding questions are hidden. Global
  structure and installed UI checks remain necessary for labels and order.

- Query 04E was reported to return no rows. This establishes no matching
  sub-element records through that query's join, not absence of document
  elements or their built-in UI. Query 02 does contain SIS document elements.
- Query 04F returns the school-preference elements identified in query 02.
  Preserve configured school choices separately from form audience rules.
  Default flags and blank values need interpretation against the installed UI;
  a configured school value alone does not establish its name or special meaning.

- Query 04G returns one global structure row with type `default`, but blank
  label, sequence, field mapping, and flags. This does not establish a usable
  contact-field catalog or explain default inheritance. Together, 04C, 04D,
  and 04G expose built-in settings without resolving rendered contact labels
  and order; inspect the installed contact implementation and UI next.

User-supplied results now cover all 10 statements (01, 02, 03, and 04A-G),
including the reported empty result for 04E. These checks do not establish
cross-version compatibility or accurate interpretation of all visibility rules.
District-specific outputs are intentionally kept outside this repository.

## Installed contact source findings

A read-only builder/source inspection on September 11, 2026 confirmed the
returned contact settings against builder controls. The installed contact
element template separates builder headers from responder cards and supports
custom-structure branches. The standard responder contact dialog defines
built-in fields that are not individual form-element rows.

The standard template's first/last-name required markers also depend on a
runtime duplicate-contact flag, beyond the stored requirement flags. Custody,
school-pickup, and mail flags participate in disabled-state expressions and
required markers; they must not be treated simply as visibility switches.
Contact Type uses a conditional display expression. Permissions and conditional
non-custodial updates affect editing separately.

Sources inspected through Custom Page Management:
`/scripts/formbuilder/partials/elements/contacts.element.html` and
`/scripts/formbuilder/partials/dialogs/responder.contactdetail.html`.
These findings establish template behavior, not a completed responder-preview
test or exhaustive question order. Additional builder options and their storage
mappings, feature flags, and nested contact dialogs remain to be traced.

The dictionary and installed builder agree on five further settings stored in
`U_FB_CONTACTS_DETAIL`: calculate contact type, conditional update of
non-custodial contacts, restrict Apply Contacts controls, auto-approve all
responses, and create new contacts for potential matches. Query 04D now appends
these fields. Its original columns and joins remain unchanged. Rerun 04D to
validate the new output against the selected builder controls.

The installed responder permission function checks school-specific portal
records only when `use_by_school_sharing` is enabled. When it is disabled, that
function falls back to the form's portal-level permission. Queries 01 and 02 now
report distinct school values and condition records separately, and query 02
labels configured school rows whose use flag is false. This source finding is
version-specific and still needs a parent-form-list check before it is described
as complete effective availability.

## Questions to resolve with live configuration

| Area | Required verification |
| --- | --- |
| Enrollment scope | Confirm the enrollment flag captures intended forms, including pre-registration, older forms, and unpublished definitions. |
| School availability | Resolve school-sharing values, special/default values, the relevant school population, and the role of `use_by_school_sharing`. Do not treat the owning school or a sharing-row count as effective availability. |
| Form conditions | Establish how field conditions combine, including grouping and AND/OR behavior. A zero count for one sharing type does not prove a form is unconditional. |
| Question workflows | Verify controller links, trigger encodings, multi-value matching, hidden/defaulted controllers, and whether current field values or in-progress answers control display. |
| Inherited conditions | Trace form, container, collection, and controller-chain restrictions. The draft exposes direct links rather than evaluating every ancestor. |
| Question order | Verify container identifiers, multi-column order, nested placement, duplicate positions, and elements with multiple placements. Numeric stored position is not sufficient to establish every visual sequence. |
| Composite elements | Compare contact, race, event, payment, collection, and document elements with their rendered subquestions. Some built-in questions are not standalone element rows. |
| Permissions and publication | Check role permissions, publication windows, single-student settings, and custom CSS in the relevant user context. |
| Export fidelity | Confirm SQL Studio preserves CLOB summaries. Use the individual sharing and detail statements when aggregated output is clipped. |
| Calculated fields | Form metadata identifies a dependency on a field; the logic calculating that field may live elsewhere and requires separate investigation. |

## Suggested live validation

1. Compare query 01 with the intended enrollment form list.
2. Run query 02 and reconcile its rows against query 01's element counts,
   allowing one retained row for each empty form.
3. Compare an ordinary form, a school-restricted form, a form restricted by
   student values, and a form with conditional questions against Form Builder
   and the relevant parent-facing context.
4. Inspect individual sharing records with query 03 and composite configuration
   using the applicable statement from query 04.
5. Record verified behavior separately from assumptions before implementing
   dashboard labels such as "all schools" or "always visible."

## Dictionary reference map

The source dictionary is not distributed with this project.

| Pages | Configuration |
| --- | --- |
| 40-43 | Form definitions, ownership, sharing flags, publication, and enrollment checkbox. |
| 45-46 | Answer choices, values, and stored order. |
| 49-52 | Pre-registration school preferences and collection placement. |
| 53-56 | Form elements, layout, permissions, mapped fields, and workflow. |
| 71 | School, student, and admin-role sharing records. |
| 72 | SIS document subquestions; no documented position column. |
| 28-29, 109-111 | Contact settings and configurable contact fields. |
