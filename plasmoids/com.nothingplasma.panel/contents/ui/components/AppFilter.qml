pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models

SortFilterProxyModel {
    id: root
    property var inputModel: null
    readonly property ListModel emptyModel: ListModel {}
    model: inputModel ?? emptyModel
    property var hiddenApps: []
    property string query: ""
    function identity(value) { return String(value || "").replace(/^applications:/, ""); }
    function trigger(row, action, argument) {
        const source = root.mapToSource(root.index(row, 0));
        if (source.valid && root.model) return root.model.trigger(source.row, action, argument);
        return false;
    }
    onHiddenAppsChanged: invalidate()
    onQueryChanged: invalidate()
    filters: FunctionFilter {
        component RoleData: QtObject {
            property string favoriteId
            property string display
        }
        function filter(data: RoleData): bool {
            return !root.hiddenApps.includes(root.identity(data.favoriteId))
                && (!root.query.length || data.display.toLocaleLowerCase().includes(root.query.toLocaleLowerCase()));
        }
    }
}
