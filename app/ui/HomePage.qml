/*
 * Copyright (C) 2015-2016 Canonical Ltd
 *
 * This file is part of Ubuntu Weather App
 *
 * Ubuntu Weather App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * Ubuntu Weather App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"
import "../data/keys.js" as Keys


Page {
    // Set to null otherwise the header is shown (but blank) over the top of the listview
    id: locationPage
    objectName: "homePage"
    flickable: null

    BottomEdge {
        id: bottomEdge
        // Note: cannot use contentUrl and preload until pad.lv/1604509
        contentComponent: locationsPage
        height: parent.height
        preloadContent: true
        hint {
            // Force using mouse style bottom edge hint (works well in touch)
            status: BottomEdgeHint.Locked
            // Once pad.lv/1536669 is fixed, the status will be auto set to
            // locked when a mouse is detected, in that case we'll show text
            // otherwise we hide the text as this causes strange animations
            text: bottomEdge.hint.status == BottomEdgeHint.Locked ? i18n.tr("Locations") : ""

            // Force using mouse style bottom edge hint (works well in touch)
            onStatusChanged: {
                if (status == BottomEdgeHint.Inactive) {
                    bottomEdge.hint.status = BottomEdgeHint.Locked;
                }
            }
        }

        Component {
            id: locationsPage
            LocationsPage {
                height: bottomEdge.height
                width: bottomEdge.width

                onPop: bottomEdge.collapse()
            }
        }
    }

    property bool hourlyVisible : false

    property var iconMap: {
        "sun": "weather-clear-symbolic",
        "moon": "weather-clear-night-symbolic",
        "cloud_sun": "weather-few-clouds-symbolic",
        "cloud_moon": "weather-few-clouds-night-symbolic",
        "cloud": "weather-clouds-symbolic",
        "rain": "weather-showers-symbolic",
        "thunder": "weather-storm-symbolic",
        "snow_shower": "weather-snow-symbolic",
        "fog": "weather-fog-symbolic",
        "snow_rain": "weather-snow-symbolic",
        "scattered": "weather-showers-scattered-symbolic",
        "overcast": "weather-overcast-symbolic"
    }

    property var imageMap: {
        "sun": Qt.resolvedUrl("../graphics/Sunny.png"),
        "moon": Qt.resolvedUrl("../graphics/Starry-Night.png"),
        "cloud_sun": Qt.resolvedUrl("../graphics/Cloudy-Circles.png"),
        "cloud_moon": Qt.resolvedUrl("../graphics/Cloudy-Night.png"),
        "cloud": Qt.resolvedUrl("../graphics/Cloudy.png"),
        "rain": Qt.resolvedUrl("../graphics/Big-Rain.png"),
        "thunder": Qt.resolvedUrl("../graphics/Stormy.png"),
        "snow_shower": Qt.resolvedUrl("../graphics/Cloudy-Snow.png"),
        "fog": Qt.resolvedUrl("../graphics/Fog.png"),
        "snow_rain": Qt.resolvedUrl("../graphics/Cloudy-Snow.png"),
        "scattered": Qt.resolvedUrl("../graphics/Showers.png"),
        "overcast": Qt.resolvedUrl("../graphics/Cloudy.png")
    }

    /*
      Format date object by given format.
    */
    function formatTimestamp(dateData, format) {
        return Qt.formatDate(getDate(dateData), i18n.tr(format))
    }

    /*
      Format time object by given format.
    */
    function formatTime(dateData, format) {
        return Qt.formatTime(getDate(dateData), i18n.tr(format))
    }

    /*
      Get Date object from dateData.
    */
    function getDate(dateData) {
        return new Date(dateData.year, dateData.month, dateData.date, dateData.hours, dateData.minutes)
    }

    // Do not show the Page Header
    header: PageHeader {
        visible: false
    }

    /*
      Background for the PageWithBottomEdge
    */
    Rectangle {
        id: pageBackground
        anchors.fill: parent
        color: "white"
    }

    /*
      ListView for locations with snap-scrolling horizontally.
    */
    ListView {
        id: locationPages
        objectName: "locationPages"
        anchors {
            fill: parent
        }
        contentHeight: parent.height - bottomEdge.hint.height
        currentIndex: settings.current
        delegate: LocationPane {
            objectName: "locationPane" + index
            graphicVisible: !hourlyVisible
        }
        highlightRangeMode: ListView.StrictlyEnforceRange
        model: weatherApp.locationsList.length
        orientation: ListView.Horizontal
        // TODO with snapMode, currentIndex is not properly set and setting currentIndex fails
        //snapMode: ListView.SnapOneItem

        property bool loaded: false

        signal collapseOtherDelegates(int index)

        onCurrentIndexChanged: {
            if (loaded) {
                // FIXME: when a model is reloaded this causes the currentIndex to be lost
                settings.current = currentIndex

                collapseOtherDelegates(-1)  // collapse all
            }
        }
        onModelChanged: {
            currentIndex = settings.current

            if (model > 0) {
                loading = false
                loaded = true
            }
        }
        onVisibleChanged: {
            if (!visible && loaded) {
                collapseOtherDelegates(-1)  // collapse all
            }
        }

        // TODO: workaround for not being able to use snapMode property
        Component.onCompleted: {
            var scaleFactor = units.gridUnit * 10;
            maximumFlickVelocity = maximumFlickVelocity * scaleFactor;
            flickDeceleration = flickDeceleration * scaleFactor;
        }

        Connections {
            target: settings
            onCurrentChanged: {
                locationPages.currentIndex = settings.current
            }
        }
    }

    LoadingIndicator {
        id: loadingIndicator
        anchors {
            bottom: parent.bottom
            bottomMargin: Qt.inputMethod.keyboardRectangle.height + bottomEdge.hint.height
            left: parent.left
            right: parent.right
        }
        processing: loading
    }

    Loader {
        active: (locationsList === null || locationsList.length === 0) && mainPageStack.depth === 1
        anchors {
            fill: parent
        }
        asynchronous: true
        source: "../components/HomePageEmptyStateComponent.qml"
        visible: status === Loader.Ready && active
    }
    
    Loader {
        active: networkError && mainPageStack.depth === 1 && (Keys.twcKey || Keys.owmKey)
        anchors {
            fill: parent
        }
        asynchronous: true
        source: "../components/NetworkErrorStateComponent.qml"
        visible: status === Loader.Ready && active
    }

    Loader {
        active: mainPageStack.depth === 1 && !Keys.twcKey && !Keys.owmKey
        anchors {
            fill: parent
        }
        asynchronous: true
        source: "../components/NoAPIKeyErrorStateComponent.qml"
        visible: status === Loader.Ready && active
    }
}
