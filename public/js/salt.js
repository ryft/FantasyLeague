var app = angular.module('SaltApp', ['chart.js']);

app.controller('StandingsCtrl', function($scope, $attrs, $http) {
    var api_url = ($attrs.split) ? '/api/standings/' + $attrs.split : '/api/standings';
    $http.get(api_url)
        .success(function(response) {
            $scope.standings = response;
            $scope.predicate = '[splits, won, tied, pf, pa]';
            $scope.reverse   = true;
        }
    );
});

app.controller('ChartCtrl', function($scope, $attrs, $http) {
    var api_url = ($attrs.split) ? '/api/' + $attrs.metric + '/' + $attrs.split : '/api/' + $metric;
    $http.get(api_url)
        .success(function(response) {
            $scope.labels = response.labels;
            $scope.series = response.series;
            $scope.data   = response.data;
        }
    );
});

