'use strict';

define(function(require) {
    var module = require('components/enrollment_express_form_explorer/module');

    module.factory('formInventoryService', [
        '$http',
        function($http) {
            function load(fileName) {
                return $http.get('data/' + fileName, {
                    headers: { Accept: 'application/json' }
                }).then(function(response) {
                    if (Array.isArray(response.data)) {
                        return response.data;
                    }

                    if (typeof response.data === 'string' && response.data.trim()) {
                        return JSON.parse(response.data);
                    }

                    return [];
                });
            }

            return {
                loadForms: function() {
                    return load('forms.json');
                },
                loadRules: function() {
                    return load('rules.json');
                },
                loadQuestions: function() {
                    return load('questions.json');
                }
            };
        }
    ]);
});
