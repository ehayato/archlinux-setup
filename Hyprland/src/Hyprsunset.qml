pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    signal gammaChangeAttempt()
    property bool temperatureActive: false
    property real gammaLowerLimit: 25
    property int gamma: 100
    property int colorTemperature: 6500
    property bool automatic: false
    property bool shouldBeOn: false
    property var manualActive: undefined
    function load() {}
    function startHyprsunset() {}
    function enableTemperature() {}
    function disableTemperature() {}
    function setGamma(g) {}
    function fetchState() {}
    function toggleTemperature(active = undefined) {}
    function reEvaluate() {}
    function ensureState() {}
}