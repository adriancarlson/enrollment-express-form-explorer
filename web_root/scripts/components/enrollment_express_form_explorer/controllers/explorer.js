'use strict';

define(function(require) {
    var angular = require('angular');
    var module = require('components/enrollment_express_form_explorer/module');

    module.controller('formExplorerController', [
        '$q',
        '$timeout',
        'formInventoryService',
        function($q, $timeout, formInventoryService) {
            var vm = this;

            vm.activeView = 'questions';
            vm.loading = true;
            vm.loadError = false;
            vm.showUnpublished = false;
            vm.showPreEnrollments = false;
            vm.gridReady = true;
            vm.allForms = [];
            vm.forms = [];
            vm.visibleForms = [];
            vm.matchingForms = [];
            vm.allRules = [];
            vm.rules = [];
            vm.visibleRules = [];
            vm.matchingRules = [];
            vm.allQuestions = [];
            vm.questions = [];
            vm.visibleQuestions = [];
            vm.matchingQuestions = [];
            vm.yesNoMap = { Yes: 'Yes', No: 'No' };
            vm.schoolScopeMap = {
                'Enabled with rules': 'Enabled with rules',
                'Enabled without rules': 'Enabled without rules',
                'Configured, not enabled': 'Configured, not enabled',
                'No configured school rules': 'No configured school rules'
            };
            vm.dependencyMap = {
                'Direct workflow': 'Direct workflow',
                'Controller unresolved': 'Controller unresolved',
                'No direct workflow': 'No direct workflow'
            };
            vm.elementTypeMap = {};
            vm.elementTypeLabels = {
                checkbox: 'Checkbox',
                collection: 'Collection',
                contacts: 'Contacts',
                document: 'Document',
                dropdown: 'Dropdown',
                ecollection: 'E Collection',
                enhancedevent: 'Enhanced Event',
                event: 'Event',
                hidden: 'Hidden',
                multidd: 'Dropdown',
                paragraph: 'Paragraph',
                pinpassword: 'PIN Password',
                pstag: 'PS Tag',
                race: 'Race',
                radio: 'Radio',
                responselist: 'Response List',
                sbscontainer: 'Container',
                sectionbreak: 'Section Break',
                sisdocument: 'SIS Document',
                text: 'Text',
                textblock: 'Text Block'
            };
            vm.ruleTypeMap = {};
            vm.formMaps = {
                forms: {},
                rules: {},
                questions: {}
            };

            function asNumber(value) {
                var number = Number(value);
                return isNaN(number) ? 0 : number;
            }

            function isTrue(value) {
                return String(value || '').toLowerCase() === 'true';
            }

            function isPreEnrollment(formType) {
                return String(formType || '').toUpperCase() === 'PR';
            }

            function replaceMap(target, rows) {
                angular.forEach(target, function(value, key) {
                    delete target[key];
                });
                angular.forEach(rows, function(row) {
                    if (row.form_title) {
                        target[row.form_title] = row.form_title;
                    }
                });
            }

            function normalizeBoolean(value) {
                return isTrue(value) ? 'Yes' : 'No';
            }

            function normalizeForm(form) {
                form.form_id = asNumber(form.form_id);
                form.form_filter = form.form_title;
                form.form_display_order = asNumber(form.form_display_order);
                form.element_count = asNumber(form.element_count);
                form.school_rule_count = asNumber(form.school_rule_count);
                form.distinct_school_value_count = asNumber(form.distinct_school_value_count);
                form.condition_rule_count = asNumber(form.condition_rule_count);
                form.published_display = normalizeBoolean(form.publish);
                form.school_sharing_display = normalizeBoolean(form.use_by_school_sharing);
                if (isTrue(form.use_by_school_sharing)) {
                    form.school_scope_status = form.school_rule_count ? 'Enabled with rules' : 'Enabled without rules';
                } else if (form.school_rule_count) {
                    form.school_scope_status = 'Configured, not enabled';
                } else {
                    form.school_scope_status = 'No configured school rules';
                }
                return form;
            }

            function normalizeQuestion(question) {
                question.form_id = asNumber(question.form_id);
                question.form_filter = question.form_title;
                question.form_display_order = asNumber(question.form_display_order);
                question.element_id = asNumber(question.element_id);
                question.element_type_display = vm.elementTypeLabels[
                    String(question.element_type || '').toLowerCase()
                ] || String(question.element_type || '').replace(/\b\w/g, function(character) {
                    return character.toUpperCase();
                });
                question.numeric_position = /^\d+$/.test(String(question.stored_position || '')) ?
                    asNumber(question.stored_position) : null;
                question.required_display = normalizeBoolean(question.required);
                question.workflow_display = normalizeBoolean(question.wf_enabled);
                question.dependency_status = isTrue(question.wf_enabled) ?
                    (question.controlling_question ? 'Direct workflow' : 'Controller unresolved') :
                    'No direct workflow';
                return question;
            }

            function prepareQuestions(rows) {
                var elementMap = {};
                var columnPositions = {};
                var currentFormId = null;
                var displayPosition = 0;

                function sortNumber(value) {
                    return /^\d+$/.test(String(value || '')) ? asNumber(value) : Number.MAX_VALUE;
                }

                rows = rows.filter(function(question) {
                    return question.element_id > 0 && !(
                        isTrue(question.container_enabled) &&
                        /^-\d+$/.test(String(question.container_id || ''))
                    );
                });

                angular.forEach(rows, function(question) {
                    elementMap[question.form_id + ':' + question.element_id] = question;
                    if (isTrue(question.container_enabled) && !/^-\d+$/.test(String(question.container_id || ''))) {
                        var columnKey = question.form_id + ':' + question.container_id + ':' + question.container_column;
                        columnPositions[columnKey] = columnPositions[columnKey] || [];
                        if (columnPositions[columnKey].indexOf(sortNumber(question.container_position)) === -1) {
                            columnPositions[columnKey].push(sortNumber(question.container_position));
                        }
                    }
                });

                angular.forEach(columnPositions, function(positions) {
                    positions.sort(function(left, right) {
                        return left - right;
                    });
                });

                angular.forEach(rows, function(question) {
                    var parentQuestion = isTrue(question.container_enabled) ?
                        elementMap[question.form_id + ':' + question.container_id] : null;
                    var columnKey = question.form_id + ':' + question.container_id + ':' + question.container_column;
                    var positions = columnPositions[columnKey] || [];

                    question.visual_parent_position = sortNumber(
                        parentQuestion ? parentQuestion.stored_position : question.stored_position
                    );
                    question.visual_child_rank = parentQuestion ? 1 : 0;
                    question.visual_container_column = sortNumber(question.container_column);
                    question.visual_container_row = parentQuestion ?
                        positions.indexOf(sortNumber(question.container_position)) + 1 : Number.MAX_VALUE;
                    question.visual_stored_position = sortNumber(question.stored_position);
                });

                rows.sort(function(left, right) {
                    return left.form_display_order - right.form_display_order ||
                        left.form_id - right.form_id ||
                        left.visual_parent_position - right.visual_parent_position ||
                        left.visual_child_rank - right.visual_child_rank ||
                        left.visual_container_row - right.visual_container_row ||
                        left.visual_container_column - right.visual_container_column ||
                        left.visual_stored_position - right.visual_stored_position ||
                        left.element_id - right.element_id;
                });

                angular.forEach(rows, function(question) {
                    if (question.form_id !== currentFormId) {
                        currentFormId = question.form_id;
                        displayPosition = 0;
                    }
                    displayPosition += 1;
                    question.numeric_position = displayPosition;
                });

                return rows;
            }

            function normalizeRule(rule) {
                rule.form_id = asNumber(rule.form_id);
                rule.form_filter = rule.form_title;
                rule.sharing_rule_id = asNumber(rule.sharing_rule_id);
                rule.school_rule_status = String(rule.share_type || '').toLowerCase() === 'school' ?
                    (isTrue(rule.use_by_school_sharing) ? 'Enabled' : 'Configured, not enabled') : '';
                return rule;
            }

            vm.showView = function(view) {
                vm.activeView = view;
            };

            vm.applyVisibilityFilters = function() {
                vm.forms = vm.allForms.filter(function(form) {
                    return (vm.showUnpublished || isTrue(form.publish)) &&
                        (vm.showPreEnrollments || !isPreEnrollment(form.form_type));
                });
                vm.rules = vm.allRules.filter(function(rule) {
                    return (vm.showUnpublished || isTrue(rule.form_publish)) &&
                        (vm.showPreEnrollments || !isPreEnrollment(rule.form_type));
                });
                vm.questions = vm.allQuestions.filter(function(question) {
                    return (vm.showUnpublished || isTrue(question.form_publish)) &&
                        (vm.showPreEnrollments || !isPreEnrollment(question.form_type));
                });
                replaceMap(vm.formMaps.forms, vm.forms);
                replaceMap(vm.formMaps.rules, vm.rules);
                replaceMap(vm.formMaps.questions, vm.questions);
            };

            vm.toggleVisibilityFilters = function() {
                vm.applyVisibilityFilters();
                vm.gridReady = false;
                $timeout(function() {
                    vm.gridReady = true;
                });
            };

            vm.retry = function() {
                vm.loading = true;
                vm.loadError = false;
                load();
            };

            function load() {
                $q.all([
                    formInventoryService.loadForms(),
                    formInventoryService.loadRules(),
                    formInventoryService.loadQuestions()
                ]).then(function(results) {
                    vm.allForms = results[0].map(normalizeForm);
                    vm.allRules = results[1].map(normalizeRule);
                    vm.allQuestions = prepareQuestions(results[2].map(normalizeQuestion));
                    angular.forEach(vm.allRules, function(rule) {
                        if (rule.share_type) {
                            vm.ruleTypeMap[rule.share_type] = rule.share_type;
                        }
                    });
                    angular.forEach(vm.allQuestions, function(question) {
                        if (question.element_type_display) {
                            vm.elementTypeMap[question.element_type_display] = question.element_type_display;
                        }
                    });
                    vm.applyVisibilityFilters();
                }, function() {
                    vm.loadError = true;
                }).finally(function() {
                    vm.loading = false;
                });
            }

            load();
        }
    ]);
});
