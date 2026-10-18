pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models
import org.kde.kitemmodels as KItemModels

// KDE's proxy API is stable across Qt 6.10–6.12; Qt's preview FunctionFilter
// changed its callback contract in 6.12 and silently stopped hiding apps.
KItemModels.KSortFilterProxyModel {
    id: root
    property var inputModel: null
    readonly property ListModel emptyModel: ListModel {}
    property var hiddenApps: []
    property string query: ""
    // Integer role id behind "favoriteId" (resolved by the inner proxy's role name).
    readonly property int favoriteIdRole: visibleApps.filterRole
    function identity(value) { return String(value || "").replace(/^applications:/, ""); }
    function trigger(row, action, argument) {
        const filtered = root.mapToSource(root.index(row, 0));
        const source = visibleApps.mapToSource(filtered);
        if (source.valid && root.inputModel) return root.inputModel.trigger(source.row, action, argument);
        return false;
    }
    onHiddenAppsChanged: visibleApps.invalidateFilter()
    onQueryChanged: invalidateFilter()
    sourceModel: KItemModels.KSortFilterProxyModel {
        id: visibleApps
        sourceModel: root.inputModel ?? root.emptyModel
        filterRoleName: "favoriteId"
        filterRowCallback: (row, parent) => {
            const id = sourceModel.data(sourceModel.index(row, 0, parent), filterRole);
            return !root.hiddenApps.includes(root.identity(id));
        }
    }
    filterRoleName: "display"
    filterRowCallback: (row, parent) => {
        const title = String(visibleApps.data(visibleApps.index(row, 0, parent), root.filterRole) || "");
        return !root.query.length || title.toLocaleLowerCase().includes(root.query.toLocaleLowerCase());
    }
}
