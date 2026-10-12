import QtQuick
import QtQuick.Shapes

// Bit's outfits, drawn on the top of its body (parent coordinates: 0,0 = body top-left).
Item {
    id: root

    required property string outfit
    // Where the eyes sit on the body, so glasses can line up
    property real eyeY: 14

    anchors.fill: parent

    // cap: a dome and a brim sticking out to the right
    Item {
        visible: root.outfit === "cap"

        Rectangle {
            x: 9
            y: -7
            width: 30
            height: 14
            radius: 9
            color: "#3A86FF"
        }

        Rectangle {
            x: 22
            y: 3
            width: 22
            height: 4
            radius: 2
            color: "#2667CC"
        }
    }

    // bow on the upper right
    Item {
        visible: root.outfit === "bow"

        Rectangle {
            x: root.width - 22
            y: -2
            width: 11
            height: 8
            radius: 3
            rotation: -22
            color: "#FF6B9D"
        }

        Rectangle {
            x: root.width - 13
            y: -1
            width: 11
            height: 8
            radius: 3
            rotation: 22
            color: "#FF6B9D"
        }

        Rectangle {
            x: root.width - 15
            y: 1
            width: 5
            height: 5
            radius: 2.5
            color: "#D6336C"
        }
    }

    // dark glasses across the eyes
    Item {
        visible: root.outfit === "shades"

        Repeater {
            model: 2

            Rectangle {
                required property int index

                x: root.width / 2 - 17 + index * 18
                y: root.eyeY - 2
                width: 16
                height: 10
                radius: 4
                color: "#15151A"
            }
        }

        Rectangle {
            x: root.width / 2 - 2
            y: root.eyeY + 1
            width: 4
            height: 2
            color: "#15151A"
        }
    }

    Poly {
        visible: root.outfit === "crown"
        fill: "#F7B32B"
        points: [[13, 2], [13, -9], [19, -3], [24, -11], [29, -3], [35, -9], [35, 2], [13, 2]]
    }

    // pumpkin: an orange gourd with a green stem
    Item {
        visible: root.outfit === "pumpkin"

        Rectangle {
            x: 12
            y: -8
            width: 24
            height: 14
            radius: 7
            color: "#F2740B"
        }

        Rectangle {
            x: 22
            y: -13
            width: 4
            height: 7
            radius: 2
            color: "#3C8D2F"
        }
    }

    // santa hat: red cone, white band and pom-pom
    Item {
        visible: root.outfit === "santa"

        Poly {
            fill: "#D62828"
            points: [[10, 3], [14, -9], [26, -15], [40, -10], [38, 3], [10, 3]]
        }

        Rectangle {
            x: 8
            y: 0
            width: 32
            height: 6
            radius: 3
            color: "white"
        }

        Rectangle {
            x: 36
            y: -14
            width: 8
            height: 8
            radius: 4
            color: "white"
        }
    }

    // party hat with a stripe and a pom-pom
    Item {
        visible: root.outfit === "party"

        Poly {
            fill: "#8E5CF2"
            points: [[14, 3], [24, -18], [34, 3], [14, 3]]
        }

        Poly {
            fill: "#F7B32B"
            points: [[18, -5], [30, -5], [32, -1], [16, -1], [18, -5]]
        }

        Rectangle {
            x: 21
            y: -22
            width: 6
            height: 6
            radius: 3
            color: "#FF6B9D"
        }
    }

    component Poly: Shape {
        id: poly

        property var points: []
        property color fill: "white"

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: poly.fill
            strokeColor: "transparent"

            PathPolyline {
                path: poly.points.map(p => Qt.point(p[0], p[1]))
            }
        }
    }
}
