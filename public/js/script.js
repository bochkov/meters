var metersApp = angular.module('metersApp', ['mm.foundation', "chart.js"]);

metersApp
    .controller('modalController', function($scope, $http, $modalInstance, title, data, meterId, valueId) {

        $scope.title = title;
        $scope.data = data;
        $scope.value = valueId;
        $scope.meter = meterId;
        $scope.data.date = data.date === undefined ? new Date() : new Date(data.date);

        $scope.getValue = function(valueId) {
            if (valueId != null)
                $http
                    .get("/api/value/" + valueId + "/")
                    .then(function(v) { $scope.value = v.data; })
        };
        $scope.getValue(valueId);

        $scope.getMeter = function(meterId) {
            if (meterId != null)
                $http
                    .get("/api/meter/" + meterId + "/")
                    .then(function(m) { $scope.meter = m.data; });
        };
        $scope.getMeter(meterId);

        $scope.ok = function() {
            $modalInstance.close($scope.data);
        };

        $scope.cancel = function() {
            $modalInstance.dismiss();
        };
    })
    .controller('meterController', function($scope, $http, $modal) {

        $scope.init = function() {
            $scope.result = "";
            $scope.resultLog = "";
            $scope.currentView = "table-view";
        };

        $scope.showAll = function() {
            $http
                .get("/api/meter/all/")
                .then(function(data) {
                    $scope.resultLog = null;
                    $scope.result = data.data;
                })
        };
        $scope.showAll();

        $scope.addMeter = function() {
            var modalInstance = $modal.open({
                templateUrl: "addMeter.html",
                controller: "modalController",
                resolve: {
                    title: function() { return "Добавить счетчик" },
                    data: function() { return {}; },
                    meterId: function() { return null },
                    valueId: function() { return null }
                }
            });
            modalInstance.result.then(function(data) {
                $http
                    .post("/api/meter/save/", {name: data.name, number: data.number, unit: data.unit})
                    .then(function() {
                        $scope.resultLog = null;
                        $scope.showAll();
                    }, function(data) {
                        $scope.resultLog = data;
                    });
            })
        };

        $scope.editMeter = function(id) {
            $http.get("/api/meter/" + id + "/")
                .then(function(data) {
                    var modalInstance = $modal.open({
                        templateUrl: "addMeter.html",
                        controller: "modalController",
                        resolve: {
                            title: function() { return "Редактировать счетчик" },
                            data: function() { return data.data },
                            meterId: function() { return id },
                            valueId: function() { return null }
                        }
                    });
                    modalInstance.result.then(function(data) {
                        $http
                            .post("/api/meter/update/", 
                                {id: id, name: data.name, number : data.number, unit: data.unit})
                            .then(function() {
                                $scope.resultLog = null;
                                $scope.showAll();
                            }, function(data) {
                                $scope.resultLog = data;
                            })
                    })
                })
        };

        $scope.deleteMeter = function(id) {
            var modalInstance = $modal.open({
                templateUrl: "confirmDeleteMeter.html",
                controller: "modalController",
                resolve: {
                    title: function() { return null },
                    data: function() { return {} },
                    meterId: function() { return id },
                    valueId: function() { return null }
                }
            });
            modalInstance.result.then(function(data) {
                $http
                    .post("/api/meter/delete/", {id: id})
                    .then(function() {
                        $scope.showAll();
                    }, function(data) {
                        $scope.resultLog = data;
                    });
            });
        };

        $scope.addValue = function(id) {
            var modalInstance = $modal.open({
                templateUrl: "addValue.html",
                controller: "modalController",
                resolve: {
                    title: function() { return "Добавить значение" },
                    data: function() { return {}; },
                    meterId: function() { return id },
                    valueId: function() { return null }
                }
            });
            modalInstance.result.then(function(data) {
                $http
                    .post("/api/value/save/", 
                        {meter: id, value: data.value, date: data.date.getTime()})
                    .then(function() {
                        $scope.resultLog = null;
                        $scope.showAll();
                    }, function(data) {
                        $scope.resultLog = data;
                    });
            });
        };

        $scope.editValue = function(id) {
            $http.get("/api/value/" + id + "/")
                .then(function(data) {
                    var modalInstance = $modal.open({
                        templateUrl: "addValue.html",
                        controller: "modalController",
                        resolve: {
                            title: function() { return "Редактировать значение" },
                            data: function() { return data.data },
                            meterId: function() { return data.data.meter.id },
                            valueId: function() { return id }
                        }
                    });
                    modalInstance.result.then(function(data) {
                        $http
                            .post("/api/value/update/",
                                {id: id, value: data.value, date: data.date.getTime()})
                            .then(function() {
                                $scope.resultLog = null;
                                $scope.showAll();
                            }, function(data) {
                                $scope.resultLog = data;
                            });
                    });
                });
        };

        $scope.deleteValue = function(valueId, meterId) {
            var modalInstance = $modal.open({
                templateUrl : "confirmDeleteValue.html",
                controller: "modalController",
                resolve: {
                    title: function() { return null },
                    data: function() { return {}; },
                    meterId: function() { return meterId },
                    valueId: function() { return valueId }
                }
            });
            modalInstance.result.then(function(data) {
                $http
                    .post("/api/value/delete/", {id : valueId})
                    .then(function() {
                        $scope.resultLog = null;
                        $scope.showAll();
                    }, function(data) {
                        $scope.resultLog = data;
                    });
            });
        };
});