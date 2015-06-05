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
    var api_url = ($attrs.split) ? '/api/pf/' + $attrs.split : '/api/pf';
    $http.get(api_url)
        .success(function(response) {
console.log(response);
            $scope.labels = response.labels;
            $scope.series = response.series;
            $scope.data   = response.data;
        }
    );
//    $scope.labels = ["January", "February", "March", "April", "May", "June", "July"];
//    $scope.series = ['Series A', 'Series B'];
//    $scope.data = [
//      [65, 59, 80, 81, 56, 55, 40],
//      [28, 48, 40, 19, 86, 27, 90]
//    ];
});

