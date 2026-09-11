'use strict';

define(function(require) {
    var angular = require('angular');
    var module = require('components/enrollment_express_form_explorer/module');

    module.controller('formExplorerController', [
        '$q',
        'formInventoryService',
        function($q, formInventoryService) {
            var vm = this;

            vm.activeView = 'forms';
            vm.loading = true;
            vm.loadError = false;
            vm.forms = [];
            vm.visibleForms = [];
            vm.matchingForms = [];
            vm.rules = [];
            vm.visibleRules = [];
            vm.matchingRules = [];
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
            vm.ruleTypeMap = {};

            function asNumber(value) {
                var number = Number(value);
                return isNaN(number) ? 0 : number;
            }

            function isTrue(value) {
                return String(value || '').toLowerCase() === 'true';
            }

            function normalizeBoolean(value) {
                return isTrue(value) ? 'Yes' : 'No';
            }

            function normalizeForm(form) {
                form.form_id = asNumber(form.form_id);
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
                question.element_id = asNumber(question.element_id);
                question.numeric_position = /^\d+$/.test(String(question.stored_position || '')) ?
                    asNumber(question.stored_position) : null;
                question.required_display = normalizeBoolean(question.required);
                question.workflow_display = normalizeBoolean(question.wf_enabled);
                question.dependency_status = isTrue(question.wf_enabled) ?
                    (question.controlling_question ? 'Direct workflow' : 'Controller unresolved') :
                    'No direct workflow';
                return question;
            }

            function normalizeRule(rule) {
                rule.form_id = asNumber(rule.form_id);
                rule.sharing_rule_id = asNumber(rule.sharing_rule_id);
                rule.school_rule_status = String(rule.share_type || '').toLowerCase() === 'school' ?
                    (isTrue(rule.use_by_school_sharing) ? 'Enabled' : 'Configured, not enabled') : '';
                return rule;
            }

            vm.showView = function(view) {
                vm.activeView = view;
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
                    vm.forms = results[0].map(normalizeForm);
                    vm.rules = results[1].map(normalizeRule);
                    vm.questions = results[2].map(normalizeQuestion);
                    angular.forEach(vm.rules, function(rule) {
                        if (rule.share_type) {
                            vm.ruleTypeMap[rule.share_type] = rule.share_type;
                        }
                    });
                    angular.forEach(vm.questions, function(question) {
                        if (question.element_type) {
                            vm.elementTypeMap[question.element_type] = question.element_type;
                        }
                    });
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
