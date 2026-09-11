# Project conventions

Read `docs/angularjs-grid.md` and `docs/validation.md` before implementing the
dashboard or changing the interpretation of form metadata.

- Target AngularJS 1.4.7 and the PowerSchool native grid widget. Use the host's
  RequireJS loader and `powerSchoolModule`; do not bundle another Angular runtime.
- Follow the existing native PowerSchool admin page shell and styles. Separate
  controllers, services, and reusable views under a project-specific component.
- Keep the SQL Studio queries runnable independently. Do not silently change
  their scope or behavior when adding a dashboard data endpoint.
- Inventory configuration only. Do not load student responses or evaluate a
  particular student's eligibility unless that work is explicitly requested.
- Distinguish configured restrictions from verified effective visibility. Keep
  unknown conditions and ordering unresolved rather than inventing defaults.
- Keep district IDs, private results, credentials, local paths, and vendor
  reference files out of tracked source. Use ignored `local/` for research.
- Verify pagination, filters, loading failures, and permissions in PowerSchool
  before claiming live behavior. Static validation alone is not runtime proof.
- No license has been chosen. Do not add one without the owner's decision.
