'use strict';

define(function(require) {
    var module = require('components/enrollment_express_form_explorer/module');

    module.factory('formInventoryService', [
        '$http',
        function($http) {
            var headers = {
                Accept: 'application/json',
                'Content-Type': 'application/json'
            };

            function query(name) {
                return $http({
                    method: 'POST',
                    url: '/ws/schema/query/' + name,
                    params: { pagesize: 0 },
                    data: {},
                    headers: headers
                }).then(function(response) {
                    return response.data.record || [];
                });
            }

            return {
                loadForms: function() {
                    return query('com.adriancarlson.enrollment.formexplorer.forms');
                },
                loadRules: function() {
                    return query('com.adriancarlson.enrollment.formexplorer.rules');
                },
                loadQuestions: function() {
                    return query('com.adriancarlson.enrollment.formexplorer.questions');
                }
            };
        }
    ]);
});
