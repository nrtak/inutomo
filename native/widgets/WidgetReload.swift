import WidgetKit

@_cdecl("inushima_reload_widget")
func inushimaReloadWidget() {
    WidgetCenter.shared.reloadTimelines(ofKind: "InushimaDog")
}
