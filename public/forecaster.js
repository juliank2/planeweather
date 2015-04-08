/*
** Globals
*/
var map;
var flightPoly;
var weatherMarkers = [];
var flightPath = [];

/*
** Initialization
*/
function init() {
    var mapOptions = {
        center: {lat: 35.877639, lng: -78.787472},
        zoom: 5
    };
    map = new google.maps.Map(document.getElementById("map-canvas"), mapOptions);
}
google.maps.event.addDomListener(window, "load", init);

/*
** Plotting
*/
function plotFlightPath(flightPath) {
    if (flightPoly == null) {
        flightPoly = new google.maps.Polyline({
            path: flightPath,
            geodesic: true
        });
        var bounds = new google.maps.LatLngBounds();
        for (var i=0; i < flightPath.length; i++) {
            bounds.extend(flightPath[i]);
        }
        map.fitBounds(bounds);
        flightPoly.setMap(map);
    }
}
function removeFlightPath() {
    if (flightPoly != null) {
        flightPoly.setMap(null);
        flightPoly = null;
    }
}
function addMarker(markerLocation) {
    var marker = new google.maps.Marker({
        position: markerLocation,
        map: map
    });
    weatherMarkers.push(marker);
}
function removeMarkers() {
    if (weatherMarkers != null) {
        for (var i=0; i<weatherMarkers.length; i++) {
            weatherMarkers[i].setMap(null);
        }
        weatherMarkers = [];
    }
}

/*
** DOM Manipulation
*/
function buildForecastListElement(forecastData, index) {
    var li = document.createElement("li");
    li.onmouseover = function() {
        weatherMarkers[index].setAnimation(google.maps.Animation.BOUNCE);
    };
    li.onmouseout = function() {
        weatherMarkers[index].setAnimation(null);
    };
    var a = document.createElement("a");
    a.href = "#";
    li.appendChild(a);
    var h = document.createElement("h4");
    a.appendChild(h);
    h.appendChild(document.createTextNode("Forecast for (" + forecastData["location_rnd"][0] + ", " + forecastData["location_rnd"][1] + ")"));
    h.appendChild(document.createElement("br"));
    h.appendChild(document.createTextNode((new Date(forecastData["time"]*1000).toUTCString())));
    var p = document.createElement("p");
    a.appendChild(p);
    p.appendChild(document.createTextNode("temperature: " + forecastData["temperature"] + "\u2109"));
    p.appendChild(document.createElement("br"));
    p.appendChild(document.createTextNode("humidity: " + (100*forecastData["humidity"]) + "%"));
    p.appendChild(document.createElement("br"));
    p.appendChild(document.createTextNode("wind speed: " + forecastData["wind_speed"] + "mph"));
    return li;
}
function removeForecastList() {
    var forecastList = document.getElementById("forecast-container");
    while (forecastList.firstChild) {
        forecastList.removeChild(forecastList.firstChild);
    }
}

/*
** Validation
*/
function validateLocation(loc) {
    var latLngRe = /^-?(\d+(\.\d+)?),-?(\d+(\.\d+)?)$/;
    var IATARe = /^[A-Za-z]{3}$/;
    var regs = loc.match(latLngRe);
    //maybe add synchronous request to /resolve here
    return IATARe.test(loc) || (regs && regs[1] <= 90 && regs[3] <= 180);
}
function validateDate(date) {
    var dateRe = /^(\d{4})-(\d{1,2})-(\d{1,2})$/;
    var regs = date.match(dateRe);
    /* leave the year for now */
    return regs && regs[2] >= 1 && regs[2] <= 12 && regs[3] >= 1 && regs[3] <= 31;
}
function validateTime(time) {
    var timeRe = /^(\d{1,2}):(\d{2})$/;
    var regs = time.match(timeRe);
    return regs && regs[1] < 24 && regs[2] < 60;
}
function validatePosFloat(text) {
    posFltRe = /^\d+(.\d+)?$/;
    return posFltRe.test(text);
}
function validate() {
    if (!validateLocation(document.flight_details.origin.value)) {
        alert("Please enter your flight origin correctly. Either a three character IATA code or a latitude and longitude separated by a comma.");
        return false;
    }
    if (!validateLocation(document.flight_details.destination.value)) {
        alert("Please enter your flight destination correctly. Either a three character IATA code or a latitude and longitude separated by a comma.");
        return false;
    }
    if (!validateDate(document.flight_details.date.value)) {
        alert("Please enter your departure date as shown.");
        return false;
    }
    if (!validateTime(document.flight_details.time.value)) {
        alert("Please enter your departure time as shown.");
        return false;
    }
    if (!validatePosFloat(document.flight_details.speed.value)) {
        alert("Please enter the estimated average flight (in mile per hour) speed correctly.");
        return false;
    }
    if (!validatePosFloat(document.flight_details.time_d.value)) {
        alert("Please enter interval between reports (in hours) correctly.");
        return false;
    }
    return true;
}

/*
** AJAX
*/
function flightVertexListener() {
    /*deal with failure*/
    var loc = JSON.parse(this.responseText)["location"];
    flightPath.push(new google.maps.LatLng(loc[0], loc[1]));
    if (flightPath.length == 2) {
        plotFlightPath(flightPath);
    }
}
function requestResolve(locStr) {
    var resReq = new XMLHttpRequest();
    resReq.onload = flightVertexListener;
    resReq.open("get", "resolve/" + locStr, true);
    resReq.send();
}  
function resolveAndPlotFlightPath(origin, destination) {
    flightPath = [];
    requestResolve(origin);
    requestResolve(destination);
}
function forecastListener() {
    var forecast = JSON.parse(this.responseText)["forecast"];
    var forecastContainer = document.getElementById("forecast-container");
    for (var i=0; i<forecast.length; i++) {
        var markerLocation = forecast[i]["location"];
        addMarker(new google.maps.LatLng(markerLocation[0], markerLocation[1]));
        forecastContainer.appendChild(buildForecastListElement(forecast[i], i));
    }
}

/*
** Form Submission
*/
function submitFlight() {
    if (validate()) {
        removeMarkers();
        removeFlightPath();
        removeForecastList();
        
        var form = document.flight_details;
        resolveAndPlotFlightPath(form.origin.value, form.destination.value);
        var reqPath = "forecast/" + form.origin.value + "/" + form.destination.value + "/" +
            form.date.value + "T" + form.time.value + ":00/" + 
            form.speed.value + "/" + form.time_d.value;
        var req = new XMLHttpRequest();
        req.onload = forecastListener;
        req.open("get", reqPath, true);
        req.send();
    }
}

