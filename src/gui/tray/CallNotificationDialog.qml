import QtQuick 2.15
import QtQuick.Window 2.15
import Style 1.0
import com.nextcloud.desktopclient 1.0
import QtQuick.Layouts 1.2
import QtMultimedia 5.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15

Window {
    id: root
    color: "transparent"
    flags: Qt.Dialog | Qt.FramelessWindowHint

    readonly property int windowSpacing: 10
    readonly property int windowWidth: 240

    readonly property string svgImage: "image://svgimage-custom-color/%1.svg" + "/"
    readonly property string talkIcon: svgImage.arg("wizard-talk")
    readonly property string deleteIcon: svgImage.arg("delete")

    // We set talkNotificationData, subject, and links properties in C++
    property var talkNotificationData: ({})
    property string subject: ""
    property var links: []
    property string link: ""
    property string ringtonePath: "qrc:///client/theme/call-notification.wav"

    readonly property bool usingUserAvatar: root.talkNotificationData.userAvatar !== ""

    function closeNotification() {
        ringSound.stop();
        root.close();
    }

    width: root.windowWidth
    height: rootBackground.height

    Component.onCompleted: {
        Systray.forceWindowInit(root);
        Systray.positionNotificationWindow(root);

        root.show();
        root.raise();
        root.requestActivate();

        ringSound.play();
     }

    Audio {
        id: ringSound
        source: root.ringtonePath
        loops: 9 // about 45 seconds of audio playing
        audioRole: Audio.RingtoneRole
        onStopped: root.closeNotification()
    }

    Rectangle {
        id: rootBackground
        width: parent.width
        height: contentLayout.height + (root.windowSpacing * 2)
        radius: Systray.useNormalWindow ? 0.0 : Style.trayWindowRadius
        color: Style.backgroundColor
        border.width: Style.trayWindowBorderWidth
        border.color: Style.menuBorder
        clip: true

        Loader {
            id: backgroundLoader
            anchors.fill: parent
            active: root.usingUserAvatar
            sourceComponent: Item {
                anchors.fill: parent

                Image {
                    id: backgroundImage
                    anchors.fill: parent
                    cache: true
                    source: root.talkNotificationData.userAvatar
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: false
                }

                FastBlur {
                    id: backgroundBlur
                    anchors.fill: backgroundImage
                    source: backgroundImage
                    radius: 50
                    visible: false
                }

                Rectangle {
                    id: backgroundMask
                    color: "white"
                    radius: rootBackground.radius
                    anchors.fill: backgroundImage
                    visible: false
                    width: backgroundImage.paintedWidth
                    height: backgroundImage.paintedHeight
                }

                OpacityMask {
                    id: backgroundOpacityMask
                    anchors.fill: backgroundBlur
                    source: backgroundBlur
                    maskSource: backgroundMask
                }

                Rectangle {
                    id: darkenerRect
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.4
                    visible: backgroundOpacityMask.visible
                    radius: rootBackground.radius
                }
            }
        }

        ColumnLayout {
            id: contentLayout
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.windowSpacing
            spacing: root.windowSpacing

            Item {
                width: Style.accountAvatarSize
                height: Style.accountAvatarSize
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Image {
                    id: callerAvatar
                    anchors.fill: parent
                    cache: true

                    source: root.usingUserAvatar ? root.talkNotificationData.userAvatar :
                                                   Theme.darkMode ? root.talkIcon + Style.ncTextColor : root.talkIcon + Style.ncBlue
                    sourceSize.width: Style.accountAvatarSize
                    sourceSize.height: Style.accountAvatarSize

                    visible: !root.usingUserAvatar

                    Accessible.role: Accessible.Indicator
                    Accessible.name: qsTr("Talk notification caller avatar")
                }

                Rectangle {
                    id: mask
                    color: "white"
                    radius: width * 0.5
                    anchors.fill: callerAvatar
                    visible: false
                    width: callerAvatar.paintedWidth
                    height: callerAvatar.paintedHeight
                }

                OpacityMask {
                    anchors.fill: callerAvatar
                    source: callerAvatar
                    maskSource: mask
                    visible: root.usingUserAvatar
                }
            }

            Label {
                id: message
                text: root.subject
                color: root.usingUserAvatar ? "white" : Style.ncTextColor
                font.pixelSize: Style.topLinePixelSize
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: root.windowSpacing / 2
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Repeater {
                    id: linksRepeater
                    model: root.links

                    CustomButton {
                        id: answerCall
                        readonly property string verb: modelData.verb
                        readonly property bool isAnswerCallButton: verb === "WEB"

                        visible: isAnswerCallButton
                        text: modelData.label
                        bold: true
                        bgColor: Style.ncBlue
                        bgOpacity: 0.8

                        textColor: Style.ncHeaderTextColor

                        imageSource: root.talkIcon + Style.ncHeaderTextColor
                        imageSourceHover: root.talkIcon + Style.ncHeaderTextColor

                        Layout.fillWidth: true
                        Layout.preferredHeight: Style.callNotificationPrimaryButtonMinHeight

                        onClicked: {
                            Qt.openUrlExternally(root.link);
                            root.closeNotification();
                        }

                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Answer Talk call notification")
                        Accessible.onPressAction: answerCall.clicked()
                    }

                }

                CustomButton {
                    id: declineCall
                    text: qsTr("Decline")
                    bold: true
                    bgColor: Style.errorBoxBackgroundColor
                    bgOpacity: 0.8

                    textColor: Style.ncHeaderTextColor

                    imageSource: root.deleteIcon + "white"
                    imageSourceHover: root.deleteIcon + "white"

                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.callNotificationPrimaryButtonMinHeight

                    onClicked: root.closeNotification()

                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Decline Talk call notification")
                    Accessible.onPressAction: declineCall.clicked()
                }
            }
        }

    }
}
